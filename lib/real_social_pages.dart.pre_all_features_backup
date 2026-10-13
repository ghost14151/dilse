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
