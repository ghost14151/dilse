import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _pink = Color(0xFFE94E91);
const _purple = Color(0xFF7556D9);

class FirestoreProfilePage extends StatefulWidget {
  const FirestoreProfilePage({super.key});

  @override
  State<FirestoreProfilePage> createState() => _FirestoreProfilePageState();
}

class _FirestoreProfilePageState extends State<FirestoreProfilePage> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      setState(() {
        _loading = false;
        _error = 'Pehle verified email se login karo.';
      });
      return;
    }

    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await ref.get();
      final data = snapshot.data();

      final name = (data?['displayName'] as String?) ??
          user.displayName ??
          (user.email?.split('@').first ?? 'DilSe User');
      final bio = (data?['bio'] as String?) ?? '';

      if (!snapshot.exists) {
        await ref.set({
          'uid': user.uid,
          'displayName': name,
          'bio': '',
          'photoUrl': '',
          'searchName': name.toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      _name.text = name;
      _bio.text = bio;
    } catch (e) {
      if (mounted) setState(() => _error = 'Profile load nahi hua: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    final name = _name.text.trim();
    final bio = _bio.text.trim();

    if (user == null || !user.emailVerified) {
      setState(() => _error = 'Verified login zaroori hai.');
      return;
    }
    if (name.length < 2 || name.length > 40) {
      setState(() => _error = 'Naam 2 se 40 characters ka rakho.');
      return;
    }
    if (bio.length > 160) {
      setState(() => _error = 'Bio 160 characters se chhoti rakho.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': name,
        'bio': bio,
        'photoUrl': '',
        'searchName': name.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile save ho gayi!')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Save nahi hua: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('My Profile ❤️',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold,
                color: _purple)),
        const SizedBox(height: 20),
        const Center(
          child: CircleAvatar(
            radius: 43,
            backgroundColor: Color(0xFFFFD8E6),
            child: Icon(Icons.person, size: 48, color: _pink),
          ),
        ),
        const SizedBox(height: 18),
        Text(user?.email ?? '', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'Display name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bio,
          maxLength: 160,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Apne baare mein',
            hintText: 'Music, gaming, hobbies...',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        FilledButton(
          onPressed: _saving || _loading ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save Profile'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Abhi naam aur bio save hote hain. Profile photo upload agle step mein connect karenge.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class FirestoreDiscoverPage extends StatefulWidget {
  const FirestoreDiscoverPage({super.key});

  @override
  State<FirestoreDiscoverPage> createState() => _FirestoreDiscoverPageState();
}

class _FirestoreDiscoverPageState extends State<FirestoreDiscoverPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || !user.emailVerified) {
      return const Center(child: Text('Verified login zaroori hai.'));
    }

    final prefix = _query.trim().toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Discover Friends 💕',
                  style: TextStyle(fontSize: 26,
                      fontWeight: FontWeight.bold, color: _purple)),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Naam se users search karo',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: prefix.length < 2
              ? const Center(
                  child: Text('Search ke liye kam se kam 2 letters likho.'))
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('searchName')
                      .startAt([prefix])
                      .endAt(['$prefix\uf8ff'])
                      .limit(30)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Search error. Firestore Rules check karo.'),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data!.docs
                        .where((doc) => doc.id != user.uid)
                        .toList();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text('Koi profile nahi mili. Naam ke shuru ke letters try karo.'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final data = users[index].data();
                        final name = data['displayName'] as String? ?? 'DilSe User';
                        final bio = data['bio'] as String? ?? '';

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFFD8E6),
                              child: Icon(Icons.person, color: _pink),
                            ),
                            title: Text(name),
                            subtitle: Text(bio.isEmpty ? 'DilSe member' : bio),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PublicUserProfilePage(
                                  userId: users[index].id,
                                  name: name,
                                  bio: bio,
                                ),
                              ),
                            ),

                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}


class PublicUserProfilePage extends StatelessWidget {
  final String userId, name, bio;
  const PublicUserProfilePage({
    super.key, required this.userId, required this.name, required this.bio,
  });

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const CircleAvatar(
          radius: 45, child: Icon(Icons.person, size: 48),
        ),
        const SizedBox(height: 16),
        Center(child: Text(name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Center(child: Text(bio.isEmpty ? 'DilSe member' : bio)),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.chat),
          label: const Text('Private Message'),
          onPressed: me == null || !me.emailVerified || me.uid == userId
              ? null
              : () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DirectChatPage(
                    otherUserId: userId, otherName: name,
                  ),
                )),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Report profile'),
          onPressed: me == null || !me.emailVerified || me.uid == userId
              ? null
              : () async {
                  final reason = await showDialog<String>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Report profile'),
                      content: const Text(
                        'Kya ye profile spam, fake ya inappropriate hai?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, 'Spam or inappropriate'),
                          child: const Text('Report')),
                      ],
                    ),
                  );
                  if (reason == null || !context.mounted) return;
                  try {
                    await FirebaseFirestore.instance.collection('reports').add({
                      'reporterId': me.uid,
                      'targetUserId': userId,
                      'reason': reason,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report submitted')),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(
                          'Report failed. Firestore rules check karein.')),
                      );
                    }
                  }
                },
        ),
      ]),
    );
  }
}

