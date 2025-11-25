import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSampleRoutesScreen extends StatefulWidget {
  const AddSampleRoutesScreen({super.key});

  @override
  State<AddSampleRoutesScreen> createState() => _AddSampleRoutesScreenState();
}

class _AddSampleRoutesScreenState extends State<AddSampleRoutesScreen> {
  bool _loading = false;
  String _message = '';

  Future<void> _addSampleRoutes() async {
    setState(() {
      _loading = true;
      _message = 'Adding routes...';
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Route 1: CBD to Westlands
      await firestore.collection('routes').add({
        'name': 'CBD to Westlands',
        'code': '14A',
        'baseFare': 100,
        'active': true,
        'estimatedDuration': 30,
        'stops': [
          {'id': 'stop1', 'name': 'CBD Terminal', 'lat': -1.286389, 'lng': 36.817223, 'order': 1},
          {'id': 'stop2', 'name': 'Museum Hill', 'lat': -1.275, 'lng': 36.815, 'order': 2},
          {'id': 'stop3', 'name': 'Westlands Square', 'lat': -1.265, 'lng': 36.810, 'order': 3},
        ],
      });

      // Route 2: Thika Road
      await firestore.collection('routes').add({
        'name': 'Thika Road Express',
        'code': '7B',
        'baseFare': 150,
        'active': true,
        'estimatedDuration': 45,
        'stops': [
          {'id': 'stop4', 'name': 'Roysambu', 'lat': -1.220, 'lng': 36.890, 'order': 1},
          {'id': 'stop5', 'name': 'Kasarani', 'lat': -1.215, 'lng': 36.900, 'order': 2},
        ],
      });

      // Route 3: Ngong Road
      await firestore.collection('routes').add({
        'name': 'Ngong Road Line',
        'code': '22C',
        'baseFare': 80,
        'active': true,
        'estimatedDuration': 25,
        'stops': [
          {'id': 'stop7', 'name': 'Adams Arcade', 'lat': -1.310, 'lng': 36.780, 'order': 1},
          {'id': 'stop8', 'name': 'Karen', 'lat': -1.320, 'lng': 36.770, 'order': 2},
        ],
      });

      setState(() {
        _loading = false;
        _message = '✅ Successfully added 3 routes!';
      });

      // Auto-close after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _message = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sample Routes'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.route, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Add Sample Routes to Firestore',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This will add 3 sample routes:\n• CBD to Westlands (14A)\n• Thika Road Express (7B)\n• Ngong Road Line (22C)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (_loading)
                const CircularProgressIndicator()
              else if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _message.contains('✅') ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _message.contains('✅') ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _addSampleRoutes,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Routes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
