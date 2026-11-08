CREATE TABLE IF NOT EXISTS public.school_settings (
  id smallint PRIMARY KEY CHECK (id = 1),
  school_name text NOT NULL,
  academic_year text NOT NULL,
  class_count integer NOT NULL CHECK (class_count >= 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.school_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_manage_school_settings
  ON public.school_settings;
CREATE POLICY admin_manage_school_settings
  ON public.school_settings
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

GRANT SELECT, INSERT, UPDATE ON public.school_settings TO authenticated;

INSERT INTO public.school_settings (
  id,
  school_name,
  academic_year,
  class_count
)
SELECT
  1,
  'SMK Negeri 8 Malang',
  CASE
    WHEN extract(month FROM CURRENT_DATE) >= 7
      THEN format('%s/%s', extract(year FROM CURRENT_DATE)::integer,
        extract(year FROM CURRENT_DATE)::integer + 1)
    ELSE format('%s/%s', extract(year FROM CURRENT_DATE)::integer - 1,
      extract(year FROM CURRENT_DATE)::integer)
  END,
  (
    SELECT count(DISTINCT nullif(btrim(account.kelas), ''))::integer
    FROM public."user" AS account
    WHERE account.kelas IS NOT NULL
  )
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.quiz_attempts
  ADD COLUMN IF NOT EXISTS total_points numeric(7, 2) NOT NULL DEFAULT 0;

UPDATE public.quiz_attempts AS attempt
SET total_points = question_totals.total_points,
    score = round(attempt.score * question_totals.total_points / 100, 2)
FROM (
  SELECT quiz_id, sum(points)::numeric(7, 2) AS total_points
  FROM public.quiz_questions
  GROUP BY quiz_id
) AS question_totals
WHERE attempt.quiz_id = question_totals.quiz_id
  AND attempt.total_points = 0;

CREATE OR REPLACE FUNCTION public.submit_quiz_attempt(
  p_quiz_id uuid,
  p_answers jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_attempt_id uuid;
  v_question_count integer;
  v_answer_count integer;
  v_distinct_answer_count integer;
  v_correct_count integer;
  v_wrong_count integer;
  v_total_points numeric(7, 2);
  v_earned_points numeric(7, 2);
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
       OR coalesce(submitted.answer->>'question_id', '')
            !~ '^[0-9a-fA-F-]{36}$'
       OR coalesce(submitted.answer->>'selected_option', '')
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

  SELECT count(*)::integer, coalesce(sum(question.points), 0)::numeric(7, 2)
  INTO v_question_count, v_total_points
  FROM public.quiz_questions AS question
  WHERE question.quiz_id = p_quiz_id;
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
    LEFT JOIN public.quiz_questions AS question
      ON question.id = (submitted.answer->>'question_id')::uuid
     AND question.quiz_id = p_quiz_id
    WHERE question.id IS NULL
  ) THEN
    RAISE EXCEPTION 'Jawaban mengandung soal yang bukan bagian dari quiz.';
  END IF;

  SELECT
    count(*) FILTER (
      WHERE (submitted.answer->>'selected_option')::integer =
        question.correct_option
    )::integer,
    coalesce(
      sum(question.points) FILTER (
        WHERE (submitted.answer->>'selected_option')::integer =
          question.correct_option
      ),
      0
    )::numeric(7, 2)
  INTO v_correct_count, v_earned_points
  FROM jsonb_array_elements(p_answers) AS submitted(answer)
  JOIN public.quiz_questions AS question
    ON question.id = (submitted.answer->>'question_id')::uuid
   AND question.quiz_id = p_quiz_id;

  v_wrong_count := v_question_count - v_correct_count;

  INSERT INTO public.quiz_attempts (
    user_id,
    quiz_id,
    score,
    total_points,
    correct_count,
    wrong_count,
    completed
  )
  VALUES (
    v_user_id,
    p_quiz_id,
    v_earned_points,
    v_total_points,
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

REVOKE ALL ON FUNCTION public.submit_quiz_attempt(uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_quiz_attempt(uuid, jsonb)
  TO authenticated;
