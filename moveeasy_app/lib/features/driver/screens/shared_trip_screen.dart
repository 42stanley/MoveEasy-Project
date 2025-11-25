import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/services/ride_service.dart';
import '../../shared/models/route_model.dart' as model;

class SharedTripScreen extends StatefulWidget {
  final String routeId;
  final String routeName;

  const SharedTripScreen({
    super.key,
    required this.routeId,
    required this.routeName,
  });

  @override
  State<SharedTripScreen> createState() => _SharedTripScreenState();
}

class _SharedTripScreenState extends State<SharedTripScreen> {
  String? _currentStopId;
  int _currentStopIndex = 0;
  List<model.RouteStop> _stops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRouteDetails();
  }

  Future<void> _loadRouteDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('routes').doc(widget.routeId).get();
      if (doc.exists) {
        final route = model.Route.fromFirestore(doc.data()!, doc.id);
        setState(() {
          _stops = route.stops;
          _stops.sort((a, b) => a.order.compareTo(b.order));
          if (_stops.isNotEmpty) {
            _currentStopId = _stops.first.id;
          }
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _advanceStop() {
    if (_currentStopIndex < _stops.length - 1) {
      setState(() {
        _currentStopIndex++;
        _currentStopId = _stops[_currentStopIndex].id;
      });
    } else {
      // End of route
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route Completed!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Current Stop Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.purple[50],
                  width: double.infinity,
                  child: Column(
                    children: [
                      const Text('NEXT STOP', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text(
                        _stops[_currentStopIndex].name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stop ${_currentStopIndex + 1} of ${_stops.length}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Passengers at this stop
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: RideService().getQueueForStop(widget.routeId, _currentStopId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final passengers = snapshot.data!.docs;

                      if (passengers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No passengers waiting here', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: passengers.length,
                        itemBuilder: (context, index) {
                          final data = passengers[index].data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple[100],
                                child: Text(
                                  (data['passengerName'] != null && data['passengerName'].isNotEmpty) 
                                      ? data['passengerName'][0] 
                                      : 'P',
                                  style: TextStyle(color: Colors.purple[700]),
                                ),
                              ),
                              title: Text(data['passengerName'] ?? 'Passenger'),
                              subtitle: Text('Going to: ${data['dropoff'] ?? 'Unknown'}'),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  // Pick up passenger logic
                                  RideService().updateRideStatus(passengers[index].id, 'in_transit');
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('PICK UP'),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Action Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _advanceStop,
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(_currentStopIndex < _stops.length - 1 ? 'ARRIVED AT STOP' : 'COMPLETE ROUTE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
