import 'package:flutter/material.dart';
import '../../shared/services/ride_service.dart';
import 'waiting_for_driver_screen.dart';
import 'route_browser_screen.dart';
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
  
  String _rideMode = 'private'; // 'private' or 'shared'
  DateTime? _scheduledTime;
  double _estimatedCost = 0.0;
  bool _loading = false;
  String? _selectedRouteId;
  String? _selectedStopId;

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
        rideType: _rideMode,
        routeId: _selectedRouteId,
        stopId: _selectedStopId,
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
                rideType: _rideMode,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride Mode Selector
            const Text('Select Ride Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'private',
                  label: Text('Private Ride'),
                  icon: Icon(Icons.directions_car),
                ),
                ButtonSegment(
                  value: 'shared',
                  label: Text('Shared Ride'),
                  icon: Icon(Icons.group),
                ),
              ],
              selected: {_rideMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _rideMode = newSelection.first;
                  // Reset fields when switching modes
                  if (_rideMode == 'shared') {
                    _pickupController.clear();
                    _dropoffController.clear();
                    _selectedRouteId = null;
                    _selectedStopId = null;
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Conditional UI based on mode
            if (_rideMode == 'private') ...[
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
            ] else ...[
              // Shared Ride - Route Selection
              const Text('Select a Route', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Browse available routes and join the queue at your preferred stop',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RouteBrowserScreen()),
                  ).then((result) {
                    if (result != null && result is Map) {
                      setState(() {
                        _selectedRouteId = result['routeId'];
                        _selectedStopId = result['stopId'];
                        _pickupController.text = result['stopName'] ?? '';
                        _dropoffController.text = result['routeName'] ?? '';
                        _estimatedCost = result['fare'] ?? 100.0;
                      });
                    }
                  });
                },
                icon: const Icon(Icons.map),
                label: Text(_selectedRouteId == null ? 'Browse Routes' : 'Change Route'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              if (_selectedRouteId != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          const Text('Route Selected', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 16),
                      Text('Stop: ${_pickupController.text}'),
                      Text('Route: ${_dropoffController.text}'),
                    ],
                  ),
                ),
              ],
            ],
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

            const SizedBox(height: 24),
            
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
