import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/services/ride_service.dart';
import '../../shared/utils/date_time_utils.dart';
import '../screens/active_trip_screen.dart';

class ScheduledRidesList extends StatelessWidget {
  const ScheduledRidesList({super.key});

  Future<void> _acceptScheduledRide(BuildContext context, String requestId, Map<String, dynamic> requestData) async {
    // Check if it's too early to accept
    final scheduledTime = requestData['scheduledTime'] as Timestamp?;
    if (scheduledTime != null) {
      final scheduledDate = scheduledTime.toDate();
      final now = DateTime.now();
      final difference = scheduledDate.difference(now);
      
      // If scheduled time is more than 15 minutes away, show warning
      if (difference.inMinutes > 15) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
                  const SizedBox(width: 12),
                  const Text('Early Acceptance'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This ride is scheduled for:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.orange[800]),
                        const SizedBox(width: 8),
                        Text(
                          DateTimeUtils.formatScheduledTime(scheduledTime),
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Time remaining: ${DateTimeUtils.getTimeRemaining(scheduledTime)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Are you sure you want to accept this ride now? You should be ready to pick up the passenger at the scheduled time.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ACCEPT ANYWAY'),
                ),
              ],
            );
          },
        );
        
        // If user cancelled, return early
        if (shouldContinue != true) return;
      }
    }
    
    try {
      // Get driver info from Firestore
      final driverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();
      
      final driverData = driverDoc.data() ?? {};
      
      // Determine status based on scheduled time
      final scheduledTime = requestData['scheduledTime'] as Timestamp?;
      String newStatus = 'accepted';
      
      if (scheduledTime != null) {
        final scheduledDate = scheduledTime.toDate();
        final now = DateTime.now();
        final difference = scheduledDate.difference(now);
        
        // If more than 15 minutes away, set to waiting_for_time
        if (difference.inMinutes > 15) {
          newStatus = 'waiting_for_time';
        }
      }
      
      // Update request status and add driver info
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(requestId)
          .update({
        'status': newStatus,
        'driverId': FirebaseAuth.instance.currentUser?.uid,
        'driverName': driverData['name'] ?? 'Driver',
        'driverPhone': driverData['phone'] ?? '',
        'vehicleModel': driverData['vehicleModel'] ?? 'Vehicle',
        'plate': driverData['plate'] ?? '',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      
      if (context.mounted) {
        if (newStatus == 'waiting_for_time') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride reserved! It will appear in Active Trips closer to the scheduled time.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scheduled ride accepted!'), backgroundColor: Colors.green),
          );
          
          // Navigate to active trip screen only if accepting close to scheduled time
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActiveTripScreen(
                requestId: requestId,
                pickup: requestData['pickup'] ?? '',
                dropoff: requestData['dropoff'] ?? '',
                cost: (requestData['cost'] ?? 0).toDouble(),
                passengerName: requestData['passengerName'] ?? 'Passenger',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Scheduled Rides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: RideService().getScheduledRides(),
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
                child: const Center(child: Text('No scheduled rides', style: TextStyle(color: Colors.grey))),
              );
            }

            // Filter to only show pending scheduled rides (not accepted/waiting)
            final scheduledRides = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['scheduledTime'] != null && data['status'] == 'pending';
            }).toList();

            if (scheduledRides.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(child: Text('No scheduled rides', style: TextStyle(color: Colors.grey))),
              );
            }

            return Column(
              children: scheduledRides.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final scheduledTime = data['scheduledTime'] as Timestamp?;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
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
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: Colors.orange[800]),
                                const SizedBox(width: 4),
                                Text(
                                  DateTimeUtils.formatScheduledTime(scheduledTime),
                                  style: TextStyle(
                                    color: Colors.orange[800],
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
                          ElevatedButton(
                            onPressed: () => _acceptScheduledRide(context, doc.id, data),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
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
      ],
    );
  }
}
