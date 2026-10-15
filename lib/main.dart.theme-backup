import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'auth_gate.dart';
import 'real_social_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DilSeApp());
}

const pink = Color(0xFFFF3D9A);
const purple = Color(0xFF925CFF);
const bg = Color(0xFF090B18);
const surface = Color(0xFF15182B);

class DilSeApp extends StatelessWidget {
  const DilSeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DilSe',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: pink),
        appBarTheme: const AppBarTheme(backgroundColor: bg),
      ),
      home: const AuthGate(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int tab = 0;

  final pages = const [
    HomePage(),
    FirestoreDiscoverPage(),
    ChatsPage(),
    RoomsPage(),
    FirestoreProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: tab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFE0EF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.graphic_eq),
            selectedIcon: Icon(Icons.mic),
            label: 'Voice',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [pink, purple]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 27),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DilSe',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: purple,
                    ),
                  ),
                  Text(
                    'Dosti Jo Dil Tak Jaaye ❤️',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [purple, pink]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Har dosti ki shuruaat yahin se! 💕',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Naye logon se milo, baatein karo aur apni yaari banao.',
                style: TextStyle(color: Colors.white, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const SectionTitle('DilSe Members', 'Real profiles'),
        const SizedBox(height: 15),
        SizedBox(
          height: 125,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .limit(30)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Profiles load nahi hui.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = snapshot.data!.docs
                  .where((doc) => doc.id != currentUser?.uid)
                  .toList();

              if (members.isEmpty) {
                return const Center(
                  child: Text('Abhi doosre members nahi hain.'),
                );
              }

              return ListView(
                scrollDirection: Axis.horizontal,
                children: members.map((doc) {
                  final data = doc.data();
                  final name = data['displayName'] as String? ?? 'DilSe User';
                  final bio = data['bio'] as String? ?? '';
                  return SizedBox(
                    width: 82,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PublicUserProfilePage(
                            userId: doc.id,
                            name: name,
                            bio: bio,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 29,
                            backgroundColor: const Color(0xFFFFD8E6),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: pink,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'View profile',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('DilSe par kya naya hai?', 'Explore'),
        const SizedBox(height: 12),
        const FeatureCard(
          icon: Icons.people_alt,
          title: 'Naye dost banao',
          subtitle: 'Real members ki profiles dekho',
          color: purple,
        ),
        const FeatureCard(
          icon: Icons.chat_rounded,
          title: 'Dil khol kar baat karo',
          subtitle: 'Private chat ka experience',
          color: pink,
        ),
        const FeatureCard(
          icon: Icons.mic,
          title: 'Live Voice Rooms',
          subtitle: 'Voice rooms ka feature abhi taiyar karna baaki hai',
          color: Color(0xFF269B8D),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Nayi yaari, nayi kahani ❤️',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeading(
          title: 'Find Friends',
          subtitle: 'Nayi yaari ki shuruaat karo ✨',
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: InputDecoration(
            hintText: 'Naam ya interest search karo',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Suggested for you',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const DiscoverCard(
          name: 'Aanya Sharma',
          detail: 'Music • Movies • Jaipur',
          emoji: '👩🏻',
          color: Color(0xFFFFD8E6),
        ),
        const DiscoverCard(
          name: 'Rohan Verma',
          detail: 'Gaming • Cricket • Delhi',
          emoji: '👨🏻',
          color: Color(0xFFD8E3FF),
        ),
        const DiscoverCard(
          name: 'Meera Singh',
          detail: 'Travel • Art • Lucknow',
          emoji: '👩🏽',
          color: Color(0xFFFFE8BD),
        ),
        const DiscoverCard(
          name: 'Arjun Patel',
          detail: 'Music • Fitness • Mumbai',
          emoji: '🧑🏻',
          color: Color(0xFFD4F5DE),
        ),
        const SizedBox(height: 10),
        const Text(
          'Demo profiles — real users ke liye account system connect karna hoga.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});
  @override
  Widget build(BuildContext context) => const FirestoreChatsPage();
}

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeading(
          title: 'Live Voice Rooms 🎙️',
          subtitle: 'Suno, bolo aur naye dost banao',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7556D9), Color(0xFFE94E91)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            children: [
              Icon(Icons.graphic_eq, color: Colors.white, size: 55),
              SizedBox(height: 10),
              Text(
                'Your voice, your community',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Apni pasand ke topics par baat karo',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const RoomCard(
          title: '🎵 Music & Masti',
          subtitle: 'Songs aur fun conversations',
          people: '12 people',
          color: Color(0xFFFFE1EF),
        ),
        const RoomCard(
          title: '🤝 New Friends Club',
          subtitle: 'Naye logon se milo',
          people: '8 people',
          color: Color(0xFFE6DEFF),
        ),
        const RoomCard(
          title: '🌙 Late Night Talks',
          subtitle: 'Relaxed group chat',
          people: '5 people',
          color: Color(0xFFDCEBFF),
        ),
        const SizedBox(height: 12),
        const Text(
          'Voice rooms ka live audio feature abhi demo hai; audio service aur moderation connect karni hogi.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeading(
          title: 'My Profile',
          subtitle: 'Apni DilSe identity banao',
        ),
        const SizedBox(height: 24),
        const Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Color(0xFFFFD8E6),
            child: Icon(Icons.person, size: 55, color: pink),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Your Name',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
        ),
        const Center(
          child: Text(
            'Apni chhoti si bio yahan likho ✨',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 26),
        const ProfileOption(icon: Icons.edit_outlined, title: 'Edit Profile'),
        const ProfileOption(icon: Icons.favorite_border, title: 'My Interests'),
        const ProfileOption(
          icon: Icons.lock_outline,
          title: 'Privacy & Safety',
        ),
        const ProfileOption(icon: Icons.block_outlined, title: 'Blocked Users'),
        const ProfileOption(icon: Icons.help_outline, title: 'Help & Support'),
        const SizedBox(height: 12),
        const Text(
          'Profile demo hai. Login aur account data baad mein connect hoga.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class PageHeading extends StatelessWidget {
  final String title, subtitle;
  const PageHeading({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.bold,
          color: purple,
        ),
      ),
      const SizedBox(height: 5),
      Text(subtitle, style: const TextStyle(color: Colors.white70)),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  final String title, action;
  const SectionTitle(this.title, this.action, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      Text(
        action,
        style: const TextStyle(color: pink, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class FriendAvatar extends StatelessWidget {
  final String name, emoji;
  final Color color;
  final bool online;
  const FriendAvatar({
    super.key,
    required this.name,
    required this.color,
    required this.emoji,
    required this.online,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 75,
    child: Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 29,
              backgroundColor: color,
              child: Text(emoji, style: const TextStyle(fontSize: 29)),
            ),
            if (online)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: bg, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 27),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.white54),
      ],
    ),
  );
}

class DiscoverCard extends StatelessWidget {
  final String name, detail, emoji;
  final Color color;
  const DiscoverCard({
    super.key,
    required this.name,
    required this.detail,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color,
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: pink,
            foregroundColor: Colors.white,
          ),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend requests feature abhi connect nahi hai.'),
            ),
          ),
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

class ChatTile extends StatelessWidget {
  final String name, message, emoji;
  final Color color;
  const ChatTile({
    super.key,
    required this.name,
    required this.message,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
    leading: CircleAvatar(
      radius: 27,
      backgroundColor: color,
      child: Text(emoji, style: const TextStyle(fontSize: 27)),
    ),
    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text(message),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Private chat abhi connect nahi hai.')),
    ),
  );
}

class RoomCard extends StatelessWidget {
  final String title, subtitle, people;
  final Color color;
  const RoomCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.people,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 7),
              Text(
                '● $people',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: purple,
            foregroundColor: Colors.white,
          ),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Live audio abhi setup hona baaki hai.'),
            ),
          ),
          child: const Text('Join'),
        ),
      ],
    ),
  );
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  const ProfileOption({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: purple),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title feature baad mein connect hoga.')),
    ),
  );
}
