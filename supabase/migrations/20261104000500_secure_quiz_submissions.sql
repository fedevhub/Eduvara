CREATE TABLE IF NOT EXISTS public.quiz_attempt_answers (
  attempt_id uuid NOT NULL
    REFERENCES public.quiz_attempts(id) ON DELETE CASCADE,
  question_id uuid NOT NULL
    REFERENCES public.quiz_questions(id) ON DELETE CASCADE,
  selected_option integer NOT NULL CHECK (selected_option BETWEEN 0 AND 3),
  PRIMARY KEY (attempt_id, question_id)
);

ALTER TABLE public.quiz_attempt_answers ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON public.quiz_attempt_answers TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.quiz_attempt_answers
  FROM PUBLIC, anon, authenticated;

CREATE POLICY student_read_own_quiz_attempt_answers
  ON public.quiz_attempt_answers
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.quiz_attempts attempt
      WHERE attempt.id = quiz_attempt_answers.attempt_id
        AND attempt.user_id = auth.uid()
    )
  );

CREATE POLICY teacher_read_enrolled_quiz_attempt_answers
  ON public.quiz_attempt_answers
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.quiz_attempts attempt
      JOIN public.quizzes quiz ON quiz.id = attempt.quiz_id
      JOIN public.courses course ON course.id = quiz.course_id
      JOIN public.enrollments enrollment
        ON enrollment.course_id = course.id
       AND enrollment.student_id = attempt.user_id
      WHERE attempt.id = quiz_attempt_answers.attempt_id
        AND course.teacher_id::text = auth.uid()::text
    )
  );

DROP POLICY IF EXISTS enrolled_read_quiz_questions
  ON public.quiz_questions;

DROP POLICY IF EXISTS authenticated_manage_quiz_attempts
  ON public.quiz_attempts;

CREATE POLICY student_read_own_quiz_attempts
  ON public.quiz_attempts
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

REVOKE INSERT, UPDATE, DELETE ON public.quiz_attempts
  FROM PUBLIC, anon, authenticated;

DROP POLICY IF EXISTS authenticated_manage_material_progress
  ON public.material_progress;

CREATE POLICY enrolled_manage_material_progress
  ON public.material_progress
  FOR ALL
  TO authenticated
  USING (
    public.is_admin()
    OR (
      user_id = auth.uid()
      AND EXISTS (
        SELECT 1
        FROM public.materials AS material
        JOIN public.courses AS course ON course.id = material.course_id
        JOIN public.enrollments AS enrollment
          ON enrollment.course_id = course.id
         AND enrollment.student_id = auth.uid()
        WHERE material.id = material_progress.material_id
          AND course.status = 'active'
      )
    )
  )
  WITH CHECK (
    public.is_admin()
    OR (
      user_id = auth.uid()
      AND EXISTS (
        SELECT 1
        FROM public.materials AS material
        JOIN public.courses AS course ON course.id = material.course_id
        JOIN public.enrollments AS enrollment
          ON enrollment.course_id = course.id
         AND enrollment.student_id = auth.uid()
        WHERE material.id = material_progress.material_id
          AND course.status = 'active'
      )
    )
  );

DROP POLICY IF EXISTS authenticated_read_courses
  ON public.courses;

CREATE POLICY authenticated_read_courses
  ON public.courses
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin()
    OR teacher_id::text = auth.uid()::text
    OR (
      status = 'active'
      AND EXISTS (
        SELECT 1
        FROM public.enrollments AS enrollment
        WHERE enrollment.course_id = courses.id
          AND enrollment.student_id = auth.uid()
      )
    )
  );

