# Eduvara

## Username login and password reset

The public user table retains its internal Auth email field. The app does not
ask for or display it: students sign in with their NISN, teachers with their
NIP, and admins with the username set in the user form. The server resolves
that identifier to the user's private Supabase Auth email. New accounts get a
non-routable synthetic Auth address; existing addresses remain unchanged.

Apply `supabase/migrations/20261111000100_username_login_and_password_resets.sql`
before deploying the app. It preserves email/NISN/NIP data, adds a canonical
username, and enables encrypted reset requests. Deploy these functions with
gateway JWT verification disabled; each function validates admin tokens
itself where required:

```powershell
npx supabase functions deploy username-auth --no-verify-jwt
npx supabase functions deploy admin-create-user --no-verify-jwt
npx supabase functions deploy password-reset --no-verify-jwt
```

Apply `supabase/migrations/20261111000200_admin_password_reset_notifications.sql`
after the reset-request migration to create admin notifications for new and
already-pending password reset requests. This migration must be applied to the
same Supabase project used by the app before the notifications appear.

When `PASSWORD_RESET_ENCRYPTION_KEY` is not set, the function derives its
encryption key from the Supabase service-role key. To use a dedicated key,
generate and store a private 32-byte encryption key:

```powershell
openssl rand -base64 32
npx supabase secrets set PASSWORD_RESET_ENCRYPTION_KEY="PASTE_BASE64_KEY_HERE"
```

Keep a dedicated key stable: rotating it prevents decryption of pending reset
requests. If relying on the service-role-key fallback, rotating the Supabase
service-role key also invalidates pending requests encrypted before rotation.

Users submit username, full name, class, and a proposed new password. The
password is encrypted server-side until an admin approves or rejects the
request. Approval updates the Auth password; rejection discards the encrypted
password. Never put the service-role key or reset encryption key in the Flutter
app.
