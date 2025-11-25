import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_earnings.dart';
import 'driver_ratings.dart';
import 'driver_profile.dart';
import '../widgets/online_toggle_button.dart';
import '../widgets/driver_stats_row.dart';
import '../widgets/incoming_requests_list.dart';
import '../widgets/active_trips_list.dart';
import '../widgets/today_trips_list.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _currentIndex = 0;

  // List of screens for navigation
  final List<Widget> _screens = [
    const DriverHome(),
    const DriverEarningsScreen(),
    const DriverRatingsScreen(),
    const DriverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // If index is 0, show the Home Dashboard
    // Otherwise, show the selected screen (Earnings, Ratings, Profile)
    if (_currentIndex != 0) {
      return Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Morning, Driver', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Vehicle: KDB 223Y', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Online/Offline Toggle
            const OnlineToggleButton(),
            const SizedBox(height: 24),

            // Stats Row
            const DriverStatsRow(),
            const SizedBox(height: 24),

            // Active Trips (NEW)
            const ActiveTripsList(),
            const SizedBox(height: 24),

            // Incoming Requests
            const IncomingRequestsList(),
            const SizedBox(height: 24),

            // Today's Trips
            TodayTripsList(
              onSeeAll: () => setState(() => _currentIndex = 1),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedItemColor: Colors.green[700],
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Earnings'),
        BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Ratings'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

// Placeholder for DriverHome (kept for compatibility)
class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
