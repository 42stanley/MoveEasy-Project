import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Request a ride
  Future<String> requestRide({
    required String pickup,
    required String dropoff,
    required double cost,
    DateTime? scheduledTime,
    String rideType = 'private', // 'private' or 'shared'
    String? routeId,
    String? stopId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final docRef = await _firestore.collection('ride_requests').add({
      'passengerId': user.uid,
      'passengerName': user.displayName ?? 'Passenger',
      'pickup': pickup,
      'dropoff': dropoff,
      'cost': cost,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'scheduledTime': scheduledTime != null ? Timestamp.fromDate(scheduledTime) : null,
      'rideType': rideType,
      'routeId': routeId,
      'stopId': stopId,
      'queuePosition': rideType == 'shared' ? await _getNextQueuePosition(routeId, stopId) : null,
    });

    return docRef.id;
  }

  // Get next queue position for shared rides
  Future<int> _getNextQueuePosition(String? routeId, String? stopId) async {
    if (routeId == null || stopId == null) return 1;
    
    final snapshot = await _firestore
        .collection('ride_requests')
        .where('routeId', isEqualTo: routeId)
        .where('stopId', isEqualTo: stopId)
        .where('status', isEqualTo: 'pending')
        .get();
    
    return snapshot.docs.length + 1;
  }

  // Submit a review
  Future<void> submitReview({
    required String driverId,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore.collection('reviews').add({
      'driverId': driverId,
      'passengerId': user.uid,
      'passengerName': user.email,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream of incoming requests for drivers (immediate requests only, no scheduled)
  Stream<QuerySnapshot> getIncomingRequests() {
    return _firestore
        .collection('ride_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Check if user has a pending request
  Future<bool> hasPendingRequest() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _firestore
        .collection('ride_requests')
        .where('passengerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Get active trips for a driver
  Stream<QuerySnapshot> getActiveTripsForDriver(String driverId) {
    return _firestore
        .collection('ride_requests')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  // Get a specific ride request by ID (for real-time updates)
  Stream<DocumentSnapshot> getRideRequestById(String requestId) {
    return _firestore
        .collection('ride_requests')
        .doc(requestId)
        .snapshots();
  }

  // Cancel a ride request
  Future<void> cancelRequest(String requestId) async {
    await _firestore
        .collection('ride_requests')
        .doc(requestId)
        .update({'status': 'cancelled'});
  }

  // Update ride status (e.g., 'in_transit', 'completed')
  Future<void> updateRideStatus(String requestId, String status) async {
    await _firestore
        .collection('ride_requests')
        .doc(requestId)
        .update({'status': status});
  }

  // Get scheduled rides (pending rides with scheduledTime)
  Stream<QuerySnapshot> getScheduledRides() {
    return _firestore
        .collection('ride_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('scheduledTime')
        .snapshots();
  }

  // Promote a waiting ride to accepted status
  Future<void> promoteWaitingRide(String requestId) async {
    await _firestore
        .collection('ride_requests')
        .doc(requestId)
        .update({'status': 'accepted'});
  }

  // Get all active routes
  Stream<QuerySnapshot> getActiveRoutes() {
    return _firestore
        .collection('routes')
        .where('active', isEqualTo: true)
        .snapshots();
  }

  // Get queue for a specific route and stop
  Stream<QuerySnapshot> getQueueForStop(String routeId, String stopId) {
    return _firestore
        .collection('ride_requests')
        .where('routeId', isEqualTo: routeId)
        .where('stopId', isEqualTo: stopId)
        .where('status', isEqualTo: 'pending')
        .where('rideType', isEqualTo: 'shared')
        .orderBy('queuePosition')
        .snapshots();
  }

  // Get total queue count across all stops for a route
  Future<int> getRouteQueueCount(String routeId) async {
    final snapshot = await _firestore
        .collection('ride_requests')
        .where('routeId', isEqualTo: routeId)
        .where('status', isEqualTo: 'pending')
        .where('rideType', isEqualTo: 'shared')
        .get();
    
    return snapshot.docs.length;
  }

  // Get shared rides for a specific route (for driver)
  Stream<QuerySnapshot> getSharedRidesForRoute(String routeId) {
    return _firestore
        .collection('ride_requests')
        .where('rideType', isEqualTo: 'shared')
        .where('routeId', isEqualTo: routeId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Get shared rides for a driver
  Stream<QuerySnapshot> getSharedRidesForDriver(String driverId) {
    return _firestore
        .collection('ride_requests')
        .where('driverId', isEqualTo: driverId)
        .where('rideType', isEqualTo: 'shared')
        .where('status', whereIn: ['accepted', 'in_transit'])
        .snapshots();
  }
}
