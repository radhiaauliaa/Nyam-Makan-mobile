// utils/validators.dart
class Validators {
  // Email validator
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email harus diisi';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    
    return null;
  }

  // Password validator
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password harus diisi';
    }
    
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    
    return null;
  }

  // Username validator
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username harus diisi';
    }
    
    if (value.length < 3) {
      return 'Username minimal 3 karakter';
    }
    
    if (value.length > 20) {
      return 'Username maksimal 20 karakter';
    }
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username hanya boleh mengandung huruf, angka, dan underscore';
    }
    
    return null;
  }

  // Phone number validator
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon harus diisi';
    }
    
    final cleanedPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanedPhone.length < 10) {
      return 'Nomor telepon minimal 10 digit';
    }
    
    if (cleanedPhone.length > 13) {
      return 'Nomor telepon maksimal 13 digit';
    }
    
    return null;
  }

  // Required field validator
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    
    return null;
  }

  // Minimum length validator
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.length < minLength) {
      return '$fieldName minimal $minLength karakter';
    }
    
    return null;
  }

  // Maximum length validator
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName maksimal $maxLength karakter';
    }
    
    return null;
  }

  // Number validator
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName harus berupa angka';
    }
    
    if (number <= 0) {
      return '$fieldName harus lebih dari 0';
    }
    
    return null;
  }

  // Price validator
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Harga harus diisi';
    }
    
    final price = double.tryParse(value);
    if (price == null) {
      return 'Harga harus berupa angka';
    }
    
    if (price < 0) {
      return 'Harga tidak boleh negatif';
    }
    
    return null;
  }

  // Time validator
  static String? validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Waktu harus diisi';
    }
    
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value)) {
      return 'Format waktu tidak valid (HH:MM)';
    }
    
    return null;
  }

  // Date validator
  static String? validateDate(DateTime? value) {
    if (value == null) {
      return 'Tanggal harus diisi';
    }
    
    if (value.isBefore(DateTime.now())) {
      return 'Tanggal tidak boleh di masa lalu';
    }
    
    return null;
  }

  // Confirm password validator
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password harus diisi';
    }
    
    if (value != password) {
      return 'Password tidak cocok';
    }
    
    return null;
  }

  // Description validator
  static String? validateDescription(String? value, String fieldName, {int minLength = 10}) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    
    if (value.length < minLength) {
      return '$fieldName minimal $minLength karakter';
    }
    
    return null;
  }

  // Address validator
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Alamat harus diisi';
    }
    
    if (value.length < 10) {
      return 'Alamat terlalu pendek';
    }
    
    return null;
  }

  // Category validator
  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kategori harus diisi';
    }
    
    return null;
  }

  // Rating validator
  static String? validateRating(double? value) {
    if (value == null) {
      return 'Rating harus diisi';
    }
    
    if (value < 1 || value > 5) {
      return 'Rating harus antara 1-5';
    }
    
    return null;
  }

  // Guest count validator
  static String? validateGuestCount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Jumlah tamu harus diisi';
    }
    
    final count = int.tryParse(value);
    if (count == null) {
      return 'Jumlah tamu harus berupa angka';
    }
    
    if (count < 1) {
      return 'Jumlah tamu minimal 1';
    }
    
    if (count > 20) {
      return 'Jumlah tamu maksimal 20';
    }
    
    return null;
  }

  // Multi validator
  static String? validateMultiple(List<String? Function()> validators) {
    for (final validator in validators) {
      final error = validator();
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}