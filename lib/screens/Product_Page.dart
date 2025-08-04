import 'package:cactus_shop/Widgets/ShowSnackBar.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cactus_shop/constants.dart';
import 'package:cactus_shop/helper/CartClass.dart';
import 'package:cactus_shop/helper/CartProvider.dart';
import 'package:cactus_shop/helper/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ... import statements as is

class ProductPage extends StatefulWidget {
  final String productId;
  const ProductPage({super.key, required this.productId});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Map<String, dynamic>? productData;
  bool isLoading = true;
  String error = '';
  int _currentPage = 0;
  int selectedSizeIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadProduct();

    _pageController.addListener(() {
      int next = _pageController.page?.round() ?? 0;
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  Future<void> _loadProduct() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();
      if (doc.exists) {
        setState(() {
          productData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'المنتج غير موجود';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'حدث خطأ أثناء تحميل المنتج';
        isLoading = false;
      });
    }
  }

  bool _isValidCloudinaryUrl(String url) {
    return url.startsWith('https://res.cloudinary.com/');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = (productData?['images'] as List?)
            ?.whereType<String>()
            .where(_isValidCloudinaryUrl)
            .toList() ??
        [];

    return Scaffold(
      appBar: buildAppBar(
        text: productData?['name'] ?? 'تفاصيل المنتج',
        show: true,
        context: context,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: ListView(
                    children: [
                      SizedBox(
                        height: 360,
                        child: images.isNotEmpty
                            ? Column(
                                children: [
                                  Expanded(
                                    child: PageView.builder(
                                      controller: _pageController,
                                      itemCount: images.length,
                                      itemBuilder: (context, index) {
                                        final imageUrl = images[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child:InteractiveViewer(
                                            panEnabled: true,
                                            minScale: 1,
                                            maxScale: 4,
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      images.length,
                                      (index) => AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: _currentPage == index ? 12 : 8,
                                        height: _currentPage == index ? 12 : 8,
                                        decoration: BoxDecoration(
                                          color: _currentPage == index
                                              ? Colors.brown
                                              : Colors.brown.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Image.asset('images/default.png'),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₪ ${(productData!['sizesWithPrices'] as List).isNotEmpty ? productData!['sizesWithPrices'][selectedSizeIndex]['price'] : 0} ',
                        style: kHeadingOne,
                        textAlign: TextAlign.right,
                      ),
                      Text(productData!['name'] ?? 'اسم المنتج',
                          style: kHeadingOne, textAlign: TextAlign.right),
                      const SizedBox(height: 5),
                      SelectableText(
                        productData!['description'] ?? 'وصف للمنتج',
                        style: kHeadingTwo,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 5),
                      Text('الأحجام المتوفرة',
                          style: kHeadingOne, textAlign: TextAlign.right),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        children: List.generate(
                          (productData!['sizesWithPrices'] as List).length,
                          (index) {
                            final size =
                                productData!['sizesWithPrices'][index]['size'];
                            final price =
                                productData!['sizesWithPrices'][index]['price'];
                            final isSelected = selectedSizeIndex == index;
                            return ChoiceChip(
                              label: Text('₪ $price - $size'),
                              selected: isSelected,
                              selectedColor: Colors.brown[200],
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.brown[900] : Colors.black,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              backgroundColor: Colors.brown[50],

                              onSelected: (_) {
                                setState(() {
                                  selectedSizeIndex = index;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('طريقة الاستخدام',
                          style: kHeadingTwo, textAlign: TextAlign.right),
                      SelectableText(productData!['usage'] ?? '',
                          style: kHeadingTwo, textAlign: TextAlign.right),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final selected = (productData!['sizesWithPrices']
                              as List)[selectedSizeIndex];
                          final imagePath = images.isNotEmpty ? images[0] : '';

                          final cartProvider =
                              Provider.of<CartProvider>(context, listen: false);

                          await cartProvider.addItem(
                            CartItem(
                              id: widget.productId,
                              name: productData!['name'] ?? '',
                              size: selected['size'],
                              price: (selected['price'] as num).toDouble(),
                              image: imagePath,
                              productNumber:
                                  productData!['productNumber'].toString() ??
                                      "",
                              quantity: 1,
                            ),
                          );

                          // يتم الحفظ تلقائياً في addItem() في الكود المرسل سابقاً

                          showSnackBar(context, 'تمت إضافة المنتج إلى السلة');
                        },
                        child: const Center(
                          child: Icon(Icons.add_shopping_cart_sharp,
                              size: 30, color: kBrownColor),
                        ),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.brown[50]),
                          shadowColor: MaterialStateProperty.all(kBrownColor),
                          elevation: MaterialStateProperty.all(9),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('منتجات ذات صلة',
                          style: kHeadingOne, textAlign: TextAlign.right),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('products')
                            .where('categories',
                                arrayContains: productData!['categories'][0])
                            .limit(4)
                            .snapshots(),
                        builder: (ctx, snap) {
                          if (!snap.hasData)
                            return const CircularProgressIndicator();
                          final docs = snap.data!.docs
                              .where((d) => d.id != widget.productId)
                              .toList();
                          if (docs.isEmpty)
                            return const Text('لا توجد منتجات مرتبطة');

                          return SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: docs.length,
                              itemBuilder: (context, i) {
                                final d =
                                    docs[i].data() as Map<String, dynamic>;
                                final imageList = (d['images'] as List?)
                                        ?.whereType<String>()
                                        .where(_isValidCloudinaryUrl)
                                        .toList() ??
                                    [];
                                final img = imageList.isNotEmpty
                                    ? NetworkImage(imageList[0])
                                    : null;

                                final name = d['name'] ?? '';
                                final price =
                                    (d['sizesWithPrices'] as List).isNotEmpty
                                        ? d['sizesWithPrices'][0]['price']
                                        : 0;
                                return SizedBox(
                                  width: 160,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductPage(
                                              productId: docs[i].id),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: img != null
                                                ? Image(
                                                    image: img,
                                                    fit: BoxFit.cover)
                                                : const Center(
                                                    child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        size: 50,
                                                        color: Colors.grey)),
                                          ),
                                          Text(name, style: kHeadingTwo),
                                          Text('₪ $price', style: kHeadingTwo),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
