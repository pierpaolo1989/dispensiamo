import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final _collection = _firestore.collection('products');

  static Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    final batch = _firestore.batch();

    for (var product in products) {
      final docRef = _collection.doc();
      batch.set(docRef, {
        'name': product['name'],
        'price': product['price'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  static Future<List<Map<String, dynamic>>> getPaginatedProducts(
      String? lastDocId) async {
    Query query = _collection.orderBy('createdAt').limit(10);

    if (lastDocId != null) {
      final lastDoc = await _collection.doc(lastDocId).get();
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': data["name"],
        'price': data['price'],
      };
    }).toList();
  }
}
