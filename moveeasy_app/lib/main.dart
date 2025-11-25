// lib/main.dart → FINAL 100% COMPLETE & WORKING (NOV 2025)

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import 'features/auth/screens/welcome_screen.dart';
import 'features/driver/screens/driver_dashboard.dart';
import 'features/passenger/screens/passenger_dashboard.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MoveEasyApp());
}

class MoveEasyApp extends StatelessWidget {
  const MoveEasyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoveEasy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const AuthWrapper(),
    );
  }
}

// AUTH WRAPPER — 100% AUTO REDIRECT (NO BACK BUTTON EVER)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) return const WelcomeScreen();

        final uid = snapshot.data!.uid;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnap) {
            if (!userSnap.hasData || userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final role = (userSnap.data!.data() as Map<String, dynamic>?)?['role'] ?? 'passenger';

            if (role == 'driver') {
              return const DriverDashboardScreen(); // INSTANT
            } else {
              return const PassengerDashboard(); // New Dashboard
            }
          },
        );
      },
    );
  }
}

// FULL PASSENGER MAP — LIVE MATATUS + STOPS + POLYLINE
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int _liveBusCount = 0;
  bool _loading = true;
  Timer? _timer;
  late BitmapDescriptor stopIcon;
  late BitmapDescriptor busIcon;

  String get baseUrl => Platform.isAndroid
      ? 'http://10.0.2.2:5001'
      : 'http://192.168.1.102:5001'; // CHANGE TO YOUR PC IP

  @override
  void initState() {
    super.initState();
    _loadIcons().then((_) => _loadStopsAndStart());
  }

  Future<void> _loadIcons() async {
    stopIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    busIcon = BitmapDescriptor.defaultMarker;
    try {
      stopIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(), 'assets/icons/stop.png');
      busIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(), 'assets/icons/bus.png');
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadStopsAndStart() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/stops'));
      if (res.statusCode == 200) {
        final stops = json.decode(res.body) as List;
        final stopMarkers = <Marker>[];
        final points = <LatLng>[];

        for (var s in stops) {
          final lat = s['stop_lat'] is int ? (s['stop_lat'] as int).toDouble() : s['stop_lat'] as double;
          final lon = s['stop_lon'] is int ? (s['stop_lon'] as int).toDouble() : s['stop_lon'] as double;
          stopMarkers.add(Marker(
            markerId: MarkerId(s['stop_id']),
            position: LatLng(lat, lon),
            infoWindow: InfoWindow(title: s['stop_name']),
            icon: stopIcon,
          ));
          points.add(LatLng(lat, lon));
        }

        setState(() {
          _markers.addAll(stopMarkers);
          if (points.isNotEmpty) {
            _polylines.add(Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: Colors.blue,
              width: 5,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ));
          }
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stops error: $e')));
    }
    _startLiveTracking();
  }

  void _startLiveTracking() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _updateBuses());
    _updateBuses();
  }

  Future<void> _updateBuses() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/gtfs-realtime'));
      if (res.statusCode == 200) {
        final feed = FeedMessage.fromBuffer(res.bodyBytes);
        final busMarkers = <Marker>[];

        for (final entity in feed.entity) {
          if (entity.hasVehicle()) {
            final v = entity.vehicle;
            final id = entity.id.isNotEmpty ? entity.id : 'bus_${v.vehicle.id}';
            busMarkers.add(Marker(
              markerId: MarkerId(id),
              position: LatLng(v.position.latitude, v.position.longitude),
              infoWindow: const InfoWindow(title: 'Matatu Live'),
              icon: busIcon,
              rotation: v.position.bearing,
            ));
          }
        }

        setState(() {
          _markers.removeWhere((m) => m.markerId.value.startsWith('bus'));
          _markers.addAll(busMarkers);
          _liveBusCount = busMarkers.length;
        });
      }
    } catch (e) {
      if (kDebugMode) print('GTFS error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MoveEasy – Live Tracking')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(target: LatLng(-1.2921, 36.8219), zoom: 12),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (c) => _controller = c,
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.directions_bus, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Live Buses: $_liveBusCount',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}