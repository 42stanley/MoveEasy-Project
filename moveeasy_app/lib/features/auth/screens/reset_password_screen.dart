import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/auth_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String oobCode;

  const ResetPasswordScreen({super.key, required this.oobCode});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  Future<void> _confirmReset() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.confirmPasswordReset(code: widget.oobCode, newPassword: password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password reset successfully! Please login.'),
          backgroundColor: Colors.green,
        ));
        // Pop until we are back at login (or just pop this screen if it was pushed from forgot password)
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set New Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Create a new password for your account.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            AuthTextField(
              controller: _passwordController,
              label: 'New Password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              obscureText: true,
            ),
            const SizedBox(height: 32),
            AuthButton(
              text: 'Reset Password',
              onPressed: _confirmReset,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
