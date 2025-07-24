import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/FetchUserData.dart';

class UserOrdersPage extends StatelessWidget {
  const UserOrdersPage({super.key});

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    DateTime date = timestamp.toDate();
    // صيغة التاريخ والوقت بالعربية
    return DateFormat('dd MMMM yyyy - HH:mm', 'ar').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبياتي'),
        centerTitle: true,
        backgroundColor: Colors.brown[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: UserDataService.uid)
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا يوجد طلبات بعد'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final items = (order['items'] as List<dynamic>? ?? []);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عرض الوقت بشكل منسق
                      Text(
                        'وقت الطلب: ${formatTimestamp(order['orderDate'])}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'المنتجات:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),

                      // قائمة المنتجات بشكل أفضل
                      ...items.map((item) {
                        final i = item as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            title: Text(
                              i['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('حجم: ${i['size'] ?? "-"}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('كمية: x${i['quantity'] ?? 0}'),
                                const SizedBox(height: 4),
                                Text(
                                  '${i['price'] ?? 0} ₪',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      const Divider(height: 30),

                      Text(
                        'المجموع النهائي بدون سعر التوصيل : ${order['finalPrice']} ₪',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
