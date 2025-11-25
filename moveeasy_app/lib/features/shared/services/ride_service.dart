import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new ride request
  Future<String> requestRide({
    required String pickup,
    required String dropoff,
    required double cost,
    DateTime? scheduledTime,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final docRef = await _firestore.collection('ride_requests').add({
      'passengerId': user.uid,
      'passengerName': user.email, // Ideally use display name
      'pickup': pickup,
      'dropoff': dropoff,
      'cost': cost,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'scheduledTime': scheduledTime != null ? Timestamp.fromDate(scheduledTime) : null,
    });

    return docRef.id;
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

  // Stream of incoming requests for drivers
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
}
