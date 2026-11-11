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

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (request.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !serviceKey || !anonKey) {
    console.error("Missing Supabase environment configuration.");
    return json({ code: "server_error" }, 500);
  }

  const token = request.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return json({ code: "unauthorized" }, 401);

  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const caller = createClient(url, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let newUserId: string | null = null;
  try {
    const { data: callerData, error: callerError } = await caller.auth.getUser(token);
    if (callerError || !callerData.user) return json({ code: "unauthorized" }, 401);

    const { data: profile, error: profileError } = await admin
      .from("profiles")
      .select("role")
      .eq("id", callerData.user.id)
      .maybeSingle();
    if (profileError) throw profileError;
    if (profile?.role !== "admin") return json({ code: "forbidden" }, 403);

    const body = await request.json();
    const name = typeof body.name === "string" ? body.name.trim() : "";
    const username = typeof body.username === "string"
      ? body.username.trim().toLowerCase()
      : "";
    const password = typeof body.password === "string" ? body.password : "";
    const role = body.role;
    const active = body.active;
    const mapel = typeof body.mapel === "string" ? body.mapel.trim() : null;
    const kelas = typeof body.kelas === "string" ? body.kelas.trim() : null;

    if (
      !name || name.length > 200 || !username || username.length > 128 ||
      !password || password.length < 6 ||
      typeof active !== "boolean" ||
      !["admin", "teacher", "student"].includes(role) ||
      (role === "teacher" && !mapel) ||
      (role === "student" && !kelas)
    ) {
      return json({ code: "invalid_request" }, 400);
    }

    const { data: existing, error: existingError } = await admin
      .from("user")
      .select("id_user")
      .eq("username", username)
      .maybeSingle();
    if (existingError) throw existingError;
    if (existing) return json({ code: "username_taken" }, 409);

    const email = `${crypto.randomUUID()}@accounts.eduvara.invalid`;
    const { data: created, error: createError } =
      await admin.auth.admin.createUser({
        email,
        email_confirm: true,
        password,
        user_metadata: { full_name: name, role, username },
      });
    if (createError) throw createError;
    if (!created.user) throw new Error("Auth user creation returned no user.");
    newUserId = created.user.id;

    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { error: rpcError } = await userClient.rpc("admin_create_user", {
      p_target: newUserId,
      p_full_name: name,
      p_role: role,
      p_active: active,
      p_username: username,
      p_mapel: mapel,
      p_kelas: kelas,
    });
    if (rpcError) throw rpcError;

    newUserId = null;
    return json({ message: "Pengguna berhasil dibuat." });
  } catch (error) {
    console.error("admin-create-user failed", error);
    if (newUserId) {
      const { error: cleanupError } = await admin.auth.admin.deleteUser(newUserId);
      if (cleanupError) {
        console.error("Failed to clean up incomplete user", cleanupError);
        return json({ code: "cleanup_failed" }, 500);
      }
    }
    const code = (error as { code?: string }).code;
    if (code === "23505") return json({ code: "username_taken" }, 409);
    if (code === "PGRST202" || code === "PGRST204" || code === "42703") {
      return json({ code: "migration_required" }, 503);
    }
    return json({ code: "server_error" }, 500);
  }
});