class DirectChatPage extends StatefulWidget {
  final String otherUserId, otherName;
  const DirectChatPage({
    super.key, required this.otherUserId, required this.otherName,
  });
  @override
  State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
  final _input = TextEditingController();
  bool _sending = false;

  String get _chatId {
    final ids = [FirebaseAuth.instance.currentUser!.uid, widget.otherUserId]
      ..sort();
    return ids.join('_');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
    });
  }

  Future<void> _markRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) return;
    try {
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
        'unreadCounts.${user.uid}': 0,
      });
    } catch (_) {
      // Chat doc ya unread count abhi na ho to ignore karein.
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _input.text.trim();
    if (user == null || !user.emailVerified || text.isEmpty || _sending) return;
    if (text.length > 4000) return;

    setState(() => _sending = true);
    _input.clear();
    try {
      final db = FirebaseFirestore.instance;
      final chat = db.collection('chats').doc(_chatId);
      final usage = db.collection('chatUsage').doc(user.uid);
      final subscription = db.collection('subscriptions').doc(user.uid);
      final message = chat.collection('messages').doc();
      final participants = [user.uid, widget.otherUserId]..sort();

      // Ensure the chat exists before the atomic message transaction.
      await chat.set({
        'participants': participants,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await db.runTransaction((tx) async {
        final usageSnap = await tx.get(usage);
        final subscriptionSnap = await tx.get(subscription);
        final chatSnap = await tx.get(chat);

        if (!chatSnap.exists) {
          throw StateError('CHAT_NOT_FOUND');
        }

        final sub = subscriptionSnap.data();
        final expiry = sub?['expiresAt'];
        final premium = sub?['active'] == true &&
            expiry is Timestamp &&
            expiry.toDate().isAfter(DateTime.now());

        final sent = (usageSnap.data()?['messagesSent'] as num?)?.toInt() ?? 0;
        if (!premium && sent >= 10) {
          throw StateError('FREE_CHAT_LIMIT');
        }

        if (!premium) {
          tx.set(usage, {
            'messagesSent': sent + 1,
            'lastChatId': _chatId,
            'lastMessageId': message.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        tx.set(chat, {
          'participants': participants,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': text,
        }, SetOptions(merge: true));

        tx.set(message, {
          'senderId': user.uid,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      try {
        await chat.update({
          'unreadCounts.${widget.otherUserId}': FieldValue.increment(1),
        });
      } catch (_) {}
    } catch (e) {
      _input.text = text;
      if (mounted) {
        final limitReached = e.toString().contains('FREE_CHAT_LIMIT');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            limitReached
                ? '10 free messages complete. Chat ke liye ₹99 / 30-day Pass chahiye.'
                : 'Message send nahi hua. Firestore rules aur connection check karein.',
          )),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      return const Scaffold(body: Center(
        child: Text('Verified login required')));
    }
    final ref = FirebaseFirestore.instance.collection('chats')
      .doc(_chatId).collection('messages')
      .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ref.snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(
                  child: Text('Chat permission error. Firestore rules check karein.'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('Pehla message bhejo 👋'));
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data();
                  final mine = d['senderId'] == user.uid;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * .78),
                      decoration: BoxDecoration(
                        color: mine ? const Color(0xFF7556D9) : Colors.black12,
                        borderRadius: BorderRadius.circular(14)),
                      child: Text(d['text'] as String? ?? '',
                        style: TextStyle(
                          color: mine ? Colors.white : Colors.black87)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _input, maxLength: 4000, maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Message...', counterText: '',
                border: OutlineInputBorder()),
              onSubmitted: (_) => _send(),
            )),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: const Icon(Icons.send),
            ),
          ]),
        )),
      ]),
    );
  }
}

class FirestoreChatsPage extends StatelessWidget {
  const FirestoreChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      return const Center(child: Text('Verified login required'));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('chats')
        .where('participants', arrayContains: user.uid).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Chats permission error. Rules check karein.'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text('Abhi chats nahi hain. Discover se message karo 💌'));
        }
        return ListView(children: snap.data!.docs.map((doc) {
          final data = doc.data();
          final ids = List<String>.from(data['participants'] ?? []);
          final other = ids.where((id) => id != user.uid).firstOrNull;
          if (other == null) return const SizedBox.shrink();
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance.collection('users').doc(other).get(),
            builder: (context, profile) {
              final name = profile.data?.data()?['displayName'] as String?
                ?? 'DilSe User';
              final counts = data['unreadCounts'];
              final unread = counts is Map
                  ? (counts[user.uid] as num?)?.toInt() ?? 0
                  : 0;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFE3F0),
                  child: const Icon(Icons.person, color: Color(0xFFE94E91)),
                ),
                title: Text(name),
                subtitle: Text(data['lastMessage'] as String? ?? ''),
                trailing: unread > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE94E91),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DirectChatPage(
                    otherUserId: other, otherName: name),
                )),
              );
            },
          );
        }).toList());
      },
    );
  }
}
