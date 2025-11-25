import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ride_request_screen.dart';
import 'leave_review_screen.dart';
import 'my_schedules_screen.dart';
import '../widgets/dashboard_widgets.dart';

class PassengerDashboard extends StatelessWidget {
  const PassengerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MoveEasy',
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            Text(
              'Kinatwa Sacco Transit',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        /* actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ], */
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search routes, destinations...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Passenger"),
              accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? "No Email"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.teal),
              ),
              decoration: const BoxDecoration(color: Colors.teal),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                // AuthWrapper will handle the redirect
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                QuickAction(
                  icon: Icons.location_on_outlined,
                  label: 'Plan Trip',
                  subLabel: 'Find routes',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RideRequestScreen())),
                ),
                const SizedBox(width: 12),
                QuickAction(
                  icon: Icons.calendar_today_outlined,
                  label: 'Schedules',
                  subLabel: 'View times',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MySchedulesScreen())),
                ),
                const SizedBox(width: 12),
                QuickAction(
                  icon: Icons.star_outline,
                  label: 'Rate',
                  subLabel: 'Review trip',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveReviewScreen(driverId: 'test_driver_id'))),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live Queue Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Updated 2 min ago', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            const QueueCard(title: 'Greenpark Station', subtitle: 'Stage', count: 8, status: 'Light', color: Colors.green),
            const QueueCard(title: 'Shamba Hub', subtitle: 'Stage', count: 15, status: 'Moderate', color: Colors.orange),
            const QueueCard(title: 'Market Square', subtitle: 'Stage', count: 28, status: 'Heavy', color: Colors.red),
            const SizedBox(height: 24),
            const Text('Available Routes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const RouteCard(code: '14A', name: 'Greenpark Central', time: 'Next: 5 min', queueStatus: 'Light Queue', color: Colors.teal),
            const RouteCard(code: '7B', name: 'Shamba Market', time: 'Next: 12 min', queueStatus: 'Moderate Queue', color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
