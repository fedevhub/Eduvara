-- Create the content tables the mobile app expects for student courses, quizzes,
-- progress tracking, and notifications.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  course_id_type text;
BEGIN
  SELECT format_type(attribute.atttypid, attribute.atttypmod)
  INTO course_id_type
  FROM pg_attribute AS attribute
  WHERE attribute.attrelid = 'public.courses'::regclass
    AND attribute.attname = 'id'
    AND NOT attribute.attisdropped;

  IF course_id_type IS NULL THEN
    RAISE EXCEPTION 'public.courses must have an id column before student learning tables can be created.';
  END IF;

  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS public.materials (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      course_id %s NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
      title text NOT NULL,
      content text DEFAULT '''',
      summary text DEFAULT '''',
      file_name text DEFAULT '''',
      file_size bigint DEFAULT 0,
      file_url text DEFAULT '''',
      scheduled_at timestamptz,
      order_no integer NOT NULL DEFAULT 0,
      created_at timestamptz NOT NULL DEFAULT now()
    )',
    course_id_type
  );

  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS public.quizzes (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      course_id %s NOT NULL REFERENCES public.courses(id) ON DELETE CASCADE,
      title text NOT NULL,
      description text DEFAULT '''',
      question_count integer NOT NULL DEFAULT 0,
      duration_minutes integer NOT NULL DEFAULT 0,
      passing_score integer NOT NULL DEFAULT 0,
      order_no integer NOT NULL DEFAULT 0,
      created_at timestamptz NOT NULL DEFAULT now()
    )',
    course_id_type
  );
END;
$$;

CREATE TABLE IF NOT EXISTS public.material_progress (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  material_id uuid NOT NULL REFERENCES public.materials(id) ON DELETE CASCADE,
  completed boolean NOT NULL DEFAULT false,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, material_id)
);

CREATE TABLE IF NOT EXISTS public.quiz_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  quiz_id uuid NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
  score numeric(5,2) NOT NULL DEFAULT 0,
  correct_count integer NOT NULL DEFAULT 0,
  wrong_count integer NOT NULL DEFAULT 0,
  completed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS quiz_attempts_user_quiz_unique_idx
  ON public.quiz_attempts (user_id, quiz_id);

CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  is_read boolean NOT NULL DEFAULT false
);

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS title text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS message text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS is_read boolean NOT NULL DEFAULT false;

UPDATE public.notifications
SET id = gen_random_uuid()
WHERE id IS NULL;

ALTER TABLE public.notifications
  ALTER COLUMN id SET DEFAULT gen_random_uuid(),
  ALTER COLUMN id SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS notifications_id_idx
  ON public.notifications(id);

ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.material_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS authenticated_read_materials ON public.materials;
CREATE POLICY authenticated_read_materials
ON public.materials
FOR SELECT
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.courses AS c
    WHERE c.id::text = materials.course_id::text
      AND c.teacher_id::text = auth.uid()::text
  )
  OR EXISTS (
    SELECT 1
    FROM public.enrollments AS e
    WHERE e.course_id::text = materials.course_id::text
      AND e.student_id::text = auth.uid()::text
  )
);

DROP POLICY IF EXISTS authenticated_read_quizzes ON public.quizzes;
CREATE POLICY authenticated_read_quizzes
ON public.quizzes
FOR SELECT
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.courses AS c
    WHERE c.id::text = quizzes.course_id::text
      AND c.teacher_id::text = auth.uid()::text
  )
  OR EXISTS (
    SELECT 1
    FROM public.enrollments AS e
    WHERE e.course_id::text = quizzes.course_id::text
      AND e.student_id::text = auth.uid()::text
  )
);

DROP POLICY IF EXISTS authenticated_manage_material_progress ON public.material_progress;
CREATE POLICY authenticated_manage_material_progress
ON public.material_progress
FOR ALL
TO authenticated
USING (user_id::text = auth.uid()::text OR public.is_admin())
WITH CHECK (user_id::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS authenticated_manage_quiz_attempts ON public.quiz_attempts;
CREATE POLICY authenticated_manage_quiz_attempts
ON public.quiz_attempts
FOR ALL
TO authenticated
USING (user_id::text = auth.uid()::text OR public.is_admin())
WITH CHECK (user_id::text = auth.uid()::text OR public.is_admin());

DROP POLICY IF EXISTS authenticated_read_notifications ON public.notifications;
CREATE POLICY authenticated_read_notifications
ON public.notifications
FOR SELECT
TO authenticated
USING (user_id::text = auth.uid()::text OR user_id IS NULL OR public.is_admin());

DROP POLICY IF EXISTS authenticated_insert_notifications ON public.notifications;
CREATE POLICY authenticated_insert_notifications
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (user_id::text = auth.uid()::text OR user_id IS NULL OR public.is_admin());

GRANT SELECT ON public.materials TO authenticated;
GRANT SELECT ON public.quizzes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.material_progress TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.quiz_attempts TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.notifications TO authenticated;

CREATE INDEX IF NOT EXISTS materials_course_id_idx
  ON public.materials(course_id, order_no);
CREATE INDEX IF NOT EXISTS quizzes_course_id_idx
  ON public.quizzes(course_id, order_no);
CREATE INDEX IF NOT EXISTS material_progress_user_idx
  ON public.material_progress(user_id, material_id);
CREATE INDEX IF NOT EXISTS quiz_attempts_user_idx
  ON public.quiz_attempts(user_id, quiz_id, created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_user_idx
  ON public.notifications(user_id, created_at DESC);
