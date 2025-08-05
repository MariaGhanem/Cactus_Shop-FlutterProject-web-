import 'package:cactus_shop/AdminPages/displayOrder.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final ScrollController _scrollController = ScrollController();
  final int _limit = 10;

  List<DocumentSnapshot> _orders = [];
  List<DocumentSnapshot> _filteredOrders = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading &&
        _hasMore &&
        !_isSearching) { // لا تجلب طلبات جديدة أثناء البحث
      _fetchOrders();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      // إذا البحث فارغ، عرض كل الطلبات
      setState(() {
        _isSearching = false;
        _filteredOrders = [];
      });
    } else {
      // فلترة الطلبات حسب رقم الطلب (order.id)
      final filtered = _orders
          .where((order) =>
          order.id.toLowerCase().contains(query.toLowerCase()))
          .toList();

      setState(() {
        _isSearching = true;
        _filteredOrders = filtered;
      });
    }
  }

  Future<void> _fetchOrders() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .limit(_limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      setState(() {
        _orders.addAll(snapshot.docs);
      });
    }

    if (snapshot.docs.length < _limit) {
      _hasMore = false;
    }

    setState(() => _isLoading = false);
  }

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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'ابحث عن رقم الطلب...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white54),
      ),
      style: TextStyle(color: Colors.white, fontSize: 18),
    );
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            setState(() {
              _isSearching = false;
              _filteredOrders = [];
            });
          },
        ),
      ];
    }

    return [
      IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          setState(() {
            _isSearching = true;
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final displayOrders = _isSearching ? _filteredOrders : _orders;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching ? _buildSearchField() : const Text("الطلبات"),
          actions: _buildActions(),
        ),
        body: displayOrders.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          controller: _scrollController,
          itemCount: displayOrders.length + (_hasMore && !_isSearching ? 1 : 0),
          itemBuilder: (context, index) {
            if (!_isSearching && index == displayOrders.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final order = displayOrders[index];
            final bool isOpened = order['opened'] == true;

            return Dismissible(
              key: Key(order.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                final confirm = await _showDeleteConfirmationDialog(context);
                if (confirm == true) {
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(order.id)
                      .delete();
                  setState(() => _orders.removeWhere((o) => o.id == order.id));
                  setState(() => _filteredOrders.removeWhere((o) => o.id == order.id));
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
                    color: Colors.blue, size: 12),
                title: Text(order['customerName'] ?? 'بدون اسم'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("رقم الطلب: ${order.id}"),
                    Text("المجموع: ${order['finalPrice'].toStringAsFixed(0)} ₪"),
                  ],
                ),
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

