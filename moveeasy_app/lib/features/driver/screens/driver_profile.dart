import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/profile_widgets.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? 'Driver Name',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Verified Driver', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Vehicle Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vehicle Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Divider(height: 24),
                  ProfileRow(label: 'Vehicle Model', value: 'Toyota HiAce'),
                  SizedBox(height: 12),
                  ProfileRow(label: 'License Plate', value: 'KDB 223Y'),
                  SizedBox(height: 12),
                  ProfileRow(label: 'Route', value: 'Kawangware - CBD'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings / Actions
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ProfileAction(icon: Icons.edit, label: 'Edit Profile', onTap: () {}),
                  const Divider(height: 1),
                  ProfileAction(icon: Icons.settings, label: 'Settings', onTap: () {}),
                  const Divider(height: 1),
                  ProfileAction(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
                  const Divider(height: 1),
                  ProfileAction(
                    icon: Icons.logout,
                    label: 'Log Out',
                    isDestructive: true,
                    onTap: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
