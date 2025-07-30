import 'package:cactus_shop/Widgets/ShowSnackBar.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Widgets/AdminButton.dart';

class ViewDiscountCodesPage extends StatelessWidget {
  const ViewDiscountCodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("أكواد الخصم")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('discounts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا توجد أكواد خصم مضافة بعد"));
          }

          final codes = snapshot.data!.docs;

          return Column(
            children: [
              AdminButton(
                onPressed: () {
                  final codeController = TextEditingController();
                  final percentageController = TextEditingController();

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("إضافة كود خصم"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: codeController,
                            decoration: const InputDecoration(
                              labelText: 'كود الخصم',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: percentageController,
                            decoration: const InputDecoration(
                              labelText: 'نسبة الخصم (%)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
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
                            final code = codeController.text.trim();
                            final percentage = percentageController.text.trim();

                            if (code.isEmpty || percentage.isEmpty) {
                              showSnackBar(context, 'يرجى إدخال جميع الحقول');
                              return;
                            }

                            try {
                              final percent = double.parse(percentage);

                              final existing = await FirebaseFirestore.instance
                                  .collection('discounts')
                                  .doc(code)
                                  .get();

                              if (existing.exists) {
                                showSnackBar(context, 'هذا الكود موجود بالفعل ⚠️');
                                return;
                              }

                              await FirebaseFirestore.instance
                                  .collection('discounts')
                                  .doc(code)
                                  .set({
                                'percentage': percent,
                                'isActive': true,
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              showSnackBar(context, 'تمت إضافة كود الخصم ✅');
                              Future.delayed(const Duration(milliseconds: 300), () {
                                Navigator.pop(context);
                              });
                            } catch (e) {
                              showSnackBar(context, 'حدث خطأ أثناء الإضافة ❌');
                            }
                          },
                          child: const Text("إضافة"),
                        ),
                      ],
                    ),
                  );
                },

                icon: const Icon(Icons.discount),
                text: "إضافة كود خصم",
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                    final codeDoc = codes[index];
                    final data = codeDoc.data() as Map<String, dynamic>;
                    final code = codeDoc.id;
                    final percentage = data['percentage'] ?? 0;
                    final isActive = data['isActive'] ?? true;
                    return ListTile(
                      title: Text("الكود: $code"),
                      subtitle: Text("نسبة الخصم: $percentage%"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isActive,
                            onChanged: (value) {
                              FirebaseFirestore.instance
                                  .collection('discounts')
                                  .doc(code)
                                  .update({'isActive': value});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("تأكيد الحذف"),
                                  content: Text("هل أنت متأكد أنك تريد حذف الكود '$code'؟"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("إلغاء"),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('discounts')
                                            .doc(code)
                                            .delete();

                                        Navigator.pop(context);
                                        showSnackBar(context, "تم حذف الكود ✅");
                                      },
                                      child: const Text("حذف"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );

                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
