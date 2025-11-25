import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/profile_widgets.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;

  void _showEditProfileDialog(Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final phoneController = TextEditingController(text: data['phone'] ?? '');
    final plateController = TextEditingController(text: data['plate'] ?? '');
    final routeController = TextEditingController(text: data['route'] ?? '');
    final modelController = TextEditingController(text: data['vehicleModel'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
              TextField(controller: plateController, decoration: const InputDecoration(labelText: 'License Plate')),
              TextField(controller: modelController, decoration: const InputDecoration(labelText: 'Vehicle Model')),
              TextField(controller: routeController, decoration: const InputDecoration(labelText: 'Route (e.g. CBD - Westlands)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'plate': plateController.text.trim(),
                  'vehicleModel': modelController.text.trim(),
                  'route': routeController.text.trim(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Center(child: Text("Not Logged In"));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
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
                        data['name'] ?? _user!.email ?? 'Driver',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(data['email'] ?? '', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vehicle Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      ProfileRow(label: 'Vehicle Model', value: data['vehicleModel'] ?? 'Not Set'),
                      const SizedBox(height: 12),
                      ProfileRow(label: 'License Plate', value: data['plate'] ?? 'Not Set'),
                      const SizedBox(height: 12),
                      ProfileRow(label: 'Route', value: data['route'] ?? 'Not Set'),
                      const SizedBox(height: 12),
                      ProfileRow(label: 'Phone', value: data['phone'] ?? 'Not Set'),
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
                      ProfileAction(
                        icon: Icons.edit,
                        label: 'Edit Profile',
                        onTap: () => _showEditProfileDialog(data),
                      ),
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
          );
        },
      ),
    );
  }
}
