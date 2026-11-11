ALTER TABLE public."user"
  ADD COLUMN IF NOT EXISTS email text,
  ADD COLUMN IF NOT EXISTS username text,
  ADD COLUMN IF NOT EXISTS nisn text,
  ADD COLUMN IF NOT EXISTS nip text;

UPDATE public."user" AS account
SET
  email = COALESCE(
    NULLIF(BTRIM(account.email), ''),
    (
      SELECT auth_user.email
      FROM auth.users AS auth_user
      WHERE auth_user.id = account.id_user
    )
  ),
  nisn = COALESCE(
    NULLIF(BTRIM(account.nisn), ''),
    CASE WHEN account.id_role = 3 THEN NULLIF(BTRIM(account.username), '') END
  ),
  nip = COALESCE(
    NULLIF(BTRIM(account.nip), ''),
    CASE WHEN account.id_role = 2 THEN NULLIF(BTRIM(account.username), '') END
  ),
  username = COALESCE(
    NULLIF(LOWER(BTRIM(account.username)), ''),
    CASE
      WHEN account.id_role = 3 THEN NULLIF(LOWER(BTRIM(account.nisn)), '')
      WHEN account.id_role = 2 THEN NULLIF(LOWER(BTRIM(account.nip)), '')
      WHEN account.id_role = 1
        AND COALESCE(
          NULLIF(BTRIM(account.email), ''),
          (
            SELECT auth_user.email
            FROM auth.users AS auth_user
            WHERE auth_user.id = account.id_user
          )
        ) NOT LIKE '%@accounts.eduvara.invalid'
      THEN NULLIF(
        LOWER(
          SPLIT_PART(
            COALESCE(
              NULLIF(BTRIM(account.email), ''),
              (
                SELECT auth_user.email
                FROM auth.users AS auth_user
                WHERE auth_user.id = account.id_user
              )
            ),
            '@',
            1
          )
        ),
        ''
      )
    END
  );

CREATE UNIQUE INDEX IF NOT EXISTS user_username_lower_unique
ON public."user" (LOWER(username))
WHERE username IS NOT NULL;

DROP FUNCTION IF EXISTS public.admin_create_user(
  uuid, text, text, boolean, text, text, text
);
DROP FUNCTION IF EXISTS public.admin_create_user(
  uuid, text, text, boolean, text, text, text, text, text
);

CREATE FUNCTION public.admin_create_user(
  p_target uuid,
  p_full_name text,
  p_role text,
  p_active boolean,
  p_username text,
  p_mapel text DEFAULT NULL,
  p_kelas text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_email text;
  v_username text := LOWER(BTRIM(p_username));
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only administrators can create user profiles.'
      USING ERRCODE = '42501';
  END IF;

  IF p_role IS NULL OR p_role NOT IN ('admin', 'teacher', 'student') THEN
    RAISE EXCEPTION 'Invalid user role.';
  END IF;

  IF NULLIF(BTRIM(p_full_name), '') IS NULL OR v_username IS NULL THEN
    RAISE EXCEPTION 'Name and username are required.';
  END IF;

  IF p_role = 'teacher' AND NULLIF(BTRIM(p_mapel), '') IS NULL THEN
    RAISE EXCEPTION 'Teacher subject is required.';
  END IF;

  IF p_role = 'student' AND NULLIF(BTRIM(p_kelas), '') IS NULL THEN
    RAISE EXCEPTION 'Student class is required.';
  END IF;

  SELECT auth_user.email
  INTO v_email
  FROM auth.users AS auth_user
  WHERE auth_user.id = p_target;

  IF v_email IS NULL THEN
    RAISE EXCEPTION 'Auth user not found.';
  END IF;

  INSERT INTO public.profiles (id, full_name, role)
  VALUES (p_target, BTRIM(p_full_name), p_role);

  INSERT INTO public."user" (
    id_user,
    id_role,
    nama_lengkap,
    email,
    password,
    status,
    username,
    nisn,
    nip,
    mapel,
    kelas
  )
  VALUES (
    p_target,
    CASE p_role
      WHEN 'admin' THEN 1
      WHEN 'teacher' THEN 2
      ELSE 3
    END,
    BTRIM(p_full_name),
    v_email,
    NULL,
    CASE WHEN p_active THEN 'aktif' ELSE 'nonaktif' END,
    v_username,
    CASE WHEN p_role = 'student' THEN BTRIM(p_username) ELSE NULL END,
    CASE WHEN p_role = 'teacher' THEN BTRIM(p_username) ELSE NULL END,
    CASE WHEN p_role = 'teacher' THEN NULLIF(BTRIM(p_mapel), '') ELSE NULL END,
    CASE WHEN p_role = 'student' THEN NULLIF(BTRIM(p_kelas), '') ELSE NULL END
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_create_user(
  uuid, text, text, boolean, text, text, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_create_user(
  uuid, text, text, boolean, text, text, text
) TO authenticated;

CREATE TABLE IF NOT EXISTS public.password_reset_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  username text NOT NULL,
  full_name text NOT NULL,
  role text NOT NULL CHECK (role IN ('admin', 'teacher', 'student')),
  class_name text,
  encrypted_password text,
  encryption_iv text,
  reason text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'approved', 'rejected')),
  created_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz,
  reviewer_id uuid REFERENCES auth.users(id) ON DELETE SET NULL
);

ALTER TABLE public.password_reset_requests
  DROP CONSTRAINT IF EXISTS password_reset_secret_pair;
ALTER TABLE public.password_reset_requests
  ADD CONSTRAINT password_reset_secret_pair CHECK (
    (encrypted_password IS NULL) = (encryption_iv IS NULL)
  );

CREATE UNIQUE INDEX IF NOT EXISTS password_reset_one_pending_per_user
ON public.password_reset_requests (target_user_id)
WHERE status IN ('pending', 'processing');

ALTER TABLE public.password_reset_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.password_reset_requests
  ADD COLUMN IF NOT EXISTS reason text NOT NULL DEFAULT '';
REVOKE ALL ON public.password_reset_requests FROM PUBLIC, anon, authenticated;
GRANT ALL ON public.password_reset_requests TO service_role;
