-- Admin CRUD needs to manage profile rows.  Direct calls from the Flutter
-- client still obey RLS, so explicitly allow an authenticated administrator.
-- This helper is SECURITY DEFINER to avoid an RLS policy recursively querying
-- the same `profiles` table.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_manage_profiles ON public.profiles;
CREATE POLICY admin_manage_profiles
ON public.profiles
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- This RPC is also used when creating a user fails halfway through.  It must
-- be SECURITY DEFINER; otherwise DELETE on profiles is evaluated using the
-- caller's RLS policies and leaves an orphaned auth.users record.
CREATE OR REPLACE FUNCTION public.admin_delete_user(target uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only administrators can delete user accounts.';
  END IF;

  IF target = auth.uid() THEN
    RAISE EXCEPTION 'Administrators cannot delete their own account.';
  END IF;

  DELETE FROM public."user" WHERE id_user = target;
  DELETE FROM public.profiles WHERE id = target;
  DELETE FROM auth.users WHERE id = target;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User account not found.';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_user(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_user(uuid) TO authenticated;
