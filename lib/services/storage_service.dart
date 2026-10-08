// services/storage_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload image to Firebase Storage
  Future<String> uploadImage(File image, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal upload gambar: $e');
    }
  }

  // Upload multiple images
  Future<List<String>> uploadMultipleImages(List<File> images, String basePath) async {
    try {
      List<String> urls = [];
      for (int i = 0; i < images.length; i++) {
        String path = '$basePath/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        String url = await uploadImage(images[i], path);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception('Gagal upload multiple gambar: $e');
    }
  }

  // Delete image from Storage
  Future<void> deleteImage(String url) async {
    try {
      Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Gagal hapus gambar: $e');
    }
  }

  // Get image download URL
  Future<String> getImageUrl(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e) {
      throw Exception('Gagal mengambil URL gambar: $e');
    }
  }
}