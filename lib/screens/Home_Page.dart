import 'package:cactus_shop/Widgets/MyButton.dart';
import 'package:cactus_shop/Widgets/MySafeScaffold.dart';
import 'package:cactus_shop/constants.dart';
import 'package:cactus_shop/services/FetchUserData.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserType? userType;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }
  Future<void> _loadUser() async {
    final user = await UserDataService.getUserRole(); // مثال: اجلب من دالة async
    setState(() {
      userType = user.userType;
    });
  }
  @override
  Widget build(BuildContext context) {
    return MySafeScaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "images/logo.jpeg",
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MyButton(
                  onPress: () {
                    Navigator.pushNamed(context, '/welcome');
                  },
                  text: 'ابدأ الآن',
                ),
                const SizedBox(height: 5),
                Text(
                  'Cactus Shop',
                  style: kHeading,
                ),
                const SizedBox(height: 5),
                // ✅ إظهار زر "إنشاء حساب" فقط إذا لم يكن المستخدم مسجلاً الدخول
                if (userType == UserType.guest)
                  OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signUpScreen');
                      },
                      child: Text(
                        'إنشاء حساب جديد',
                        style: kButtonStyle.copyWith(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      style: kOutlinedButton),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
