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
  const subscriptionRef = db.collection("subscriptions").doc(uid);
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
    const subscriptionSnap = await tx.get(subscriptionRef);
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

    // DILSE_STREAK_PREMIUM_DAY_V1
    // Every seventh consecutive check-in grants one server-authoritative day.
    const premiumDaysGranted = next % 7 === 0;
    if (premiumDaysGranted) {
      const sub = subscriptionSnap.exists ? subscriptionSnap.data() : {};
      const expiry = sub.expiresAt &&
          typeof sub.expiresAt.toDate === "function" ?
          sub.expiresAt.toDate() : null;
      const base = expiry && expiry > now ? expiry : now;
      const newExpiry = new Date(base.getTime() + 86400000);

      tx.set(subscriptionRef, {
        active: true,
        expiresAt: admin.firestore.Timestamp.fromDate(newExpiry),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastStreakRewardAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    }

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
      premiumDaysGranted,
      points: (Number.isInteger(old.points) ? old.points : 0) + addedPoints,
      newlyUnlocked: newlyUnlocked.map((m) => ({
        days: m.days, points: m.points, badge: m.badge,
      })),
      unlockedMilestones: allUnlocked,
    };
  });
});


// DILSE_ACCOUNT_MANAGEMENT_V1
// Keep shared chats and messages when a user account is removed.
/** Verifies the signed-in user's email and moderation status.
 * @param {object} request - Callable request.
 */
async function requireVerifiedAccount(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Please sign in first.");
  }
  if (request.auth.token.email_verified !== true) {
    throw new HttpsError("permission-denied", "Verify your email first.");
  }
  const db = admin.firestore();
  const blocked = await db.collection("adminBlocks")
      .doc(request.auth.uid).get();
  if (blocked.exists) {
    throw new HttpsError("permission-denied", "This account is blocked.");
  }
  return request.auth.uid;
}

/** Verifies that the caller has an authorized admin document.
 * @param {object} request - Callable request.
 */
async function requireDilSeAdmin(request) {
  const uid = await requireVerifiedAccount(request);
  const snap = await admin.firestore().collection("admins").doc(uid).get();
  if (!snap.exists) {
    throw new HttpsError("permission-denied", "Admin permission required.");
  }
  return uid;
}

/** Deletes document references in Firestore-safe batches.
 * @param {Array} refs - Firestore document references.
 */
async function deleteDocsInBatches(refs) {
  for (let i = 0; i < refs.length; i += 400) {
    const batch = admin.firestore().batch();
    for (const ref of refs.slice(i, i + 400)) batch.delete(ref);
    await batch.commit();
  }
}

/** Removes account-owned data while preserving shared chat history.
 * @param {string} uid - Account user ID.
 */
async function removeDilSeAccountData(uid) {
  const db = admin.firestore();
  const refs = [];
  const profileRef = db.collection("users").doc(uid);

  const tokenDocs = await profileRef.collection("fcmTokens").get();
  refs.push(...tokenDocs.docs.map((doc) => doc.ref));

  for (const collectionName of [
    "chatUsage", "subscriptions", "freeChatAccess",
    "dailyStreaks", "adminBlocks", "admins",
  ]) {
    refs.push(db.collection(collectionName).doc(uid));
  }

  for (const [collectionName, field] of [
    ["friendRequests", "senderId"],
    ["friendRequests", "receiverId"],
    ["blocks", "blockerId"],
    ["blocks", "blockedUserId"],
  ]) {
    const snap = await db.collection(collectionName)
        .where(field, "==", uid).get();
    refs.push(...snap.docs.map((doc) => doc.ref));
  }

  refs.push(profileRef);
  const uniqueRefs = [...new Map(refs.map((ref) => [ref.path, ref])).values()];
  await deleteDocsInBatches(uniqueRefs);
}

exports.deleteOwnDilSeAccount = onCall(async (request) => {
  const uid = await requireVerifiedAccount(request);
  await removeDilSeAccountData(uid);
  await admin.auth().deleteUser(uid);
  return {
    success: true,
    message: "Account deleted. Shared chat history was preserved.",
  };
});

exports.adminSetUserBlocked = onCall(async (request) => {
  const adminUid = await requireDilSeAdmin(request);
  const data = request.data || {};
  const targetUid = data.targetUid;
  const blocked = data.blocked;

  if (typeof targetUid !== "string" || !targetUid ||
      targetUid === adminUid || typeof blocked !== "boolean") {
    throw new HttpsError("invalid-argument", "Invalid moderation request.");
  }

  const db = admin.firestore();
  const targetAdmin = await db.collection("admins").doc(targetUid).get();
  if (targetAdmin.exists) {
    throw new HttpsError(
        "failed-precondition", "Admin accounts cannot be moderated here.",
    );
  }

  const blockRef = db.collection("adminBlocks").doc(targetUid);
  if (blocked) {
    await blockRef.set({
      active: true,
      blockedBy: adminUid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await admin.auth().updateUser(targetUid, {disabled: true});
  } else {
    await admin.auth().updateUser(targetUid, {disabled: false});
    await blockRef.delete();
  }

  return {success: true, targetUid, blocked};
});

exports.adminDeleteDilSeUser = onCall(async (request) => {
  await requireDilSeAdmin(request);
  const data = request.data || {};
  const targetUid = data.targetUid;

  if (typeof targetUid !== "string" || !targetUid) {
    throw new HttpsError("invalid-argument", "Invalid user ID.");
  }

  const db = admin.firestore();
  const targetAdmin = await db.collection("admins").doc(targetUid).get();
  if (targetAdmin.exists) {
    throw new HttpsError(
        "failed-precondition", "Admin accounts cannot be deleted here.",
    );
  }

  await removeDilSeAccountData(targetUid);
  try {
    await admin.auth().deleteUser(targetUid);
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
  }

  return {
    success: true,
    targetUid,
    message: "User account removed; shared chat history was preserved.",
  };
});
