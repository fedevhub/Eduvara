-- Fix the student activity notification trigger so it does not reference ambiguous
-- course_id columns when completing materials or quizzes.

DROP TRIGGER IF EXISTS admin_log_student_course_material_completion ON public.material_progress;
DROP TRIGGER IF EXISTS admin_log_student_quiz_completion ON public.quiz_attempts;
DROP TRIGGER IF EXISTS notify_teacher_of_material_completion ON public.material_progress;
DROP TRIGGER IF EXISTS notify_teacher_of_quiz_completion ON public.quiz_attempts;

DROP FUNCTION IF EXISTS public.admin_log_student_course_material_completion();
DROP FUNCTION IF EXISTS public.admin_log_student_quiz_completion();
DROP FUNCTION IF EXISTS public.notify_teacher_and_admin_of_student_activity();

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
  target_course_id uuid;
  target_title text;
  course_teacher uuid;
  score_text text;
BEGIN
  SELECT COALESCE(profile.full_name, 'Siswa')
  INTO student_name
  FROM public.profiles AS profile
  WHERE profile.id::text = NEW.user_id::text;

  IF TG_TABLE_NAME = 'material_progress' THEN
    IF NEW.completed IS DISTINCT FROM true THEN
      RETURN NEW;
    END IF;

    SELECT material.course_id, material.title
    INTO target_course_id, target_title
    FROM public.materials AS material
    WHERE material.id = NEW.material_id;

    activity_title := 'Materi Diselesaikan';
    activity_message := format('%s menyelesaikan materi "%s".',
      student_name, COALESCE(target_title, 'Materi'));
  ELSIF TG_TABLE_NAME = 'quiz_attempts' THEN
    IF NEW.completed IS DISTINCT FROM true THEN
      RETURN NEW;
    END IF;

    SELECT quiz.course_id, quiz.title
    INTO target_course_id, target_title
    FROM public.quizzes AS quiz
    WHERE quiz.id = NEW.quiz_id;

    SELECT course.teacher_id
    INTO course_teacher
    FROM public.courses AS course
    WHERE course.id = target_course_id;

    score_text := COALESCE(NEW.score::text, '0');
    activity_title := 'Quiz Selesai';
    activity_message := format('%s menyelesaikan quiz "%s" dengan nilai %s.',
      student_name, COALESCE(target_title, 'Quiz'), score_text);
  ELSE
    RETURN NEW;
  END IF;

  IF course_teacher IS NULL AND target_course_id IS NOT NULL THEN
    SELECT course.teacher_id
    INTO course_teacher
    FROM public.courses AS course
    WHERE course.id = target_course_id;
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

CREATE TRIGGER notify_teacher_of_material_completion
AFTER INSERT OR UPDATE OF completed ON public.material_progress
FOR EACH ROW
EXECUTE FUNCTION public.notify_teacher_and_admin_of_student_activity();

CREATE TRIGGER notify_teacher_of_quiz_completion
AFTER INSERT OR UPDATE OF completed ON public.quiz_attempts
FOR EACH ROW
WHEN (NEW.completed IS TRUE)
EXECUTE FUNCTION public.notify_teacher_and_admin_of_student_activity();
