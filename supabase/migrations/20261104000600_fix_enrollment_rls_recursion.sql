CREATE OR REPLACE FUNCTION public.is_course_teacher(target_course_id text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.courses AS course
    WHERE course.id::text = target_course_id
      AND course.teacher_id::text = auth.uid()::text
  );
$$;

REVOKE ALL ON FUNCTION public.is_course_teacher(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_course_teacher(text) TO authenticated;

DROP POLICY IF EXISTS read_related_enrollments ON public.enrollments;
CREATE POLICY read_related_enrollments
ON public.enrollments
FOR SELECT
TO authenticated
USING (
  public.is_admin()
  OR student_id::text = auth.uid()::text
  OR public.is_course_teacher(course_id::text)
);
