// services/menu_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Menu>> getMenusByRestaurantId(String restaurantId) async {
    final querySnapshot = await _firestore
        .collection('menus')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      // Pastikan id dari doc.id bukan dari field
      return Menu.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  // Method untuk create menu
  Future<String> createMenu(Menu menu) async {
    try {
      // Remove id field because Firestore will auto-generate it
      final menuMap = menu.toMap();
      menuMap.remove('id');
      
      final docRef = await _firestore.collection('menus').add(menuMap);
      
      // Update the menu with the generated ID
      await _firestore.collection('menus').doc(docRef.id).update({
        'id': docRef.id,
      });
      
      return docRef.id;
    } catch (e) {
      print('Error creating menu: $e');
      throw e;
    }
  }

  // TAMBAHKAN: Method untuk update menu
  Future<void> updateMenu(Menu menu) async {
    try {
      await _firestore
          .collection('menus')
          .doc(menu.id)
          .update(menu.toMap());
    } catch (e) {
      print('Error updating menu: $e');
      throw e;
    }
  }

  // TAMBAHKAN: Method untuk delete menu
  Future<void> deleteMenu(String menuId) async {
    try {
      await _firestore.collection('menus').doc(menuId).delete();
    } catch (e) {
      print('Error deleting menu: $e');
      throw e;
    }
  }
}