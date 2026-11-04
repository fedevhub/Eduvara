-- Authenticated users need to read their own profile to restore their session
-- and render the student profile and dashboard.
GRANT SELECT ON public.profiles TO authenticated;

DROP POLICY IF EXISTS authenticated_read_own_profile ON public.profiles;
CREATE POLICY authenticated_read_own_profile
ON public.profiles
FOR SELECT
TO authenticated
USING (id::text = auth.uid()::text);

-- Account status and student class are stored in the legacy `user` table.
GRANT SELECT ON public."user" TO authenticated;

DROP POLICY IF EXISTS authenticated_read_own_user ON public."user";
CREATE POLICY authenticated_read_own_user
ON public."user"
FOR SELECT
TO authenticated
USING (id_user::text = auth.uid()::text);
