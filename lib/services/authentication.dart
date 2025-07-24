import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/CartProvider.dart';

class AuthMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SignUp User
  Future<String> signupUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    String res = "عذرًا، تعذرت العملية. يرجى إعادة المحاولة";
    try {
      if (email.isNotEmpty &&
          password.isNotEmpty &&
          name.isNotEmpty &&
          phone.isNotEmpty) {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _firestore.collection("users").doc(cred.user!.uid).set({
          'name': name,
          'uid': cred.user!.uid,
          'email': email,
          'phone': phone,
        });
        res = "تم اضافة الحساب بنجاح";
      }
    } catch (err) {
      return err.toString();
    }
    return res;
  }

  // LogIn User
  Future<String> SignInUser({
    required String email,
    required String password,
    required BuildContext context, // Add context parameter
  }) async {
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Initialize cart after successful login
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        await cartProvider.login(cred.user!.uid);

        return "تم تسجيل الدخول بنجاح";
      } else {
        return "الرجاء إدخال جميع الحقول";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "البريد الإلكتروني غير صحيح";
      } else if (e.code == 'wrong-password') {
        return "كلمة المرور غير صحيحة";
      } else {
        return "فشل تسجيل الدخول \n كلمة السر أو المستخدم غير صحيحة ";
      }
    } catch (err) {
      return "حدث خطأ: ${err.toString()}";
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("خطأ في عملية تسجيل الخروج: $e");
    }
  }

  // إرجاع معرّف المستخدم الحالي
  // Future<String?> getUserId() async {
  //   try {
  //     User? user = _auth.currentUser;
  //     if (user != null) {
  //       return user.uid;
  //     } else {
  //       return null;
  //     }
  //   } catch (e) {
  //     print("Error fetching user ID: $e");
  //     return null;
  //   }
  // }
}
