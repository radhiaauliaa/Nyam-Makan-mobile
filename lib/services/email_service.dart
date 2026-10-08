// services/email_service.dart
import 'package:emailjs/emailjs.dart' as emailjs;

class EmailService {
  // EmailJS Configuration
  static const String _serviceId =
      'service_tnu9o2v'; // Service yang sudah terverifikasi bisa kirim email
  static const String _publicKey =
      'gIY79AU6t3eKZ8-IU'; // Ganti dengan public_key dari EmailJS

  // Template IDs
  static const String _templateApproved =
      'template_1qa7aam'; // Restaurant Approved
  static const String _templateRejected =
      'template_ysvknzl'; // Restaurant Rejected

  // Send Restaurant Approved Email
  static Future<bool> sendRestaurantApprovedEmail({
    required String ownerEmail,
    required String ownerName,
    required String restaurantName,
    String adminEmail = 'admin@nyam-makanan.com',
  }) async {
    try {
      print('📧 ========== SENDING APPROVED EMAIL ==========');
      print('📧 To: $ownerEmail');
      print('📧 Owner Name: $ownerName');
      print('📧 Restaurant: $restaurantName');
      print('📧 Service ID: $_serviceId');
      print('📧 Template ID: $_templateApproved');
      print('📧 Public Key: ${_publicKey.substring(0, 5)}...');
      print('📧 ============================================');

      final response = await emailjs.send(_serviceId, _templateApproved, {
        'owner_name': ownerName,
        'email': ownerEmail,
        'restaurant_name': restaurantName,
        'admin_email': adminEmail,
      }, emailjs.Options(publicKey: _publicKey));

      print('✅ Restaurant approved email sent successfully!');
      print('✅ Response status: ${response.status}');
      print('✅ Response text: ${response.text}');
      return response.status == 200;
    } catch (e) {
      print('❌ ========== EMAIL ERROR ==========');
      print('❌ Error sending restaurant approved email: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ ===================================');
      return false;
    }
  }

  // Send Restaurant Rejected Email
  static Future<bool> sendRestaurantRejectedEmail({
    required String ownerEmail,
    required String ownerName,
    required String restaurantName,
    required String rejectionReason,
    String adminEmail = 'admin@nyam-makanan.com',
  }) async {
    try {
      print('📧 ========== SENDING REJECTED EMAIL ==========');
      print('📧 To: $ownerEmail');
      print('📧 Owner Name: $ownerName');
      print('📧 Restaurant: $restaurantName');
      print('📧 Rejection Reason: $rejectionReason');
      print('📧 Service ID: $_serviceId');
      print('📧 Template ID: $_templateRejected');
      print('📧 Public Key: ${_publicKey.substring(0, 5)}...');

      // Clean and trim all parameters
      final cleanOwnerName = ownerName.trim();
      final cleanEmail = ownerEmail.trim();
      final cleanRestaurantName = restaurantName.trim();
      final cleanRejectionReason = rejectionReason.trim();
      final cleanAdminEmail = adminEmail.trim();

      final params = {
        'owner_name': cleanOwnerName,
        'restaurant_name': cleanRestaurantName,
        'rejection_reason': cleanRejectionReason,
        'admin_email': cleanAdminEmail,
        'email': cleanEmail,
      };
      print('📧 Parameters: $params');
      print('📧 ==============================================');

      final response = await emailjs.send(
        _serviceId,
        _templateRejected,
        params,
        emailjs.Options(publicKey: _publicKey),
      );

      print('✅ Restaurant rejected email sent successfully!');
      print('✅ Response status: ${response.status}');
      print('✅ Response text: ${response.text}');
      return response.status == 200;
    } catch (e) {
      print('❌ ========== EMAIL ERROR ==========');
      print('❌ Error sending restaurant rejected email: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ ===================================');
      return false;
    }
  }

  // Test email connection
  static Future<bool> testEmailConnection() async {
    try {
      final response = await emailjs.send(_serviceId, _templateApproved, {
        'to_email': 'test@example.com',
        'owner_name': 'Test User',
        'restaurant_name': 'Test Restaurant',
      }, emailjs.Options(publicKey: _publicKey));

      print('✅ Email test successful: ${response.status}');
      return response.status == 200;
    } catch (e) {
      print('❌ Email test failed: $e');
      return false;
    }
  }
}
