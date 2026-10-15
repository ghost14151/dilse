import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _pink = Color(0xFFFF3D9A);
const _purple = Color(0xFF925CFF);

int dilseAvatarIndex(String? id) {
  if (id == null) return 1;
  if (id.startsWith('avatar_')) {
    return (int.tryParse(id.substring(7)) ?? 1).clamp(1, 16);
  }
  if (id.startsWith('girl')) {
    return ((int.tryParse(id.substring(4)) ?? 1) + 12).clamp(1, 16);
  }
  if (id.startsWith('boy')) {
    return (int.tryParse(id.substring(3)) ?? 1).clamp(1, 16);
  }
  return 1;
}

Widget dilseAvatar(String? id, {double radius = 22}) {
  final n = dilseAvatarIndex(id).toString().padLeft(2, '0');
  return CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFF45233F),
    backgroundImage: AssetImage('assets/avatars/avatar_$n.jpg'),
  );
}

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
  String _selectedAvatar = 'boy1';

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

      final name =
          (data?['displayName'] as String?) ??
          user.displayName ??
          (user.email?.split('@').first ?? 'DilSe User');
      final bio = (data?['bio'] as String?) ?? '';
      _selectedAvatar = (data?['avatarId'] as String?) ?? 'avatar_01';

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

  Widget _avatarChoice(String id) {
    final selected = _selectedAvatar == id;
    final n = dilseAvatarIndex(id).toString().padLeft(2, '0');
    return InkWell(
      onTap: _saving ? null : () => setState(() => _selectedAvatar = id),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 62,
        height: 62,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: selected ? _pink : Colors.white24,
            width: selected ? 3 : 1,
          ),
        ),
        child: ClipOval(
          child: Image.asset('assets/avatars/avatar_$n.jpg', fit: BoxFit.cover),
        ),
      ),
    );
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
        'avatarId': _selectedAvatar,
        'searchName': name.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile save ho gayi!')));
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
        const Text(
          'My Profile ❤️',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: _purple,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              GestureDetector(child: dilseAvatar(_selectedAvatar, radius: 48)),
              const SizedBox(height: 8),
              const Text(
                'Apni pasand ka realistic avatar chuno ❤️',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Text(
                'Apna Avatar Chuno ❤️',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(16, (i) {
                  final id = 'avatar_${(i + 1).toString().padLeft(2, '0')}';
                  return _avatarChoice(id);
                }),
              ),
              const SizedBox(height: 8),
              const Text(
                'Avatar choose karne ke baad Save Profile dabao.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const AdminFreeChatAccessSection(),
        const ProfileSocialTools(),
        const SizedBox(height: 16),
        const DilSeSettingsSection(),
        const SizedBox(height: 18),
        Text(
          user?.email ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
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
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFF6B75)),
            ),
          ),
        FilledButton(
          onPressed: _saving || _loading ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save Profile'),
        ),
      ],
    );
  }
}

class AdminFreeChatAccessSection extends StatefulWidget {
  const AdminFreeChatAccessSection({super.key});

  @override
  State<AdminFreeChatAccessSection> createState() =>
      _AdminFreeChatAccessSectionState();
}

