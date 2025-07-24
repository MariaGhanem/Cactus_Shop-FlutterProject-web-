import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/CartProvider.dart';

class CartInitializer extends StatefulWidget {
  final Widget child;

  const CartInitializer({required this.child});

  @override
  _CartInitializerState createState() => _CartInitializerState();
}

class _CartInitializerState extends State<CartInitializer> {
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final auth = FirebaseAuth.instance;

    // Handle initial auth state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = auth.currentUser;
      if (user != null) {
        Provider.of<CartProvider>(context, listen: false).login(user.uid);
      }
    });

    // Listen for auth changes
    _authSubscription = auth.authStateChanges().listen((user) {
      if (user != null) {
        Provider.of<CartProvider>(context, listen: false).login(user.uid);
      } else {
        Provider.of<CartProvider>(context, listen: false).logout();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}