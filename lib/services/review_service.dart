// services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get restaurant reviews
  Future<List<Review>> getRestaurantReviews(String restaurantId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil ulasan: $e');
    }
  }

  // Get user reviews
  Future<List<Review>> getUserReviews(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil ulasan user: $e');
    }
  }

  // Add review
  Future<void> addReview(Review review) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(review.id)
          .set(review.toMap());
      
      // Update restaurant rating
      await _updateRestaurantRating(review.restaurantId);
    } catch (e) {
      throw Exception('Gagal menambah ulasan: $e');
    }
  }

  // Update review
  Future<void> updateReview(Review review) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(review.id)
          .update(review.toMap());
      
      // Update restaurant rating
      await _updateRestaurantRating(review.restaurantId);
    } catch (e) {
      throw Exception('Gagal update ulasan: $e');
    }
  }

  // Delete review
  Future<void> deleteReview(String reviewId, String restaurantId) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .delete();
      
      // Update restaurant rating
      await _updateRestaurantRating(restaurantId);
    } catch (e) {
      throw Exception('Gagal menghapus ulasan: $e');
    }
  }

  // Add owner reply
  Future<void> addOwnerReply(String reviewId, String reply) async {
    try {
      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .update({
            'ownerReply': reply,
            'updatedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Gagal menambah balasan: $e');
    }
  }

  // Update restaurant rating
  Future<void> _updateRestaurantRating(String restaurantId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          totalRating += (data['rating'] ?? 0).toDouble();
        }
        
        double averageRating = totalRating / snapshot.docs.length;
        int totalReviews = snapshot.docs.length;
        
        await _firestore
            .collection('restaurants')
            .doc(restaurantId)
            .update({
              'rating': averageRating,
              'totalReviews': totalReviews,
              'updatedAt': Timestamp.now(),
            });
      }
    } catch (e) {
      throw Exception('Gagal update rating restoran: $e');
    }
  }

  // Report review
  Future<void> reportReview(String reviewId, String reporterId, String reason) async {
    try {
      await _firestore
          .collection('reported_reviews')
          .doc(reviewId)
          .set({
            'reviewId': reviewId,
            'reporterId': reporterId,
            'reason': reason,
            'reportedAt': Timestamp.now(),
            'status': 'pending',
          });
    } catch (e) {
      throw Exception('Gagal melaporkan ulasan: $e');
    }
  }

  // Check if user has reviewed restaurant
  Future<bool> hasUserReviewed(String userId, String restaurantId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('restaurantId', isEqualTo: restaurantId)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Gagal mengecek ulasan user: $e');
    }
  }
}