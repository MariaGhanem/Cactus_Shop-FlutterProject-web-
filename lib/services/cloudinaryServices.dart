import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // حذف صورة واحدة من Cloudinary
  static Future<bool> deleteImage(String imageUrl) async {
    final publicId = extractPublicIdFromUrl(imageUrl);
    if (publicId == null) return false;

    final url = Uri.parse('https://cloudinary-delete-api.onrender.com/delete-image');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'public_id': publicId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] == 'ok';
    } else {
      return false;
    }
  }

  // استخراج public_id من رابط الصورة
  static String? extractPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) return null;

      final publicIdParts = pathSegments.sublist(uploadIndex + 1);
      if (publicIdParts.isNotEmpty && publicIdParts[0].startsWith('v')) {
        publicIdParts.removeAt(0);
      }

      final publicIdWithExtension = publicIdParts.join('/');
      final publicId = publicIdWithExtension.split('.').first;
      return publicId;
    } catch (_) {
      return null;
    }
  }

  // حذف جميع صور منتج معين من Cloudinary
  static Future<void> deleteAllProductImages(String productId) async {
    final productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();

    if (productDoc.exists) {
      List<dynamic> imageUrls = productDoc.data()?['images'] ?? [];

      for (var url in imageUrls) {
        if (url is String && url.isNotEmpty) {
          final publicId = CloudinaryService.extractPublicIdFromUrl(url);
          if (publicId != null && publicId.isNotEmpty) {
            await CloudinaryService.deleteImage(url);
          }
        }
      }

      print('✅ تم حذف جميع صور المنتج من Cloudinary.');
    } else {
      print('❌ المنتج غير موجود.');
    }
  }
}
