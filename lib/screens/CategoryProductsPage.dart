import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cactus_shop/Widgets/Display_Product.dart';

import 'Product_Page.dart';

class CategoryProductsPage extends StatefulWidget {
  final String categoryName;

  const CategoryProductsPage({super.key, required this.categoryName});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final Set<String> _loadingProductIds = {};
  String role = 'guest'; // guest, user, admin
  String? userId;
  bool isRoleLoaded = false;

  @override
  void initState() {
    super.initState();
    checkUserStatus();
  }

  Future<void> checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        role = 'guest';
        isRoleLoaded = true;
      });
      return;
    }

    userId = user.uid;

    final adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();

    setState(() {
      print("Current UID: ${user.uid}");
      role = adminDoc.exists ? 'admin' : 'user';
      isRoleLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isRoleLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('categories', arrayContains: widget.categoryName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ أثناء تحميل المنتجات'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text('لا توجد منتجات في هذه الفئة'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250, // يمكن تعديلها لـ 260 أو 270 حسب رغبتك
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.65, // يتحكم في الطول بالنسبة للعرض
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data()! as Map<String, dynamic>;
              final name = data['name'] ?? '';

              // السعر
              double price = 0.0;
              final sizesWithPrices = data['sizesWithPrices'] as List<dynamic>?;
              if (sizesWithPrices != null && sizesWithPrices.isNotEmpty) {
                final first = sizesWithPrices[0] as Map<String, dynamic>?;
                var p = first?['price'];
                if (p is int) price = p.toDouble();
                else if (p is double) price = p;
              }

              // الصورة
              String? imageUrl;
              final images = data['images'] as List<dynamic>?;
              if (images != null && images.isNotEmpty) {
                final firstImage = images[0];
                if (firstImage is String && Uri.tryParse(firstImage)?.hasAbsolutePath == true) {
                  imageUrl = firstImage;
                }
              }

              final quantity = data['quantity'] ?? 1;
              final productId = doc.id;

              final ImageProvider imageProvider;
              if (imageUrl != null && imageUrl.isNotEmpty) {
                imageProvider = NetworkImage(imageUrl);
              } else {
                imageProvider = const AssetImage('images/default.png');
              }
              return Stack(
                children: [
                  DisplayProduct(
                    imageProvider: imageProvider,
                    text: name,
                    price: price,
                    onTap: () async {
                      if (quantity > 0) {
                        if (_loadingProductIds.contains(productId)) return;

                        setState(() {
                          _loadingProductIds.add(productId);
                        });

                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ProductPage(productId: productId)));

                        setState(() {
                          _loadingProductIds.remove(productId);
                        });
                      }
                    },
                    role: role,
                    productId: productId,
                    userId: userId,
                    quantity: quantity,
                  ),
                  if (_loadingProductIds.contains(productId))
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
