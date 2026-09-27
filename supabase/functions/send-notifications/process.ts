import type { PushSender } from "./fcm.ts";
import { buildMessage, type OutboxRow } from "./messages.ts";

export interface Recipient {
  token: string;
  platform: string;
  locale: string | null;
}

/** Database access used by the processor (PostgREST RPCs in production). */
export interface OutboxStore {
  claim(limit: number): Promise<OutboxRow[]>;
  recipients(outboxId: number): Promise<Recipient[]>;
  complete(outboxId: number, sent: number, error: string | null): Promise<void>;
  deleteTokens(tokens: string[]): Promise<void>;
}

export interface ProcessSummary {
  messages: number;
  pushes: number;
  invalidTokens: number;
  failures: number;
}

const CONCURRENCY = 10;

async function inBatches<T, R>(items: T[], size: number, fn: (item: T) => Promise<R>): Promise<R[]> {
  const results: R[] = [];
  for (let i = 0; i < items.length; i += size) {
    results.push(...await Promise.all(items.slice(i, i + size).map(fn)));
  }
  return results;
}

/** Drains the outbox until empty (or maxBatches), sending one push per device. */
export async function processOutbox(
  store: OutboxStore,
  sender: PushSender,
  { batchSize = 20, maxBatches = 10 } = {},
): Promise<ProcessSummary> {
  const summary: ProcessSummary = { messages: 0, pushes: 0, invalidTokens: 0, failures: 0 };

  for (let batch = 0; batch < maxBatches; batch++) {
    const rows = await store.claim(batchSize);
    if (rows.length === 0) break;

    for (const row of rows) {
      summary.messages++;
      try {
        const recipients = await store.recipients(row.id);
        const results = await inBatches(recipients, CONCURRENCY, async (r) => ({
          token: r.token,
          result: await sender.send(r.token, buildMessage(row, r.locale)),
        }));
        const invalid = results.filter((r) => r.result === "invalid_token").map((r) => r.token);
        const sent = results.filter((r) => r.result === "sent").length;
        const failed = results.filter((r) => r.result === "failed").length;
        if (invalid.length > 0) await store.deleteTokens(invalid);
        summary.pushes += sent;
        summary.invalidTokens += invalid.length;
        summary.failures += failed;
        // Individual device failures don't block the message; it isn't retried
        // for everyone just because a few devices failed.
        await store.complete(row.id, sent, null);
      } catch (e) {
        summary.failures++;
        await store.complete(row.id, 0, e instanceof Error ? e.message : String(e));
      }
    }
  }
  return summary;
}