CREATE POLICY student_read_enrolled_teacher_profiles
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin()
    OR (
      role = 'teacher'
      AND EXISTS (
        SELECT 1
        FROM public.courses AS course
        JOIN public.enrollments AS enrollment
          ON enrollment.course_id = course.id
        WHERE course.teacher_id::text = profiles.id::text
          AND course.status = 'active'
          AND enrollment.student_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS authenticated_read_materials
  ON public.materials;

CREATE POLICY authenticated_read_materials
  ON public.materials
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.courses AS course
      WHERE course.id = materials.course_id
        AND course.teacher_id::text = auth.uid()::text
    )
    OR EXISTS (
      SELECT 1
      FROM public.courses AS course
      JOIN public.enrollments AS enrollment
        ON enrollment.course_id = course.id
      WHERE course.id = materials.course_id
        AND course.status = 'active'
        AND enrollment.student_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS authenticated_read_quizzes
  ON public.quizzes;

CREATE POLICY authenticated_read_quizzes
  ON public.quizzes
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.courses AS course
      WHERE course.id = quizzes.course_id
        AND course.teacher_id::text = auth.uid()::text
    )
    OR EXISTS (
      SELECT 1
      FROM public.courses AS course
      JOIN public.enrollments AS enrollment
        ON enrollment.course_id = course.id
      WHERE course.id = quizzes.course_id
        AND course.status = 'active'
        AND quizzes.status = 'published'
        AND enrollment.student_id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION public.get_student_quiz_questions(p_quiz_id uuid)
RETURNS TABLE (
  id uuid,
  question text,
  option_a text,
  option_b text,
  option_c text,
  option_d text,
  points integer
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    quiz_question.id,
    quiz_question.question,
    quiz_question.option_a,
    quiz_question.option_b,
    quiz_question.option_c,
    quiz_question.option_d,
    quiz_question.points
  FROM public.quiz_questions AS quiz_question
  JOIN public.quizzes AS quiz ON quiz.id = quiz_question.quiz_id
  JOIN public.courses AS course ON course.id = quiz.course_id
  WHERE quiz.id = p_quiz_id
    AND quiz.status = 'published'
    AND course.status = 'active'
    AND EXISTS (
      SELECT 1
      FROM public.profiles AS profile
      JOIN public.enrollments AS enrollment
        ON enrollment.student_id = profile.id
       AND enrollment.course_id = course.id
      WHERE profile.id = auth.uid()
        AND profile.role = 'student'
    )
  ORDER BY quiz_question.id;
$$;

CREATE OR REPLACE FUNCTION public.submit_quiz_attempt(
  p_quiz_id uuid,
  p_answers jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_attempt_id uuid;
  v_question_count integer;
  v_answer_count integer;
  v_distinct_answer_count integer;
  v_correct_count integer;
  v_wrong_count integer;
  v_total_points numeric;
  v_earned_points numeric;
  v_score numeric(5, 2);
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Sesi login tidak ditemukan.';
  END IF;

  IF jsonb_typeof(p_answers) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'Format jawaban quiz tidak valid.';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM jsonb_array_elements(p_answers) AS submitted(answer)
    WHERE jsonb_typeof(submitted.answer) IS DISTINCT FROM 'object'
       OR COALESCE(submitted.answer->>'question_id', '')
            !~ '^[0-9a-fA-F-]{36}$'
       OR COALESCE(submitted.answer->>'selected_option', '')
            !~ '^[0-3]$'
  ) THEN
    RAISE EXCEPTION 'Pilihan jawaban quiz tidak valid.';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended(v_user_id::text || ':' || p_quiz_id::text, 0)
  );

  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles AS profile
    JOIN public.enrollments AS enrollment
      ON enrollment.student_id = profile.id
    JOIN public.quizzes AS quiz ON quiz.course_id = enrollment.course_id
    JOIN public.courses AS course ON course.id = quiz.course_id
    WHERE profile.id = v_user_id
      AND profile.role = 'student'
      AND quiz.id = p_quiz_id
      AND quiz.status = 'published'
      AND course.status = 'active'
  ) THEN
    RAISE EXCEPTION 'Quiz tidak tersedia untuk akun atau course ini.';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.quiz_attempts AS attempt
    WHERE attempt.user_id = v_user_id
      AND attempt.quiz_id = p_quiz_id
      AND attempt.completed
  ) THEN
    RAISE EXCEPTION 'Quiz ini sudah pernah diselesaikan.';
  END IF;

  SELECT count(*)::integer, COALESCE(sum(quiz_question.points), 0)
  INTO v_question_count, v_total_points
  FROM public.quiz_questions AS quiz_question
  WHERE quiz_question.quiz_id = p_quiz_id;
  IF v_question_count = 0 THEN
    RAISE EXCEPTION 'Quiz ini belum memiliki soal.';
  END IF;

  SELECT
    count(*)::integer,
    count(DISTINCT (submitted.answer->>'question_id')::uuid)::integer
  INTO v_answer_count, v_distinct_answer_count
  FROM jsonb_array_elements(p_answers) AS submitted(answer);

  IF v_answer_count <> v_distinct_answer_count THEN
    RAISE EXCEPTION 'Soal yang sama tidak dapat dijawab lebih dari sekali.';
  END IF;

  IF v_answer_count > v_question_count OR EXISTS (
    SELECT 1
    FROM jsonb_array_elements(p_answers) AS submitted(answer)
    LEFT JOIN public.quiz_questions AS quiz_question
      ON quiz_question.id = (submitted.answer->>'question_id')::uuid
     AND quiz_question.quiz_id = p_quiz_id
    WHERE quiz_question.id IS NULL
  ) THEN
    RAISE EXCEPTION 'Jawaban mengandung soal yang bukan bagian dari quiz.';
  END IF;

  SELECT
    count(*) FILTER (
      WHERE (submitted.answer->>'selected_option')::integer =
        quiz_question.correct_option
    )::integer,
    COALESCE(
      sum(quiz_question.points) FILTER (
        WHERE (submitted.answer->>'selected_option')::integer =
          quiz_question.correct_option
      ),
      0
    )
  INTO v_correct_count, v_earned_points
  FROM jsonb_array_elements(p_answers) AS submitted(answer)
  JOIN public.quiz_questions AS quiz_question
    ON quiz_question.id = (submitted.answer->>'question_id')::uuid
   AND quiz_question.quiz_id = p_quiz_id;

  v_wrong_count := v_question_count - v_correct_count;
  v_score := CASE
    WHEN v_total_points = 0 THEN 0
    ELSE round(v_earned_points * 100 / v_total_points, 2)
  END;

  INSERT INTO public.quiz_attempts (
    user_id,
    quiz_id,
    score,
    correct_count,
    wrong_count,
    completed
  )
  VALUES (
    v_user_id,
    p_quiz_id,
    v_score,
    v_correct_count,
    v_wrong_count,
    true
  )
  RETURNING id INTO v_attempt_id;

  INSERT INTO public.quiz_attempt_answers (
    attempt_id,
    question_id,
    selected_option
  )
  SELECT
    v_attempt_id,
    (submitted.answer->>'question_id')::uuid,
    (submitted.answer->>'selected_option')::integer
  FROM jsonb_array_elements(p_answers) AS submitted(answer);

  RETURN v_attempt_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_student_quiz_questions(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.submit_quiz_attempt(uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_student_quiz_questions(uuid)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_quiz_attempt(uuid, jsonb)
  TO authenticated;
