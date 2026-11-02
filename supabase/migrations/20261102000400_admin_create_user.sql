CREATE OR REPLACE FUNCTION public.admin_create_user(
  p_target uuid,
  p_full_name text,
  p_role text,
  p_active boolean,
  p_nip text DEFAULT NULL,
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
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only administrators can create user profiles.'
      USING ERRCODE = '42501';
  END IF;

  IF p_role IS NULL OR p_role NOT IN ('admin', 'teacher', 'student') THEN
    RAISE EXCEPTION 'Invalid user role.';
  END IF;

  SELECT au.email
  INTO v_email
  FROM auth.users AS au
  WHERE au.id = p_target;

  IF v_email IS NULL THEN
    RAISE EXCEPTION 'Auth user not found.';
  END IF;

  INSERT INTO public.profiles (id, full_name, role)
  VALUES (p_target, p_full_name, p_role);

  INSERT INTO public."user" (
    id_user,
    id_role,
    nama_lengkap,
    email,
    password,
    status,
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
    p_full_name,
    v_email,
    NULL,
    CASE WHEN p_active THEN 'aktif' ELSE 'nonaktif' END,
    CASE WHEN p_role = 'teacher' THEN p_nip ELSE NULL END,
    CASE WHEN p_role = 'teacher' THEN p_mapel ELSE NULL END,
    CASE WHEN p_role = 'student' THEN p_kelas ELSE NULL END
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_create_user(
  uuid, text, text, boolean, text, text, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_create_user(
  uuid, text, text, boolean, text, text, text
) TO authenticated;
