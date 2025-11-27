import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveTripScreen extends StatefulWidget {
  final String requestId;
  final String pickup;
  final String dropoff;
  final double cost;
  final String passengerName;

  const ActiveTripScreen({
    super.key,
    required this.requestId,
    required this.pickup,
    required this.dropoff,
    required this.cost,
    required this.passengerName,
  });

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};

  // Mock coordinates for pickup and dropoff (Nairobi area)
  // In a real app, you'd geocode the addresses
  static const LatLng _pickupLocation = LatLng(-1.286389, 36.817223);
  static const LatLng _dropoffLocation = LatLng(-1.292066, 36.821946);

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  void _initializeMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: 'Pickup', snippet: widget.pickup),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: _dropoffLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Dropoff', snippet: widget.dropoff),
      ),
    );
  }

  Future<void> _completeTrip() async {
    try {
      // Update request status to completed
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(widget.requestId)
          .update({'status': 'completed'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip Completed!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _pickupLocation,
              zoom: 14,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _controller = controller;
              // Fit bounds to show both markers
              _controller?.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(
                      _pickupLocation.latitude < _dropoffLocation.latitude
                          ? _pickupLocation.latitude
                          : _dropoffLocation.latitude,
                      _pickupLocation.longitude < _dropoffLocation.longitude
                          ? _pickupLocation.longitude
                          : _dropoffLocation.longitude,
                    ),
                    northeast: LatLng(
                      _pickupLocation.latitude > _dropoffLocation.latitude
                          ? _pickupLocation.latitude
                          : _dropoffLocation.latitude,
                      _pickupLocation.longitude > _dropoffLocation.longitude
                          ? _pickupLocation.longitude
                          : _dropoffLocation.longitude,
                    ),
                  ),
                  100,
                ),
              );
            },
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, color: Colors.green[700]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.passengerName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const Text('Passenger', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          'KES ${widget.cost.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.my_location, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.pickup,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.dropoff,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Card
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car, color: Colors.green, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Trip in Progress',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _completeTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'COMPLETE TRIP',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
