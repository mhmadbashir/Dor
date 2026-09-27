import type { PushMessage } from "./messages.ts";

export type SendResult = "sent" | "invalid_token" | "failed";

export interface PushSender {
  readonly dryRun: boolean;
  send(token: string, message: PushMessage): Promise<SendResult>;
}

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

const base64url = (bytes: Uint8Array) =>
  btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

const encodeJson = (value: unknown) => base64url(new TextEncoder().encode(JSON.stringify(value)));

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const body = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

/** Signed JWT assertion for Google's OAuth token endpoint. */
export async function createAssertion(account: ServiceAccount, nowSeconds: number): Promise<string> {
  const header = encodeJson({ alg: "RS256", typ: "JWT" });
  const claims = encodeJson({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  });
  const key = await importPrivateKey(account.private_key);
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`)),
  );
  return `${header}.${claims}.${base64url(signature)}`;
}

/** Sends through FCM HTTP v1 using a Firebase service account. */
export class FcmSender implements PushSender {
  readonly dryRun = false;
  #accessToken?: { value: string; expiresAt: number };

  constructor(private readonly account: ServiceAccount, private readonly fetchFn: typeof fetch = fetch) {}

  async #token(): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    if (this.#accessToken && this.#accessToken.expiresAt > now + 60) return this.#accessToken.value;
    const response = await this.fetchFn("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: await createAssertion(this.account, now),
      }),
    });
    if (!response.ok) throw new Error(`FCM auth failed: ${response.status} ${await response.text()}`);
    const json = await response.json() as { access_token: string; expires_in: number };
    this.#accessToken = { value: json.access_token, expiresAt: now + json.expires_in };
    return json.access_token;
  }

  async send(token: string, message: PushMessage): Promise<SendResult> {
    const response = await this.fetchFn(
      `https://fcm.googleapis.com/v1/projects/${this.account.project_id}/messages:send`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${await this.#token()}` },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: message.title, body: message.body },
            data: message.data,
            android: { priority: "HIGH", notification: { channel_id: "water_alerts" } },
            apns: { payload: { aps: { sound: "default" } } },
          },
        }),
      },
    );
    if (response.ok) return "sent";
    const text = await response.text();
    // Token no longer valid (app uninstalled, token rotated, wrong project).
    if (response.status === 404 || text.includes("UNREGISTERED") || text.includes("registration token")) {
      return "invalid_token";
    }
    console.error(`FCM send failed (${response.status}): ${text}`);
    return "failed";
  }
}

/** Used until FCM_SERVICE_ACCOUNT is configured: logs instead of sending. */
export class DryRunSender implements PushSender {
  readonly dryRun = true;
  readonly sent: { token: string; message: PushMessage }[] = [];

  send(token: string, message: PushMessage): Promise<SendResult> {
    this.sent.push({ token, message });
    console.log(`[dry-run] ${token.slice(0, 12)}… ${message.title} | ${message.body}`);
    return Promise.resolve("sent");
  }
}
