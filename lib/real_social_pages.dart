import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'dart:async';

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

class MyFriendsPage extends StatefulWidget {
  const MyFriendsPage({super.key});

  @override
  State<MyFriendsPage> createState() => _MyFriendsPageState();
}

class _MyFriendsPageState extends State<MyFriendsPage> {
  final TextEditingController _search = TextEditingController();
  int _filter = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
      backgroundColor: const Color(0xFF160F2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF21143F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Friends 👥',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF49216F), Color(0xFF21143F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(26),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apni DilSe family 💕',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Apne doston se jude raho',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Friend ka naam search karo...',
                      hintStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFFF5AA5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('All Friends', 0),
                      _filterChip('Online', 1),
                      _filterChip('Requests', 2),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filter == 2
                  ? _requestsShortcut(context)
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: outgoing,
                      builder: (context, a) {
                        if (a.hasError) {
                          return _message(
                            'Friends load nahi hue. Internet ya rules check karo.',
                          );
                        }
                        if (!a.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF5AA5),
                            ),
                          );
                        }
                        return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>
                        >(
                          stream: incoming,
                          builder: (context, b) {
                            if (b.hasError) {
                              return _message('Friends load nahi hue.');
                            }
                            if (!b.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF5AA5),
                                ),
                              );
                            }

                            final friends =
                                <
                                  String,
                                  DocumentReference<Map<String, dynamic>>
                                >{};
                            for (final d in a.data!.docs) {
                              final id =
                                  d.data()['receiverId'] as String? ?? '';
                              if (id.isNotEmpty) friends[id] = d.reference;
                            }
                            for (final d in b.data!.docs) {
                              final id = d.data()['senderId'] as String? ?? '';
                              if (id.isNotEmpty) friends[id] = d.reference;
                            }

                            if (friends.isEmpty) {
                              return _message(
                                'Abhi friends nahi hain.\nDiscover se request bhejo 💕',
                              );
                            }

                            final rows = friends.entries.toList();
                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                14,
                                14,
                                24,
                              ),
                              itemCount: rows.length,
                              itemBuilder: (context, i) {
                                final row = rows[i];
                                return FutureBuilder<
                                  DocumentSnapshot<Map<String, dynamic>>
                                >(
                                  future: db
                                      .collection('users')
                                      .doc(row.key)
                                      .get(),
                                  builder: (context, u) {
                                    final data = u.data?.data();
                                    final name =
                                        data?['displayName'] as String? ??
                                        'DilSe member';
                                    final bio = data?['bio'] as String? ?? '';

                                    if (!name.toLowerCase().contains(
                                      _search.text.trim().toLowerCase(),
                                    )) {
                                      return const SizedBox.shrink();
                                    }

                                    return StreamBuilder<DatabaseEvent>(
                                      stream: FirebaseDatabase.instanceFor(
                                        app: Firebase.app(),
                                        databaseURL: 'https://dilse-b7bd8-default-rtdb.asia-southeast1.firebasedatabase.app',
                                      ).ref('status/${row.key}').onValue,
                                      builder: (context, presenceSnapshot) {
                                        final presenceValue = presenceSnapshot
                                            .data
                                            ?.snapshot
                                            .value;
                                        final presence = presenceValue is Map
                                            ? presenceValue
                                            : null;
                                        final online =
                                            presence?['state'] == 'online';

                                        if (_filter == 1 && !online) {
                                          return const SizedBox.shrink();
                                        }

                                        return Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF261A43),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF7556D9)
                                                  .withValues(alpha: 0.55),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                Stack(
                                                  children: [
                                                    dilseAvatar(
                                                      data?['avatarId']
                                                          as String?,
                                                      radius: 27,
                                                    ),
                                                    if (online)
                                                      Positioned(
                                                        right: 0,
                                                        bottom: 0,
                                                        child: Container(
                                                          width: 13,
                                                          height: 13,
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFF39D98A,
                                                            ),
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color:
                                                                  const Color(
                                                                    0xFF261A43,
                                                                  ),
                                                              width: 2,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        bio.isEmpty
                                                            ? (online
                                                                  ? 'Online'
                                                                  : 'DilSe friend')
                                                            : bio,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: online
                                                              ? const Color(
                                                                  0xFF67E8A5,
                                                                )
                                                              : Colors.white60,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Unfriend',
                                                  icon: const Icon(
                                                    Icons.person_remove_alt_1,
                                                    color: Color(0xFFFF6B8A),
                                                  ),
                                                  onPressed: () async {
                                                    final ok = await showDialog<bool>(
                                                      context: context,
                                                      builder: (c) => AlertDialog(
                                                        title: const Text(
                                                          'Unfriend?',
                                                        ),
                                                        content: Text(
                                                          'Kya $name ko friends list se hatana hai?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  c,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'Cancel',
                                                            ),
                                                          ),
                                                          FilledButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  c,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              'Unfriend',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (ok != true ||
                                                        !context.mounted) {
                                                      return;
                                                    }
                                                    try {
                                                      final batch = db.batch();
                                                      for (final requestId in [
                                                        '${me.uid}_${row.key}',
                                                        '${row.key}_${me.uid}',
                                                      ]) {
                                                        final ref = db
                                                            .collection(
                                                              'friendRequests',
                                                            )
                                                            .doc(requestId);
                                                        final request =
                                                            await ref.get();
                                                        if (request.exists &&
                                                            request.data()?['status'] ==
                                                                'accepted') {
                                                          batch.update(ref, {
                                                            'status': 'ended',
                                                            'updatedAt':
                                                                FieldValue.serverTimestamp(),
                                                          });
                                                        }
                                                      }
                                                      await batch.commit();
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Friend list se hata diya.',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              'Unfriend fail: $e',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, int value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: const Color(0xFFFF3D9A),
      backgroundColor: const Color(0xFF33224F),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    );
  }

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 15),
      ),
    ),
  );

  Widget _requestsShortcut(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mark_email_unread_rounded,
              color: Color(0xFFFF5AA5),
              size: 56,
            ),
            const SizedBox(height: 12),
            const Text(
              'Friend Requests',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Requests dekhne ke liye Profile ke Friend Requests section mein jao.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
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
  Timer? _typingTimer;
  bool _typing = false;

  // DilSe chat typing indicator: status Firestore mein real-time sync hota hai.
  Future<void> _setTyping(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) return;
    try {
      final chat = FirebaseFirestore.instance.collection('chats').doc(_chatId);
      final snapshot = await chat.get();
      if (!snapshot.exists) return;
      final data = snapshot.data();
      final participants = data?['participants'];
      if (participants is! List || !participants.contains(user.uid)) return;
      await chat.update({'typing.${user.uid}': value});
    } catch (_) {}
  }

  void _onTypingChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    if (hasText && !_typing) {
      _typing = true;
      _setTyping(true);
    } else if (!hasText && _typing) {
      _typing = false;
      _setTyping(false);
    }
    _typingTimer?.cancel();
    if (hasText) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _typing = false;
        _setTyping(false);
      });
    }
  }

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
      final chat = FirebaseFirestore.instance.collection('chats').doc(_chatId);
      final chatSnapshot = await chat.get();
      if (!chatSnapshot.exists) return;
      final participants = chatSnapshot.data()?['participants'];
      if (participants is! List || !participants.contains(user.uid)) return;
      await chat.update({'unreadCounts.${user.uid}': 0});

      // Actual per-message read receipt: current user is added to readBy.
      final incoming = await chat
          .collection('messages')
          .where('senderId', isNotEqualTo: user.uid)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final message in incoming.docs) {
        final data = message.data();
        final readBy = List<String>.from(data['readBy'] ?? const []);
        if (!readBy.contains(user.uid)) {
          batch.set(message.reference, {
            'readBy': FieldValue.arrayUnion([user.uid]),
          }, SetOptions(merge: true));
        }
      }
      if (incoming.docs.isNotEmpty) await batch.commit();
    } catch (_) {
      // Rules ya unavailable chat par UI ko crash nahi karna.
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_typing) _setTyping(false);
    _input.dispose();
    super.dispose();
  }

  Future<void> _editMessage(
    DocumentReference<Map<String, dynamic>> ref,
    String oldText,
  ) async {
    final controller = TextEditingController(text: oldText);
    final replacement = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 4000,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (replacement == null ||
        replacement.isEmpty ||
        replacement == oldText.trim() ||
        !mounted) {
      return;
    }

    try {
      await ref.update({
        'text': replacement,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      debugPrint('EDIT MESSAGE ERROR: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text('Edit failed: $e'),
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('Yeh message permanently delete ho jayega.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _showMessageActions(
    DocumentReference<Map<String, dynamic>> ref,
    String text,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit message'),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete message'),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') await _editMessage(ref, text);
    if (action == 'delete') await _deleteMessage(ref);
  }

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _input.text.trim();
    if (user == null || !user.emailVerified || text.isEmpty || _sending) return;
    if (text.length > 4000) return;

    setState(() => _sending = true);
    _input.clear();
    _typingTimer?.cancel();
    _typing = false;
    _setTyping(false);
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
          'readBy': [user.uid],
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

        if (limitReached) {
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Free messages complete ❤️'),
              content: const Text(
                'Aapke 10 free messages poore ho gaye. '
                'Unlimited chat ke liye DilSe Premium Pass chunein.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Baad mein'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PremiumPlansPage(),
                      ),
                    );
                  },
                  child: const Text('Get Premium Pass 👑'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                userBlocked
                    ? 'Message nahi bhej sakte: aap mein se kisi ne doosre ko block kiya hai.'
                    : 'Message send nahi hua. Firestore rules aur connection check karein.',
              ),
            ),
          );
        }
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
          // Live typing state from the other participant's chat document.
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(_chatId)
                .snapshots(),
            builder: (context, chatSnap) {
              final data = chatSnap.data?.data();
              final typing = data?['typing'];
              final otherTyping =
                  typing is Map && typing[widget.otherUserId] == true;
              if (!otherTyping) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'typing…',
                    style: TextStyle(
                      color: Color(0xFFFF3D9A),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            },
          ),
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
                    final readBy = List<String>.from(d['readBy'] ?? const []);
                    final isRead = readBy.contains(widget.otherUserId);
                    final createdAt = d['createdAt'];
                    final time = createdAt is Timestamp
                        ? TimeOfDay.fromDateTime(createdAt.toDate())
                              .format(context)
                        : '';
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: mine
                            ? () => _showMessageActions(
                                docs[i].reference,
                                d['text'] as String? ?? '',
                              )
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.fromLTRB(14, 10, 12, 7),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * .80,
                          ),
                          decoration: BoxDecoration(
                            gradient: mine
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFE94E91),
                                      Color(0xFF7556D9),
                                    ],
                                  )
                                : null,
                            color: mine ? null : const Color(0xFF1B2035),
                            border: Border.all(
                              color: mine
                                  ? const Color(0x55FFB6DC)
                                  : const Color(0xFF303650),
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(mine ? 18 : 5),
                              bottomRight: Radius.circular(mine ? 5 : 18),
                            ),
                            boxShadow: mine
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFE94E91)
                                          .withValues(alpha: .15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  d['text'] as String? ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    height: 1.4,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      color: Color(0xCCFFFFFF),
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (mine) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      isRead ? Icons.done_all : Icons.done,
                                      size: 14,
                                      color: isRead
                                          ? const Color(0xFFB7F7FF)
                                          : const Color(0xCCFFFFFF),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
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
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFF15182B),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: const BorderSide(
                            color: Color(0xFF343852),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: const BorderSide(
                            color: Color(0xFF343852),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: const BorderSide(
                            color: Color(0xFFE94E91),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: _onTypingChanged,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFE94E91), Color(0xFF7556D9)],
                      ),
                    ),
                    child: IconButton(
                      onPressed: _sending ? null : _send,
                      color: Colors.white,
                      icon: const Icon(Icons.send_rounded),
                    ),
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

