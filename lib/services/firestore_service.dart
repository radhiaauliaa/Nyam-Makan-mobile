// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic method to get collection data
  Future<List<Map<String, dynamic>>> getCollectionData(String collection) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data dari $collection: $e');
    }
  }

  // Generic method to add document
  Future<void> addDocument(String collection, String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(id).set(data);
    } catch (e) {
      throw Exception('Gagal menambah data ke $collection: $e');
    }
  }

  // Generic method to update document
  Future<void> updateDocument(String collection, String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(id).update(data);
    } catch (e) {
      throw Exception('Gagal update data di $collection: $e');
    }
  }

  // Generic method to delete document
  Future<void> deleteDocument(String collection, String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
    } catch (e) {
      throw Exception('Gagal hapus data dari $collection: $e');
    }
  }

  // Get document by ID
  Future<Map<String, dynamic>?> getDocumentById(String collection, String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collection).doc(id).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data dari $collection: $e');
    }
  }

  // Get collection with where clause
  Future<List<Map<String, dynamic>>> getCollectionWhere(
    String collection, 
    String field, 
    dynamic value
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data dari $collection: $e');
    }
  }

  // Get collection with ordering
  Future<List<Map<String, dynamic>>> getCollectionOrdered(
    String collection, 
    String field, 
    bool descending
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collection)
          .orderBy(field, descending: descending)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data dari $collection: $e');
    }
  }
}