import 'package:cactus_shop/constants.dart';
import 'package:cactus_shop/screens/Product_Page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:cactus_shop/Widgets/ShowSnackBar.dart';

class FavoritesPage extends StatelessWidget {
  final String uid;
  const FavoritesPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("العناصر المفضلة"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لم تضف منتجات للمفضلة بعد'));
          }

          final favoritesDocs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: favoritesDocs.length,
            itemBuilder: (context, index) {
              final favDoc = favoritesDocs[index];
              final productNumber = favDoc.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('products')
                    .doc(productNumber)
                    .get(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final productData = productSnapshot.data!.data() as Map<String, dynamic>;
                  final productName = productData['name'] ?? 'منتج';
                  final images = productData['images'] as List<dynamic>? ?? [];

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          children: [
                            SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: images.isNotEmpty && images[0].toString().startsWith('https://res.cloudinary.com/')
                                  ? Image.network(
                                images[0],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'images/default.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Image.asset(
                                'images/default.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.red),
                                splashRadius: 20,
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .collection('favorites')
                                      .doc(productNumber)
                                      .delete();
                                  showSnackBar(context,'تم الحذف من المفضلة'
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown.shade700.withOpacity(0.88),
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductPage(productId: productNumber),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'عرض التفاصيل',
                                  style: TextStyle(fontSize: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Text(
                            productName,
                            textAlign: TextAlign.center,
                            style: kHeadingTwo.copyWith(
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
