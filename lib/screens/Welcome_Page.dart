import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cactus_shop/constants.dart';
import 'package:cactus_shop/helper/BottomNavigationBar.dart';
import 'package:cactus_shop/helper/app_bar.dart';
import 'package:cactus_shop/Widgets/Image_Display.dart';
import 'package:cactus_shop/Widgets/Separator_Container.dart';

import 'CategoryProductsPage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  Stream<QuerySnapshot>? _categoriesStream;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();

    // تحميل بيانات المشرف بعد وقت بسيط لتخفيف الضغط
    Future.delayed(Duration(milliseconds: 100), () {
      checkIfAdmin();
      loadCategoriesStream();
    });
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

  void loadCategoriesStream() {
    _categoriesStream = FirebaseFirestore.instance
        .collection('categories')
        .orderBy('createdAt', descending: false)
        .snapshots();
    if (mounted) setState(() {}); // لإعادة بناء الواجهة بعد تهيئة الـ stream
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

  void _navigateToCategory(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsPage(categoryName: categoryName),
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
            //املاح فوارة
            SeparatorContainer(text: 'تسوّقي حسب الفئة'),
            const SizedBox(height: 20),
            _categoriesStream == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _categoriesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('حدث خطأ: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.data == null ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('لا توجد فئات متاحة'));
                      }

                      final categories = snapshot.data!.docs;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
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
