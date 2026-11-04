DO $$
DECLARE
  missing_tables text;
BEGIN
  SELECT string_agg(required.table_name, ', ')
  INTO missing_tables
  FROM (
    VALUES
      ('public.courses'),
      ('public.enrollments'),
      ('public.profiles'),
      ('public."user"'),
      ('public.materials'),
      ('public.quizzes'),
      ('public.material_progress'),
      ('public.quiz_attempts'),
      ('public.notifications')
  ) AS required(table_name)
  WHERE to_regclass(required.table_name) IS NULL;

  IF missing_tables IS NOT NULL THEN
    RAISE EXCEPTION 'Required tables are missing: %. Apply the prerequisite migrations in order: 20261102000600_course_crud_activity.sql, then 20261104000100_student_learning_tables.sql, then 20261104000200_student_profile_read.sql and 20261104000300_teacher_content_notifications.sql. Rerun this migration last.',
      missing_tables;
  END IF;
END;
$$;

ALTER TABLE public.materials
  ADD COLUMN IF NOT EXISTS description text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS video_url text,
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.quizzes
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'draft';

CREATE TABLE IF NOT EXISTS public.quiz_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id uuid NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
  question text NOT NULL,
  option_a text NOT NULL DEFAULT '',
  option_b text NOT NULL DEFAULT '',
  option_c text NOT NULL DEFAULT '',
  option_d text NOT NULL DEFAULT '',
  correct_option integer NOT NULL DEFAULT 0 CHECK (correct_option BETWEEN 0 AND 3),
  points integer NOT NULL DEFAULT 20 CHECK (points > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS teacher_manage_materials ON public.materials;
CREATE POLICY teacher_manage_materials
ON public.materials
FOR ALL
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.courses AS course
    WHERE course.id::text = materials.course_id::text
      AND course.teacher_id::text = auth.uid()::text
  )
)
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.courses AS course
    WHERE course.id::text = materials.course_id::text
      AND course.teacher_id::text = auth.uid()::text
  )
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.materials TO authenticated;

DROP POLICY IF EXISTS teacher_manage_quizzes ON public.quizzes;
CREATE POLICY teacher_manage_quizzes
ON public.quizzes
FOR ALL
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.courses AS course
    WHERE course.id::text = quizzes.course_id::text
      AND course.teacher_id::text = auth.uid()::text
  )
)
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.courses AS course
    WHERE course.id::text = quizzes.course_id::text
      AND course.teacher_id::text = auth.uid()::text
  )
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quizzes TO authenticated;

DROP POLICY IF EXISTS teacher_manage_quiz_questions ON public.quiz_questions;
CREATE POLICY teacher_manage_quiz_questions
ON public.quiz_questions
FOR ALL
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.quizzes AS quiz
    JOIN public.courses AS course ON course.id::text = quiz.course_id::text
    WHERE quiz.id = quiz_questions.quiz_id
      AND course.teacher_id::text = auth.uid()::text
  )
)
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.quizzes AS quiz
    JOIN public.courses AS course ON course.id::text = quiz.course_id::text
    WHERE quiz.id = quiz_questions.quiz_id
      AND course.teacher_id::text = auth.uid()::text
  )
);

DROP POLICY IF EXISTS enrolled_read_quiz_questions ON public.quiz_questions;
CREATE POLICY enrolled_read_quiz_questions
ON public.quiz_questions
FOR SELECT
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.quizzes AS quiz
    JOIN public.enrollments AS enrollment
      ON enrollment.course_id::text = quiz.course_id::text
    WHERE quiz.id = quiz_questions.quiz_id
      AND quiz.status = 'published'
      AND enrollment.student_id::text = auth.uid()::text
  )
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quiz_questions TO authenticated;

