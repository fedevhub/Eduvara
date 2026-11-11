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

  try {
    const body = await request.json();
    const username = typeof body.username === "string"
      ? body.username.trim().toLowerCase()
      : "";
    const password = typeof body.password === "string" ? body.password : "";
    if (!username || !password) return json({ code: "invalid_credentials" }, 400);

    const admin = createClient(url, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: account, error: accountError } = await admin
      .from("user")
      .select("id_user, status")
      .eq("username", username)
      .maybeSingle();
    if (accountError) throw accountError;
    if (!account?.id_user) return json({ code: "invalid_credentials" }, 401);
    if (["nonaktif", "inactive", "false"].includes(
      String(account.status ?? "").toLowerCase(),
    )) {
      return json({ code: "account_inactive" }, 403);
    }

    const { data: pending, error: pendingError } = await admin
      .from("password_reset_requests")
      .select("id")
      .eq("target_user_id", account.id_user)
      .in("status", ["pending", "processing"])
      .maybeSingle();
    if (pendingError) throw pendingError;
    if (pending) return json({ code: "reset_pending" }, 423);

    const { data: authData, error: authError } =
      await admin.auth.admin.getUserById(account.id_user);
    if (authError) throw authError;
    if (!authData.user.email) return json({ code: "invalid_credentials" }, 401);

    const auth = createClient(url, anonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data, error } = await auth.auth.signInWithPassword({
      email: authData.user.email,
      password,
    });
    if (error || !data.session) return json({ code: "invalid_credentials" }, 401);
    return json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
    });
  } catch (error) {
    console.error("username-auth failed", error);
    return json({ code: "server_error" }, 500);
  }
});
