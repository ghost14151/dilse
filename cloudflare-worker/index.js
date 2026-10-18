import agoraToken from "agora-token";

const { RtcTokenBuilder, RtcRole } = agoraToken;

const json = (data, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Authorization, Content-Type",
    },
  });

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Authorization, Content-Type",
        },
      });
    }

    if (request.method !== "POST") {
      return json({ error: "POST required" }, 405);
    }

    try {
      const authorization = request.headers.get("Authorization") || "";
      const match = authorization.match(/^Bearer\s+(.+)$/i);

      if (!match || !env.FIREBASE_WEB_API_KEY) {
        return json({ error: "Authentication required" }, 401);
      }

      const verifyResponse = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${encodeURIComponent(env.FIREBASE_WEB_API_KEY)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ idToken: match[1] }),
        },
      );

      if (!verifyResponse.ok) {
        return json({ error: "Invalid Firebase login" }, 401);
      }

      const account = await verifyResponse.json();
      const user = account.users?.[0];

      if (!user || user.emailVerified !== true) {
        return json({ error: "Verified account required" }, 403);
      }

      const body = await request.json();
      const channelName = body?.channelName;
      const uid = Number(body?.uid);

      if (
        typeof channelName !== "string" ||
        !/^[a-zA-Z0-9_-]{1,64}$/.test(channelName)
      ) {
        return json({ error: "Invalid channel name" }, 400);
      }

      if (!Number.isSafeInteger(uid) || uid < 1 || uid > 2147483647) {
        return json({ error: "Invalid numeric UID" }, 400);
      }

      if (!env.AGORA_APP_ID || !env.AGORA_APP_CERTIFICATE) {
        return json({ error: "Agora secrets are not configured" }, 500);
      }

      const expiresAt = Math.floor(Date.now() / 1000) + 3600;
      const token = RtcTokenBuilder.buildTokenWithUid(
        env.AGORA_APP_ID,
        env.AGORA_APP_CERTIFICATE,
        channelName,
        uid,
        RtcRole.PUBLISHER,
        expiresAt,
      );

      return json({
        token,
        appId: env.AGORA_APP_ID,
        channelName,
        uid,
        expiresAt,
      });
    } catch {
      return json({ error: "Invalid request or token generation failed" }, 400);
    }
  },
};
