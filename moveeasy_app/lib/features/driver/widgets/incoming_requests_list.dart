import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/services/ride_service.dart';
import '../screens/active_trip_screen.dart';

class IncomingRequestsList extends StatelessWidget {
  const IncomingRequestsList({super.key});

  Future<void> _acceptRequest(BuildContext context, String requestId, Map<String, dynamic> requestData) async {
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
          .doc(requestId)
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
              requestId: requestId,
              pickup: requestData['pickup'] ?? '',
              dropoff: requestData['dropoff'] ?? '',
              cost: (requestData['cost'] ?? 0).toDouble(),
              passengerName: requestData['passengerName'] ?? 'Passenger',
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

            // Filter out scheduled rides (only show immediate requests)
            final immediateRequests = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['scheduledTime'] == null;
            }).toList();

            if (immediateRequests.isEmpty) {
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
              children: immediateRequests.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Now',
                              style: TextStyle(
                                color: Colors.green[800],
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
                            onPressed: () => _acceptRequest(context, doc.id, data),
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
      ],
    );
  }
}
