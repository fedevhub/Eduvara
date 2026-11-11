import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const encode = (value: Uint8Array) =>
  btoa(String.fromCharCode(...value));

const decode = (value: string) =>
  Uint8Array.from(atob(value), (char) => char.charCodeAt(0));

const getEncryptionKey = async (serviceKey: string) => {
  const encoded = Deno.env.get("PASSWORD_RESET_ENCRYPTION_KEY");
  const raw = encoded
    ? decode(encoded)
    : new Uint8Array(
        await crypto.subtle.digest(
          "SHA-256",
          new TextEncoder().encode(`eduvara-password-reset-v1:${serviceKey}`),
        ),
      );
  if (raw.length !== 32) throw new Error("Password reset key must be 32 bytes.");
  return crypto.subtle.importKey("raw", raw, "AES-GCM", false, [
    "encrypt",
    "decrypt",
  ]);
};

const encrypt = async (value: string, serviceKey: string) => {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encrypted = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv },
    await getEncryptionKey(serviceKey),
    new TextEncoder().encode(value),
  );
  return { ciphertext: encode(new Uint8Array(encrypted)), iv: encode(iv) };
};

const decrypt = async (ciphertext: string, iv: string, serviceKey: string) => {
  const decrypted = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: decode(iv) },
    await getEncryptionKey(serviceKey),
    decode(ciphertext),
  );
  return new TextDecoder().decode(decrypted);
};

const normalizeText = (value: unknown) =>
  String(value ?? "").trim().replace(/\s+/g, " ").toLowerCase();

const findAccount = async (
  admin: ReturnType<typeof createClient>,
  username: string,
) => {
  const { data: byUsername, error: usernameError } = await admin
    .from("user")
    .select("id_user, id_role, nama_lengkap, username, nisn, nip, kelas, status")
    .eq("username", username)
    .maybeSingle();
  if (usernameError) throw usernameError;
  if (byUsername) return byUsername;

  const { data: student, error: studentError } = await admin
    .from("user")
    .select("id_user, id_role, nama_lengkap, username, nisn, nip, kelas, status")
    .eq("id_role", 3)
    .eq("nisn", username)
    .maybeSingle();
  if (studentError) throw studentError;
  if (student) return student;

  const { data: teacher, error: teacherError } = await admin
    .from("user")
    .select("id_user, id_role, nama_lengkap, username, nisn, nip, kelas, status")
    .eq("id_role", 2)
    .eq("nip", username)
    .maybeSingle();
  if (teacherError) throw teacherError;
  return teacher;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (request.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!url || !serviceKey) {
    console.error("Missing Supabase environment configuration.");
    return json({ code: "server_error" }, 500);
  }
  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  try {
    const body = await request.json();
    if (body.action === "request") {
      const username = typeof body.username === "string"
        ? body.username.trim().toLowerCase()
        : "";
      const fullName = typeof body.full_name === "string"
        ? body.full_name.trim()
        : "";
      const className = typeof body.class_name === "string"
        ? body.class_name.trim()
        : "";
      const password = typeof body.password === "string" ? body.password : "";
      if (!username || !fullName) {
        return json({ code: "missing_fields" }, 400);
      }
      if (password.length < 6) {
        return json({ code: "password_too_short" }, 400);
      }

      const account = await findAccount(admin, username);
      const expectedClass = normalizeText(account?.kelas);
      const valid = account &&
        ["aktif", "active", "true"].includes(
          normalizeText(account.status),
        ) &&
        normalizeText(account.nama_lengkap) === normalizeText(fullName) &&
        (Number(account.id_role) !== 3 ||
          (expectedClass.length > 0 &&
            expectedClass === normalizeText(className)));
      if (!valid) return json({ code: "request_rejected" }, 400);

      const role = Number(account.id_role) === 1
        ? "admin"
        : Number(account.id_role) === 2
        ? "teacher"
        : "student";
      const { ciphertext, iv } = await encrypt(password, serviceKey);
      const { error: insertError } = await admin
        .from("password_reset_requests")
        .insert({
          target_user_id: account.id_user,
          username: account.username || username,
          full_name: account.nama_lengkap,
          role,
          class_name: account.kelas,
          encrypted_password: ciphertext,
          encryption_iv: iv,
          reason: "Reset password diminta melalui aplikasi.",
        });
      if (insertError?.code === "23505") {
        return json({ code: "request_pending" }, 409);
      }
      if (insertError) throw insertError;
      return json({ message: "Permintaan reset password dikirim." });
    }

    if (!anonKey) {
      console.error("Missing Supabase public API key for admin review.");
      return json({ code: "server_configuration" }, 503);
    }

    const token = request.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
    if (!token) return json({ code: "unauthorized" }, 401);
    const caller = createClient(url, anonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: callerData, error: callerError } = await caller.auth.getUser(token);
    if (callerError || !callerData.user) return json({ code: "unauthorized" }, 401);

    const { data: profile, error: profileError } = await admin
      .from("profiles")
      .select("role")
      .eq("id", callerData.user.id)
      .maybeSingle();
    if (profileError) throw profileError;
    if (profile?.role !== "admin") return json({ code: "forbidden" }, 403);

    if (body.action === "list") {
      const { data, error } = await admin
        .from("password_reset_requests")
        .select(
          "id, target_user_id, username, full_name, role, class_name, status, created_at",
        )
        .in("status", ["pending", "processing"])
        .order("created_at");
      if (error) throw error;
      return json({ requests: data ?? [] });
    }

    if (body.action === "review") {
      const id = typeof body.id === "string" ? body.id : "";
      const decision = body.decision;
      if (!id || !["approve", "reject"].includes(decision)) {
        return json({ code: "invalid_request" }, 400);
      }
      const { data: item, error: claimError } = await admin
        .from("password_reset_requests")
        .update({ status: "processing" })
        .eq("id", id)
        .eq("status", "pending")
        .select("id, target_user_id, encrypted_password, encryption_iv")
        .maybeSingle();
      if (claimError) throw claimError;
      if (!item) return json({ code: "request_not_pending" }, 409);

      if (decision === "approve") {
        try {
          const password = await decrypt(
            item.encrypted_password,
            item.encryption_iv,
            serviceKey,
          );
          const { error: passwordError } =
            await admin.auth.admin.updateUserById(item.target_user_id, {
              password,
            });
          if (passwordError) throw passwordError;
        } catch (error) {
          const { error: rollbackError } = await admin
            .from("password_reset_requests")
            .update({ status: "pending" })
            .eq("id", id)
            .eq("status", "processing");
          if (rollbackError) console.error("Failed to restore reset request", rollbackError);
          throw error;
        }
      }

      const { error: finishError } = await admin
        .from("password_reset_requests")
        .update({
          status: decision === "approve" ? "approved" : "rejected",
          encrypted_password: null,
          encryption_iv: null,
          reviewed_at: new Date().toISOString(),
          reviewer_id: callerData.user.id,
        })
        .eq("id", id)
        .eq("status", "processing");
      if (finishError) throw finishError;
      return json({ message: "Permintaan berhasil diproses." });
    }

    return json({ code: "invalid_request" }, 400);
  } catch (error) {
    console.error("password-reset failed", error);
    const code = (error as { code?: string }).code;
    if (
      code === "42P01" ||
      code === "42703" ||
      code === "PGRST204" ||
      code === "PGRST205"
    ) {
      return json({ code: "migration_required" }, 503);
    }
    return json({ code: "server_error" }, 500);
  }
});
