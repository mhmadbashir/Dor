import { assertEquals } from "jsr:@std/assert@1";
import { DryRunSender, type PushSender, type SendResult } from "./fcm.ts";
import type { OutboxRow } from "./messages.ts";
import { type OutboxStore, processOutbox, type Recipient } from "./process.ts";

function fakeStore(rows: OutboxRow[], recipients: Record<number, Recipient[]>) {
  const pending = [...rows];
  const completed: { id: number; sent: number; error: string | null }[] = [];
  const deleted: string[] = [];
  const store: OutboxStore = {
    claim: (limit) => Promise.resolve(pending.splice(0, limit)),
    recipients: (id) =>
      id === 99 ? Promise.reject(new Error("db down")) : Promise.resolve(recipients[id] ?? []),
    complete: (id, sent, error) => {
      completed.push({ id, sent, error });
      return Promise.resolve();
    },
    deleteTokens: (tokens) => {
      deleted.push(...tokens);
      return Promise.resolve();
    },
  };
  return { store, completed, deleted };
}

const outbox = (id: number): OutboxRow => ({
  id,
  kind: "water_arrived",
  neighborhood_id: "nb",
  elevation_band: "low",
  payload: { name_ar: "ماركا", name_en: "Marka" },
});

Deno.test("sends one localized push per device and completes each message", async () => {
  const { store, completed } = fakeStore([outbox(1), outbox(2)], {
    1: [{ token: "a", platform: "android", locale: "ar" }, { token: "b", platform: "ios", locale: "en" }],
    2: [],
  });
  const sender = new DryRunSender();

  const summary = await processOutbox(store, sender, { batchSize: 1 });

  assertEquals(summary, { messages: 2, pushes: 2, invalidTokens: 0, failures: 0 });
  assertEquals(sender.sent.map((s) => s.message.title), ["وصلت المياه إلى ماركا", "Water arrived in Marka"]);
  assertEquals(completed, [{ id: 1, sent: 2, error: null }, { id: 2, sent: 0, error: null }]);
});

Deno.test("removes invalid tokens and records failures for retry", async () => {
  const { store, completed, deleted } = fakeStore([outbox(1), outbox(99)], {
    1: [{ token: "ok", platform: "android", locale: "ar" }, {
      token: "gone",
      platform: "android",
      locale: "ar",
    }],
  });
  const sender: PushSender = {
    dryRun: false,
    send: (token) => Promise.resolve<SendResult>(token === "gone" ? "invalid_token" : "sent"),
  };

  const summary = await processOutbox(store, sender);

  assertEquals(deleted, ["gone"]);
  assertEquals(summary.invalidTokens, 1);
  assertEquals(completed[0], { id: 1, sent: 1, error: null });
  assertEquals(completed[1], { id: 99, sent: 0, error: "db down" });
});
