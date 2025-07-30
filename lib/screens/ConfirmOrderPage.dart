import 'package:cactus_shop/services/FetchUserData.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cactus_shop/Widgets/ShowSnackBar.dart';
import '../helper/CartProvider.dart';

class ConfirmOrderPage extends StatefulWidget {
  const ConfirmOrderPage({super.key});

  @override
  State<ConfirmOrderPage> createState() => _ConfirmOrderPageState();
}

class _ConfirmOrderPageState extends State<ConfirmOrderPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountCodeController = TextEditingController();

  double _discountValue = 0.0;
  double _finalPrice = 0.0;
  bool _discountChecked = false;
  String? _discountError;

  final List<String> deliveryAreas = [
    'الضفة الغربية',
    'الداخل المحتل',
    'القدس',
    'نقطة استلام مجانية في جنين',
  ];

  String selectedArea = 'الضفة الغربية';
  int deliveryFee = 20;

  bool _isSubmitting = false;

  void updateDeliveryFee(String area) {
    setState(() {
      selectedArea = area;
      switch (area) {
        case 'الضفة الغربية':
          deliveryFee = 20;
          break;
        case 'الداخل المحتل':
          deliveryFee = 70;
          break;
        case 'القدس':
          deliveryFee = 30;
          break;
        case 'نقطة استلام مجانية في جنين':
          deliveryFee = 0;
          break;
      }
    });
  }

  Future<void> _checkDiscountCode() async {
    final code = _discountCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _discountValue = 0.0;
        _discountChecked = false;
        _discountError = null;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('discounts')
        .doc(code)
        .get();

    if (doc.exists) {
      final data = doc.data();
      final value = data?['percentage'];
      final isActive = data?['isActive'] ?? false;

      if (value != null && value is num && isActive == true) {
        setState(() {
          _discountValue = value.toDouble();
          _discountChecked = true;
          _discountError = null;
          _finalPrice =
              Provider.of<CartProvider>(context, listen: false).totalPrice *
                  (1 - _discountValue / 100);
        });
      } else {
        setState(() {
          _discountValue = 0.0;
          _discountChecked = true;
          _discountError = 'كود الخصم غير مفعل';
          _finalPrice =
              Provider.of<CartProvider>(context, listen: false).totalPrice;
        });
      }
    } else {
      setState(() {
        _discountValue = 0.0;
        _discountChecked = true;
        _discountError = 'كود الخصم غير صحيح';
        _finalPrice =
            Provider.of<CartProvider>(context, listen: false).totalPrice;
      });
    }
  }

  Future<void> _submitOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      // إذا فيه أخطاء في الفورم
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);

    if (cart.items.isEmpty) {
      showSnackBar(context, 'سلة المشتريات فارغة');
      return;
    }
    if (_discountCodeController.text.trim().isNotEmpty &&
        (_discountError != null || !_discountChecked)) {
      showSnackBar(context, 'يرجى التحقق من كود الخصم قبل تأكيد الطلب');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final ordersCollection = FirebaseFirestore.instance.collection('orders');

      final orderData = {
        'userId': UserDataService.uid,
        'customerName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'instagram': _instagramController.text.trim().isEmpty
            ? null
            : _instagramController.text.trim(),
        'address': selectedArea + " " + _addressController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'discountCode': _discountCodeController.text.trim().isEmpty
            ? null
            : _discountCodeController.text.trim(),
        'items': cart.items
            .map((item) => {
          'productId': item.id, // <- التعديل هنا: productId مباشر
          'productNumber': item.productNumber,
          'name': item.name,
          'size': item.size,
          'quantity': item.quantity,
          'price': item.price,
          'total': item.price * item.quantity,
        })
            .toList(),
        'originalPrice': cart.totalPrice,
        'finalPrice': _discountValue > 0 ? _finalPrice : cart.totalPrice,
        'discount': _discountValue > 0
            ? {
          'code': _discountCodeController.text.trim(),
          'percentage': _discountValue,
        }
            : null,
        'orderDate': Timestamp.now(),
        'status': 'new',
        'opened': false,
      };

      await ordersCollection.add(orderData);

      // تحديث الكميات باستخدام productId مباشر بدون استعلام منفصل
      for (var item in cart.items) {
        final productRef =
        FirebaseFirestore.instance.collection('products').doc(item.id);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(productRef);

          if (!snapshot.exists) {
            throw Exception("المنتج غير موجود: ${item.name}");
          }

          final data = snapshot.data() as Map<String, dynamic>;
          final currentQuantity = data['quantity'] ?? 0;

          final remainingQuantity = currentQuantity - item.quantity;

          if (remainingQuantity < 0) {
            throw Exception("الكمية غير كافية للمنتج: ${item.name}");
          }

          transaction.update(productRef, {'quantity': remainingQuantity});
        });
      }

      cart.clearCart();

      showSnackBar(context, 'تم تقديم الطلب بنجاح!');

      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context, 'فشل في تقديم الطلب: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _discountCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تأكيد الطلب'),
          centerTitle: true,
        ),
        body: cart.items.isEmpty
            ? Center(child: Text('سلة المشتريات فارغة'))
            : Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    border: OutlineInputBorder(),
                  ),
                  textDirection: TextDirection.rtl,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال الاسم الكامل';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال رقم الهاتف';
                    }
                    if (!RegExp(r'^\+?\d{8,15}$').hasMatch(value.trim())) {
                      return 'يرجى إدخال رقم هاتف صحيح';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _instagramController,
                  decoration: InputDecoration(
                    labelText: 'حساب الانستجرام (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                  textDirection: TextDirection.ltr,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedArea,
                  decoration: const InputDecoration(labelText: 'منطقة التوصيل'),
                  items: deliveryAreas.map((area) {
                    return DropdownMenuItem<String>(
                      value: area,
                      child: Text(area),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) updateDeliveryFee(value);
                  },
                ),
                SizedBox(height: 12),
                if (selectedArea != 'نقطة استلام مجانية في جنين')
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'العنوان بالتفصيل',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textDirection: TextDirection.rtl,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال العنوان بالتفصيل';
                      }
                      return null;
                    },
                  ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات ',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _discountCodeController,
                  decoration: InputDecoration(
                    labelText: 'كود الخصم',
                    border: OutlineInputBorder(),
                    errorText: _discountError,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.check),
                      onPressed: _checkDiscountCode,
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_discountValue > 0) ...[
                      Text(
                        'السعر قبل الخصم: ${cart.totalPrice.toStringAsFixed(0)} ₪',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        'السعر بعد الخصم: ${_finalPrice.toStringAsFixed(0)} ₪',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ] else
                      Text(
                        'الإجمالي: ${cart.totalPrice.toStringAsFixed(0)} ₪',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'تكلفة التوصيل: $deliveryFee ₪',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'المجموع النهائي: ${((_discountValue > 0 ? _finalPrice : cart.totalPrice) + deliveryFee).toStringAsFixed(0)} ₪',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                    if (_discountCodeController.text.trim().isNotEmpty &&
                        !_discountChecked) {
                      await _checkDiscountCode(); // تحقق من الكود
                      if (_discountError != null) return; // إذا فشل، لا تكمل
                    }
                    _submitOrder(context);
                  },
                  child: _isSubmitting
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text('تأكيد الطلب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
