import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'driver_earnings.dart';
import 'driver_ratings.dart';
import 'driver_profile.dart';
import '../widgets/stat_card.dart';
import '../widgets/trip_item.dart';
import '../services/driver_service.dart';
import '../../shared/services/ride_service.dart';
import 'active_trip_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _currentIndex = 0;
  bool _isOnline = false;
  StreamSubscription<Position>? _positionStream;
  final _driverService = DriverService();
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<dynamic>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'driver1';
    _statsFuture = _driverService.getDriverStats(uid);
    _tripsFuture = _driverService.getDriverTrips(uid);
  }

  // List of screens for navigation
  final List<Widget> _screens = [
    const DriverHome(),
    const DriverEarningsScreen(),
    const DriverRatingsScreen(),
    const DriverProfileScreen(),
  ];

  Future<void> _toggleOnline() async {
    if (_isOnline) {
      _positionStream?.cancel();
      await FirebaseFirestore.instance
          .collection('drivers_online')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .delete();
      setState(() => _isOnline = false);
      return;
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    // Request permission with full handling
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission required')),
      );
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied forever. Enable in app settings.')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Mark online in Firestore
      await FirebaseFirestore.instance.collection('drivers_online').doc(uid).set({
        'online': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'plate': 'KDB 223Y',
        'location': const GeoPoint(0, 0),
        'bearing': 0.0,
      }, SetOptions(merge: true));

      // Start live location stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((position) {
        FirebaseFirestore.instance.collection('drivers_online').doc(uid).update({
          'location': GeoPoint(position.latitude, position.longitude),
          'bearing': position.heading,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      });

      // Success — update UI
      setState(() => _isOnline = true);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are now ONLINE!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error going online: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If index is 0, show the Home Dashboard with online toggle logic
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
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green[700] : Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: _isOnline ? Colors.greenAccent : Colors.redAccent),
                            const SizedBox(width: 6),
                            Text(_isOnline ? 'Active' : 'Inactive', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isOnline)
                    const Text('Searching for passengers...', style: TextStyle(color: Colors.white70, fontSize: 14))
                  else
                    const Text('Go online to start receiving trips.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleOnline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _isOnline ? Colors.red : Colors.green[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isOnline ? 'GO OFFLINE' : 'GO ONLINE',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Row
            FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                final data = snapshot.data ?? {"earnings": "...", "trips": 0, "hours": 0.0};
                return Row(
                  children: [
                    StatCard(label: 'Earnings', value: '${data['earnings']}', icon: Icons.account_balance_wallet, color: Colors.blue),
                    const SizedBox(width: 12),
                    StatCard(label: 'Trips', value: '${data['trips']}', icon: Icons.directions_bus, color: Colors.orange),
                    const SizedBox(width: 12),
                    StatCard(label: 'Hours', value: '${data['hours']}', icon: Icons.access_time, color: Colors.purple),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 24),

            // Incoming Requests Section
            const Text('Incoming Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: RideService().getIncomingRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Center(child: Text('No active requests', style: TextStyle(color: Colors.grey))),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isScheduled = data['scheduledTime'] != null;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(data['passengerName'] ?? 'Passenger', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isScheduled ? Colors.orange[50] : Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isScheduled ? 'Scheduled' : 'Now',
                                  style: TextStyle(
                                    color: isScheduled ? Colors.orange[800] : Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.my_location, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text(data['pickup'] ?? '', style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(data['dropoff'] ?? '', style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('KES ${data['cost'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    // Get driver info from Firestore
                                    final driverDoc = await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth.instance.currentUser?.uid)
                                        .get();
                                    
                                    final driverData = driverDoc.data() ?? {};
                                    
                                    // Update request status to accepted and add driver info
                                    await FirebaseFirestore.instance
                                        .collection('ride_requests')
                                        .doc(doc.id)
                                        .update({
                                      'status': 'accepted',
                                      'driverId': FirebaseAuth.instance.currentUser?.uid,
                                      'driverName': driverData['name'] ?? 'Driver',
                                      'driverPhone': driverData['phone'] ?? '',
                                      'vehicleModel': driverData['vehicleModel'] ?? 'Vehicle',
                                      'plate': driverData['plate'] ?? '',
                                      'acceptedAt': FieldValue.serverTimestamp(),
                                    });
                                    
                                    if (context.mounted) {
                                      // Navigate to active trip screen
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ActiveTripScreen(
                                            requestId: doc.id,
                                            pickup: data['pickup'] ?? '',
                                            dropoff: data['dropoff'] ?? '',
                                            cost: (data['cost'] ?? 0).toDouble(),
                                            passengerName: data['passengerName'] ?? 'Passenger',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('ACCEPT'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Today\'s Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 1), // Switch to Earnings tab
                  child: const Text('See All', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _tripsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final trips = snapshot.data ?? [];
                if (trips.isEmpty) return const Text('No trips yet.');

                return Column(
                  children: trips.map((trip) => TripItem(
                    route: trip['route'],
                    time: trip['time'],
                    price: trip['price'],
                  )).toList(),
                );
              },
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

// --- Helper Widgets (Extracted for cleaner code) ---

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Home Content Loaded via Dashboard"));
  }
}
