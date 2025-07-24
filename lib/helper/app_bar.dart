import 'package:cactus_shop/services/SignOutMenu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cactus_shop/helper/CartProvider.dart';
import 'package:cactus_shop/constants.dart';

import '../services/FetchUserData.dart';

AppBar buildAppBar({
  required String text,
  Color color = const Color(0xFFeed5d1),
  bool show = false,
  required BuildContext context,
}) {
  return AppBar(
    backgroundColor: Colors.brown[50],
    title: Text(
      text,
      style: kAppBarStyle,
    ),
    centerTitle: true,
    shadowColor: color,
    iconTheme: const IconThemeData(color: kBrownColor),
    automaticallyImplyLeading: show,
    actions: [
      Consumer<CartProvider>(
        builder: (context, cart, child) {
          return Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_sharp, size: 30),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),

      // ✅ Show SignOutMenu only if user is signed in
      if (UserDataService.currentUser != null) SignOutMenu(),
    ],
  );
}
