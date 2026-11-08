INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'materials',
  'materials',
  true,
  104857600,
  ARRAY[
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
    'image/bmp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS materials_public_read ON storage.objects;
CREATE POLICY materials_public_read
ON storage.objects
FOR SELECT
TO anon, authenticated
USING (bucket_id = 'materials');

DROP POLICY IF EXISTS materials_course_file_upload ON storage.objects;
CREATE POLICY materials_course_file_upload
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'materials'
  AND split_part(name, '/', 1) = auth.uid()::text
  AND (
    public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.courses AS course
      WHERE course.id::text = split_part(name, '/', 2)
        AND course.teacher_id::text = auth.uid()::text
    )
  )
);
