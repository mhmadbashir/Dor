import { assertEquals } from "jsr:@std/assert@1";
import { buildMessage, formatTime, type OutboxRow } from "./messages.ts";

const row = (kind: OutboxRow["kind"], payload: Record<string, unknown> = {}): OutboxRow => ({
  id: 1,
  kind,
  neighborhood_id: "nb-1",
  elevation_band: kind === "schedule_reminder" || kind === "schedule_start" ? null : "high",
  payload: { name_ar: "خلدا", name_en: "Khalda", ...payload },
});

Deno.test("formats times with Western digits in both languages", () => {
  assertEquals(formatTime("08:00", "en"), "8:00 AM");
  assertEquals(formatTime("18:30", "en"), "6:30 PM");
  assertEquals(formatTime("00:05", "en"), "12:05 AM");
  assertEquals(formatTime("12:00", "ar"), "12:00 م");
  assertEquals(formatTime("06:00", "ar"), "6:00 ص");
});

Deno.test("water arrived message in Arabic (default) and English", () => {
  assertEquals(buildMessage(row("water_arrived"), "ar").title, "وصلت المياه إلى خلدا");
  assertEquals(buildMessage(row("water_arrived"), null).title, "وصلت المياه إلى خلدا");
  assertEquals(buildMessage(row("water_arrived"), "en").title, "Water arrived in Khalda");
});

Deno.test("reached-lower message explains the elevation delay", () => {
  const m = buildMessage(row("water_reached_lower"), "en");
  assertEquals(m.title, "Water reached Khalda");
  assertEquals(m.body.includes("higher ground"), true);
  assertEquals(m.data, { kind: "water_reached_lower", neighborhood_id: "nb-1", elevation_band: "high" });
});

Deno.test("water-day start reminder says it is per the schedule", () => {
  const ar = buildMessage(row("schedule_start", { start_time: "08:00" }), "ar");
  assertEquals(ar.title, "بدأ دور المياه في خلدا");
  assertEquals(ar.body, "الضخ مجدول من الساعة 8:00 ص. سنخبرك عندما يؤكد جيرانك وصول المياه.");
  const en = buildMessage(row("schedule_start", { start_time: "18:00" }), "en");
  assertEquals(en.title, "Your water day in Khalda starts now");
  assertEquals(en.body.startsWith("Supply is scheduled from 6:00 PM."), true);
});

Deno.test("reminder includes the localized start time", () => {
  const m = buildMessage(row("schedule_reminder", { start_time: "08:00" }), "ar");
  assertEquals(m.title, "غدًا دور المياه في خلدا");
  assertEquals(m.body, "يبدأ الضخ المجدول الساعة 8:00 ص. جهّز خزاناتك.");
  assertEquals(m.data, { kind: "schedule_reminder", neighborhood_id: "nb-1" });
});
