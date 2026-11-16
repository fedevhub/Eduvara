
const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type, x-retry-count",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (
    body: Record<string, unknown>,
    status = 200
) =>
    new Response(JSON.stringify(body), {
        status,
        headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
        },
    });

Deno.serve(async (request: Request) => {
    // Handle CORS preflight
    if (request.method === "OPTIONS") {
        return new Response("ok", {
            status: 200,
            headers: corsHeaders,
        });
    }

    if (request.method !== "POST") {
        return json({ error: "method_not_allowed" }, 405);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const geminiKey = Deno.env.get("GEMINI_API_KEY");

    if (!supabaseUrl || !anonKey || !serviceKey || !geminiKey) {
        console.error("Required server secrets are not configured.");
        return json({ error: "server_configuration_error" }, 500);
    }

    try {
        const authorization =
            request.headers.get("Authorization") ?? "";

        if (!authorization.startsWith("Bearer ")) {
            return json({ error: "unauthorized" }, 401);
        }

        // Use Supabase REST endpoints instead of importing supabase-js. This keeps
        // the Edge Function lightweight and prevents cold-start resource spikes.
        const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
            headers: {
                apikey: anonKey,
                Authorization: authorization,
            },
        });

        if (!userResponse.ok) {
            return json({ error: "unauthorized" }, 401);
        }

        const user = await userResponse.json() as { id?: string };

        if (!user.id) {
            return json({ error: "unauthorized" }, 401);
        }

        // Check user role with the service-role key; the user id is obtained
        // only from the verified access token above.
        const profileResponse = await fetch(
            `${supabaseUrl}/rest/v1/profiles?id=eq.${encodeURIComponent(user.id)}&select=role`,
            {
                headers: {
                    apikey: serviceKey,
                    Authorization: `Bearer ${serviceKey}`,
                },
            }
        );

        if (!profileResponse.ok) {
            console.error("Profile lookup failed:", profileResponse.status);
            return json({ error: "profile_lookup_failed" }, 500);
        }

        const profiles = await profileResponse.json() as Array<{ role?: unknown }>;
        const role = String(profiles[0]?.role ?? "").toLowerCase();

        if (!['admin', 'teacher', 'student'].includes(role)) {
            return json({ error: "role_not_allowed" }, 403);
        }

        // Read request body
        const body = await request.json();

        const message =
            typeof body.message === "string"
                ? body.message.trim()
                : "";

        const attachmentBase64 = typeof body.attachment_base64 === "string"
            ? body.attachment_base64
            : "";
        const attachmentMimeType = typeof body.attachment_mime_type === "string"
            ? body.attachment_mime_type
            : "image/jpeg";

        if (!message && !attachmentBase64) {
            return json({ error: "empty_message" }, 400);
        }

        if (message.length > 6000) {
            return json({ error: "message_too_long" }, 413);
        }

        if (attachmentBase64.length > 6_500_000) {
            return json({ error: "attachment_too_large" }, 413);
        }

        if (!/^(image\/(jpeg|jpg|png|webp)|application\/pdf)$/i.test(attachmentMimeType)) {
            return json({ error: "unsupported_attachment_type" }, 400);
        }

        // Conversation history
        const rawHistory = Array.isArray(body.history)
            ? body.history
            : [];

        const history = rawHistory
            .slice(-12)
            .flatMap((item: unknown) => {
                if (!item || typeof item !== "object") return [];

                const entry = item as Record<string, unknown>;

                const content =
                    typeof entry.content === "string"
                        ? entry.content.trim()
                        : "";

                const speaker =
                    entry.role === "user" ? "user" : "model";

                if (!content || content.length > 6000) return [];

                return [{
                    role: speaker,
                    parts: [{ text: content }],
                }];
            });

        const contents = [
            ...history,
            {
                role: "user",
                parts: [
                    { text: message || "Jelaskan isi gambar ini untuk keperluan belajar." },
                    ...(attachmentBase64 ? [{
                        inline_data: {
                            mime_type: attachmentMimeType,
                            data: attachmentBase64,
                        },
                    }] : []),
                ],
            },
        ];

        const prompt = [
            "Kamu adalah Eduvara AI Assistant, asisten belajar di aplikasi LMS Eduvara.",
            "Jawab dalam Bahasa Indonesia yang jelas, ramah, akurat, dan sesuai tingkat pelajar SMK.",
            "Bantu memahami konsep dan proses berpikir; jangan mengarang sumber atau fakta.",
            "Jika pertanyaan di luar pembelajaran, tetap jawab singkat dan arahkan kembali dengan sopan.",
            "Jika informasi tidak pasti, katakan bahwa kamu tidak yakin.",
        ].join(" ");

        // Request Gemini API
        const geminiResponse = await fetch(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent",
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "x-goog-api-key": geminiKey,
                },
                body: JSON.stringify({
                    system_instruction: {
                        parts: [{ text: prompt }],
                    },
                    contents,
                    generationConfig: {
                        temperature: 0.7,
                        maxOutputTokens: 1200,
                    },
                }),
                signal: AbortSignal.timeout(20_000),
            }
        );

        const result = await geminiResponse.json();

        if (!geminiResponse.ok) {
            const providerMessage = typeof result?.error?.message === "string"
                ? result.error.message.slice(0, 300)
                : "Gemini tidak dapat memproses permintaan.";

            console.error("Gemini API error:", geminiResponse.status, providerMessage);
            return json({
                error: "gemini_request_failed",
                provider_status: geminiResponse.status,
                message: providerMessage,
            }, 502);
        }

        const reply = result?.candidates?.[0]?.content?.parts
            ?.map((part: { text?: string }) => part.text ?? "")
            .join("")
            .trim();

        if (!reply) {
            return json({ error: "empty_ai_response" }, 502);
        }

        return json({ reply });

    } catch (error) {
        if (error instanceof DOMException && error.name === "TimeoutError") {
            return json({ error: "gemini_timeout" }, 504);
        }

        console.error("gemini-chat failed:", error);
        return json({ error: "internal_server_error" }, 500);
    }
});
