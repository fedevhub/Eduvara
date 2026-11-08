# Eduvara

## Password recovery setup

Password recovery verifies the account owner through a Supabase email link. Add
`eduvara://reset-password` to the Supabase Auth redirect URL allowlist for
Android and iOS. For Flutter web, allow the deployed app's origin as a redirect
URL. After the link is opened, the app presents the new-password and
confirmation fields.