DROP POLICY IF EXISTS authenticated_update_own_notifications ON public.notifications;
CREATE POLICY authenticated_update_own_notifications
ON public.notifications
FOR UPDATE
TO authenticated
USING (user_id::text = auth.uid()::text OR public.is_admin())
WITH CHECK (user_id::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS teacher_read_enrolled_student_profiles ON public.profiles;
CREATE POLICY teacher_read_enrolled_student_profiles
ON public.profiles
FOR SELECT
TO authenticated
USING (
  role = 'student'
  AND EXISTS (
    SELECT 1
    FROM public.enrollments AS enrollment
    JOIN public.courses AS course
      ON course.id::text = enrollment.course_id::text
    WHERE enrollment.student_id::text = profiles.id::text
      AND course.teacher_id::text = auth.uid()::text
  )
);

DROP POLICY IF EXISTS teacher_read_enrolled_student_users ON public."user";
CREATE POLICY teacher_read_enrolled_student_users
ON public."user"
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.enrollments AS enrollment
    JOIN public.courses AS course
      ON course.id::text = enrollment.course_id::text
    WHERE enrollment.student_id::text = "user".id_user::text
      AND course.teacher_id::text = auth.uid()::text
  )
);

DROP POLICY IF EXISTS teacher_read_enrolled_material_progress ON public.material_progress;
CREATE POLICY teacher_read_enrolled_material_progress
ON public.material_progress
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.materials AS material
    JOIN public.courses AS course
      ON course.id::text = material.course_id::text
    JOIN public.enrollments AS enrollment
      ON enrollment.course_id::text = course.id::text
    WHERE material.id = material_progress.material_id
      AND enrollment.student_id::text = material_progress.user_id::text
      AND course.teacher_id::text = auth.uid()::text
  )
);

DROP POLICY IF EXISTS teacher_read_enrolled_quiz_attempts ON public.quiz_attempts;
CREATE POLICY teacher_read_enrolled_quiz_attempts
ON public.quiz_attempts
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.quizzes AS quiz
    JOIN public.enrollments AS enrollment
      ON enrollment.course_id::text = quiz.course_id::text
    JOIN public.courses AS course
      ON course.id::text = quiz.course_id::text
    WHERE quiz.id = quiz_attempts.quiz_id
      AND enrollment.student_id::text = quiz_attempts.user_id::text
      AND course.teacher_id::text = auth.uid()::text
  )
);

CREATE OR REPLACE FUNCTION public.notify_course_students_of_new_content()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  content_kind text;
  content_title text;
  course_title text;
  teacher_name text;
