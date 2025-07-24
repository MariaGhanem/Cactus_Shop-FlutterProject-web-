import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants.dart';
import '../services/FetchUserData.dart';
import '../screens/FavoritesPage.dart';
import '../screens/UserOrdersPage.dart';

Widget buildUserProfileView() {
  return FutureBuilder<String?>(
    future: UserDataService.getCurrentUserUid(),
    builder: (context, uidSnapshot) {
      if (uidSnapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final uid = uidSnapshot.data;

      if (uid == null) {
        return const Center(child: Text('تعذر تحميل المستخدم'));
      }

      return FutureBuilder<String?>(
        future: UserDataService.getCurrentUserName(),
        builder: (context, nameSnapshot) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.brown[50],
                        ),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.brown,
                              child: Icon(Icons.person, size: 40, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "مرحبًا، ${nameSnapshot.data ?? 'مستخدم'}",
                              style: kHeadingTwo.copyWith(fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Divider(height: 0),
                      ListTile(
                        leading: const FaIcon(FontAwesomeIcons.addressCard, color: kBrownColor,),
                        title: const Text("عنوان التوصيل"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.red),
                        title: const Text("مفضلاتي"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>  FavoritesPage(uid: uid)),
                          );
                        },
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.shopping_bag, color: kBrownColor,),
                        title: const Text("طلبياتي"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const UserOrdersPage()),
                          );
                        },
                      ),

                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
