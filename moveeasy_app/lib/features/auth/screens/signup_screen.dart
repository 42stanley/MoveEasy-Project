import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _role = 'passenger';
  File? _profileImage;
  bool _loading = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _plateController = TextEditingController();

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == 'driver' && _plateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver needs plate number')));
      return;
    }

    setState(() => _loading = true);
    try {
      // Create auth user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Upload photo if exists
      String? photoURL;
      if (_profileImage != null) {
        final ref = FirebaseStorage.instance.ref('profiles/${cred.user!.uid}.jpg');
        await ref.putFile(_profileImage!);
        photoURL = await ref.getDownloadURL();
      }

      // Save user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _role,
        'plate': _role == 'driver' ? _plateController.text.trim().toUpperCase() : null,
        'photoURL': photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // SUCCESS → AuthWrapper will auto redirect; pop auth route to reveal it
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Redirecting...'), backgroundColor: Colors.green),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('FirebaseAuthException: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth Error (${e.code}): ${e.message ?? "Signup failed"}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (kDebugMode) print('General Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null ? const Icon(Icons.add_a_photo, size: 40) : null,
                ),
              ),
              const SizedBox(height: 20),
              AuthTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _phoneController,
                label: 'Phone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.contains('@') ? null : 'Invalid email',
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                validator: (v) => v!.length >= 6 ? null : 'Min 6 chars',
              ),
              if (_role == 'driver') ...[
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _plateController,
                  label: 'Plate Number (e.g. KDB 223Y)',
                ),
              ],
              const SizedBox(height: 20),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'passenger', label: Text('Passenger'), icon: Icon(Icons.person)),
                  ButtonSegment(value: 'driver', label: Text('Driver'), icon: Icon(Icons.local_taxi)),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 30),
              AuthButton(
                text: 'CREATE ACCOUNT',
                onPressed: _signup,
                isLoading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}