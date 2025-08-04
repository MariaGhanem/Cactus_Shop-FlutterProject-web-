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
  final ScrollController _scrollController = ScrollController();

  String role = 'guest'; // guest, user, admin
  String? userId;
  bool isRoleLoaded = false;

  List<DocumentSnapshot> products = [];
  DocumentSnapshot? lastDoc;
  bool isLoading = false;
  bool hasMore = true;
  final int limit = 6;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    checkUserStatus();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        role = 'guest';
        isRoleLoaded = true;
      });
      fetchProducts(reset: true);
      return;
    }

    userId = user.uid;

    final adminDoc =
    await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();

    setState(() {
      role = adminDoc.exists ? 'admin' : 'user';
      isRoleLoaded = true;
    });

    fetchProducts(reset: true);
  }

  Future<void> fetchProducts({bool reset = false}) async {
    if (isLoading || (!hasMore && !reset)) return;

    if (reset) {
      products.clear();
      lastDoc = null;
      hasMore = true;
    }

    setState(() {
      isLoading = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('products')
        .where('categories', arrayContains: widget.categoryName);

    if (searchQuery.trim().isNotEmpty) {
      query = query
          .orderBy('name')
          .startAt([searchQuery])
          .endAt(['$searchQuery\uf8ff']);
    } else {
      query = query.orderBy('name');

      // 👇 نبدأ من آخر وثيقة فقط إذا ما كنا نعمل reset
      if (lastDoc != null && !reset) {
        query = query.startAfterDocument(lastDoc!);
      }
    }

    query = query.limit(limit);

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      if (searchQuery.isEmpty) {
        lastDoc = snapshot.docs.last;
      }
      products.addAll(snapshot.docs);

      if (snapshot.docs.length < limit) {
        hasMore = false;
      }
    } else {
      hasMore = false;
    }

    setState(() {
      isLoading = false;
    });
  }


  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      fetchProducts();
    }
  }

  void onSearchChanged(String value) {
    searchQuery = value.toLowerCase();
    fetchProducts(reset: true);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'ابحث عن منتج',
                prefixIcon: const Icon(Icons.search),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          Expanded(
            child: products.isEmpty && isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty && !isLoading
                ? const Center(child: Text('لا يوجد منتجات مطابقة'))
                : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemCount: products.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == products.length) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final doc = products[index];
                final data = doc.data()! as Map<String, dynamic>;
                final name = data['name'] ?? '';

                // السعر
                double price = 0.0;
                final sizesWithPrices =
                data['sizesWithPrices'] as List<dynamic>?;
                if (sizesWithPrices != null &&
                    sizesWithPrices.isNotEmpty) {
                  final first =
                  sizesWithPrices[0] as Map<String, dynamic>?;
                  var p = first?['price'];
                  if (p is int) price = p.toDouble();
                  else if (p is double) price = p;
                }

                // الصورة
                String? imageUrl;
                final images = data['images'] as List<dynamic>?;
                if (images != null && images.isNotEmpty) {
                  final firstImage = images[0];
                  if (firstImage is String &&
                      Uri.tryParse(firstImage)?.hasAbsolutePath ==
                          true) {
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
                          if (_loadingProductIds.contains(productId)) {
                            return;
                          }

                          setState(() {
                            _loadingProductIds.add(productId);
                          });

                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ProductPage(productId: productId)));

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
                            child:
                            CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

