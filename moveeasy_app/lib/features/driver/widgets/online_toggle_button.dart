import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class OnlineToggleButton extends StatefulWidget {
  const OnlineToggleButton({super.key});

  @override
  State<OnlineToggleButton> createState() => _OnlineToggleButtonState();
}

class _OnlineToggleButtonState extends State<OnlineToggleButton> {
  bool _isOnline = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
      }
      return;
    }

    // Request permission with full handling
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
      }
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied forever. Enable in app settings.')),
        );
      }
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

      setState(() => _isOnline = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOnline ? [Colors.green[400]!, Colors.green[700]!] : [Colors.grey[400]!, Colors.grey[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isOnline ? Colors.green : Colors.grey).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isOnline ? 'You\'re Online' : 'You\'re Offline',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _isOnline ? 'Accepting ride requests' : 'Tap to go online',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _toggleOnline,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _isOnline ? Colors.green[700] : Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _isOnline ? 'GO OFFLINE' : 'GO ONLINE',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
