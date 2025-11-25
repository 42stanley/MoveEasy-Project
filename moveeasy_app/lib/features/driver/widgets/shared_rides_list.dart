import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/services/ride_service.dart';
import '../../shared/models/route_model.dart' as model;
import '../screens/shared_trip_screen.dart';

class SharedRidesList extends StatelessWidget {
  const SharedRidesList({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current driver's route
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox.shrink();
        
        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final driverRouteId = userData?['route'];

        if (driverRouteId == null) {
          return const Center(child: Text('Please select a route in your profile to see shared rides.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shared Rides (Your Route)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              // Filter by the driver's route
              stream: RideService().getSharedRidesForRoute(driverRouteId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.directions_bus_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No active rides on your route ($driverRouteId)', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                // Group rides by route (though now it should only be one route)
                final rides = snapshot.data!.docs;
                final Map<String, List<DocumentSnapshot>> ridesByRoute = {};
                
                for (var doc in rides) {
                  final data = doc.data() as Map<String, dynamic>;
                  final routeId = data['routeId'] ?? 'unknown';
                  if (!ridesByRoute.containsKey(routeId)) {
                    ridesByRoute[routeId] = [];
                  }
                  ridesByRoute[routeId]!.add(doc);
                }

                return Column(
                  children: ridesByRoute.entries.map((entry) {
                    final routeId = entry.key;
                    final routeRides = entry.value;
                    final firstRide = routeRides.first.data() as Map<String, dynamic>;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.purple[700],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  firstRide['dropoff'] ?? 'Route',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.purple[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.people, size: 14, color: Colors.purple[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${routeRides.length} passengers',
                                      style: TextStyle(
                                        color: Colors.purple[700],
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
                          ...routeRides.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.purple[700],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['passengerName'] ?? 'Passenger',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          data['pickup'] ?? '',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'KES ${data['cost'] ?? 0}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total: KES ${routeRides.fold<double>(0, (sum, doc) => sum + ((doc.data() as Map)['cost'] ?? 0)).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SharedTripScreen(
                                        routeId: routeId,
                                        routeName: firstRide['dropoff'] ?? 'Route',
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('MANAGE ROUTE'),
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
      },
    );
  }
}
