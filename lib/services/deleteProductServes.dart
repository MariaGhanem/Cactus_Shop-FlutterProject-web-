import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteProductAndFavorites(String productId) async {
  final productDoc = FirebaseFirestore.instance.collection('products').doc(productId);
  final productSnapshot = await productDoc.get();

  if (productSnapshot.exists) {
    final productData = productSnapshot.data();
    final int productNumber = productData?['productNumber'];

    // 1. حذف المنتج
    await productDoc.delete();

    // 2. حذف كل المفضلات التي تحتوي على نفس productNumber
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    for (final userDoc in usersSnapshot.docs) {
      final favsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('favorites');

      final favsSnapshot = await favsRef
          .where('productNumber', isEqualTo: productNumber)
          .get();

      for (final favDoc in favsSnapshot.docs) {
        await favDoc.reference.delete();
      }
    }
  }
}
