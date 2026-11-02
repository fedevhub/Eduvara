CREATE OR REPLACE FUNCTION public.delete_user_account(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF auth.uid() IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM public.profiles
       WHERE id = auth.uid()
         AND role = 'admin'
     ) THEN
    RAISE EXCEPTION 'Only administrators can delete user accounts.';
  END IF;

  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Administrators cannot delete their own account.';
  END IF;

  DELETE FROM public.profiles WHERE id = target_user_id;
  DELETE FROM auth.users WHERE id = target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User account not found.';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user_account(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account(uuid) TO authenticated;
