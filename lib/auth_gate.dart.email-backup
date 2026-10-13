import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) return const MainScreen();
        return const EmailLoginScreen();
      },
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
        setState(() => errorMessage = e.message ?? 'Reset email nahi bhej paye.');
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
