// utils/constants.dart
class AppConstants {
  // App Info
  static const String appName = 'Nyam! Makaan';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String restaurantsCollection = 'restaurants';
  static const String reservationsCollection = 'reservations';
  static const String reviewsCollection = 'reviews';
  static const String menusCollection = 'menus';
  static const String notificationsCollection = 'notifications';
  static const String reportedReviewsCollection = 'reported_reviews';
  
  // Storage Paths
  static const String restaurantImagesPath = 'restaurant_images';
  static const String menuImagesPath = 'menu_images';
  static const String userProfilesPath = 'user_profiles';
  static const String licensePath = 'business_licenses';
  static const String paymentProofsPath = 'payment_proofs';
  
  // App Settings
  static const double maxImageSize = 2 * 1024 * 1024; // 2MB
  static const int maxRestaurantImages = 5;
  static const int maxReviewImages = 3;
  static const double defaultSearchRadius = 10.0; // 10km
  static const int itemsPerPage = 20;
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 20;
  static const int minUsernameLength = 3;
  
  // Notifications
  static const String channelId = 'nyam_makaan_channel';
  static const String channelName = 'Nyam! Makaan Notifications';
  static const String channelDescription = 'Notifications for restaurant reservations and reviews';
}

class RouteConstants {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/role-selection';
  static const String home = '/home';
  static const String adminHome = '/admin-home';
  static const String ownerHome = '/owner-home';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String restaurantDetail = '/restaurant-detail';
  static const String reservation = '/reservation';
  static const String review = '/review';
  static const String favorite = '/favorite';
  static const String reservationList = '/reservation-list';
  static const String notification = '/notification';
  static const String promo = '/promo';
}

class AssetConstants {
  static const String logo = 'assets/images/logo.png';
  static const String placeholder = 'assets/images/placeholder.jpg';
  static const String emptyState = 'assets/images/empty_state.png';
  static const String errorState = 'assets/images/error_state.png';
  
  // Icons
  static const String homeIcon = 'assets/icons/home.png';
  static const String searchIcon = 'assets/icons/search.png';
  static const String favoriteIcon = 'assets/icons/favorite.png';
  static const String profileIcon = 'assets/icons/profile.png';
  static const String reservationIcon = 'assets/icons/reservation.png';
}