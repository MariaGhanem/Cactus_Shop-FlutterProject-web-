import 'package:cactus_shop/screens/Home_Page.dart';
import 'package:cactus_shop/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cactus_shop/helper/CartProvider.dart';

class SignOutMenu extends StatelessWidget {
  const SignOutMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem<String>(
            value: 'signout',
            child: Text('تسجيل الخروج'),
          ),
        ];
      },
      onSelected: (value) async {
        if (value == 'signout') {
          final cartProvider = Provider.of<CartProvider>(context, listen: false);

          await AuthMethod().signOut(); // تسجيل الخروج من Firebase
          await cartProvider.logout();         // مسح السلة محلياً وتفريغها

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
                (Route<dynamic> route) => false,
          );
        }
      },
    );
  }
}
