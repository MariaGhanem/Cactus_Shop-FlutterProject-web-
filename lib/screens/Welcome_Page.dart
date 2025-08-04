import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cactus_shop/constants.dart';
import 'package:cactus_shop/helper/BottomNavigationBar.dart';
import 'package:cactus_shop/helper/app_bar.dart';
import 'package:cactus_shop/Widgets/Image_Display.dart';
import 'package:cactus_shop/Widgets/Separator_Container.dart';

import '../Widgets/DiscountCounter.dart';
import 'CategoryProductsPage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool isAdmin = false;

  // متغيرات بيانات الخصم
  String discountCode = '';
  int discountPercentage = 0;
  DateTime discountExpireDate = DateTime.now().add(const Duration(hours: 4));
  String discountMessage = "خصم حصري لفترة محدودة!";

  // Pagination variables
  final int batchSize = 6;
  List<DocumentSnapshot> categories = [];
  bool isLoadingCategories = false;
  bool hasMoreCategories = true;
  DocumentSnapshot? lastCategoryDoc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 100), () {
      checkIfAdmin();
      loadDiscountData();
      fetchCategories();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        fetchCategories();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: email)
          .get();

      if (mounted) {
        setState(() {
          isAdmin = querySnapshot.docs.isNotEmpty;
        });
      }
    }
  }

  Future<void> loadDiscountData() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('currentDiscount')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final code = data['code'] ?? '';

      if (code.isNotEmpty) {
        final discountDoc =
        await FirebaseFirestore.instance.collection('discounts').doc(code).get();

        if (discountDoc.exists) {
          final discountData = discountDoc.data()!;
          final Timestamp? ts = discountData['expirationDate'];

          if (mounted) {
            setState(() {
              discountCode = code;
              discountPercentage = discountData['percentage'] ?? 0;
              discountMessage = discountData['message'] ?? discountMessage;
              if (ts != null) discountExpireDate = ts.toDate();
            });
          }
        }
      }
    }
  }

  Future<void> fetchCategories() async {
    if (isLoadingCategories || !hasMoreCategories) return;

    setState(() {
      isLoadingCategories = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('categories')
        .orderBy('createdAt', descending: false)
        .limit(batchSize);

    if (lastCategoryDoc != null) {
      query = query.startAfterDocument(lastCategoryDoc!);
    }

    final querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      lastCategoryDoc = querySnapshot.docs.last;
      categories.addAll(querySnapshot.docs);

      if (querySnapshot.docs.length < batchSize) {
        hasMoreCategories = false;
      }
    } else {
      hasMoreCategories = false;
    }

    setState(() {
      isLoadingCategories = false;
    });
  }

  void _navigateToCategory(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsPage(categoryName: categoryName),
      ),
    );
  }

  Widget _buildBanner(String imageUrl) {
    if (imageUrl.isEmpty) return const Text("لا توجد صورة حالياً");

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Text('فشل تحميل الصورة'));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFfcf9f7),
        appBar: buildAppBar(
          text: 'الحنين',
          color: const Color(0xFFeed5d1),
          context: context,
        ),
        body: ListView(
          controller: _scrollController,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('settings')
                    .doc('welcomeBanner')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("لا توجد صورة حالياً");
                  }

                  final bannerData =
                      snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final imageUrl = bannerData['image'] ?? '';

                  return Column(
                    children: [
                      _buildBanner(imageUrl),
                      if (isAdmin)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.pushNamed(context, '/editWelcomeBanner');
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                "مرحباً بكِ في عالم العناية الطبيعية!",
                style: kHeadingOne,
                textAlign: TextAlign.right,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                "اختاري الأفضل لبشرتك و لمنزلك من منتجاتنا المختارة بعناية",
                style: kHeadingTwo,
                textAlign: TextAlign.right,
              ),
            ),

            if (discountCode.isNotEmpty && discountPercentage > 0)
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DiscountCountdownBanner(
                  expirationDate: discountExpireDate,
                  message: discountMessage,
                  discountCode: discountCode,
                  discountPercentage: discountPercentage,
                ),
              ),

            SeparatorContainer(text: 'تسوّقي حسب الفئة'),

            const SizedBox(height: 20),

            categories.isEmpty && isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length + (hasMoreCategories ? 1 : 0),
              gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                if (index == categories.length) {
                  // Loader أثناء تحميل المزيد
                  return const Center(child: CircularProgressIndicator());
                }

                final categoryData =
                categories[index].data() as Map<String, dynamic>;
                final name = categoryData['name'] ?? '';
                final imageUrl = categoryData['image'] ?? '';

                final imageProvider = imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : const AssetImage('images/welcome.jpeg')
                as ImageProvider;

                return ImageDisplay(
                  text: name,
                  imageProvider: imageProvider,
                  onTap: () => _navigateToCategory(name),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(),
      ),
    );
  }
}
