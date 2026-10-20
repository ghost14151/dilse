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


// Server-authoritative daily check-in and milestone rewards.
exports.dailyStreakCheckIn = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }
  if (request.auth.token.email_verified !== true) {
    throw new HttpsError(
        "permission-denied", "Verify your email before checking in.",
    );
  }

  const uid = request.auth.uid;
  const db = admin.firestore();
  const ref = db.collection("dailyStreaks").doc(uid);
  const now = new Date();
  const today = now.toISOString().slice(0, 10);
  const yesterdayDate = new Date(now.getTime() - 86400000);
  const yesterday = yesterdayDate.toISOString().slice(0, 10);
  const milestones = [
    {days: 3, points: 30, badge: "streak_3"},
    {days: 7, points: 70, badge: "streak_7"},
    {days: 15, points: 150, badge: "streak_15"},
    {days: 30, points: 300, badge: "streak_30"},
    {days: 60, points: 600, badge: "streak_60"},
    {days: 100, points: 1000, badge: "streak_100"},
  ];

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const old = snap.exists ? snap.data() : {};
    if (old.lastCheckInDate === today) {
      return {
        alreadyCheckedIn: true,
        streak: old.streak || 0,
        points: old.points || 0,
        unlockedMilestones: old.unlockedMilestones || [],
      };
    }

    const previous = Number.isInteger(old.streak) ? old.streak : 0;
    const next = old.lastCheckInDate === yesterday ? previous + 1 : 1;
    const unlocked = Array.isArray(old.unlockedMilestones) ?
        old.unlockedMilestones : [];
    const newlyUnlocked = milestones.filter(
        (m) => m.days === next && !unlocked.includes(m.days),
    );
    const addedPoints = newlyUnlocked.reduce((sum, m) => sum + m.points, 0);
    const allUnlocked = [...new Set([
      ...unlocked, ...newlyUnlocked.map((m) => m.days),
    ])];

    tx.set(ref, {
      uid,
      streak: next,
      lastCheckInDate: today,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      points: (Number.isInteger(old.points) ? old.points : 0) + addedPoints,
      unlockedMilestones: allUnlocked,
      badges: [...new Set([
        ...(Array.isArray(old.badges) ? old.badges : []),
        ...newlyUnlocked.map((m) => m.badge),
      ])],
    });

    return {
      alreadyCheckedIn: false,
      streak: next,
      points: (Number.isInteger(old.points) ? old.points : 0) + addedPoints,
      newlyUnlocked: newlyUnlocked.map((m) => ({
        days: m.days, points: m.points, badge: m.badge,
      })),
      unlockedMilestones: allUnlocked,
    };
  });
});
