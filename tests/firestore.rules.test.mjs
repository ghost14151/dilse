import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc,
  setDoc,
  updateDoc,
  deleteDoc,
  getDoc,
  serverTimestamp,
  Timestamp,
  writeBatch,
} from 'firebase/firestore';

const projectId = 'dilse-b7bd8';
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'chats', 'chat1'), {
      participants: ['alice', 'bob'],
    });
    await setDoc(doc(db, 'chats', 'chat1', 'messages', 'm1'), {
      senderId: 'alice',
      text: 'Hello',
      createdAt: Timestamp.now(),
      readBy: ['alice'],
    });
  });
});

function user(uid) {
  return env.authenticatedContext(uid, { email_verified: true }).firestore();
}

test('sender can edit own message', async () => {
  const db = user('alice');
  await assertSucceeds(updateDoc(doc(db, 'chats/chat1/messages/m1'), {
    text: 'Edited',
    editedAt: serverTimestamp(),
  }));
});

test('sender can delete own message', async () => {
  await assertSucceeds(deleteDoc(doc(user('alice'), 'chats/chat1/messages/m1')));
});

test('receiver can add own seen receipt', async () => {
  await assertSucceeds(updateDoc(doc(user('bob'), 'chats/chat1/messages/m1'), {
    readBy: ['alice', 'bob'],
  }));
});

test('other user cannot read or edit chat messages', async () => {
  const db = user('mallory');
  await assertFails(getDoc(doc(db, 'chats/chat1/messages/m1')));
  await assertFails(updateDoc(doc(db, 'chats/chat1/messages/m1'), {
    text: 'Hacked',
    editedAt: serverTimestamp(),
  }));
});

test('receiver cannot delete sender message', async () => {
  await assertFails(deleteDoc(doc(user('bob'), 'chats/chat1/messages/m1')));
});

test('sender cannot mark their own message as seen by receiver', async () => {
  await assertFails(updateDoc(doc(user('alice'), 'chats/chat1/messages/m1'), {
    readBy: ['alice', 'bob'],
  }));
});

test('message creation requires sender readBy and usage accounting', async () => {
  const db = user('alice');
  const batch = writeBatch(db);
  const usage = doc(db, 'chatUsage/alice');
  const message = doc(db, 'chats/chat1/messages/new1');

  batch.set(usage, {
    messagesSent: 1,
    lastChatId: 'chat1',
    lastMessageId: 'new1',
    updatedAt: serverTimestamp(),
  });
  batch.set(message, {
    senderId: 'alice',
    text: 'First message',
    createdAt: serverTimestamp(),
    readBy: ['alice'],
  });

  await assertSucceeds(batch.commit());
});
