CREATE OR REPLACE FUNCTION public.log_student_quiz_completion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  student_name text;
  quiz_title text;
BEGIN
  IF NEW.completed IS DISTINCT FROM true THEN
    RETURN NEW;
  END IF;

  SELECT profile.full_name
  INTO student_name
  FROM public.profiles AS profile
  WHERE profile.id = NEW.user_id
    AND profile.role = 'student';

  IF student_name IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT quiz.title
  INTO quiz_title
  FROM public.quizzes AS quiz
  WHERE quiz.id = NEW.quiz_id;

  INSERT INTO public.activity_logs (
    actor_id,
    actor_name,
    actor_role,
    action,
    entity,
    entity_id,
    entity_name
  )
  VALUES (
    NEW.user_id,
    student_name,
    'student',
    'submit',
    'quiz',
    NEW.quiz_id::text,
    coalesce(quiz_title, 'Quiz')
  );

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.log_student_quiz_completion()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS admin_log_student_quiz_completion
  ON public.quiz_attempts;
CREATE TRIGGER admin_log_student_quiz_completion
AFTER INSERT ON public.quiz_attempts
FOR EACH ROW
EXECUTE FUNCTION public.log_student_quiz_completion();

CREATE OR REPLACE FUNCTION public.log_student_course_completion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  student_id uuid := NEW.user_id;
  course_id text;
  course_title text;
  total_tasks bigint;
  completed_tasks bigint;
BEGIN
  IF NEW.completed IS DISTINCT FROM true
     OR (
       TG_TABLE_NAME = 'material_progress'
       AND TG_OP = 'UPDATE'
       AND OLD.completed = true
     ) THEN
    RETURN NEW;
  END IF;

  IF TG_TABLE_NAME = 'material_progress' THEN
    SELECT material.course_id::text
    INTO course_id
    FROM public.materials AS material
    WHERE material.id = NEW.material_id;
  ELSE
    SELECT quiz.course_id::text
    INTO course_id
    FROM public.quizzes AS quiz
    WHERE quiz.id = NEW.quiz_id
      AND quiz.status = 'published';
  END IF;

  IF course_id IS NULL OR NOT EXISTS (
    SELECT 1
    FROM public.enrollments AS enrollment
    WHERE enrollment.course_id::text = course_id
      AND enrollment.student_id = student_id
  ) THEN
    RETURN NEW;
  END IF;

  SELECT course.title
  INTO course_title
  FROM public.courses AS course
  WHERE course.id::text = course_id;

  SELECT (
    SELECT count(*)
    FROM public.materials AS material
    WHERE material.course_id::text = course_id
  ) + (
    SELECT count(*)
    FROM public.quizzes AS quiz
    WHERE quiz.course_id::text = course_id
      AND quiz.status = 'published'
  )
  INTO total_tasks;

  IF total_tasks = 0 THEN
    RETURN NEW;
  END IF;

  SELECT (
    SELECT count(*)
    FROM public.material_progress AS progress
    JOIN public.materials AS material
      ON material.id = progress.material_id
    WHERE progress.user_id = student_id
      AND progress.completed
      AND material.course_id::text = course_id
  ) + (
    SELECT count(DISTINCT attempt.quiz_id)
    FROM public.quiz_attempts AS attempt
    JOIN public.quizzes AS quiz
      ON quiz.id = attempt.quiz_id
    WHERE attempt.user_id = student_id
      AND attempt.completed
      AND quiz.status = 'published'
      AND quiz.course_id::text = course_id
  )
  INTO completed_tasks;

  IF completed_tasks >= total_tasks AND NOT EXISTS (
    SELECT 1
    FROM public.activity_logs AS activity
    WHERE activity.actor_id = student_id
      AND activity.actor_role = 'student'
      AND activity.action = 'complete'
      AND activity.entity = 'course'
      AND activity.entity_id = course_id
  ) THEN
    INSERT INTO public.activity_logs (
      actor_id,
      actor_name,
      actor_role,
      action,
      entity,
      entity_id,
      entity_name
    )
    SELECT profile.id,
      profile.full_name,
      'student',
      'complete',
      'course',
      course_id,
      coalesce(course_title, 'Course')
    FROM public.profiles AS profile
    WHERE profile.id = student_id
      AND profile.role = 'student';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.log_student_course_completion()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS admin_log_student_course_material_completion
  ON public.material_progress;
CREATE TRIGGER admin_log_student_course_material_completion
AFTER INSERT OR UPDATE OF completed ON public.material_progress
FOR EACH ROW
EXECUTE FUNCTION public.log_student_course_completion();

DROP TRIGGER IF EXISTS admin_log_student_course_quiz_completion
  ON public.quiz_attempts;
CREATE TRIGGER admin_log_student_course_quiz_completion
AFTER INSERT ON public.quiz_attempts
FOR EACH ROW
EXECUTE FUNCTION public.log_student_course_completion();
