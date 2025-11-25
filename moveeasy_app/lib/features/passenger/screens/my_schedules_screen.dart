import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/utils/date_time_utils.dart';
import '../../shared/services/ride_service.dart';

class MySchedulesScreen extends StatefulWidget {
  const MySchedulesScreen({super.key});

  @override
  State<MySchedulesScreen> createState() => _MySchedulesScreenState();
}

class _MySchedulesScreenState extends State<MySchedulesScreen> {
  String _selectedFilter = 'all'; // all, upcoming, completed, cancelled

  Future<void> _cancelScheduledRide(BuildContext context, String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Scheduled Ride'),
        content: const Text('Are you sure you want to cancel this scheduled ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await RideService().cancelRequest(requestId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride cancelled'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting for driver';
      case 'waiting_for_time':
        return 'Driver assigned';
      case 'accepted':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'waiting_for_time':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<QueryDocumentSnapshot> _filterAndSortRides(List<QueryDocumentSnapshot> docs) {
    // Filter based on selected filter
    List<QueryDocumentSnapshot> filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';

      switch (_selectedFilter) {
        case 'upcoming':
          return status == 'pending' || status == 'waiting_for_time' || status == 'accepted';
        case 'completed':
          return status == 'completed';
        case 'cancelled':
          return status == 'cancelled';
        default:
          return true; // 'all'
      }
    }).toList();

    // Sort: incomplete rides first (by scheduled time), then completed/cancelled (by scheduled time desc)
    filtered.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aStatus = aData['status'] ?? 'pending';
      final bStatus = bData['status'] ?? 'pending';
      final aTime = (aData['scheduledTime'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bTime = (bData['scheduledTime'] as Timestamp?)?.toDate() ?? DateTime.now();

      final aComplete = aStatus == 'completed' || aStatus == 'cancelled';
      final bComplete = bStatus == 'completed' || bStatus == 'cancelled';

      // Incomplete rides come first
      if (aComplete && !bComplete) return 1;
      if (!aComplete && bComplete) return -1;

      // Within same category, sort by time
      if (!aComplete && !bComplete) {
        return aTime.compareTo(bTime); // Upcoming: earliest first
      } else {
        return bTime.compareTo(aTime); // Completed: latest first
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Schedules', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: userId == null
          ? const Center(child: Text('Please log in'))
          : Column(
              children: [
                // Filter chips
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Upcoming', 'upcoming'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Completed', 'completed'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Cancelled', 'cancelled'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('ride_requests')
                        .where('passengerId', isEqualTo: userId)
                        .where('scheduledTime', isNull: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No scheduled rides', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Text('Schedule a ride to see it here', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        );
                      }

                      final filteredDocs = _filterAndSortRides(snapshot.data!.docs);

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.filter_list_off, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No rides in this category', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final scheduledTime = data['scheduledTime'] as Timestamp?;
                          final status = data['status'] ?? 'pending';
                          final isPast = DateTimeUtils.hasPassed(scheduledTime);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.schedule, size: 14, color: _getStatusColor(status)),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateTimeUtils.formatScheduledTime(scheduledTime),
                                            style: TextStyle(
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getStatusText(status),
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.my_location, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        data['pickup'] ?? '',
                                        style: const TextStyle(fontSize: 14),
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
                                        data['dropoff'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                if (data['driverName'] != null) ...[
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 16, color: Colors.blue[700]),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Driver: ${data['driverName']}',
                                        style: TextStyle(fontSize: 14, color: Colors.blue[700], fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'KES ${data['cost'] ?? 0}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.green,
                                      ),
                                    ),
                                    if (status == 'pending' && !isPast)
                                      OutlinedButton(
                                        onPressed: () => _cancelScheduledRide(context, doc.id),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                        child: const Text('CANCEL'),
                                      ),
                                    if (!isPast && status == 'waiting_for_time')
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.access_time, size: 16, color: Colors.blue[700]),
                                            const SizedBox(width: 6),
                                            Text(
                                              DateTimeUtils.getTimeRemaining(scheduledTime),
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.green[700] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
