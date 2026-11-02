-- The admin form writes application-specific user data after it upserts a
-- profile.  Give the same administrator access to this table as profiles.
ALTER TABLE public."user" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_manage_user ON public."user";
CREATE POLICY admin_manage_user
ON public."user"
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());