BEGIN
  content_kind := CASE WHEN TG_TABLE_NAME = 'materials' THEN 'materi' ELSE 'quiz' END;
  IF TG_TABLE_NAME = 'quizzes' THEN
    IF to_jsonb(NEW) ->> 'status' IS DISTINCT FROM 'published'
       OR (
         TG_OP = 'UPDATE'
         AND to_jsonb(OLD) ->> 'status' = 'published'
       ) THEN
      RETURN NEW;
    END IF;
  END IF;

  content_title := coalesce(
    to_jsonb(NEW) ->> 'title',
    to_jsonb(NEW) ->> 'nama_quiz',
    'baru'
  );

  SELECT course.title, coalesce(profile.full_name, 'Guru')
  INTO course_title, teacher_name
  FROM public.courses AS course
  LEFT JOIN public.profiles AS profile
    ON profile.id::text = course.teacher_id::text
  WHERE course.id::text = coalesce(
    to_jsonb(NEW) ->> 'course_id',
    to_jsonb(NEW) ->> 'id_course'
  );

  IF course_title IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, title, message)
  SELECT DISTINCT enrollment.student_id,
    CASE WHEN content_kind = 'materi' THEN 'Materi Baru' ELSE 'Quiz Baru' END,
    format('%s menambahkan %s "%s" di course "%s".',
      teacher_name, content_kind, content_title, course_title)
  FROM public.enrollments AS enrollment
  WHERE enrollment.course_id::text = coalesce(
    to_jsonb(NEW) ->> 'course_id',
    to_jsonb(NEW) ->> 'id_course'
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS notify_students_of_new_material ON public.materials;
CREATE TRIGGER notify_students_of_new_material
AFTER INSERT ON public.materials
FOR EACH ROW EXECUTE FUNCTION public.notify_course_students_of_new_content();

DROP TRIGGER IF EXISTS notify_students_of_new_quiz ON public.quizzes;
CREATE TRIGGER notify_students_of_new_quiz
AFTER INSERT OR UPDATE OF status ON public.quizzes
FOR EACH ROW EXECUTE FUNCTION public.notify_course_students_of_new_content();

CREATE OR REPLACE FUNCTION public.notify_teacher_and_admin_of_student_activity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  student_name text;
  activity_title text;
  activity_message text;
  target_course_id text;
  quiz_title text;
  course_teacher uuid;
  score_text text;
BEGIN
  SELECT coalesce(profile.full_name, 'Siswa')
  INTO student_name
  FROM public.profiles AS profile
  WHERE profile.id::text = NEW.user_id::text;

  IF TG_TABLE_NAME = 'material_progress' THEN
    IF NEW.completed IS DISTINCT FROM true
       OR (TG_OP = 'UPDATE' AND OLD.completed = true) THEN
      RETURN NEW;
    END IF;

    SELECT material.course_id::text, material.title
    INTO target_course_id, quiz_title
    FROM public.materials AS material
    WHERE material.id = NEW.material_id;

    activity_title := 'Materi Diselesaikan';
    activity_message := format('%s menyelesaikan materi "%s".',
      student_name, coalesce(quiz_title, 'Materi'));
  ELSE
    IF NEW.completed IS DISTINCT FROM true THEN
      RETURN NEW;
    END IF;

    SELECT quiz.course_id::text, quiz.title
    INTO target_course_id, quiz_title
    FROM public.quizzes AS quiz
    WHERE quiz.id = NEW.quiz_id;
    SELECT course.teacher_id
    INTO course_teacher
    FROM public.courses AS course
    WHERE course.id::text = target_course_id;

    score_text := coalesce(NEW.score::text, '0');
    activity_title := 'Quiz Selesai';
    activity_message := format('%s menyelesaikan quiz "%s" dengan nilai %s.',
      student_name, coalesce(quiz_title, 'Quiz'), score_text);
  END IF;

  IF course_teacher IS NULL AND target_course_id IS NOT NULL THEN
    SELECT course.teacher_id
    INTO course_teacher
    FROM public.courses AS course
    WHERE course.id::text = target_course_id;
  END IF;

  INSERT INTO public.notifications (user_id, title, message)
  SELECT DISTINCT recipient.user_id, activity_title, activity_message
  FROM (
    SELECT course_teacher AS user_id
    UNION
    SELECT profile.id
    FROM public.profiles AS profile
    WHERE profile.role = 'admin'
  ) AS recipient
  WHERE recipient.user_id IS NOT NULL;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS notify_teacher_of_material_completion ON public.material_progress;
CREATE TRIGGER notify_teacher_of_material_completion
AFTER INSERT OR UPDATE OF completed ON public.material_progress
FOR EACH ROW EXECUTE FUNCTION public.notify_teacher_and_admin_of_student_activity();

DROP TRIGGER IF EXISTS notify_teacher_of_quiz_completion ON public.quiz_attempts;
CREATE TRIGGER notify_teacher_of_quiz_completion
AFTER INSERT ON public.quiz_attempts
FOR EACH ROW EXECUTE FUNCTION public.notify_teacher_and_admin_of_student_activity();

CREATE OR REPLACE FUNCTION public.notify_students_of_admin_course()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  admin_name text;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles AS profile
    WHERE profile.id::text = auth.uid()::text
      AND profile.role = 'admin'
  ) THEN
    RETURN NEW;
  END IF;

  SELECT coalesce(profile.full_name, 'Admin')
  INTO admin_name
  FROM public.profiles AS profile
  WHERE profile.id::text = auth.uid()::text;

  INSERT INTO public.notifications (user_id, title, message)
  SELECT profile.id, 'Course Baru',
    format('%s menambahkan course "%s".',
      coalesce(admin_name, 'Admin'), NEW.title)
  FROM public.profiles AS profile
  WHERE profile.role IN ('student', 'admin');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS notify_users_of_new_course ON public.courses;
CREATE TRIGGER notify_users_of_new_course
AFTER INSERT ON public.courses
FOR EACH ROW
WHEN (coalesce(auth.jwt() ->> 'role', '') = 'authenticated')
EXECUTE FUNCTION public.notify_students_of_admin_course();
