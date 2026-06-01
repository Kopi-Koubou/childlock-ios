import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

type RevenueCatEvent = {
  event?: {
    app_user_id?: string;
    aliases?: string[];
    entitlement_id?: string;
    entitlement_ids?: string[];
    expiration_at_ms?: number | null;
    event_timestamp_ms?: number;
    period_type?: string;
    type?: string;
  };
};

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET") ?? "";

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false },
});

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return Response.json({ error: "Method not allowed" }, { status: 405, headers: corsHeaders });
  }

  const authorization = req.headers.get("authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "");
  if (!webhookSecret || token !== webhookSecret) {
    return Response.json({ error: "Unauthorized" }, { status: 401, headers: corsHeaders });
  }

  const payload = (await req.json()) as RevenueCatEvent;
  const event = payload.event ?? {};
  const appUserID = event.app_user_id;

  if (!appUserID) {
    return Response.json({ error: "Missing app_user_id" }, { status: 400, headers: corsHeaders });
  }

  const now = new Date();
  const expiresAt = event.expiration_at_ms ? new Date(event.expiration_at_ms) : null;
  const lastEventAt = event.event_timestamp_ms ? new Date(event.event_timestamp_ms) : now;
  const entitlementIdentifier = event.entitlement_id ?? event.entitlement_ids?.[0] ?? null;
  const inactiveEvents = new Set(["EXPIRATION", "CANCELLATION", "BILLING_ISSUE"]);
  const isActive = expiresAt ? expiresAt > now : !inactiveEvents.has(event.type ?? "");

  const { data: profile, error: profileError } = await supabase
    .from("parent_profiles")
    .select("id")
    .or(`revenuecat_app_user_id.eq.${appUserID},apple_user_id.eq.${appUserID}`)
    .maybeSingle();

  if (profileError) {
    return Response.json({ error: profileError.message }, { status: 500, headers: corsHeaders });
  }

  if (!profile?.id) {
    return Response.json({ ok: true, matched: false }, { headers: corsHeaders });
  }

  const { error } = await supabase.from("subscription_status").upsert(
    {
      parent_id: profile.id,
      revenuecat_app_user_id: appUserID,
      entitlement_identifier: entitlementIdentifier,
      is_active: isActive,
      period_type: event.period_type ?? null,
      expires_at: expiresAt?.toISOString() ?? null,
      last_event_type: event.type ?? null,
      last_event_at: lastEventAt.toISOString(),
      raw_payload: payload,
    },
    { onConflict: "parent_id" },
  );

  if (error) {
    return Response.json({ error: error.message }, { status: 500, headers: corsHeaders });
  }

  return Response.json({ ok: true, matched: true }, { headers: corsHeaders });
});
