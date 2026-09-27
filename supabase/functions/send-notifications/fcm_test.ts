import { assert, assertEquals } from "jsr:@std/assert@1";
import { createAssertion, FcmSender, type ServiceAccount } from "./fcm.ts";

async function testAccount(): Promise<{ account: ServiceAccount; publicKey: CryptoKey }> {
  const { privateKey, publicKey } = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey("pkcs8", privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${
    btoa(String.fromCharCode(...pkcs8))
  }\n-----END PRIVATE KEY-----\n`;
  return {
    account: {
      project_id: "dor-test",
      client_email: "push@dor-test.iam.gserviceaccount.com",
      private_key: pem,
    },
    publicKey,
  };
}

const decode = (part: string) => JSON.parse(atob(part.replace(/-/g, "+").replace(/_/g, "/")));

Deno.test("creates a verifiable RS256 assertion for FCM", async () => {
  const { account, publicKey } = await testAccount();
  const jwt = await createAssertion(account, 1_700_000_000);
  const [header, claims, signature] = jwt.split(".");

  assertEquals(decode(header), { alg: "RS256", typ: "JWT" });
  assertEquals(decode(claims), {
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: 1_700_000_000,
    exp: 1_700_003_600,
  });
  const sig = Uint8Array.from(atob(signature.replace(/-/g, "+").replace(/_/g, "/")), (c) => c.charCodeAt(0));
  assert(
    await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      publicKey,
      sig,
      new TextEncoder().encode(`${header}.${claims}`),
    ),
  );
});

Deno.test("sends via FCM v1, reuses the access token, and detects dead tokens", async () => {
  const { account } = await testAccount();
  const calls: { url: string; body: string }[] = [];
  const fakeFetch = ((input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    calls.push({ url, body: String(init?.body ?? "") });
    if (url.includes("oauth2")) {
      return Promise.resolve(Response.json({ access_token: "at-1", expires_in: 3600 }));
    }
    if (String(init?.body).includes("dead-token")) {
      return Promise.resolve(
        new Response('{"error":{"status":"NOT_FOUND","details":[{"errorCode":"UNREGISTERED"}]}}', {
          status: 404,
        }),
      );
    }
    return Promise.resolve(Response.json({ name: "projects/dor-test/messages/1" }));
  }) as typeof fetch;

  const sender = new FcmSender(account, fakeFetch);
  const message = { title: "t", body: "b", data: { kind: "water_arrived" } };
  assertEquals(await sender.send("good-token", message), "sent");
  assertEquals(await sender.send("dead-token", message), "invalid_token");

  assertEquals(calls.filter((c) => c.url.includes("oauth2")).length, 1, "token cached");
  const send = calls.find((c) => c.url.includes("messages:send"))!;
  assertEquals(send.url, "https://fcm.googleapis.com/v1/projects/dor-test/messages:send");
  const payload = JSON.parse(send.body).message;
  assertEquals(payload.token, "good-token");
  assertEquals(payload.notification, { title: "t", body: "b" });
  assertEquals(payload.android.notification.channel_id, "water_alerts");
});
