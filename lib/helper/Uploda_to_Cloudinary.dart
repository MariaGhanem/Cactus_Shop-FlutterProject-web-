import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show Uint8List;

class CloudinaryHelper {
  static const String cloudName = 'diuwox1o6';       // عدل حسب حسابك
  static const String uploadPreset = 'Products_Image';  // عدل حسب الـ preset في حسابك

  static Future<String?> uploadImageToCloudinary(Uint8List imageBytes, String fileName) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: fileName));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseData);
      return data['secure_url'];
    } else {
      print('Upload failed: ${response.statusCode}');
      print(responseData);
      return null;
    }
  }
}
