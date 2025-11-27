import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Format scheduled time in a human-readable way
  /// Examples: "Today at 2:00 PM", "Tomorrow at 9:00 AM", "Dec 25, 2025 at 3:00 PM"
  static String formatScheduledTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Not scheduled';
    
    final scheduledDate = timestamp.toDate();
    final now = DateTime.now();
    final difference = scheduledDate.difference(now);
    
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    if (difference.inDays == 0) {
      return 'Today at ${timeFormat.format(scheduledDate)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${timeFormat.format(scheduledDate)}';
    } else {
      return '${dateFormat.format(scheduledDate)} at ${timeFormat.format(scheduledDate)}';
    }
  }

  /// Get time remaining until scheduled time
  /// Returns formatted string like "2h 30m" or "45m"
  static String getTimeRemaining(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    final scheduledDate = timestamp.toDate();
    final now = DateTime.now();
    final difference = scheduledDate.difference(now);
    
    if (difference.isNegative) return 'Overdue';
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Check if scheduled time is within threshold (in minutes)
  static bool isWithinThreshold(Timestamp? timestamp, int thresholdMinutes) {
    if (timestamp == null) return false;
    
    final scheduledDate = timestamp.toDate();
    final now = DateTime.now();
    final difference = scheduledDate.difference(now);
    
    return difference.inMinutes <= thresholdMinutes && !difference.isNegative;
  }

  /// Check if scheduled time has passed
  static bool hasPassed(Timestamp? timestamp) {
    if (timestamp == null) return false;
    
    final scheduledDate = timestamp.toDate();
    final now = DateTime.now();
    
    return now.isAfter(scheduledDate);
  }
}
