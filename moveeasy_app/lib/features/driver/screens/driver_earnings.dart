import 'package:flutter/material.dart';
import '../widgets/trip_item.dart';
import '../services/driver_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Earnings', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Earnings Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green[700]!, Colors.green[500]!]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data ?? {"earnings": "...", "trips": 0, "hours": 0.0};
                  return Column(
                    children: [
                      const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('${data['earnings']}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _EarningStat(label: 'Today', value: 'KES 4,500'), // Keep mock for now or add to API
                          _EarningStat(label: 'This Week', value: 'KES 28,000'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Chart Placeholder
            const Text('Weekly Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Text('Chart Placeholder', style: TextStyle(color: Colors.grey[400])),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            const Text('Recent Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    );
  }
}

class _EarningStat extends StatelessWidget {
  final String label;
  final String value;

  const _EarningStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