class FirestoreChatsPage extends StatefulWidget {
  const FirestoreChatsPage({super.key});

  @override
  State<FirestoreChatsPage> createState() => _FirestoreChatsPageState();
}

class _FirestoreChatsPageState extends State<FirestoreChatsPage> {
  bool _showHidden = false;

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
        final visibleChats = snap.data!.docs.where((doc) {
          final hiddenBy = doc.data()['hiddenBy'];
          final isHidden = hiddenBy is Map && hiddenBy[user.uid] == true;
          return _showHidden ? isHidden : !isHidden;
        }).toList();
        if (visibleChats.isEmpty) {
          return const Center(
            child: Text('Abhi chats nahi hain. Discover se message karo 💌'),
          );
        }
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showHidden = !_showHidden),
                icon: Icon(
                  _showHidden
                      ? Icons.chat_bubble_outline
                      : Icons.visibility_off_outlined,
                ),
                label: Text(_showHidden ? 'Back to Chats' : 'Hidden Chats'),
              ),
            ),
            ...visibleChats.map((doc) {
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (unread > 0)
                          Container(
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
                          ),
                        if (unread > 0) const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          tooltip: 'Chat options',
                          onSelected: (value) async {
                            if (value != 'hide' && value != 'unhide') return;
                            try {
                              await doc.reference.update({
                                'hiddenBy.${user.uid}': value == 'hide',
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      value == 'hide'
                                          ? 'Chat hidden'
                                          : 'Chat restored',
                                    ),
                                  ),
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Chat hide nahi ho payi.'),
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: _showHidden ? 'unhide' : 'hide',
                              child: Text(
                                _showHidden ? 'Unhide chat' : 'Hide chat',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
            }),
          ],
        );
      },
    );
  }
}
