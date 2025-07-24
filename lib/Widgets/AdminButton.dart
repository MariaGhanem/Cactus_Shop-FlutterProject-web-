import 'package:cactus_shop/Widgets/ShowSnackBar.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminButton extends StatelessWidget {
  final Widget Function()? pageBuilder;
  final Icon icon;
  final String text;
  final VoidCallback? onPressed;

  const AdminButton({
    Key? key,
     this.pageBuilder,
    required this.icon,
    required this.text,
     this.onPressed
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ElevatedButton.icon(
      onPressed: onPressed ?? () {
        if (user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => pageBuilder!()),
          );
        } else {
         showSnackBar(context,'يرجى تسجيل الدخول أولاً'
          );
          Navigator.pushNamed(context, '/signInScreen');
        }
      },
      icon: icon,
      label: Text(text),
    );
  }
}