import 'package:cactus_shop/Widgets/ShowSnackBar.dart';
import 'package:cactus_shop/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../AdminPages/AddCategoryPage.dart';
import '../AdminPages/add_products.dart';
import '../AdminPages/discounts.dart';
import '../screens/Welcome_Page.dart';
import '../services/FetchUserData.dart';
import 'AdminButton.dart';
import 'Separator_Container.dart';

Widget AdminProfile(BuildContext context) {
  final user = UserDataService.currentUser;


  return FutureBuilder<String?>(
    future: UserDataService.getCurrentUserName(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final userName = snapshot.data ?? '';

      return ListView(
        children: [
          const SizedBox(height: 30),
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "مرحباً ",
                style: kHeadingOne,
              ),
              Text(
                userName,
                style: kHeadingOne,
              ),
            ],
          ),
          Center(
            child: Text(
              "أنت الأن مسجل الدخول كمسؤول",
              style: kHeadingTwo,
            ),
          ),
          const SizedBox(height: 40),
          SeparatorContainer(
            text: 'إضافة و تعديل وحذف المنتجات',
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminButton(
                  pageBuilder: () => AddProduct(user: user!),
                  icon: const Icon(Icons.add_photo_alternate),
                  text: 'إضافة منتج جديد',
                ),
                AdminButton(
                  pageBuilder: () => const WelcomePage(),
                  icon: const Icon(Icons.edit_outlined),
                  text: "تعديل / حذف المنتجات",
                ),
                Text("*ملاحظة: حذف و تعديل الصور يتم من خلال الفئات",style: kHeadingTwo.copyWith(color: Colors.red),)
              ],
            ),
          ),
          SeparatorContainer(
            text: 'اضافة و حذف الفئات',
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminButton(
                  pageBuilder: () => AddCategoryPage(user: user!),
                  icon: const Icon(Icons.category),
                  text: "اضافة / حذف فئة",
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SeparatorContainer(
            text: 'المزيد من الإعدادات',
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminButton(
                  onPressed: () {
                    String email = '';

                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              title: const Text("إدارة حسابات الأدمن"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    onChanged: (value) => email = value.trim(),
                                    decoration: const InputDecoration(
                                      labelText: 'البريد الإلكتروني لإضافته كأدمن',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(),
                                  const Text("الحسابات الحالية:"),
                                  const SizedBox(height: 5),
                                  FutureBuilder<QuerySnapshot>(
                                    future: FirebaseFirestore.instance.collection('admins').get(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const CircularProgressIndicator();
                                      }

                                      final admins = snapshot.data!.docs;

                                      if (admins.isEmpty) {
                                        return const Text("لا يوجد حسابات أدمن بعد");
                                      }

                                      return SizedBox(
                                        height: 150,
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: admins.length,
                                          itemBuilder: (context, index) {
                                            final admin = admins[index];
                                            final adminEmail = admin['email'];

                                            return ListTile(
                                              title: Text(adminEmail),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text("تأكيد الحذف"),
                                                      content: Text("هل أنت متأكد أنك تريد إزالة الأدمن '$adminEmail'؟"),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          child: const Text("إلغاء"),
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.red,
                                                          ),
                                                          onPressed: () => Navigator.pop(context, true),
                                                          child: const Text("حذف"),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirm == true) {
                                                    await FirebaseFirestore.instance
                                                        .collection('admins')
                                                        .doc(admin.id)
                                                        .delete();
                                                    showSnackBar(context, 'تم حذف الأدمن ✅');
                                                    setState(() {}); // تحديث القائمة
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("إلغاء"),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (email.isEmpty) {
                                      showSnackBar(context, 'الرجاء إدخال البريد الإلكتروني');
                                      return;
                                    }

                                    try {
                                      final usersSnapshot = await FirebaseFirestore.instance
                                          .collection('users')
                                          .where('email', isEqualTo: email)
                                          .get();

                                      if (usersSnapshot.docs.isEmpty) {
                                        showSnackBar(context, 'الحساب غير موجود في مجموعة المستخدمين ❌');
                                        return;
                                      }

                                      final userDoc = usersSnapshot.docs.first;
                                      final userId = userDoc.id;

                                      final adminDoc = await FirebaseFirestore.instance
                                          .collection('admins')
                                          .doc(userId)
                                          .get();

                                      if (adminDoc.exists) {
                                        showSnackBar(context, 'هذا الحساب موجود مسبقًا كأدمن ⚠️');
                                        return;
                                      }

                                      await FirebaseFirestore.instance.collection('admins').doc(userId).set({
                                        'email': email,
                                        'addedAt': FieldValue.serverTimestamp(),
                                      });

                                      showSnackBar(context, 'تمت إضافة الأدمن بنجاح ✅');
                                      setState(() {}); // لتحديث القائمة بعد الإضافة
                                    } catch (e) {
                                      showSnackBar(context, 'حدث خطأ أثناء الإضافة ❌');
                                    }
                                  },
                                  child: const Text("إضافة"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.settings),
                  text: "إدارة حسابات الأدمن",
                ),


                AdminButton(
                  icon: const Icon(Icons.discount_sharp),
                  text: 'إضافة/حذف/تعديل كود خصم',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ViewDiscountCodesPage()),
                    );
                  },
                )
              ],
            ),
          ),
        ],
      );
    },
  );
}
