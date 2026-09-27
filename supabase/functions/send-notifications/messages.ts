import { type PushKey, type PushLocale, pushStrings } from "../_shared/push_strings.ts";

export type OutboxKind = "water_arrived" | "water_reached_lower" | "schedule_reminder" | "schedule_start";

export interface OutboxRow {
  id: number;
  kind: OutboxKind;
  neighborhood_id: string;
  elevation_band: "low" | "middle" | "high" | null;
  payload: Record<string, unknown>;
}

export interface PushMessage {
  title: string;
  body: string;
  /** Delivered to the app for routing when the notification is opened. */
  data: Record<string, string>;
}

const keys: Record<OutboxKind, [PushKey, PushKey]> = {
  water_arrived: ["pushWaterArrivedTitle", "pushWaterArrivedBody"],
  water_reached_lower: ["pushReachedLowerTitle", "pushReachedLowerBody"],
  schedule_reminder: ["pushReminderTitle", "pushReminderBody"],
  schedule_start: ["pushScheduleStartTitle", "pushScheduleStartBody"],
};

export function resolveLocale(locale: string | null | undefined): PushLocale {
  return locale === "en" ? "en" : "ar";
}

/** "08:00" -> "8:00 AM" / "8:00 ص" (Western digits in both languages). */
export function formatTime(hhmm: string, locale: PushLocale): string {
  const [h, m] = hhmm.split(":").map(Number);
  const hour12 = h % 12 === 0 ? 12 : h % 12;
  const minutes = String(m).padStart(2, "0");
  const period = locale === "ar" ? (h < 12 ? "ص" : "م") : (h < 12 ? "AM" : "PM");
  return `${hour12}:${minutes} ${period}`;
}

function fill(template: string, values: Record<string, string>): string {
  return template.replace(/\{(\w+)\}/g, (match, name) => values[name] ?? match);
}

export function buildMessage(row: OutboxRow, localeName: string | null | undefined): PushMessage {
  const locale = resolveLocale(localeName);
  const strings = pushStrings[locale];
  const neighborhood = String(row.payload[locale === "en" ? "name_en" : "name_ar"] ?? "");
  const time = typeof row.payload.start_time === "string" ? formatTime(row.payload.start_time, locale) : "";
  const values = { neighborhood, time };
  const [titleKey, bodyKey] = keys[row.kind];
  return {
    title: fill(strings[titleKey], values),
    body: fill(strings[bodyKey], values),
    data: {
      kind: row.kind,
      neighborhood_id: row.neighborhood_id,
      ...(row.elevation_band ? { elevation_band: row.elevation_band } : {}),
    },
  };
}
