CREATE OR REPLACE FUNCTION public.notify_enrolled_students_of_new_content()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  row_data jsonb;
  target_course_id text;
  content_title text;
  course_title text;
  teacher_name text;
  notification_title text;
  notification_message text;
BEGIN
  row_data := to_jsonb(NEW);
  target_course_id := coalesce(
    row_data ->> 'course_id',
    row_data ->> 'id_course',
    row_data ->> 'courses_id',
    row_data ->> 'id_courses',
    row_data ->> 'course'
  );
  content_title := coalesce(
    row_data ->> 'title',
    row_data ->> 'nama_quiz',
    row_data ->> 'judul',
    row_data ->> 'judul_quiz',
    row_data ->> 'quiz_title',
    row_data ->> 'name',
    row_data ->> 'nama',
    'Materi atau quiz baru'
  );

  IF target_course_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT
    coalesce(course.title, 'course'),
    coalesce(profile.full_name, 'Guru')
  INTO course_title, teacher_name
  FROM public.courses AS course
  LEFT JOIN public.profiles AS profile
    ON profile.id::text = course.teacher_id::text
  WHERE course.id::text = target_course_id;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  IF TG_TABLE_NAME = 'materials' THEN
    notification_title := 'Materi Baru';
    notification_message := format(
      '%s menambahkan materi "%s" di course "%s".',
      teacher_name,
      content_title,
      course_title
    );
  ELSE
    notification_title := 'Quiz Baru';
    notification_message := format(
      '%s menambahkan quiz "%s" di course "%s".',
      teacher_name,
      content_title,
      course_title
    );
  END IF;

  INSERT INTO public.notifications (user_id, title, message)
  SELECT DISTINCT enrollment.student_id, notification_title, notification_message
  FROM public.enrollments AS enrollment
  WHERE enrollment.course_id::text = target_course_id;

  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NULL
     OR to_regclass('public.courses') IS NULL
     OR to_regclass('public.enrollments') IS NULL
     OR to_regclass('public.profiles') IS NULL THEN
    RAISE NOTICE
      'Content notification triggers were not installed; apply the prerequisite student learning schema, then rerun this migration.';
    RETURN;
  END IF;

  IF to_regclass('public.materials') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS notify_students_of_new_material ON public.materials';
    EXECUTE 'CREATE TRIGGER notify_students_of_new_material
      AFTER INSERT ON public.materials
      FOR EACH ROW
      EXECUTE FUNCTION public.notify_enrolled_students_of_new_content()';
  ELSE
    RAISE NOTICE
      'public.materials does not exist; apply 20261104000100_student_learning_tables.sql, then rerun this migration.';
  END IF;

  IF to_regclass('public.quizzes') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS notify_students_of_new_quiz ON public.quizzes';
    EXECUTE 'CREATE TRIGGER notify_students_of_new_quiz
      AFTER INSERT ON public.quizzes
      FOR EACH ROW
      EXECUTE FUNCTION public.notify_enrolled_students_of_new_content()';
  END IF;

  IF to_regclass('public.quiz') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS notify_students_of_new_legacy_quiz ON public.quiz';
    EXECUTE 'CREATE TRIGGER notify_students_of_new_legacy_quiz
      AFTER INSERT ON public.quiz
      FOR EACH ROW
      EXECUTE FUNCTION public.notify_enrolled_students_of_new_content()';
  END IF;
END;
$$;
