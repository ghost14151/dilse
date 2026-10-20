import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const EmailLoginScreen();
        if (!user.emailVerified) return const EmailVerificationScreen();
        return const AgeNoticeGate();
      },
    );
  }
}

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool loading = false;
  String message =
      'Apne Gmail inbox mein verification link check karo. Spam folder bhi dekho.';

  Future<void> resendEmail() async {
    setState(() => loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.sendEmailVerification();
      if (mounted) {
        setState(
          () => message =
              'Verification link bhej diya. Gmail aur Spam folder check karo.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => message =
              e.message ?? 'Email nahi bhej paye. Thodi der baad try karo.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> checkVerification() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (!mounted) return;
      if (user != null && user.emailVerified) {
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
        setState(
          () => message = 'Email verify ho gaya! Home screen khul rahi hai.',
        );
      } else {
        setState(
          () => message = 'Abhi verification confirm nahi hua. Gmail ka link kholo, phir dobara check karo.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Check nahi ho paya. Internet check karke dobara try karo.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Gmail verify karo')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 72,
                  color: Color(0xFFE94E91),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Apna email verify karo',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Humne $email par verification link bheja hai.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : checkVerification,
                  child: const Text('Maine email verify kar liya'),
                ),
                OutlinedButton(
                  onPressed: loading ? null : resendEmail,
                  child: const Text('Verification email dobara bhejo'),
                ),
                TextButton(
                  onPressed: loading ? null : logout,
                  child: const Text('Logout'),
                ),
                if (loading) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool loading = false;
  bool hidePassword = true;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => errorMessage = 'Sahi email address likho.');
      return;
    }
    if (password.length < 6) {
      setState(() => errorMessage = 'Password kam se kam 6 characters ka ho.');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (mounted) {
          await FirebaseAuth.instance.currentUser?.sendEmailVerification();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'Is email ka account pehle se hai. Login karo.';
            break;
          case 'invalid-email':
            errorMessage = 'Email address sahi nahi hai.';
            break;
          case 'weak-password':
            errorMessage = 'Thoda strong password banao.';
            break;
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            errorMessage = 'Email ya password galat hai.';
            break;
          case 'network-request-failed':
            errorMessage = 'Internet connection check karo.';
            break;
          case 'too-many-requests':
            errorMessage = 'Bahut attempts hue. Thodi der baad try karo.';
            break;
          default:
            errorMessage = e.message ?? 'Login nahi ho paya. Dobara try karo.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => errorMessage = 'Kuch problem hui. Dobara try karo.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => errorMessage = 'Pehle email address likho.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email bhej diya.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => errorMessage = e.message ?? 'Reset email nahi bhej paye.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFE94E91);
    const purple = Color(0xFF7556D9);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.favorite, size: 68, color: pink),
                const SizedBox(height: 12),
                const Text(
                  'DilSe ❤️',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: purple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dosti jo dil tak jaaye',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 34),
                Text(
                  isLogin ? 'Welcome back!' : 'DilSe par account banao',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email / Gmail',
                    hintText: 'you@example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  autofillHints: [
                    isLogin
                        ? AutofillHints.password
                        : AutofillHints.newPassword,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => hidePassword = !hidePassword),
                      icon: Icon(
                        hidePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => loading ? null : submit(),
                ),
                if (isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading ? null : resetPassword,
                      child: const Text('Password bhool gaye?'),
                    ),
                  ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: pink,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isLogin ? 'Login' : 'Create Account'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => setState(() {
                          isLogin = !isLogin;
                          errorMessage = null;
                        }),
                  child: Text(
                    isLogin
                        ? 'Naye ho? Account banao'
                        : 'Pehle se account hai? Login karo',
                  ),
                ),
                const Text(
                  'Account banane par email verification bheji jayegi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class AgeNoticeGate extends StatefulWidget {
  const AgeNoticeGate({super.key});

  @override
  State<AgeNoticeGate> createState() => _AgeNoticeGateState();
}

class _AgeNoticeGateState extends State<AgeNoticeGate> {
  bool loading = true;
  bool accepted = false;
  bool confirmAdult = false;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadNotice();
  }

  Future<void> loadNotice() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;
      setState(() {
        accepted = doc.data()?['ageNoticeAccepted'] == true &&
            doc.data()?['ageOver18'] == true;
        loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Age notice load nahi hua. Internet check karo.';
        });
      }
    }
  }

  Future<void> confirmAndContinue() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !confirmAdult || saving) return;

    setState(() {
      saving = true;
      error = null;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'ageNoticeAccepted': true,
        'ageOver18': true,
        'ageNoticeAcceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) setState(() => accepted = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Save nahi hua. Internet ya Firestore rules check karo.';
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (accepted) return const MainScreen();

    return Scaffold(
      appBar: AppBar(title: const Text('DilSe age notice')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 68,
                  color: Color(0xFF925CFF),
                ),
                const SizedBox(height: 18),
                const Text(
                  '18+ Notice',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'DilSe ke social features 18 saal ya usse zyada umar ke '
                  'users ke liye hain. Aage badhne se pehle apni age confirm '
                  'karo. Yeh self-declaration hai, official age verification nahi.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                CheckboxListTile(
                  value: confirmAdult,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: saving
                      ? null
                      : (value) => setState(
                            () => confirmAdult = value ?? false,
                          ),
                  title: const Text('Meri umar 18 saal ya usse zyada hai.'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                FilledButton(
                  onPressed: saving || !confirmAdult
                      ? null
                      : confirmAndContinue,
                  child: Text(saving ? 'Saving...' : 'Confirm and continue'),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () => FirebaseAuth.instance.signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
