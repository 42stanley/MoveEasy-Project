import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/auth_widgets.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  // Helper to get base URL based on platform
  String get baseUrl => 'https://moveeasy-project-backend-production.up.railway.app';
  // String get baseUrl => Platform.isAndroid
  //     ? 'http://10.0.2.2:5001'
  //     : 'http://192.168.1.102:5001';

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email address')));
      return;
    }

    setState(() => _loading = true);
    try {
      // CALL BACKEND TO GET LINK
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/get-reset-link'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final link = data['link'] as String;
        
        // Extract oobCode from link
        final uri = Uri.parse(link);
        final oobCode = uri.queryParameters['oobCode'];

        if (oobCode != null) {
          if (mounted) {
             Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ResetPasswordScreen(oobCode: oobCode)),
            );
          }
        } else {
          throw Exception('Invalid reset link format');
        }

      } else {
        final error = json.decode(response.body)['error'] ?? 'Unknown error';
        throw Exception(error);
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
      appBar: AppBar(
        title: const Text('Reset Password'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email address to reset your password instantly.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            AuthTextField(
              controller: _emailController,
              label: 'Email Address',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            AuthButton(
              text: 'Reset Password',
              onPressed: _resetPassword,
              isLoading: _loading,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
