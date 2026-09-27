// Drains public.notification_outbox and sends FCM pushes.
// Invoked every minute by pg_cron (see migrations/20260927000008_scheduled_jobs.sql).
//
// Secrets:
//   NOTIFY_CRON_SECRET    shared with the database (Vault: notify_cron_secret)
//   FCM_SERVICE_ACCOUNT   Firebase service account JSON; without it, runs in dry-run mode
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by the platform.

import { DryRunSender, FcmSender, type PushSender, type ServiceAccount } from "./fcm.ts";
import type { OutboxRow } from "./messages.ts";
import { type OutboxStore, processOutbox, type Recipient } from "./process.ts";

function restStore(url: string, serviceKey: string): OutboxStore {
  const rpc = async <T>(name: string, args: Record<string, unknown>): Promise<T> => {
    const response = await fetch(`${url}/rest/v1/rpc/${name}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
      },
      body: JSON.stringify(args),
    });
    if (!response.ok) throw new Error(`${name} failed: ${response.status} ${await response.text()}`);
    const text = await response.text();
    return (text ? JSON.parse(text) : null) as T;
  };
  return {
    claim: (limit) => rpc<OutboxRow[]>("claim_notifications", { p_limit: limit }),
    recipients: (id) => rpc<Recipient[]>("notification_recipients", { p_outbox_id: id }),
    complete: (id, sent, error) =>
      rpc<void>("complete_notification", { p_id: id, p_sent: sent, p_error: error }),
    deleteTokens: (tokens) => rpc<void>("delete_device_tokens", { p_tokens: tokens }),
  };
}

function createSender(): PushSender {
  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!raw) return new DryRunSender();
  return new FcmSender(JSON.parse(raw) as ServiceAccount);
}

Deno.serve(async (req) => {
  const secret = Deno.env.get("NOTIFY_CRON_SECRET");
  if (!secret || req.headers.get("Authorization") !== `Bearer ${secret}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  const store = restStore(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const sender = createSender();
  try {
    const summary = await processOutbox(store, sender);
    return Response.json({ ...summary, dryRun: sender.dryRun });
  } catch (e) {
    console.error(e);
    return Response.json({ error: e instanceof Error ? e.message : String(e) }, { status: 500 });
  }
});
