ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS password_reset_request_id uuid
    REFERENCES public.password_reset_requests(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS notifications_reset_request_user_unique
ON public.notifications (user_id, password_reset_request_id)
WHERE password_reset_request_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.notify_admin_of_password_reset_request()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.notifications (
    user_id,
    title,
    message,
    is_read,
    password_reset_request_id
  )
  SELECT
    admin_profile.id,
    'Permintaan Reset Password',
    format(
      '%s (@%s) mengajukan reset password.',
      NEW.full_name,
      NEW.username
    ),
    false,
    NEW.id
  FROM public.profiles AS admin_profile
  WHERE admin_profile.role = 'admin'
  ON CONFLICT (user_id, password_reset_request_id)
    WHERE password_reset_request_id IS NOT NULL
  DO NOTHING;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.notify_admin_of_password_reset_request()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS notify_admin_of_password_reset_request
ON public.password_reset_requests;
CREATE TRIGGER notify_admin_of_password_reset_request
AFTER INSERT ON public.password_reset_requests
FOR EACH ROW
EXECUTE FUNCTION public.notify_admin_of_password_reset_request();

INSERT INTO public.notifications (
  user_id,
  title,
  message,
  is_read,
  password_reset_request_id
)
SELECT
  admin_profile.id,
  'Permintaan Reset Password',
  format(
    '%s (@%s) mengajukan reset password.',
    request.full_name,
    request.username
  ),
  false,
  request.id
FROM public.password_reset_requests AS request
CROSS JOIN public.profiles AS admin_profile
WHERE request.status IN ('pending', 'processing')
  AND admin_profile.role = 'admin'
ON CONFLICT (user_id, password_reset_request_id)
  WHERE password_reset_request_id IS NOT NULL
DO NOTHING;
