import 'package:cactus_shop/constants.dart';
import 'package:cactus_shop/helper/BottomNavigationBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cactus_shop/helper/CartProvider.dart';
import 'package:cactus_shop/Widgets/ShowSnackBar.dart';

import 'ConfirmOrderPage.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    print('عدد عناصر السلة: ${cart.items.length}');


    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('سلة المشتريات', style: kAppBarStyle),
          backgroundColor: Colors.brown[50],
          iconTheme: const IconThemeData(color: kBrownColor),
          centerTitle: true,
        ),
        body: cart.isLoading
            ? const Center(child: CircularProgressIndicator())
            : cart.items.isEmpty
            ? Center(
          child: Text(
            'سلة المشتريات فارغة',
            style: kHeadingOne.copyWith(fontSize: 24),
          ),
        )
            : ListView.builder(
          itemCount: cart.items.length,
          itemBuilder: (context, index) {
            final item = cart.items[index];

            // هنا item.image هو رابط نصي URL
            final imageUrl = item.image;

            return _buildCartItem(
              item,
              (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 100,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 150,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported,
                        size: 50, color: Colors.grey),
                  );
                },
                loadingBuilder:
                    (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 100,
                    height: 150,
                    color: Colors.grey[200],
                    child:
                    Center(child: CircularProgressIndicator()),
                  );
                },
              )
                  : Container(
                width: 100,
                height: 150,
                color: Colors.grey[300],
                child: Icon(Icons.image,
                    size: 50, color: Colors.grey),
              ),
            );
          },
        ),
        bottomNavigationBar: cart.items.isEmpty
            ? CustomBottomNavBar()
            : Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.brown[50],
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع: ${cart.totalPrice.toStringAsFixed(0)} ₪',
                style: kHeadingOne,
              ),
              ElevatedButton(
                onPressed: () {
                  if (cart.items.isEmpty) {
                    showSnackBar(context,'سلة المشتريات فارغة'
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConfirmOrderPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrownColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'تأكيد الطلب',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(dynamic item, Widget imageWidget) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final bool isUnavailable = item.isAvailable == false;
    final screenWidth = MediaQuery.of(context).size.width;

    double imageWidth = screenWidth < 600 ? 100 : 150;
    double imageHeight = screenWidth < 600 ? 150 : 200;
    double fontSize = screenWidth < 600 ? 16 : 20;

    return AbsorbPointer(
      absorbing: isUnavailable,
      child: Opacity(
        opacity: isUnavailable ? 0.6 : 1.0,
        child: Dismissible(
          key: Key(item.name + item.size),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            cart.removeItem(item);
            showSnackBar(context, '${item.name} تمت إزالته من السلة');
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            color: isUnavailable ? Colors.red[50] : null,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: imageWidth,
                    height: imageHeight,
                    child: imageWidget,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.name,
                          style: kHeadingOne.copyWith(
                            fontSize: fontSize,
                            color: isUnavailable ? Colors.red : null,
                            decoration: isUnavailable ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(item.size, style: kHeadingOne.copyWith(fontSize: fontSize - 2)),
                        const SizedBox(height: 6),
                        Text('${item.price} ₪', style: kHeadingOne.copyWith(fontSize: fontSize - 2)),
                        if (isUnavailable)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'هذا المنتج لم يعد متوفرًا',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: fontSize - 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Row(
                              textDirection: TextDirection.ltr,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (item.quantity > 1) {
                                      cart.updateQuantity(item, item.quantity - 1);
                                    }
                                  },
                                  child: FaIcon(
                                    FontAwesomeIcons.minus,
                                    color: kBrownColor,
                                    size: fontSize - 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${item.quantity}', style: kHeadingOne.copyWith(fontSize: fontSize - 2)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    cart.updateQuantity(item, item.quantity + 1);
                                  },
                                  child: FaIcon(
                                    FontAwesomeIcons.plus,
                                    color: kBrownColor,
                                    size: fontSize - 2,
                                  ),
                                ),
                              ],
                            ),
                          )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


}
