const {setGlobalOptions} = require("firebase-functions");
setGlobalOptions({maxInstances: 10});

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {RtcTokenBuilder, RtcRole} = require("agora-token");

const agoraAppId = defineSecret("AGORA_APP_ID");
const agoraAppCertificate = defineSecret("AGORA_APP_CERTIFICATE");

exports.generateAgoraToken = onCall(
    {secrets: [agoraAppId, agoraAppCertificate]},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Please sign in first.");
      }

      const data = request.data || {};
      const channelName = data.channelName;
      const uid = Number(data.uid);

      if (typeof channelName !== "string" ||
          !/^[a-zA-Z0-9_-]{1,64}$/.test(channelName)) {
        throw new HttpsError("invalid-argument", "Invalid channel name.");
      }

      if (!Number.isSafeInteger(uid) || uid < 1 || uid > 2147483647) {
        throw new HttpsError("invalid-argument", "Invalid numeric UID.");
      }

      const appId = agoraAppId.value();
      const certificate = agoraAppCertificate.value();

      if (!appId || !certificate) {
        throw new HttpsError(
            "failed-precondition",
            "Agora secrets are not configured.",
        );
      }

      const expiresAt = Math.floor(Date.now() / 1000) + 3600;
      const token = RtcTokenBuilder.buildTokenWithUid(
          appId,
          certificate,
          channelName,
          uid,
          RtcRole.PUBLISHER,
          expiresAt,
      );

      return {token, appId, channelName, uid, expiresAt};
    },
);


const admin = require("firebase-admin");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

exports.sendDilSeMessageNotification = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      const message = event.data ? event.data.data() : null;
      if (!message || !message.senderId) return;

      const db = admin.firestore();
      const chatRef = db.collection("chats").doc(event.params.chatId);
      const chatSnap = await chatRef.get();
      if (!chatSnap.exists) return;

      const participants = chatSnap.get("participants");
      if (!Array.isArray(participants) ||
          !participants.includes(message.senderId)) {
        return;
      }

      const recipientIds = participants.filter(
          (uid) => uid !== message.senderId,
      );

      const senderSnap = await db.collection("users")
          .doc(message.senderId).get();
      const senderName = senderSnap.exists ?
      (senderSnap.get("displayName") || "DilSe friend") :
      "DilSe friend";

      const rawText = typeof message.text === "string" ?
          message.text.trim() :
          "";
      const body = rawText ?
          rawText.substring(0, 180) :
          "You received a new message";

      for (const recipientId of recipientIds) {
        const tokensSnap = await db
            .collection("users").doc(recipientId)
            .collection("fcmTokens").get();

        const tokens = tokensSnap.docs
            .map((doc) => doc.get("token"))
            .filter((token) => typeof token === "string" && token.length > 0);

        if (tokens.length === 0) continue;

        const response = await admin.messaging().sendEachForMulticast({
          tokens,
          notification: {
            title: senderName,
            body,
          },
          data: {
            type: "chat_message",
            chatId: event.params.chatId,
            otherUserId: message.senderId,
            otherName: senderName,
          },
          android: {
            priority: "high",
            notification: {
              channelId: "dilse_messages",
            },
          },
        });

        const invalidTokens = [];
        response.responses.forEach((result, index) => {
          if (!result.success && [
            "messaging/invalid-registration-token",
            "messaging/registration-token-not-registered",
          ].includes((result.error ? result.error.code : null))) {
            invalidTokens.push(tokens[index]);
          }
        });

        if (invalidTokens.length > 0) {
          const batch = db.batch();
          for (const token of invalidTokens) {
            for (const doc of tokensSnap.docs) {
              if (doc.get("token") === token) batch.delete(doc.ref);
            }
          }
          await batch.commit();
        }
      }
    },
);
