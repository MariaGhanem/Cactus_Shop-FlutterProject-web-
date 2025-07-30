import 'package:cactus_shop/AdminPages/displayOrder.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد أنك تريد حذف هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("الطلبات")),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .orderBy('orderDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data!.docs;

            if (orders.isEmpty) {
              return const Center(child: Text("لا توجد طلبات حالياً"));
            }

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final bool isOpened = order['opened'] == true;

                return Dismissible(
                  key: Key(order.id),
                  direction: DismissDirection.endToStart, // السحب من اليمين لليسار
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    final confirm = await _showDeleteConfirmationDialog(context);
                    if (confirm == true) {
                      // حذف الطلب من Firestore
                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(order.id)
                          .delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم حذف الطلب')),
                      );
                      return true;
                    }
                    return false;
                  },
                  child: ListTile(
                    leading: isOpened
                        ? null
                        : const Icon(Icons.fiber_manual_record,
                        color: Colors.blue, size: 12), // الدائرة الزرقاء
                    title: Text(order['customerName'] ?? 'بدون اسم'),
                    subtitle:
                    Text("المجموع: ${order['finalPrice'].toStringAsFixed(0)} ₪"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsPage(orderData: order),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
        bottomNavigationBar: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: const Text(
                  "مجموع الطلبات المكتملة: 0 ₪",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            }

            final orders = snapshot.data!.docs;

            double totalCompletedPrice = 0;
            for (var order in orders) {
              if (order['status'] == 'completed') {
                final price = order['finalPrice'];
                if (price is num) {
                  totalCompletedPrice += price.toDouble();
                }
              }
            }

            return Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Text(
                "مجموع الطلبات المكتملة: ${totalCompletedPrice.toStringAsFixed(0)} ₪",
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ),
    );
  }
}
