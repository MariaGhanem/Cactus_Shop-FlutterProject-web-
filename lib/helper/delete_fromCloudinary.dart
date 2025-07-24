import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class DeleteCloudinaryHelper {
  static const String cloudName = 'diuwox1o6';
  static const String apiKey = '725275734184246';       // عدلهم
  static const String apiSecret = '6iVigYeWyitBbExZF70TEmJbcd4'; // عدلهم

  // استخرج publicId من رابط الصورة (رابط Cloudinary يحتوي على publicId في العادة)
  static String extractPublicId(String url) {
    // مثال رابط:
    // https://res.cloudinary.com/diuwox1o6/image/upload/v1234567890/folder/image_name.jpg
    // نريد "folder/image_name" فقط (بدون الامتداد)
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // نبحث عن بداية اسم الملف (بعد "upload" مباشرة)
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex + 1 < segments.length) {
        // نأخذ كل المسار بعد upload حتى قبل اسم الملف
        final publicIdSegments = segments.sublist(uploadIndex + 1);
        var last = publicIdSegments.last;
        // إزالة الامتداد (jpg/png/...)
        final dotIndex = last.lastIndexOf('.');
        if (dotIndex != -1) {
          last = last.substring(0, dotIndex);
        }
        publicIdSegments[publicIdSegments.length - 1] = last;
        return publicIdSegments.join('/');
      }
    } catch (e) {
      print('خطأ باستخراج publicId: $e');
    }
    return '';
  }

  static Future<bool> deleteImage(String publicId) async {
    if (publicId.isEmpty) return false;

    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final toSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final signature = sha1.convert(utf8.encode(toSign)).toString();

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');

    final response = await http.post(url, body: {
      'public_id': publicId,
      'api_key': apiKey,
      'timestamp': timestamp,
      'signature': signature,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] == 'ok';
    } else {
      print('فشل حذف الصورة: ${response.body}');
      return false;
    }
  }
}
