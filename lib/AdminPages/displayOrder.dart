import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // لإظهار التاريخ بصيغة مقروءة

class OrderDetailsPage extends StatefulWidget {
  final QueryDocumentSnapshot orderData;

  const OrderDetailsPage({super.key, required this.orderData});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  String status = 'pending';

  @override
  void initState() {
    super.initState();

    // تحديث حالة opened
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderData.id)
        .update({'opened': true});

    status = widget.orderData['status'] ?? 'pending';
  }

  void updateStatus(String newStatus) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderData.id)
        .update({'status': newStatus});

    setState(() {
      status = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = widget.orderData['items'] ?? [];
    final discountCode = widget.orderData['discountCode'] ?? '';
    final notes = widget.orderData['notes'] ?? '';
    final instagram = widget.orderData['instagram'] ?? '';
    final totalPrice = widget.orderData['finalPrice'] ?? 0;
    final originalPrice = widget.orderData['originalPrice']; // قد لا يكون موجود دائمًا
    final orderTimestamp = widget.orderData['orderDate'];
    final formattedDate = orderTimestamp != null
        ? DateFormat('yyyy-MM-dd – HH:mm').format(orderTimestamp.toDate())
        : 'غير معروف';

    return Scaffold(
      appBar: AppBar(title: const Text("تفاصيل الطلب")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text("معلومات العميل", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("الاسم: ${widget.orderData['customerName']}"),
            Text("رقم الهاتف: ${widget.orderData['phone']}"),
            Text("إنستغرام: $instagram"),
            Text("العنوان: ${widget.orderData['address']}"),
            Text("كود الخصم: $discountCode"),
            Text("وقت الطلب: $formattedDate"),
          const Divider(height: 32),

          const Text("ملاحظات", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("$notes"),
            const Divider(height: 32),

            const Text("تفاصيل الطلب", style: TextStyle(fontWeight: FontWeight.bold)),
            ...items.map((item) {
              return ListTile(
                title: Text(item['name']),
                subtitle:
                Text("القياس: ${item['size']} - الكمية: ${item['quantity']}"),
                trailing: Text("${item['price']} ₪"),
              );
            }).toList(),

            const Divider(),

            if (discountCode.isNotEmpty )
              Text(
                "السعر قبل الخصم: $originalPrice ₪",
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
            Text("المجموع الكلي: ${totalPrice.toInt()} ₪", style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 24),

            const Text("حالة الطلب", style: TextStyle(fontWeight: FontWeight.bold)),

            CheckboxListTile(
              title: const Text("تم إنجاز الطلب"),
              value: status == 'completed',
              onChanged: (val) {
                if (val == true) {
                  updateStatus('completed');
                } else {
                  updateStatus('pending');
                }
              },
            ),

            CheckboxListTile(
              title: const Text("تم إلغاء الطلب"),
              value: status == 'cancelled',
              onChanged: (val) {
                if (val == true) {
                  updateStatus('cancelled');
                } else {
                  updateStatus('pending');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
