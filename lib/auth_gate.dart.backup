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
        if (snapshot.hasData) {
          return const MainScreen();
        }
        return const PhoneLoginScreen();
      },
    );
  }
}

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final phoneController = TextEditingController(text: '+91');
  final otpController = TextEditingController();

  String? verificationId;
  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();

    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      setState(() => errorMessage =
          'Country code ke saath number likho, jaise +919876543210');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
          } catch (e) {
            if (mounted) {
              setState(() => errorMessage = 'Login nahi hua. Dobara try karo.');
            }
          }
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() {
              loading = false;
              errorMessage = e.message ?? 'OTP bhejne mein problem hui.';
            });
          }
        },
        codeSent: (id, token) {
          if (mounted) {
            setState(() {
              verificationId = id;
              loading = false;
              errorMessage = null;
            });
          }
        },
        codeAutoRetrievalTimeout: (id) {
          verificationId = id;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'OTP request fail hui. Internet aur Firebase settings check karo.';
        });
      }
    }
  }

  Future<void> verifyOtp() async {
    final code = otpController.text.trim();
    final id = verificationId;

    if (id == null || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => errorMessage = '6 digit OTP enter karo.');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = e.message ?? 'OTP galat ya expire ho gaya.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'Verification fail hui. Dobara try karo.';
        });
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
                  verificationId == null ? 'Phone se login karo' : 'OTP verify karo',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (verificationId == null)
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      hintText: '+919876543210',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                  )
                else
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '6 digit OTP',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: pink,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: loading
                      ? null
                      : verificationId == null
                          ? sendOtp
                          : verifyOtp,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          verificationId == null ? 'Send OTP' : 'Verify & Login',
                        ),
                ),
                if (verificationId != null)
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                              verificationId = null;
                              otpController.clear();
                              errorMessage = null;
                            }),
                    child: const Text('Number badlo'),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Login karke tum phone verification ke liye sahmati dete ho.',
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
