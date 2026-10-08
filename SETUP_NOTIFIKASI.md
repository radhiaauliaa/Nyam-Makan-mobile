# 🔔 Setup Notifikasi - Nyam Makanan

## 📋 Yang Sudah Dibuat:

### 1. **FCMService** (`lib/services/fcm_service.dart`)
- ✅ Push notification ke HP (muncul di notification bar)
- ✅ In-app notifications (tersimpan di Firestore)
- ✅ Notifikasi untuk:
  - Reservasi disetujui/ditolak/dikonfirmasi
  - Akun ditangguhkan
  - Resto ditangguhkan

### 2. **EmailService** (`lib/services/email_service.dart`)
- ✅ Email via EmailJS
- ✅ Template:
  - `template_1qa7aam` - Resto Diterima
  - `template_ysvknzl` - Resto Ditolak

### 3. **NotificationsScreen** (`lib/screens/shared/notifications_screen.dart`)
- ✅ Tampilan list notifikasi
- ✅ Badge unread count
- ✅ Mark as read
- ✅ TimeAgo format

---

## 🚀 Setup Firebase Cloud Messaging (FCM)

### **Android Setup:**

1. **Download `google-services.json`** dari Firebase Console
   - Sudah ada di `android/app/google-services.json` ✅

2. **Update `android/app/build.gradle`:**
   ```gradle
   dependencies {
       implementation 'com.google.firebase:firebase-messaging:23.4.0'
   }
   ```

3. **Update `android/app/src/main/AndroidManifest.xml`:**
   ```xml
   <manifest ...>
       <application ...>
           <!-- FCM -->
           <service
               android:name="io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService"
               android:exported="false">
               <intent-filter>
                   <action android:name="com.google.firebase.MESSAGING_EVENT" />
               </intent-filter>
           </service>
       </application>
   </manifest>
   ```

4. **Run:**
   ```bash
   flutter pub get
   flutter clean
   flutter run
   ```

---

## 📧 Setup EmailJS

### **1. Daftar EmailJS:**
- Ke [emailjs.com](https://www.emailjs.com)
- Sign up gratis

### **2. Setup Email Service:**
- Add Email Service → Pilih Gmail/Outlook
- Connect email kamu
- Copy **Service ID**

### **3. Buat 2 Template:**

**Template 1: Restaurant Approved (template_1qa7aam)**
```
Subject: 🎉 Selamat! Restoran Anda Telah Disetujui

Halo {{owner_name}},

Selamat! Restoran {{restaurant_name}} telah disetujui dan sekarang AKTIF di aplikasi Nyam Makanan.

Anda dapat login menggunakan:
Email: {{owner_email}}

Langkah selanjutnya:
1. Login ke aplikasi
2. Lengkapi menu restoran
3. Atur ketersediaan meja
4. Kelola reservasi yang masuk

Selamat bergabung!

Kontak Admin: {{admin_email}}
```

**Template 2: Restaurant Rejected (template_ysvknzl)**
```
Subject: ❌ Data Restoran Ditolak

Halo {{owner_name}},

Mohon maaf, pendaftaran restoran {{restaurant_name}} tidak dapat disetujui.

Alasan Penolakan:
{{rejection_reason}}

Yang perlu diperbaiki:
- Pastikan data administrasi lengkap
- Upload surat izin usaha yang valid
- Pastikan lokasi valid dan dapat diakses
- Foto restoran harus jelas

Anda dapat mendaftar ulang setelah memperbaiki data.

Kontak Admin: {{admin_email}}
```

### **4. Get API Keys:**
- Di EmailJS Dashboard → Account
- Copy:
  - **Service ID**: `service_xxxxx`
  - **Public Key**: `xxxxxxxxxxxxxxx`

### **5. Update `lib/services/email_service.dart`:**
```dart
static const String _serviceId = 'service_xxxxx'; // Ganti!
static const String _publicKey = 'xxxxxxxxxxxxxxx'; // Ganti!
```

---

## 🔧 Initialize di `main.dart`

Update `main.dart`:

```dart
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize FCM
  await FCMService.initialize();
  
  runApp(const MyApp());
}
```

---

## 💡 Cara Pakai

### **1. Saat User Login:**
```dart
// Di auth_provider.dart setelah login berhasil
await FCMService.saveTokenToFirestore(user.id);
```

### **2. Saat Admin Approve/Reject Resto:**
✅ Sudah terintegrasi di `verification_screen.dart`

### **3. Saat Admin Suspend Akun/Resto:**
✅ Sudah terintegrasi di `problematic_accounts_screen.dart` & `problematic_restaurants_screen.dart`

### **4. Saat Pemilik Resto Approve/Reject Reservasi:**
Tambahkan di screen manage reservasi:
```dart
// Saat approve
await FCMService.sendReservationApprovedNotification(
  userId: reservation.userId,
  restaurantName: restaurantName,
  reservationDate: '5 Desember 2025',
  reservationTime: '19:00',
  dpAmount: 'Rp 150.000',
);

// Saat reject
await FCMService.sendReservationRejectedNotification(
  userId: reservation.userId,
  restaurantName: restaurantName,
  rejectionReason: 'Meja penuh',
);

// Saat confirm (setelah bayar DP)
await FCMService.sendReservationConfirmedNotification(
  userId: reservation.userId,
  restaurantName: restaurantName,
  reservationDate: '5 Desember 2025',
  reservationTime: '19:00',
  tableNumber: '5',
  area: 'Indoor',
);
```

### **5. Tambah Notif Badge di AppBar:**
```dart
AppBar(
  actions: [
    StreamBuilder<int>(
      stream: FCMService.getUnreadNotificationsCount(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  ],
)
```

---

## 📱 Testing

### **Test Push Notification:**
1. Install app di HP real device (emulator limited FCM)
2. Login sebagai user
3. Admin approve/reject reservasi
4. Notif muncul di notification bar HP! 🎉

### **Test Email:**
1. Setup EmailJS dengan email kamu
2. Admin approve/reject resto
3. Cek inbox email pemilik resto! 📧

### **Test In-App Notification:**
1. Buka app
2. Tap icon notifikasi di AppBar
3. List notifikasi muncul
4. Tap notif → mark as read ✅

---

## 🎯 Fitur Lengkap:

✅ **Push Notification** → Muncul di HP (notification bar)
✅ **In-App Notification** → List notifikasi dalam app
✅ **Email Notification** → Kirim email ke pemilik resto
✅ **Unread Badge** → Counter notifikasi belum dibaca
✅ **Mark as Read** → Tandai sudah dibaca
✅ **Auto Delete** → Akun/resto dihapus 7 hari setelah suspend
✅ **Template Email** → Design bagus dengan HTML

---

## ⚠️ Catatan Penting:

1. **FCM Token harus disimpan saat login**
2. **EmailJS gratis 200 email/bulan** (cukup untuk development)
3. **Push notif butuh real device** untuk testing penuh
4. **Template ID di EmailJS** harus sama dengan di code

---

## 🐛 Troubleshooting:

**Notifikasi tidak muncul di HP?**
- Pastikan FCM token tersimpan di Firestore
- Cek permission notification di HP
- Test di real device (bukan emulator)

**Email tidak terkirim?**
- Cek Service ID dan Public Key sudah benar
- Pastikan email service di EmailJS sudah connected
- Cek quota EmailJS (max 200/bulan gratis)

**Badge notifikasi tidak update?**
- Pastikan StreamBuilder dipasang di AppBar
- Check Firestore collection 'notifications' ada data

---

Sekarang notifikasi sudah siap! 🎉