class _AdminFreeChatAccessSectionState
    extends State<AdminFreeChatAccessSection> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _setAccess(String uid, String adminUid, bool enabled) async {
    final ref = FirebaseFirestore.instance
        .collection('freeChatAccess')
        .doc(uid);

    await ref.set({
      'active': enabled,
      'grantedBy': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      return const SizedBox.shrink();
    }

    final db = FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('admins').doc(user.uid).snapshots(),
      builder: (context, adminSnapshot) {
        if (!adminSnapshot.hasData || !adminSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admin Panel'),
            subtitle: const Text('Free Chat Access manage karo'),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    labelText: 'User ka naam search karo',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (_query.trim().length >= 2)
                SizedBox(
                  height: 300,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: db
                        .collection('users')
                        .orderBy('searchName')
                        .startAt([_query.trim().toLowerCase()])
                        .endAt(['${_query.trim().toLowerCase()}\uf8ff'])
                        .limit(20)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Users load nahi hue.'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = snapshot.data!.docs
                          .where((doc) => doc.id != user.uid)
                          .toList();

                      if (users.isEmpty) {
                        return const Center(child: Text('Koi user nahi mila.'));
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final profile = users[index];
                          final name =
                              profile.data()['displayName'] as String? ??
                              'DilSe User';

                          return FutureBuilder<
                            DocumentSnapshot<Map<String, dynamic>>
                          >(
                            future: db
                                .collection('freeChatAccess')
                                .doc(profile.id)
                                .get(),
                            builder: (context, accessSnapshot) {
                              final active =
                                  accessSnapshot.data?.data()?['active'] ==
                                  true;

                              return ListTile(
                                title: Text(name),
                                subtitle: Text(
                                  active
                                      ? 'Unlimited free chat ON'
                                      : 'Free chat OFF',
                                ),
                                trailing: IconButton(
                                  tooltip: active
                                      ? 'Revoke free chat'
                                      : 'Grant free chat',
                                  icon: Icon(
                                    active ? Icons.lock : Icons.lock_open,
                                  ),
                                  onPressed: !accessSnapshot.hasData
                                      ? null
                                      : () async {
                                          try {
                                            await _setAccess(
                                              profile.id,
                                              user.uid,
                                              !active,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        active
                                                            ? 'Free chat permission hata di.'
                                                            : 'Unlimited free chat de di.',
                                                      ),
                                                    ),
                                                  );
                                              setState(() {});
                                            }
                                          } catch (_) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Permission update fail. Admin rules check karo.',
                                                      ),
                                                    ),
                                                  );
                                            }
                                          }
                                        },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Search ke liye kam se kam 2 letters likho.'),
                ),
              const AdminReportsSection(),
            ],
          ),
        );
      },
    );
  }
}

class AdminReportsSection extends StatelessWidget {
  const AdminReportsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.flag_outlined),
      title: const Text('User Reports'),
      subtitle: const Text('Latest 50 reports'),
      children: [
        SizedBox(
          height: 320,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Reports load nahi hue. Firestore Rules check karo.',
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final reports = snapshot.data!.docs;
              if (reports.isEmpty) {
                return const Center(child: Text('Abhi koi report nahi hai.'));
              }
              return ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index].data();
                  final time = report['createdAt'];
                  final date = time is Timestamp
                      ? time.toDate().toLocal().toString()
                      : 'Time unavailable';
                  return ListTile(
                    leading: const Icon(Icons.report_gmailerrorred),
                    title: Text('${report['reason'] ?? 'No reason'}'),
                    subtitle: Text(
                      'Target: ${report['targetUserId'] ?? '-'}\n'
                      'Reporter: ${report['reporterId'] ?? '-'}\n'
                      '$date',
                    ),
                    isThreeLine: true,
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

class PremiumPlansPage extends StatelessWidget {
  const PremiumPlansPage({super.key});

  static const plans = <Map<String, Object>>[
    {'name': 'Monthly', 'price': '₹99', 'duration': '1 month'},
    {'name': '3 Months', 'price': '₹200', 'duration': '3 months'},
    {'name': '6 Months', 'price': '₹500', 'duration': '6 months'},
    {'name': 'Yearly', 'price': '₹1,000', 'duration': '12 months'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DilSe Premium 👑')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Apna Premium Plan Chuno ❤️',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Premium plans ki details',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ...plans.map(
            (plan) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.workspace_premium, color: _pink),
                title: Text(
                  plan['name']! as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(plan['duration']! as String),
                trailing: Text(
                  plan['price']! as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _pink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Payment abhi available nahi hai. Purchase aur payment verification '
                'securely integrate hone ke baad hi Premium khareed paoge. '
                'Abhi payment mat karo.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DilSeSettingsSection extends StatelessWidget {
  const DilSeSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    Widget option(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback tap,
    ) {
      return ListTile(
        leading: Icon(icon, color: _pink),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: tap,
      );
    }

    void info(String title, String message) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(message, textAlign: TextAlign.center)),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.settings, color: _purple),
            title: Text('Settings & Safety'),
            subtitle: Text('Account, privacy and support'),
          ),
          const Divider(height: 1),
          option(
            Icons.lock_outline,
            'Account & Privacy',
            'Account security information',
            () => info(
              'Account & Privacy',
              'Verified email se login karo aur apna password private rakho.',
            ),
          ),
          option(
            Icons.notifications_outlined,
            'Notifications',
            'Friend requests',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FriendRequestsPage()),
            ),
          ),
          option(
            Icons.block_outlined,
            'Blocked Users',
            'Manage blocked accounts',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
            ),
          ),
          option(
            Icons.flag_outlined,
            'Report a Problem',
            'Report suspicious profiles',
            () => info(
              'Report a Problem',
              'User ki profile kholo aur Report profile option chuno.',
            ),
          ),
          option(
            Icons.help_outline,
            'Help & Support',
            'Basic help',
            () => info(
              'Help & Support',
              'Login ya chat problem ho to app restart karke dobara try karo.',
            ),
          ),
          option(
            Icons.workspace_premium,
            'DilSe Premium',
            '₹99 se ₹1,000 tak ke plans dekho',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumPlansPage()),
            ),
          ),
          option(
            Icons.info_outline,
            'About DilSe',
            'Dosti Jo Dil Tak Jaaye ❤️',
            () => info('About DilSe', 'DilSe ❤️\nDosti Jo Dil Tak Jaaye'),
          ),
          const Divider(height: 1),
          option(Icons.logout, 'Log Out', 'Sign out of DilSe', () async {
            final yes = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Log Out?'),
                content: const Text('Kya tum logout karna chahte ho?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            );
            if (yes == true) await FirebaseAuth.instance.signOut();
          }),
        ],
      ),
    );
  }
}

