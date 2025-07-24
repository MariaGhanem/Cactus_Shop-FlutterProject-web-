import 'package:flutter/material.dart';
import 'package:cactus_shop/helper/app_bar.dart';
import 'package:cactus_shop/helper/BottomNavigationBar.dart';

import '../Widgets/BuildAdminProfile.dart';
import '../Widgets/BuildUserProfile.dart';
import '../services/FetchUserData.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isLoading = true;
  UserType? userType;
  String? userName;

  @override
  void initState() {
    super.initState();
    determineUserType();
  }

  Future<void> determineUserType() async {
    final result = await UserDataService.getUserRole();

    setState(() {
      userType = result.userType;
      userName = result.userName;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(text: 'الملف الشخصي', context: context),
      bottomNavigationBar: CustomBottomNavBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (userType == UserType.guest)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("يرجى تسجيل الدخول أولاً",
                          style: TextStyle(fontSize: 22)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signInScreen');
                        },
                        child: const Text("تسجيل الدخول"),
                      ),
                    ],
                  ),
                )
              : (userType == UserType.admin)
                  ? AdminProfile(context)
                  : buildUserProfileView(),
    );
  }
}
