import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // SUCCESS — POP THE LOGIN SCREEN TO TRIGGER REDIRECT
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('Login Auth Error: ${e.code} - ${e.message}');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Error (${e.code}): ${e.message}')));
    } catch (e) {
      if (kDebugMode) print('Login Error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AuthTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                ),
                child: const Text('Forgot Password?', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
            AuthButton(
              text: 'Log In',
              onPressed: _login,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}