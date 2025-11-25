import 'package:flutter/material.dart';
import '../../shared/services/ride_service.dart';
import 'waiting_for_driver_screen.dart';
import '../widgets/dashboard_widgets.dart'; // Reusing widgets if needed, or just standard UI

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({super.key});

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _rideService = RideService();
  
  DateTime? _scheduledTime;
  double _estimatedCost = 0.0;
  bool _loading = false;

  void _calculateCost() {
    // Mock calculation logic
    if (_pickupController.text.isNotEmpty && _dropoffController.text.isNotEmpty) {
      setState(() {
        _estimatedCost = 450.0; // Mock fixed cost for now
      });
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter pickup and dropoff')));
      return;
    }

    setState(() => _loading = true);
    try {
      // Check for existing pending request
      final hasPending = await _rideService.hasPendingRequest();
      if (hasPending) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You already have a pending request. Please wait for it to be accepted or cancel it first.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final requestId = await _rideService.requestRide(
        pickup: _pickupController.text.trim(),
        dropoff: _dropoffController.text.trim(),
        cost: _estimatedCost,
        scheduledTime: _scheduledTime,
      );
      
      if (mounted) {
        if (_scheduledTime != null) {
          // For scheduled rides, show confirmation and return to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ride scheduled successfully! You will be notified when a driver accepts.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.pop(context); // Return to dashboard
        } else {
          // For immediate rides, navigate to waiting screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WaitingForDriverScreen(
                pickup: _pickupController.text.trim(),
                dropoff: _dropoffController.text.trim(),
                cost: _estimatedCost,
                requestId: requestId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Ride')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _pickupController,
              decoration: const InputDecoration(
                labelText: 'Pickup Location',
                prefixIcon: Icon(Icons.my_location),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculateCost(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dropoffController,
              decoration: const InputDecoration(
                labelText: 'Dropoff Destination',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculateCost(),
            ),
            const SizedBox(height: 24),
            
            // Cost Display
            if (_estimatedCost > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Cost', style: TextStyle(fontSize: 16)),
                    Text('KES ${_estimatedCost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),

            // Schedule Option
            ListTile(
              title: Text(_scheduledTime == null ? 'Schedule for Later' : 'Scheduled: ${_scheduledTime.toString().substring(0, 16)}'),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: _selectDateTime,
            ),
            if (_scheduledTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  onPressed: () => setState(() => _scheduledTime = null),
                  child: const Text('Clear Schedule (Request Now)', style: TextStyle(color: Colors.red)),
                ),
              ),

            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_scheduledTime == null ? 'REQUEST RIDE' : 'SCHEDULE RIDE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
