import 'package:auto_size_text/auto_size_text.dart';
import 'package:cactus_shop/Widgets/ShowSnackBar.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cactus_shop/constants.dart';

import '../AdminPages/EditProductPage.dart';
import '../services/cloudinaryServices.dart';
import '../services/deleteProductServes.dart';

class DisplayProduct extends StatefulWidget {
  final ImageProvider imageProvider;
  final String text;
  final double price;
  final VoidCallback onTap;
  final String? role; // admin, user, null
  final String? productId;
  final int quantity;
  final String? userId;

  const DisplayProduct({
    super.key,
    required this.imageProvider,
    required this.text,
    required this.price,
    required this.onTap,
    this.role,
    this.productId,
    this.userId,
    required this.quantity,
  });

  @override
  State<DisplayProduct> createState() => _DisplayProductState();
}

class _DisplayProductState extends State<DisplayProduct> {
  bool isFavorite = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print(widget.role);
    checkIfFavorite();
  }

  Future<void> checkIfFavorite() async {
    if (widget.userId == null || widget.productId == null) {
      setState(() {
        isFavorite = false;
        isLoading = false;
      });
      return;
    }
    final favDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('favorites')
        .doc(widget.productId)
        .get();

    setState(() {
      isFavorite = favDoc.exists;
      isLoading = false;
    });
  }

  Future<void> toggleFavorite() async {
    if (widget.userId == null || widget.productId == null) {
      showSnackBar(context, 'يجب تسجيل الدخول أولاً');
      return;
    }

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('favorites')
        .doc(widget.productId);

    setState(() {
      isFavorite = !isFavorite;
    });

    if (isFavorite) {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      final productNumber = productDoc.data()?['productNumber'] ?? 0;

      await favRef.set({
        'name': widget.text,
        'productNumber': productNumber,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await favRef.delete();
    }
  }

  void deleteProduct(BuildContext context) async {
    if (widget.productId != null) {
      // احذف الصور من Cloudinary
      await CloudinaryService.deleteAllProductImages(widget.productId!);

      // احذف المنتج من Firestore
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .delete();

      showSnackBar(context, 'تم حذف المنتج مع جميع صوره');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GestureDetector(
        // لا تسمح بالضغط إذا الكمية صفر
        onTap: widget.quantity > 0 ? widget.onTap : null,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                    child: AspectRatio(
                      aspectRatio: 2 / 2,
                      child: Image(
                        image: widget.imageProvider,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),

                  // إذا الكمية صفر، نعرض الشريط الأحمر
                  if (widget.quantity == 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.red.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        child: const Text(
                          'نفذت الكمية',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  if (widget.role == "admin") ...[
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        onPressed: () async {
                          if (widget.productId != null) {
                            // تأكيد الحذف (اختياري، يمكن إضافته)
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('تأكيد الحذف'),
                                content: Text('هل أنت متأكد من حذف المنتج؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text('إلغاء'),
                                  ),
                                  TextButton(
                                    onPressed: ()async{
                                      await CloudinaryService.deleteAllProductImages(widget.productId!);
                                      Navigator.of(context).pop(true);},
                                    child: Text('حذف'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldDelete ?? false) {
                              await deleteProductAndFavorites(widget.productId!);
                              showSnackBar(context, "تم حذف المنتج");
                            }
                          }
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ),

                    Positioned(
                      top: 5,
                      left: 5,
                      child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProductPage(
                                      productId: widget.productId!),
                                ),
                              )),
                    ),
                  ] else
                    Positioned(
                      top: 5,
                      right: 5,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : (widget.role == "user"
                          ? IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: widget.quantity > 0 ? toggleFavorite : null,
                      )
                          : IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.grey),
                        onPressed: () {
                          // إذا مش مسجل دخول، نعرض ديالوج طلب تسجيل الدخول
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('يرجى تسجيل الدخول'),
                              content: const Text('يجب تسجيل الدخول لإضافة المنتج للمفضلة.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('حسناً'),
                                ),
                              ],
                            ),
                          );
                        },
                      )),
                    ),

                ],
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    AutoSizeText(
                      widget.text,
                      style: kHeadingTwo.copyWith(fontSize: 19),
                      maxLines: 1,  // أقصى عدد أسطر مسموح
                      minFontSize: 12, // أقل حجم ممكن للنص
                      overflowReplacement: Text(
                        widget.text,
                        style: kHeadingTwo.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "${widget.price}₪",
                      style: kHeadingTwo.copyWith( fontSize: 14),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
