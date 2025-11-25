import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'stat_card.dart';

class DriverStatsRow extends StatelessWidget {
  const DriverStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ride_requests')
          .where('driverId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        double totalEarnings = 0.0;
        int totalTrips = 0;
        
        if (snapshot.hasData) {
          totalTrips = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalEarnings += (data['cost'] ?? 0).toDouble();
          }
        }
        
        return Row(
          children: [
            StatCard(
              label: 'Earnings',
              value: 'KES ${totalEarnings.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet,
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            StatCard(
              label: 'Trips',
              value: '$totalTrips',
              icon: Icons.directions_bus,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            const StatCard(
              label: 'Hours',
              value: '8.5',
              icon: Icons.access_time,
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }
}
