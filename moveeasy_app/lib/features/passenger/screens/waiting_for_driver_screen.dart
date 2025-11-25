import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'trip_completed_screen.dart';
import 'rate_driver_screen.dart';

class WaitingForDriverScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final double cost;
  final String? requestId; // Add request ID parameter
  final String rideType;

  const WaitingForDriverScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.cost,
    this.requestId,
    this.rideType = 'private',
  });

  @override
  State<WaitingForDriverScreen> createState() => _WaitingForDriverScreenState();
}

class _WaitingForDriverScreenState extends State<WaitingForDriverScreen> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Timer? _pulseTimer;
  bool _isPulsing = false;
  StreamSubscription<DocumentSnapshot>? _requestSubscription;

  // Mock passenger location (Nairobi area)
  static const LatLng _passengerLocation = LatLng(-1.286389, 36.817223);

  // Mock nearby drivers
  final List<LatLng> _nearbyDrivers = [
    LatLng(-1.290000, 36.820000),
    LatLng(-1.283000, 36.815000),
    LatLng(-1.288000, 36.822000),
    LatLng(-1.284000, 36.819000),
  ];

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _startPulseAnimation();
    if (widget.requestId != null) {
      _listenForRequestUpdates();
    }
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _requestSubscription?.cancel();
    super.dispose();
  }

  void _initializeMarkers() {
    // Add passenger marker
    _markers.add(
      Marker(
        markerId: const MarkerId('passenger'),
        position: _passengerLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Add nearby driver markers
    for (int i = 0; i < _nearbyDrivers.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('driver_$i'),
          position: _nearbyDrivers[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Driver ${i + 1}'),
        ),
      );
    }
  }

  void _startPulseAnimation() {
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() => _isPulsing = !_isPulsing);
      }
    });
  }

  void _listenForRequestUpdates() {
    if (widget.requestId == null) return;

    // Listen to the specific request document
    _requestSubscription = FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'];

      // if (status == 'completed') {
      //   // Navigate to completion screen
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(
      //       builder: (_) => TripCompletedScreen(
      //         requestId: snapshot.id,
      //         pickup: data['pickup'] ?? widget.pickup,
      //         dropoff: data['dropoff'] ?? widget.dropoff,
      //         cost: (data['cost'] ?? widget.cost).toDouble(),
      //         driverName: data['driverName'] ?? 'Driver',
      //         driverId: data['driverId'] ?? '',
      //         vehicleModel: data['vehicleModel'] ?? 'Vehicle',
      //         plate: data['plate'] ?? '',
      //       ),
      //     ),
      //   );
      // }
    });
  }

  Future<void> _cancelRequest() async {
    if (widget.requestId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('ride_requests')
            .doc(widget.requestId)
            .update({'status': 'cancelled'});
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requestId == null) {
      return const Scaffold(body: Center(child: Text('No request ID provided')));
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ride_requests')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, snapshot) {
          String statusText = 'Waiting for driver to accept...';
          Color statusColor = Colors.orange;
          Widget? driverInfo;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              final status = data['status'];

              if (status == 'accepted') {
                statusText = 'Driver is on the way!';
                statusColor = Colors.green;
              } else if (status == 'in_transit') {
                statusText = 'On Board - In Transit';
                statusColor = Colors.blue;
              } else if (status == 'completed') {
                statusText = 'Payment Due';
                statusColor = Colors.orange;
              }
                
              // Show driver info if accepted
              if (status == 'accepted') {
                driverInfo = Card(
                  margin: const EdgeInsets.only(top: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green[100],
                          child: Icon(Icons.person, size: 35, color: Colors.green[700]),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data!['driverName'] ?? 'Driver',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data['vehicleModel'] ?? 'Vehicle'} - ${data['plate'] ?? ''}',
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                              if (data['driverPhone'] != null && data['driverPhone'].toString().isNotEmpty)
                                Text(
                                  data['driverPhone'],
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.phone, color: Colors.green[700]),
                      ],
                    ),
                  ),
                );
              }
            }
          }

          return Stack(
            children: [
              // Map
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _passengerLocation,
                  zoom: 14,
                ),
                markers: _markers,
                onMapCreated: (controller) => _controller = controller,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
              ),

              // Top Info Card
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 800),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _isPulsing ? statusColor : statusColor.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                statusText,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.my_location, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(widget.pickup, style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(widget.dropoff, style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                        if (driverInfo != null) driverInfo,
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Info Card
              Positioned(
                bottom: 30,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        if (widget.rideType == 'shared') ...[
                          // SHARED RIDE UI
                          if (statusText.contains('Driver is on the way') || statusText.contains('Boarding')) ...[
                            // DIGITAL TICKET
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.purple.shade200, width: 2),
                                boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 8)],
                              ),
                              child: Column(
                                children: [
                                  const Text('DIGITAL TICKET', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.requestId?.substring(0, 4).toUpperCase() ?? 'CODE',
                                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 4),
                                  ),
                                  const Text('Show this code to driver', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('PASSENGER', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                          Text('You', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('ROUTE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                          Text(widget.dropoff, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else if (statusText.contains('In Transit') || statusText.contains('On Board')) ...[
                            // IN TRANSIT UI
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.check_circle, size: 48, color: Colors.green),
                                  const SizedBox(height: 12),
                                  const Text('ON BOARD', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20)),
                                  const SizedBox(height: 8),
                                  const Text('Enjoy your ride!', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        // Manually trigger payment due status
                                        await FirebaseFirestore.instance
                                            .collection('ride_requests')
                                            .doc(widget.requestId)
                                            .update({'status': 'completed'});
                                      },
                                      icon: const Icon(Icons.exit_to_app),
                                      label: const Text('ALIGHT & PAY', style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('NEXT STOP', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text(widget.dropoff, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else if (statusText.contains('Payment Due')) ...[
                            // PAYMENT UI
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.orange.shade200, width: 2),
                                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 8)],
                              ),
                              child: Column(
                                children: [
                                  const Text('PAYMENT DUE', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'KES ${widget.cost.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Mock payment success -> Go to Rating
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RateDriverScreen(
                                              requestId: widget.requestId!,
                                              driverId: '', // Ideally fetch from snapshot
                                              driverName: 'Driver', // Ideally fetch from snapshot
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('PAY CASH / M-PESA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // QUEUE VIEW
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Queue Position', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance.collection('ride_requests').doc(widget.requestId).snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return const Text('-');
                                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                                    final position = data?['queuePosition'] ?? 1;
                                    return Text(
                                      '#$position',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.directions_bus, color: Colors.purple[700]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Waiting for bus on Route ${widget.dropoff}', 
                                      style: TextStyle(color: Colors.purple[900], fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ] else ...[
                          // PRIVATE RIDE UI
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated Fare', style: TextStyle(fontSize: 16, color: Colors.grey)),
                              Text(
                                'KES ${widget.cost.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_taxi, color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${_nearbyDrivers.length} drivers nearby',
                                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _cancelRequest,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('CANCEL REQUEST', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
