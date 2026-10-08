// providers/reservation_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';
import '../services/reservation_service.dart';
import '../services/notification_service.dart';

class ReservationProvider with ChangeNotifier {
  final ReservationService _reservationService = ReservationService();
  final NotificationService _notificationService = NotificationService();

  List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _error;
  // Stream<List<Reservation>>? _reservationsStream; // removed unused field

  List<Reservation> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Reservation> get pendingReservations =>
      _reservations.where((r) => r.isPending).toList();

  List<Reservation> get acceptedReservations =>
      _reservations.where((r) => r.isAccepted).toList();

  List<Reservation> get rejectedReservations =>
      _reservations.where((r) => r.isRejected).toList();

  // Load user reservations (once)
  Future<void> loadUserReservations(String userId) async {
    if (userId.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reservations = await _reservationService.getUserReservations(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user reservations as stream (real-time)
  Stream<List<Reservation>> getUserReservationsStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }
    return _reservationService.getUserReservationsStream(userId);
  }

  // Load restaurant reservations (for owner)
  Future<void> loadRestaurantReservations(String restaurantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reservations = await _reservationService.getRestaurantReservations(
        restaurantId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new reservation
  Future<bool> createReservation(Reservation reservation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _reservationService.createReservation(reservation);

      // Get restaurant data for notifications
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(reservation.restaurantId)
          .get();
      final restaurantData = restaurantDoc.data();
      final restaurantName = restaurantData?['name'] ?? 'Restoran';
      final ownerId = restaurantData?['ownerId'] ?? '';

      // SEND NOTIFICATION to user (confirmation)
      await _notificationService.notifyReservationCreated(
        reservation.userId,
        restaurantName,
        reservation.id,
      );

      // SEND NOTIFICATION to restaurant owner (use ownerId, not restaurantId)
      if (ownerId.isNotEmpty) {
        await _notificationService.notifyNewReservation(
          ownerId,
          reservation.customerName,
          reservation.id,
        );
        print('✅ Notification sent to owner: $ownerId');
      } else {
        print(
          '⚠️ OwnerId not found for restaurant: ${reservation.restaurantId}',
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update reservation status (for owner)
  Future<bool> updateReservationStatus(
    String reservationId,
    String status, {
    String? reason,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _reservationService.updateReservationStatus(
        reservationId,
        status,
        reason: reason,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Assign table to reservation
  Future<bool> assignTable(
    String reservationId,
    String tableGroup,
    String tableNumber,
  ) async {
    _error = null;
    notifyListeners();

    try {
      await _reservationService.assignTable(
        reservationId,
        tableGroup,
        tableNumber,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update local reservations (for stream)
  void updateReservations(List<Reservation> newReservations) {
    _reservations = newReservations;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data
  void clearData() {
    _reservations = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // ========== NEW METHODS FOR UPDATED FLOW ==========

  // Owner: Approve reservation (status: pending_review -> awaiting_payment)
  Future<bool> approveReservation(String reservationId) async {
    _error = null;
    notifyListeners();

    try {
      // Get reservation data first
      final reservation = _reservations.firstWhere(
        (r) => r.id == reservationId,
      );

      await _reservationService.updateReservationStatus(
        reservationId,
        'awaiting_payment',
      );

      // SEND NOTIFICATION to user
      await _notificationService.notifyReservationApproved(
        reservation.userId,
        reservation.restaurantName,
        reservationId,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Owner: Reject reservation
  Future<bool> rejectReservation(String reservationId, String reason) async {
    _error = null;
    notifyListeners();

    try {
      final reservation = _reservations.firstWhere(
        (r) => r.id == reservationId,
      );

      await _reservationService.updateReservationStatus(
        reservationId,
        'rejected',
        reason: reason,
      );

      // SEND NOTIFICATION to user
      await _notificationService.notifyReservationRejected(
        reservation.userId,
        reservation.restaurantName,
        reservationId,
        reason,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Owner: Offer alternative time
  Future<bool> offerAlternativeTime(
    String reservationId,
    String alternativeTime,
  ) async {
    _error = null;
    notifyListeners();

    try {
      final reservation = _reservations.firstWhere(
        (r) => r.id == reservationId,
      );

      await _reservationService.offerAlternativeTime(
        reservationId,
        alternativeTime,
      );

      // SEND NOTIFICATION to user
      await _notificationService.notifyAlternativeTime(
        reservation.userId,
        reservation.restaurantName,
        alternativeTime,
        reservationId,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // User: Upload payment proof (after approved)
  Future<bool> uploadPaymentProof(
    String reservationId,
    String paymentProofUrl,
  ) async {
    _error = null;
    notifyListeners();

    try {
      final reservation = _reservations.firstWhere(
        (r) => r.id == reservationId,
      );

      await _reservationService.uploadPaymentProof(
        reservationId,
        paymentProofUrl,
      );

      // Get owner ID from restaurant
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(reservation.restaurantId)
          .get();
      final ownerId = restaurantDoc.data()?['ownerId'] ?? '';

      // SEND NOTIFICATION to restaurant owner (use ownerId)
      if (ownerId.isNotEmpty) {
        await _notificationService.notifyPaymentReceived(
          ownerId,
          reservationId,
        );
        print('✅ Payment notification sent to owner: $ownerId');
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Owner: Verify payment proof (awaiting_payment -> confirmed)
  Future<bool> verifyPaymentProof(String reservationId, bool isValid) async {
    _error = null;
    notifyListeners();

    try {
      final reservation = _reservations.firstWhere(
        (r) => r.id == reservationId,
      );

      if (isValid) {
        await _reservationService.updateReservationStatus(
          reservationId,
          'confirmed',
        );
        // Mark payment as verified
        await _reservationService.markPaymentVerified(reservationId);

        // SEND NOTIFICATION to user (confirmed)
        // Format date and time for notification
        final dateStr =
            '${reservation.date.day}/${reservation.date.month}/${reservation.date.year}';
        await _notificationService.notifyReservationConfirmed(
          reservation.userId,
          reservation.restaurantName,
          dateStr,
          reservation.time,
          reservationId,
        );
      } else {
        // Back to awaiting_payment with note
        await _reservationService.updateReservationStatus(
          reservationId,
          'awaiting_payment',
          reason: 'Bukti transfer tidak valid, silakan upload ulang',
        );

        // SEND NOTIFICATION to user (payment rejected)
        await _notificationService.notifyPaymentRejected(
          reservation.userId,
          reservation.restaurantName,
          reservationId,
          'Bukti transfer tidak valid',
        );
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark reservation as completed (after customer visited)
  Future<bool> completeReservation(String reservationId) async {
    _error = null;
    notifyListeners();

    try {
      await _reservationService.updateReservationStatus(
        reservationId,
        'completed',
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // User: Cancel reservation
  Future<bool> cancelReservation(String reservationId, String reason) async {
    _error = null;
    notifyListeners();

    try {
      await _reservationService.updateReservationStatus(
        reservationId,
        'cancelled',
        reason: reason,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get reservations by status
  List<Reservation> getReservationsByStatus(String status) {
    return _reservations.where((r) => r.status == status).toList();
  }

  // New getters for different statuses
  List<Reservation> get pendingReviewReservations =>
      _reservations.where((r) => r.isPendingReview).toList();

  List<Reservation> get awaitingPaymentReservations =>
      _reservations.where((r) => r.isAwaitingPayment).toList();

  List<Reservation> get confirmedReservations =>
      _reservations.where((r) => r.isConfirmed).toList();

  List<Reservation> get completedReservations =>
      _reservations.where((r) => r.isCompleted).toList();
}
