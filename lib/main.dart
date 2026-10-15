import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

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

const String dilseDatabaseUrl =
    'https://dilse-b7bd8-default-rtdb.asia-southeast1.firebasedatabase.app';

final FirebaseDatabase dilseRealtimeDatabase = FirebaseDatabase.instanceFor(
  app: Firebase.app(),
  databaseURL: dilseDatabaseUrl,
);

class DilSeApp extends StatelessWidget {
  const DilSeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DilSe',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: pink,
          secondary: purple,
          surface: surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          error: Color(0xFFFF6B75),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIconColor: purple,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF343852)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: pink, width: 1.5),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: Color(0xFF45233F),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: Colors.white, fontSize: 12),
          ),
          iconTheme: WidgetStatePropertyAll(
            IconThemeData(color: Colors.white70),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: pink,
            foregroundColor: Colors.white,
          ),
        ),
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
  StreamSubscription<DatabaseEvent>? _presenceConnection;
  DatabaseReference? _myPresenceRef;

  @override
  void initState() {
    super.initState();
    _startPresence();
  }

  void _startPresence() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) return;

    final presenceRef = dilseRealtimeDatabase.ref('status/${user.uid}');
    _myPresenceRef = presenceRef;

    _presenceConnection = dilseRealtimeDatabase
        .ref('.info/connected')
        .onValue
        .listen((event) async {
          if (event.snapshot.value != true) return;

          try {
            await presenceRef.onDisconnect().set({
              'state': 'offline',
              'last_changed': ServerValue.timestamp,
            });
            await presenceRef.set({
              'state': 'online',
              'last_changed': ServerValue.timestamp,
            });
          } catch (e) {
            debugPrint('DilSe presence update failed: $e');
          }
        });
  }

  @override
  void dispose() {
    _presenceConnection?.cancel();
    final ref = _myPresenceRef;
    if (ref != null) {
      ref
          .set({'state': 'offline', 'last_changed': ServerValue.timestamp})
          .catchError((Object e) {
            debugPrint('DilSe offline update failed: $e');
          });
    }
    super.dispose();
  }

  late final List<Widget> pages = [
    HomePage(onOpenTab: (index) => setState(() => tab = index)),
    const FirestoreDiscoverPage(),
    const ChatsPage(),
    const RoomsPage(),
    const FirestoreProfilePage(),
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
        backgroundColor: surface,
        indicatorColor: const Color(0xFF45233F),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? pink
                : Colors.white70,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: 11,
          ),
        ),
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

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  int _refreshKey = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openTab(int index) => widget.onOpenTab(index);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return RefreshIndicator(
      color: pink,
      backgroundColor: surface,
      onRefresh: () async {
        setState(() => _refreshKey++);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [pink, purple]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
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
              IconButton(
                tooltip: 'Refresh members',
                onPressed: () => setState(() => _refreshKey++),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [purple, pink],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: pink.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome${currentUser?.displayName != null && currentUser!.displayName!.trim().isNotEmpty ? ', ${currentUser.displayName!.trim()}' : ' to DilSe'}! 💕',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Naye logon se milo, dosti badhao aur apni kahani shuru karo.',
                  style: TextStyle(color: Colors.white, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Nayi yaari, nayi kahani',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const SectionTitle('Apne naye dost khojo', 'Discover'),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _search = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Naam ya bio search karo...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                      icon: const Icon(Icons.close),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('DilSe Members', 'Real profiles'),
          const SizedBox(height: 13),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            key: ValueKey(_refreshKey),
            stream: FirebaseFirestore.instance
                .collection('users')
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Members load nahi ho paaye. Internet ya Firebase rules check karo.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(25),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final members = snapshot.data!.docs.where((doc) {
                if (doc.id == currentUser?.uid) return false;
                final data = doc.data();
                final name = (data['displayName'] ?? '')
                    .toString()
                    .toLowerCase();
                final bio = (data['bio'] ?? '').toString().toLowerCase();
                return _search.isEmpty ||
                    name.contains(_search) ||
                    bio.contains(_search);
              }).toList();

              if (members.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline, size: 38, color: pink),
                      const SizedBox(height: 8),
                      Text(
                        _search.isEmpty
                            ? 'Abhi doosre members nahi hain.'
                            : 'Is search se koi member nahi mila.',
                        textAlign: TextAlign.center,
                      ),
                      if (_search.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          child: const Text('Search clear karo'),
                        ),
                    ],
                  ),
                );
              }

              return SizedBox(
                height: 145,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final doc = members[index];
                    final data = doc.data();
                    final name =
                        (data['displayName'] as String?)?.trim().isNotEmpty ==
                            true
                        ? (data['displayName'] as String).trim()
                        : 'DilSe User';
                    final bio = (data['bio'] ?? '').toString();
                    final photoValue = (data['photoUrl'] ?? '')
                        .toString()
                        .trim();
                    final photoUrl = photoValue.isEmpty ? null : photoValue;
                    final avatarValue = (data['avatarId'] ?? '').toString();
                    final avatarId = avatarValue.isEmpty ? null : avatarValue;

                    return SizedBox(
                      width: 100,
                      child: Material(
                        color: surface,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
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
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(0xFFFFD8E6),
                                  backgroundImage:
                                      photoUrl != null && photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : avatarId is String &&
                                            avatarId.isNotEmpty
                                      ? AssetImage(
                                          'assets/avatars/avatar_${dilseAvatarIndex(avatarId).toString().padLeft(2, '0')}.jpg',
                                        )
                                      : null,
                                  child:
                                      (photoUrl == null || photoUrl.isEmpty) &&
                                          !(avatarId is String &&
                                              avatarId.isNotEmpty)
                                      ? Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: pink,
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 5),
                                StreamBuilder<DatabaseEvent>(
                                  stream: dilseRealtimeDatabase
                                      .ref('status/${doc.id}')
                                      .onValue,
                                  builder: (context, statusSnapshot) {
                                    final value =
                                        statusSnapshot.data?.snapshot.value;
                                    final statusData = value is Map
                                        ? value
                                        : null;
                                    final isOnline =
                                        statusData?['state'] == 'online';
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: isOnline
                                                ? Colors.greenAccent
                                                : Colors.white38,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isOnline ? 'Online' : 'Offline',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isOnline
                                                ? Colors.greenAccent
                                                : Colors.white60,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'View profile',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 25),
          const SectionTitle('DilSe par kya kar sakte ho?', 'Explore'),
          const SizedBox(height: 12),
          FeatureCard(
            icon: Icons.people_alt_rounded,
            title: 'Naye dost banao',
            subtitle: 'Members ki profiles dekho aur apne jaise log khojo.',
            color: purple,
            onTap: () => _openTab(1),
          ),
          FeatureCard(
            icon: Icons.chat_rounded,
            title: 'Private chat',
            subtitle: 'Apni conversations kholo aur message bhejo.',
            color: pink,
            onTap: () => _openTab(2),
          ),
          FeatureCard(
            icon: Icons.mic_rounded,
            title: 'Voice Rooms',
            subtitle: 'Voice room section kholo.',
            color: Color(0xFF269B8D),
            onTap: () => _openTab(3),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'DilSe — Dosti Jo Dil Tak Jaaye ❤️',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
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
  final VoidCallback? onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(17),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [surface, color.withValues(alpha: 0.12)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.30)),
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
