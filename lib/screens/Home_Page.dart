import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cactus_shop/Widgets/MyButton.dart';
import 'package:cactus_shop/Widgets/MySafeScaffold.dart';
import 'package:cactus_shop/constants.dart';
import 'package:cactus_shop/services/FetchUserData.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserType? userType;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _simulateImageLoading(); // نحاكي تحميل الصورة
  }

  Future<void> _loadUser() async {
    final user = await UserDataService.getUserRole();
    setState(() {
      userType = user.userType;
    });
  }

  Future<void> _simulateImageLoading() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _imageLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final imagePath = isPortrait ? "images/logo.jpeg" : "images/logo3.jpg";
    final position = isPortrait ? MainAxisAlignment.end : MainAxisAlignment.center;

    return MySafeScaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _imageLoaded
                ? Image.asset(
              imagePath,
              fit: BoxFit.cover,
            )
                : const Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          if (_imageLoaded)
            Center(
              child: Column(
                mainAxisAlignment: position,
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
                      style: kOutlinedButton,
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
