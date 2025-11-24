// lib/screens/driver_dashboard.dart — FIXED "GO ONLINE" (WITH ERROR HANDLING)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _isOnline = false;
  StreamSubscription<Position>? _positionStream;

  Future<void> _toggleOnline() async {
    if (_isOnline) {
      _positionStream?.cancel();
      await FirebaseFirestore.instance
          .collection('drivers_online')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .delete();
      setState(() => _isOnline = false);
      return;
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    // Request permission with full handling
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission required')),
      );
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied forever. Enable in app settings.')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Mark online in Firestore
      await FirebaseFirestore.instance.collection('drivers_online').doc(uid).set({
        'online': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'plate': 'KDB 223Y',
        'location': const GeoPoint(0, 0),
        'bearing': 0.0,
      }, SetOptions(merge: true));

      // Start live location stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((position) {
        FirebaseFirestore.instance.collection('drivers_online').doc(uid).update({
          'location': GeoPoint(position.latitude, position.longitude),
          'bearing': position.heading,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      });

      // Success — update UI
      setState(() => _isOnline = true);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are now ONLINE!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error going online: $e')),
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_taxi, size: 140, color: _isOnline ? Colors.green : Colors.grey[600]),
            const SizedBox(height: 30),
            Text(
              _isOnline ? 'ONLINE – WAITING FOR RIDES' : 'OFFLINE',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _isOnline ? Colors.green : Colors.grey[700]),
            ),
            const SizedBox(height: 60),
            ElevatedButton.icon(
              onPressed: _toggleOnline,
              icon: Icon(_isOnline ? Icons.stop : Icons.play_arrow, size: 32),
              label: Text(_isOnline ? 'GO OFFLINE' : 'GO ONLINE', style: const TextStyle(fontSize: 22)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isOnline ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            if (_isOnline)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Text('Live location active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}