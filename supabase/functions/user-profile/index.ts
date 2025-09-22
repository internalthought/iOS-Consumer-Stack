// Edge Function: user-profile
// Supports: { action: "delete_account" } and is extensible for future profile operations.
// Deploy with: supabase functions deploy user-profile
// Invoke from client via Supabase Functions with Authorization bearer token.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type RequestBody =
  | { action: "delete_account" }
  | { action: "update_profile"; profile: Record<string, unknown> };

type JsonResponse =
  | { success: true; message?: string }
  | { success: false; message: string };

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const authHeader = req.headers.get("Authorization") ?? "";
    const jwt = authHeader.replace("Bearer ", "");

    if (!jwt) {
      return json({ success: false, message: "Missing bearer token" }, 401);
    }

    const anon = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: `Bearer ${jwt}` } },
    });

    const service = createClient(supabaseUrl, serviceRoleKey);

    const {
      data: { user },
      error: getUserError,
    } = await anon.auth.getUser();

    if (getUserError || !user) {
      return json({ success: false, message: "Unauthorized" }, 401);
    }

    const userId = user.id;

    let body: RequestBody | undefined;
    if (req.headers.get("content-type")?.includes("application/json")) {
      body = await req.json();
    } else {
      // Default to delete if using POST without body for simplicity
      body = { action: "delete_account" };
    }

    switch (body.action) {
      case "delete_account": {
        // Delete related application data first (adjust table/column names to your schema)
        // Example cascade deletions:
        await deleteRows(service, "survey_responses", "user_id", userId);
        await deleteRows(service, "user_profiles", "id", userId);
        await deleteRows(service, "users", "user_id", userId);

        // Finally, delete the auth user
        const { error: adminDeleteError } = await service.auth.admin.deleteUser(userId);
        if (adminDeleteError) {
          return json({ success: false, message: `Auth delete failed: ${adminDeleteError.message}` }, 500);
        }

        return json({ success: true, message: "Account deleted" });
      }

      case "update_profile": {
        // Extend this block for future updates to user profile
        // Example:
        // const updates = body.profile;
        // await service.from("user_profiles").update(updates).eq("id", userId);
        return json({ success: true, message: "No-op update_profile (extend as needed)" });
      }

      default:
        return json({ success: false, message: "Unsupported action" }, 400);
    }
  } catch (e) {
    return json({ success: false, message: e?.message ?? "Unknown error" }, 500);
  }
});

async function deleteRows(
  client: ReturnType<typeof createClient>,
  table: string,
  column: string,
  value: string
) {
  const { error } = await client.from(table).delete().eq(column, value);
  if (error && error.code !== "PGRST116") {
    // PGRST116: No rows found to delete - not an error for our purposes
    throw error;
  }
}

function json(body: JsonResponse, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });
}