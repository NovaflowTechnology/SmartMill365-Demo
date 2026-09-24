import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference productCollection =
      FirebaseFirestore.instance.collection('products');
  final CollectionReference equipmentCollection =
      FirebaseFirestore.instance.collection('equipments');
  final CollectionReference processRouteCollection =
      FirebaseFirestore.instance.collection('processRoutes');

  Future<List<Map<String, dynamic>>> fetchProduct() async {
    try {
      QuerySnapshot snapshot = await productCollection.get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching product : $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await productCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  Future<void> addProductWithGeneratedId(
      String number,
      String name,
      String specification,
      String description,
      int batchQuantity,
      int packingQuantity,
      String classification,
      String category,
      String equipment,
      String processRoute) async {
    try {
      QuerySnapshot snapshot = await productCollection.get();
      List<String> existingIds = snapshot.docs.map((doc) => doc.id).toList();

      String nextProductId = generateNextProductId(existingIds);

      await addProduct(
          nextProductId,
          number,
          name,
          specification,
          description,
          batchQuantity,
          packingQuantity,
          classification,
          category,
          equipment,
          processRoute);
    } catch (e) {
      throw Exception('Error adding product with custom ID: $e');
    }
  }

  String generateNextProductId(List<String> existingIds) {
    if (existingIds.isEmpty) {
      return 'PROD0001';
    } else {
      existingIds.sort();
      String lastId = existingIds.last;
      int numericPart = int.parse(lastId.substring(4));
      String nextId = 'PROD${(numericPart + 1).toString().padLeft(4, '0')}';
      return nextId;
    }
  }

  Future<void> addProduct(
      String id,
      String number,
      String name,
      String specification,
      String description,
      int batchQuantity,
      int packingQuantity,
      String classification,
      String category,
      String equipment,
      String processRoute) async {
    try {
      // QuerySnapshot querySnapshot =
      //     await productCollection.where('name', isEqualTo: name).get();
      // if (querySnapshot.docs.isNotEmpty) {
      //   throw Exception('A product with the same name already exists.');
      // }
      await productCollection.doc(id).set({
        'number': number,
        'name': name,
        'specification': specification,
        'description': description,
        'batchQuantity': batchQuantity,
        'packingQuantity': packingQuantity,
        'classification': classification,
        'category': category,
        'equipment': equipment,
        'processRoute': processRoute,
      });

      await equipmentCollection.doc(equipment).update({'product': id});
    } catch (e) {
      throw Exception('Error adding product: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchEquipment() async {
    try {
      QuerySnapshot snapshot = await equipmentCollection.get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching equipments: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProcessRoute() async {
    try {
      QuerySnapshot snapshot = await processRouteCollection.get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching process routes: $e');
    }
  }

  Future<void> editProduct(
      String id,
      String number,
      String name,
      String specification,
      String description,
      int batchQuantity,
      int packingQuantity,
      String classification,
      String category,
      String equipment,
      String processRoute,
      String previousEquipment,
      String previousProcessRoute) async {
    try {
      await productCollection.doc(id).update({
        'number': number,
        'name': name,
        'specification': specification,
        'description': description,
        'batchQuantity': batchQuantity,
        'packingQuantity': packingQuantity,
        'classification': classification,
        'category': category,
        'equipment': equipment,
        'processRoute': processRoute,
      });

      if (equipment != '0') {
        await equipmentCollection.doc(equipment).update({'product': id});
      } else {
        await equipmentCollection
            .doc(previousEquipment)
            .update({'product': '0'});
      }
    } catch (e) {
      throw Exception('Error editing product: $e');
    }
  }
}
