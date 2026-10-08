// utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import 'theme.dart';

class Helpers {
  // Format currency
  static String formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  // Format date
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    return DateFormat(format).format(date);
  }

  // Format time
  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Calculate distance text
  static String getDistanceText(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)}m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  }

  // Calculate estimated time
  static String getEstimatedTime(double distanceInKm) {
    // Assume average speed of 5km/h for walking
    double timeInMinutes = (distanceInKm / 5) * 60;
    if (timeInMinutes < 1) {
      return '<1min';
    } else if (timeInMinutes < 60) {
      return '${timeInMinutes.toStringAsFixed(0)}min';
    } else {
      double hours = timeInMinutes / 60;
      return '${hours.toStringAsFixed(1)}jam';
    }
  }

  // Get rating text
  static String getRatingText(double rating) {
    if (rating == 0) return 'Belum ada rating';
    return '$rating/5.0';
  }

  // Get review count text
  static String getReviewCountText(int count) {
    if (count == 0) return 'Belum ada ulasan';
    if (count < 1000) return '($count)';
    if (count < 1000000) {
      return '(${((count / 1000).toStringAsFixed(1)).replaceAll('.0', '')}k)';
    }
    return '(${(count / 1000000).toStringAsFixed(1)}M)';
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Parse time string to TimeOfDay
  static TimeOfDay? parseTime(String timeString) {
    try {
      List<String> parts = timeString.split(':');
      if (parts.length == 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Check if time is between two times
  static bool isTimeBetween(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    int timeInMinutes = time.hour * 60 + time.minute;
    int startInMinutes = start.hour * 60 + start.minute;
    int endInMinutes = end.hour * 60 + end.minute;

    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  }

  // Make phone call
  static Future<void> makePhoneCall(String phoneNumber) async {
    // url_launcher is not guaranteed to be available in this workspace.
    // To enable proper phone calling, add `url_launcher` to pubspec.yaml
    // and import `package:url_launcher/url_launcher.dart`.
    throw UnimplementedError(
      'makePhoneCall requires package:url_launcher. Add it to pubspec.yaml or implement platform-specific call.',
    );
  }

  // Launch URL
  static Future<void> launchUrlString(String url) async {
    // url_launcher missing; this is a stub to avoid analyzer errors.
    throw UnimplementedError(
      'launchUrlString requires package:url_launcher. Add it to pubspec.yaml or implement platform-specific handling.',
    );
  }

  // Show snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'waiting':
        return AppColors.primaryOrange;
      case 'accepted':
      case 'verified':
      case 'active':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
      case 'suspended':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Get status text
  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'accepted':
        return 'Diterima';
      case 'rejected':
        return 'Ditolak';
      case 'verified':
        return 'Terverifikasi';
      case 'active':
        return 'Aktif';
      case 'suspended':
        return 'Ditangguhkan';
      case 'processing':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  // Calculate discount percentage
  static double calculateDiscountPercentage(
    double originalPrice,
    double discountedPrice,
  ) {
    if (originalPrice <= 0 || discountedPrice >= originalPrice) return 0;
    return ((originalPrice - discountedPrice) / originalPrice) * 100;
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Check if string is valid email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Check if string is valid phone number
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,13}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  // Generate random ID
  static String generateId({String prefix = ''}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return '$prefix$timestamp$random';
  }

  // Debounce function
  static Function debounce(Function func, Duration delay) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, () => func());
    };
  }
}