class ProfileSocialTools extends StatelessWidget {
  const ProfileSocialTools({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || !me.emailVerified) return const SizedBox.shrink();

    final pending = FirebaseFirestore.instance
        .collection('friendRequests')
        .where('receiverId', isEqualTo: me.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return Card(
      child: Column(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: pending,
            builder: (context, snap) => ListTile(
              leading: const Icon(Icons.person_add_alt_1, color: _purple),
              title: const Text('Friend Requests'),
              subtitle: Text('${snap.data?.docs.length ?? 0} pending'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendRequestsPage()),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt, color: _pink),
            title: const Text('My Friends'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyFriendsPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.redAccent),
            title: const Text('Blocked Users'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class MyFriendsPage extends StatelessWidget {
  const MyFriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || !me.emailVerified) {
      return const Scaffold(
        body: Center(child: Text('Verified login zaroori hai.')),
      );
    }

    final db = FirebaseFirestore.instance;
    final outgoing = db
        .collection('friendRequests')
        .where('senderId', isEqualTo: me.uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
    final incoming = db
        .collection('friendRequests')
        .where('receiverId', isEqualTo: me.uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('My Friends 👥')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: outgoing,
        builder: (context, a) {
          if (a.hasError) {
            return const Center(
              child: Text('Friends load nahi hue. Rules/index check karo.'),
            );
          }
          if (!a.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: incoming,
            builder: (context, b) {
              if (b.hasError) {
                return const Center(
                  child: Text('Friends load nahi hue. Rules/index check karo.'),
                );
              }
              if (!b.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final friends =
                  <String, DocumentReference<Map<String, dynamic>>>{};
              for (final d in a.data!.docs) {
                final id = d.data()['receiverId'] as String? ?? '';
                if (id.isNotEmpty) friends[id] = d.reference;
              }
              for (final d in b.data!.docs) {
                final id = d.data()['senderId'] as String? ?? '';
                if (id.isNotEmpty) friends[id] = d.reference;
              }

              if (friends.isEmpty) {
                return const Center(
                  child: Text(
                    'Abhi friends nahi hain. Discover se request bhejo 💕',
                  ),
                );
              }

              final rows = friends.entries.toList();
              return ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final row = rows[i];
                  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: db.collection('users').doc(row.key).get(),
                    builder: (context, u) {
                      final data = u.data?.data();
                      final name =
                          data?['displayName'] as String? ?? 'DilSe member';
                      return ListTile(
                        leading: dilseAvatar(data?['avatarId'] as String?),
                        title: Text(name),
                        subtitle: Text(data?['bio'] as String? ?? ''),
                        trailing: IconButton(
                          tooltip: 'Unfriend',
                          icon: const Icon(
                            Icons.person_remove_alt_1,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Unfriend?'),
                                content: Text(
                                  'Kya $name ko friends list se hatana hai?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Unfriend'),
                                  ),
                                ],
                              ),
                            );
                            if (ok != true || !context.mounted) return;
                            try {
                              final db = FirebaseFirestore.instance;
                              final batch = db.batch();
                              for (final requestId in [
                                '${me.uid}_${row.key}',
                                '${row.key}_${me.uid}',
                              ]) {
                                final ref = db
                                    .collection('friendRequests')
                                    .doc(requestId);
                                final request = await ref.get();
                                if (request.exists &&
                                    request.data()?['status'] == 'accepted') {
                                  batch.update(ref, {
                                    'status': 'ended',
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                                }
                              }
                              await batch.commit();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Friend list se hata diya.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Unfriend fail: $e')),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || !me.emailVerified) {
      return const Scaffold(
        body: Center(child: Text('Verified login zaroori hai.')),
      );
    }

    final blocked = FirebaseFirestore.instance
        .collection('blocks')
        .where('blockerId', isEqualTo: me.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users 🚫')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: blocked,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text(
                'Blocked list load nahi hui. Firestore rules check karo.',
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Koi blocked user nahi hai.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final uid = doc.data()['blockedUserId'] as String? ?? '';
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get(),
                builder: (context, u) {
                  final name =
                      u.data?.data()?['displayName'] as String? ??
                      'DilSe member';
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.block)),
                    title: Text(name),
                    trailing: OutlinedButton(
                      child: const Text('Unblock'),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Unblock user?'),
                            content: Text('$name ko unblock karna hai?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Unblock'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !context.mounted) return;
                        try {
                          await doc.reference.delete();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User unblock ho gaya.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Unblock fail: $e')),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
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
  Set<String> _hiddenUserIds = {};
  bool _privacyLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadHiddenUsers();
  }

  Future<void> _loadHiddenUsers() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    try {
      final db = FirebaseFirestore.instance;
      final results = await Future.wait([
        db
            .collection('friendRequests')
            .where('senderId', isEqualTo: me.uid)
            .where('status', isEqualTo: 'accepted')
            .get(),
        db
            .collection('friendRequests')
            .where('receiverId', isEqualTo: me.uid)
            .where('status', isEqualTo: 'accepted')
            .get(),
        db.collection('blocks').where('blockerId', isEqualTo: me.uid).get(),
        db.collection('blocks').where('blockedUserId', isEqualTo: me.uid).get(),
      ]);

      final hidden = <String>{};
      for (final doc in results[0].docs) {
        final id = doc.data()['receiverId'] as String?;
        if (id != null) hidden.add(id);
      }
      for (final doc in results[1].docs) {
        final id = doc.data()['senderId'] as String?;
        if (id != null) hidden.add(id);
      }
      for (final doc in results[2].docs) {
        final id = doc.data()['blockedUserId'] as String?;
        if (id != null) hidden.add(id);
      }
      for (final doc in results[3].docs) {
        final id = doc.data()['blockerId'] as String?;
        if (id != null) hidden.add(id);
      }

      if (mounted) {
        setState(() {
          _hiddenUserIds = hidden;
          _privacyLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _privacyLoaded = true);
    }
  }

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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Discover Friends 💕',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _purple,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh profiles',
                    onPressed: _loadHiddenUsers,
                    icon: const Icon(Icons.refresh, color: _purple),
                  ),
                ],
              ),
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
                  child: Text('Search ke liye kam se kam 2 letters likho.'),
                )
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
                        child: Text(
                          'Search error. Firestore Rules check karo.',
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!_privacyLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data!.docs
                        .where(
                          (doc) =>
                              doc.id != user.uid &&
                              !_hiddenUserIds.contains(doc.id),
                        )
                        .toList();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          'Koi profile nahi mili. Naam ke shuru ke letters try karo.',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final data = users[index].data();
                        final name =
                            data['displayName'] as String? ?? 'DilSe User';
                        final bio = data['bio'] as String? ?? '';

                        return Card(
                          child: ListTile(
                            leading: dilseAvatar(data['avatarId'] as String?),
                            title: Text(name),
                            subtitle: Text(bio.isEmpty ? 'DilSe member' : bio),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PublicUserProfilePage(
                                    userId: users[index].id,
                                    name: name,
                                    bio: bio,
                                    avatarId: data["avatarId"] as String?,
                                  ),
                                ),
                              );
                              await _loadHiddenUsers();
                            },
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

class FriendRequestsPage extends StatelessWidget {
  const FriendRequestsPage({super.key});

  Future<void> _respond(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String status,
  ) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || !me.emailVerified) return;
    try {
      await doc.reference.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? 'Friend request accept ho gayi!'
                  : 'Friend request reject ho gayi.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Action nahi hua. Firestore rules publish/check karo.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || !me.emailVerified) {
      return const Scaffold(
        body: Center(child: Text('Verified login zaroori hai.')),
      );
    }

    final requests = FirebaseFirestore.instance
        .collection('friendRequests')
        .where('receiverId', isEqualTo: me.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Requests & Notifications 🔔')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: requests,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Requests load nahi hue. Firestore rules/index check karo.',
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('Abhi koi new friend request nahi hai 💕'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              return Card(
                child: ListTile(
                  leading:
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .doc(data["senderId"] as String? ?? "")
                            .snapshots(),
                        builder: (context, profile) => dilseAvatar(
                          profile.data?.data()?["avatarId"] as String?,
                        ),
                      ),
                  title: Text(data['senderName'] as String? ?? 'DilSe member'),
                  subtitle: const Text('Friend request bheji hai'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Accept',
                        onPressed: () => _respond(context, doc, 'accepted'),
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Reject',
                        onPressed: () => _respond(context, doc, 'rejected'),
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PublicUserProfilePage extends StatelessWidget {
  final String userId, name, bio;
  final String? avatarId;
  const PublicUserProfilePage({
    super.key,
    required this.userId,
    required this.name,
    required this.bio,
    this.avatarId,
  });

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: dilseAvatar(avatarId)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(bio.isEmpty ? 'DilSe member' : bio)),
          const SizedBox(height: 24),
          if (me != null && me.emailVerified && me.uid != userId)
            FilledButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Send Friend Request'),
              onPressed: () async {
                final db = FirebaseFirestore.instance;
                final requestId = '${me.uid}_$userId';
                try {
                  final blockA = await db
                      .collection('blocks')
                      .doc('${me.uid}_$userId')
                      .get();
                  final blockB = await db
                      .collection('blocks')
                      .doc('${userId}_${me.uid}')
                      .get();
                  if (blockA.exists || blockB.exists) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Block hone ki wajah se request nahi bhej sakte.',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  final ref = db.collection('friendRequests').doc(requestId);
                  final old = await ref.get();
                  if (old.exists && old.data()?['status'] == 'pending') {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request pehle se pending hai.'),
                        ),
                      );
                    }
                    return;
                  }
                  await ref.set({
                    'senderId': me.uid,
                    'receiverId': userId,
                    'senderName': me.displayName ?? 'DilSe member',
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Friend request bhej di!')),
                    );
                  }
                } catch (e) {
                  debugPrint('DilSe friend request failed: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Request fail: $e')));
                  }
                }
              },
            ),
          if (me != null && me.emailVerified)
            OutlinedButton.icon(
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Requests & Notifications'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FriendRequestsPage()),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('Private Message'),
            onPressed: me == null || !me.emailVerified || me.uid == userId
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DirectChatPage(otherUserId: userId, otherName: name),
                    ),
                  ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.block),
            label: const Text('Block User'),
            onPressed: me == null || !me.emailVerified || me.uid == userId
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Block this user?'),
                        content: const Text(
                          'Block karne ke baad aap dono ek dusre ko message nahi bhej paayenge.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Block'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true || !context.mounted) return;
                    try {
                      final db = FirebaseFirestore.instance;
                      final blockRef = db
                          .collection('blocks')
                          .doc('${me.uid}_$userId');
                      final existingBlock = await blockRef.get();
                      final batch = db.batch();
                      if (!existingBlock.exists) {
                        batch.set(blockRef, {
                          'blockerId': me.uid,
                          'blockedUserId': userId,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }

                      for (final requestId in [
                        '${me.uid}_$userId',
                        '${userId}_${me.uid}',
                      ]) {
                        final ref = db
                            .collection('friendRequests')
                            .doc(requestId);
                        final request = await ref.get();
                        if (request.exists &&
                            request.data()?['status'] == 'accepted') {
                          batch.update(ref, {
                            'status': 'ended',
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        }
                      }

                      await batch.commit();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'User blocked aur friend list se hata diya.',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      debugPrint('DilSe block failed: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Block failed. Firestore rules publish karein.',
                            ),
                          ),
                        );
                      }
                    }
                  },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Report profile'),
            onPressed: me == null || !me.emailVerified || me.uid == userId
                ? null
                : () async {
                    final reason = await showDialog<String>(
                      context: context,
                      builder: (c) => SimpleDialog(
                        title: const Text('Report profile'),
                        children: [
                          for (final reason in const [
                            'Fake Profile',
                            'Harassment / Bad Behaviour',
                            'Inappropriate Content',
                            'Fake Identity / Impersonation',
                            'Other',
                          ])
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(c, reason),
                              child: Text(reason),
                            ),
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                    if (reason == null || !context.mounted) return;
                    try {
                      await FirebaseFirestore.instance
                          .collection('reports')
                          .add({
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
                          const SnackBar(
                            content: Text(
                              'Report failed. Firestore rules check karein.',
                            ),
                          ),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class DirectChatPage extends StatefulWidget {
  final String otherUserId, otherName;
  const DirectChatPage({
    super.key,
    required this.otherUserId,
    required this.otherName,
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
      final freeAccess = db.collection('freeChatAccess').doc(user.uid);
      final message = chat.collection('messages').doc();
      final participants = [user.uid, widget.otherUserId]..sort();

      final outgoingBlock = await db
          .collection('blocks')
          .doc('${user.uid}_${widget.otherUserId}')
          .get();
      final incomingBlock = await db
          .collection('blocks')
          .doc('${widget.otherUserId}_${user.uid}')
          .get();
      if (outgoingBlock.exists || incomingBlock.exists) {
        throw StateError('USER_BLOCKED');
      }

      // Ensure the chat exists before the atomic message transaction.
      await chat.set({
        'participants': participants,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await db.runTransaction((tx) async {
        final usageSnap = await tx.get(usage);
        final subscriptionSnap = await tx.get(subscription);
        final freeAccessSnap = await tx.get(freeAccess);
        final chatSnap = await tx.get(chat);

        if (!chatSnap.exists) {
          throw StateError('CHAT_NOT_FOUND');
        }

        final sub = subscriptionSnap.data();
        final expiry = sub?['expiresAt'];
        final premium =
            (sub?['active'] == true &&
                expiry is Timestamp &&
                expiry.toDate().isAfter(DateTime.now())) ||
            freeAccessSnap.data()?['active'] == true;

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
        final userBlocked = e.toString().contains('USER_BLOCKED');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              limitReached
                  ? '10 free messages complete. Chat ke liye DilSe Premium plan chahiye.'
                  : userBlocked
                  ? 'Message nahi bhej sakte: aap mein se kisi ne doosre ko block kiya hai.'
                  : 'Message send nahi hua. Firestore rules aur connection check karein.',
            ),
          ),
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
      return const Scaffold(
        body: Center(child: Text('Verified login required')),
      );
    }
    final ref = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(widget.otherUserId)
                  .snapshots(),
              builder: (context, profile) => dilseAvatar(
                profile.data?.data()?["avatarId"] as String?,
                radius: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.otherName)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ref.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                    child: Text(
                      'Chat permission error. Firestore rules check karein.',
                    ),
                  );
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
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * .78,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? const Color(0xFF7556D9)
                              : const Color(0xFF25283A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          d['text'] as String? ?? '',
                          style: TextStyle(color: Colors.white, height: 1.35),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLength: 4000,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Text('Chats permission error. Rules check karein.'),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.data!.docs.isEmpty) {
          return const Center(
            child: Text('Abhi chats nahi hain. Discover se message karo 💌'),
          );
        }
        return ListView(
          children: snap.data!.docs.map((doc) {
            final data = doc.data();
            final ids = List<String>.from(data['participants'] ?? []);
            final other = ids.where((id) => id != user.uid).firstOrNull;
            if (other == null) return const SizedBox.shrink();
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(other)
                  .get(),
              builder: (context, profile) {
                final name =
                    profile.data?.data()?['displayName'] as String? ??
                    'DilSe User';
                final counts = data['unreadCounts'];
                final unread = counts is Map
                    ? (counts[user.uid] as num?)?.toInt() ?? 0
                    : 0;
                return ListTile(
                  leading: dilseAvatar(
                    profile.data?.data()?["avatarId"] as String?,
                  ),
                  title: Text(name),
                  subtitle: Text(data['lastMessage'] as String? ?? ''),
                  trailing: unread > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DirectChatPage(otherUserId: other, otherName: name),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
