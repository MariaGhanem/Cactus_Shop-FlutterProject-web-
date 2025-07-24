import 'dart:async';
import 'dart:convert';

import 'package:cactus_shop/helper/CartClass.dart'; // تعريف CartItem
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  String? _userId;
  bool _isLoading = false;
  StreamSubscription? _productsListener;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.quantity * item.price);

  String get _cartKey => _userId != null ? 'cart_$_userId' : 'guest_cart';

  // تعيين معرف المستخدم الحالي وتشغيل المراقبة
  void setUserId(String? userId) {
    _userId = userId;
    _listenToProductChanges();
  }

  // التبديل بين مستخدم مسجل و ضيف
  Future<void> switchUser(String? userId) async {
    await clearCart(localOnly: true); // مسح السلة الحالية محلياً
    setUserId(userId);

    if (userId != null) {
      await loadCartFromFirebase();
    } else {
      await loadCart();
    }
  }

  // إضافة عنصر للسلة
  Future<void> addItem(CartItem newItem) async {
    final index = _items.indexWhere((item) =>
    item.productNumber == newItem.productNumber && item.size == newItem.size);

    if (index >= 0) {
      _items[index].quantity += newItem.quantity;
    } else {
      _items.add(newItem);
    }
    notifyListeners();
    await saveCart();
  }

  // إزالة عنصر من السلة
  Future<void> removeItem(CartItem item) async {
    _items.removeWhere((i) =>
    i.productNumber == item.productNumber && i.size == item.size);
    notifyListeners();
    await saveCart();
  }

  // تحديث كمية عنصر في السلة
  Future<void> updateQuantity(CartItem item, int newQuantity) async {
    final index = _items.indexWhere((i) =>
    i.productNumber == item.productNumber && i.size == item.size);

    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      notifyListeners();
      await saveCart();
    }
  }

  // مسح السلة، مع خيار حذف من Firebase أو محلي فقط
  Future<void> clearCart({bool localOnly = false}) async {
    _items.clear();
    notifyListeners();

    if (!localOnly && _userId != null) {
      try {
        final itemsRef = FirebaseFirestore.instance
            .collection('carts')
            .doc(_userId)
            .collection('items');

        final itemsSnapshot = await itemsRef.get();
        for (var doc in itemsSnapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        print("Error clearing cart items from Firebase: $e");
      }
    }
  }


  // تسجيل الخروج
  Future<void> logout() async {
    await clearCart(localOnly: true); // مسح السلة المحلية
    setUserId(null); // تعيين المستخدم كضيف
    _items.clear();
    notifyListeners();
    await loadCart(); // تحميل سلة الضيف (غالباً فارغة)

    // تنظيف بيانات سلة الضيف المحلية
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_cart');
  }

  // تسجيل الدخول
  Future<void> login(String userId) async {
    // 1. مسح سلة الضيف الحالية
    _items.clear();
    notifyListeners();

    // 2. تعيين userId الجديد
    _userId = userId;

    // 3. تحميل سلة المستخدم من Firebase
    await loadCartFromFirebase();

    // 4. إعلام listeners بالتغيير
    notifyListeners();
  }

  // حفظ السلة (محلياً للضيف، و Firebase للمستخدم المسجل)
  Future<void> saveCart() async {
    if (_userId == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cartData = _items.map((e) => e.toMap()).toList();
        await prefs.setString(_cartKey, jsonEncode(cartData));
      } catch (e) {
        print("Error saving cart locally: $e");
      }
    } else {
      await saveCartToFirebase();
    }
  }

  // تحميل سلة الضيف من SharedPreferences
  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cartKey);

      if (jsonString != null) {
        final List decoded = jsonDecode(jsonString);
        _items = decoded
            .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _items = [];
      }
    } catch (e) {
      print("Error loading cart locally: $e");
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // حفظ السلة في Firebase
  Future<void> saveCartToFirebase() async {
    if (_userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('carts').doc(_userId).set({
        'items': _items.map((item) => item.toMap()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving cart to Firebase: $e');
    }
  }

  // تحميل سلة المستخدم المسجل من Firebase مع فلترة المنتجات المحذوفة
  Future<void> loadCartFromFirebase() async {
    if (_userId == null || _userId!.isEmpty) {
      print('User ID is null or empty');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      print('Loading cart for user: $_userId');
      final doc = await FirebaseFirestore.instance
          .collection('carts')
          .doc(_userId)
          .get();

      if (doc.exists) {
        print('Cart document exists');
        final data = doc.data();
        if (data != null && data['items'] != null) {
          print('Cart items found: ${data['items']}');
          final items = List<Map<String, dynamic>>.from(data['items']);

          // تحميل العناصر مع التحقق من وجود المنتجات
          final productSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .get();

          final existingProducts = productSnapshot.docs
              .map((doc) => doc['productNumber'].toString())
              .toSet();

          _items = items
              .map((itemData) => CartItem.fromMap(itemData))
              .where((item) => existingProducts.contains(item.productNumber.toString()))
              .toList();

          print('Successfully loaded ${_items.length} items');
        } else {
          print('No items in cart');
          _items = [];
        }
      } else {
        print('No cart document found');
        _items = [];
      }
    } catch (e) {
      print('Error loading cart: $e');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // مراقبة حذف المنتجات من Firebase وتحديث السلة تلقائياً
  void _listenToProductChanges() {
    _productsListener?.cancel();

    _productsListener = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen((snapshot) {
      final existingProductNumbers = snapshot.docs
          .map((doc) => doc['productNumber'])
          .toSet();

      bool removed = false;

      _items.removeWhere((item) {
        final shouldRemove = !existingProductNumbers.contains(item.productNumber);
        if (shouldRemove) removed = true;
        return shouldRemove;
      });

      if (removed) {
        notifyListeners();
        saveCart();
      }
    });
  }

  @override
  void dispose() {
    _productsListener?.cancel();
    super.dispose();
  }
}
