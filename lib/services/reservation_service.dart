// services/reservation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user reservations (once)
  Future<List<Reservation>> getUserReservations(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Reservation.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('Gagal memuat reservasi: $e');
    }
  }

  // Get user reservations as stream (real-time)
  Stream<List<Reservation>> getUserReservationsStream(String userId) {
    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Reservation.fromMap({...data, 'id': doc.id});
          }).toList();
        });
  }

  // Get restaurant reservations
  Future<List<Reservation>> getRestaurantReservations(
    String restaurantId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('reservations')
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Reservation.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('Gagal memuat reservasi restoran: $e');
    }
  }

  // Create new reservation
  Future<void> createReservation(Reservation reservation) async {
    try {
      await _firestore
          .collection('reservations')
          .doc(reservation.id)
          .set(reservation.toMap());
    } catch (e) {
      throw Exception('Gagal membuat reservasi: $e');
    }
  }

  // Update reservation status
  Future<void> updateReservationStatus(
    String reservationId,
    String status, {
    String? reason,
  }) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': status,
        if (reason != null) 'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate status reservasi: $e');
    }
  }

  // Assign table to reservation
  Future<void> assignTable(
    String reservationId,
    String tableGroup,
    String tableNumber,
  ) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'tableGroup': tableGroup,
        'tableNumber': tableNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menetapkan meja: $e');
    }
  }

  // ========== NEW METHODS FOR UPDATED FLOW ==========

  // Offer alternative time
  Future<void> offerAlternativeTime(
    String reservationId,
    String alternativeTime,
  ) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'alternativeTime': alternativeTime,
        'status':
            'awaiting_payment', // Still approved but with alternative time
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menawarkan waktu alternatif: $e');
    }
  }

  // Upload payment proof
  Future<void> uploadPaymentProof(
    String reservationId,
    String paymentProofUrl,
  ) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'paymentProofUrl': paymentProofUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengupload bukti pembayaran: $e');
    }
  }

  // Mark payment as verified
  Future<void> markPaymentVerified(String reservationId) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'paymentVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal memverifikasi pembayaran: $e');
    }
  }

  // Get restaurant reservations stream (real-time)
  Stream<List<Reservation>> getRestaurantReservationsStream(
    String restaurantId,
  ) {
    return _firestore
        .collection('reservations')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Reservation.fromMap({...data, 'id': doc.id});
          }).toList();
        });
  }
}
