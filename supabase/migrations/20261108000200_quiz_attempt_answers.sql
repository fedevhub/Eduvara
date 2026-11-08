ALTER TABLE public.quiz_attempts
  ADD COLUMN IF NOT EXISTS answers jsonb DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS submitted_at timestamptz;

UPDATE public.quiz_attempts
SET answers = '{}'::jsonb
WHERE answers IS NULL;

UPDATE public.quiz_attempts
SET submitted_at = created_at
WHERE submitted_at IS NULL;

ALTER TABLE public.quiz_attempts
  ALTER COLUMN answers SET DEFAULT '{}'::jsonb,
  ALTER COLUMN answers SET NOT NULL;
