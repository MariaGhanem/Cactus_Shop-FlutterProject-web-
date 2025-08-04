import 'package:cactus_shop/Widgets/ShowSnackBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../Widgets/AdminButton.dart';
import '../services/timeCounter.dart';

class ViewDiscountCodesPage extends StatefulWidget {
  const ViewDiscountCodesPage({super.key});

  @override
  State<ViewDiscountCodesPage> createState() => _ViewDiscountCodesPageState();
}

class _ViewDiscountCodesPageState extends State<ViewDiscountCodesPage> {
  String? selectedCode; // الكود المختار من Firestore

  @override
  void initState() {
    super.initState();
    _loadSelectedCodeFromFirestore();
  }

  void _loadSelectedCodeFromFirestore() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('currentDiscount').get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          selectedCode = data['code'] as String?;
        });
      }
    }
  }

  Future<void> _updateSelectedCodeOnFirestore(String? code) async {
    final docRef = FirebaseFirestore.instance.collection('settings').doc('currentDiscount');
    if (code == null) {
      await docRef.delete().catchError((_) {}); // حذف المستند لو الكود فارغ
    } else {
      await docRef.set({'code': code}, SetOptions(merge: true));
    }
  }

  // دالة لفحص وجود كود الخصم مسبقاً
  Future<bool> _isCodeExists(String code) async {
    final doc = await FirebaseFirestore.instance.collection('discounts').doc(code).get();
    return doc.exists;
  }

  void _showAddDiscountDialog() {
    final codeController = TextEditingController();
    final percentageController = TextEditingController();

    DateTime? selectedDateTime;
    int? hoursDuration;
    String durationType = 'none'; // none, date, hours

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("إضافة كود خصم"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // إدخال كود الخصم
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'كود الخصم',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // إدخال نسبة الخصم
                    TextField(
                      controller: percentageController,
                      decoration: const InputDecoration(
                        labelText: 'نسبة الخصم (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    const Text("مدة الصلاحية:"),
                    ListTile(
                      title: const Text("لا يوجد (دائم)"),
                      leading: Radio<String>(
                        value: 'none',
                        groupValue: durationType,
                        onChanged: (value) {
                          setState(() {
                            durationType = value!;
                            selectedDateTime = null;
                            hoursDuration = null;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text("تاريخ ووقت الانتهاء"),
                      leading: Radio<String>(
                        value: 'date',
                        groupValue: durationType,
                        onChanged: (value) {
                          setState(() {
                            durationType = value!;
                            hoursDuration = null;
                          });
                        },
                      ),
                    ),
                    if (durationType == 'date')
                      Row(
                        children: [
                          Expanded(
                            child: Text(selectedDateTime == null
                                ? 'لم يتم اختيار التاريخ والوقت'
                                : 'انتهاء الصلاحية: ${selectedDateTime!.toLocal().toString().split('.')[0]}'),
                          ),
                          TextButton(
                            child: const Text('اختر تاريخ ووقت'),
                            onPressed: () async {
                              final now = DateTime.now();
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDateTime ?? now,
                                firstDate: now,
                                lastDate: DateTime(now.year + 5),
                              );
                              if (pickedDate != null) {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: selectedDateTime != null
                                      ? TimeOfDay.fromDateTime(selectedDateTime!)
                                      : TimeOfDay.now(),
                                );
                                if (pickedTime != null) {
                                  setState(() {
                                    selectedDateTime = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  });
                                } else {
                                  setState(() {
                                    selectedDateTime = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                    );
                                  });
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ListTile(
                      title: const Text("مدة صلاحية بالساعات"),
                      leading: Radio<String>(
                        value: 'hours',
                        groupValue: durationType,
                        onChanged: (value) {
                          setState(() {
                            durationType = value!;
                            selectedDateTime = null;
                          });
                        },
                      ),
                    ),
                    if (durationType == 'hours')
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'عدد الساعات',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final h = int.tryParse(val);
                          if (h != null && h > 0) {
                            hoursDuration = h;
                          } else {
                            hoursDuration = null;
                          }
                        },
                      ),
                  ],
                ),
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

                    if (durationType == 'date' && selectedDateTime == null) {
                      showSnackBar(context, 'يرجى اختيار تاريخ ووقت انتهاء صالح');
                      return;
                    }
                    if (durationType == 'hours' && (hoursDuration == null || hoursDuration! <= 0)) {
                      showSnackBar(context, 'يرجى إدخال عدد ساعات صالح');
                      return;
                    }

                    // تحقق من وجود الكود مسبقاً
                    final exists = await _isCodeExists(code);
                    if (exists) {
                      showSnackBar(context, 'هذا الكود موجود بالفعل ⚠️');
                      return;
                    }

                    try {
                      final percent = double.parse(percentage);

                      // حساب تاريخ الانتهاء
                      Timestamp? expirationTimestamp;
                      if (durationType == 'date' && selectedDateTime != null) {
                        expirationTimestamp = Timestamp.fromDate(selectedDateTime!);
                      } else if (durationType == 'hours' && hoursDuration != null) {
                        final expireDate = DateTime.now().add(Duration(hours: hoursDuration!));
                        expirationTimestamp = Timestamp.fromDate(expireDate);
                      }

                      await FirebaseFirestore.instance.collection('discounts').doc(code).set({
                        'percentage': percent,
                        'isActive': true,
                        'createdAt': FieldValue.serverTimestamp(),
                        if (expirationTimestamp != null) 'expirationDate': expirationTimestamp,
                      });

                      showSnackBar(context, 'تمت إضافة كود الخصم ✅');
                      Navigator.pop(context);
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
  }

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
                icon: const Icon(Icons.discount),
                text: "إضافة كود خصم",
                onPressed: _showAddDiscountDialog,
              ),
              if (selectedCode != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "الكود المختار للعرض: $selectedCode",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
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
                    final expirationTimestamp = data['expirationDate'] as Timestamp?;

                    return ListTile(
                      leading: expirationTimestamp != null
                          ? Checkbox(
                        value: selectedCode == code,
                        onChanged: (bool? value) async {
                          if (value == true) {
                            await _updateSelectedCodeOnFirestore(code);
                            if (mounted) {
                              setState(() {
                                selectedCode = code;
                              });
                            }
                          } else {
                            if (selectedCode == code) {
                              await _updateSelectedCodeOnFirestore(null);
                              if (mounted) {
                                setState(() {
                                  selectedCode = null;
                                });
                              }
                            }
                          }
                        },
                      )
                          : null, // لا نعرض Checkbox إن لم يكن هناك تاريخ انتهاء
                      title: Text("الكود: $code"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("نسبة الخصم: $percentage%"),
                          if (expirationTimestamp != null)
                            CountdownTimer(expirationDate: expirationTimestamp.toDate()),
                          if (expirationTimestamp == null)
                            const Text("لا يوجد انتهاء صلاحية"),
                        ],
                      ),
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

                                        // لو تم حذف الكود المختار، نلغي التحديد من Firestore وواجهة
                                        if (selectedCode == code) {
                                          await _updateSelectedCodeOnFirestore(null);
                                          if (mounted) {
                                            setState(() {
                                              selectedCode = null;
                                            });
                                          }
                                        }
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