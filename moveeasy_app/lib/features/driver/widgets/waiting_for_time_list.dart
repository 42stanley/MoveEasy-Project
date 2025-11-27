import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/utils/date_time_utils.dart';
import '../../shared/services/ride_service.dart';
import 'dart:async';

class WaitingForTimeList extends StatefulWidget {
  const WaitingForTimeList({super.key});

  @override
  State<WaitingForTimeList> createState() => _WaitingForTimeListState();
}

class _WaitingForTimeListState extends State<WaitingForTimeList> {
  Timer? _promotionTimer;
  final _rideService = RideService();

  @override
  void initState() {
    super.initState();
    _startAutoPromotionCheck();
  }

  @override
  void dispose() {
    _promotionTimer?.cancel();
    super.dispose();
  }

  void _startAutoPromotionCheck() {
    // Check every minute for rides that should be promoted
    _promotionTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkAndPromoteRides();
    });
  }

  Future<void> _checkAndPromoteRides() async {
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'waiting_for_time')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final scheduledTime = data['scheduledTime'] as Timestamp?;

        // If scheduled time is within 15 minutes, promote to accepted
        if (DateTimeUtils.isWithinThreshold(scheduledTime, 15)) {
          await _rideService.promoteWaitingRide(doc.id);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ride to ${data['dropoff']} is now active!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for promotion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    
    if (driverId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Waiting for Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Reserved',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('ride_requests')
              .where('driverId', isEqualTo: driverId)
              .where('status', isEqualTo: 'waiting_for_time')
              .snapshots(),
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
                child: const Center(child: Text('No reserved rides', style: TextStyle(color: Colors.grey))),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final scheduledTime = data['scheduledTime'] as Timestamp?;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.blue[800]),
                                const SizedBox(width: 4),
                                Text(
                                  DateTimeUtils.formatScheduledTime(scheduledTime),
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 6),
                                Text(
                                  DateTimeUtils.getTimeRemaining(scheduledTime),
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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
      ],
    );
  }
}
