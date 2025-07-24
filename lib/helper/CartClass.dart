class CartItem {
  final String id;
  final String name;
  final String image;
  final double price;
  final String size;
  int quantity;
  final String productNumber;
  bool isAvailable;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.size,
    required this.quantity,
    required this.productNumber, // غيرت إلى required
    this.isAvailable = true,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    try {
      // تحقق من الحقول الأساسية
      if (map['id'] == null ||
          map['name'] == null ||
          map['image'] == null ||
          map['price'] == null ||
          map['size'] == null ||
          map['quantity'] == null) {
        throw FormatException('Missing required fields in cart item');
      }

      // معالجة productNumber بشكل مرن
      final productNumber = _parseProductNumber(map);

      return CartItem(
        id: map['id'].toString(),
        name: map['name'].toString(),
        image: map['image'].toString(),
        price: _toDouble(map['price']),
        size: map['size'].toString(),
        quantity: _toInt(map['quantity']),
        productNumber: productNumber,
        isAvailable: map['isAvailable'] ?? true,
      );
    } catch (e) {
      print('Error parsing CartItem: $e\nData: $map');
      rethrow;
    }
  }

  static String _parseProductNumber(Map<String, dynamic> map) {
    // البحث عن productNumber بأسماء حقول مختلفة
     return map['productNumber']?.toString() ??
    //     map['productId']?.toString() ??
    //     map['product_number']?.toString() ??
        '0'; // قيمة افتراضية إذا لم يوجد
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'price': price,
      'size': size,
      'quantity': quantity,
      'productNumber': productNumber,
      'isAvailable': isAvailable,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          productNumber == other.productNumber &&
          size == other.size;

  @override
  int get hashCode => productNumber.hashCode ^ size.hashCode;
}
