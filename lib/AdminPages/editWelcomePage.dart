import 'dart:convert';
import 'dart:io' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:cactus_shop/Widgets/ShowSnackBar.dart';

import '../services/cloudinaryServices.dart';

class EditWelcomeBannerPage extends StatefulWidget {
  const EditWelcomeBannerPage({super.key});

  @override
  State<EditWelcomeBannerPage> createState() => _EditWelcomeBannerPageState();
}

class _EditWelcomeBannerPageState extends State<EditWelcomeBannerPage> {
  File? _imageFile; // للأندرويد
  XFile? _webImageFile; // للويب
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    if (!kIsWeb) {
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
      if (await Permission.storage.isPermanentlyDenied) {
        showSnackBar(context,'تم رفض صلاحية الصور. يرجى تفعيلها من الإعدادات.');
        return;
      }
    }

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImageFile = pickedFile;
          _imageFile = null;
        } else {
          _imageFile = File(pickedFile.path);
          _webImageFile = null;
        }
      });
    }
  }

  Future<String?> _uploadToCloudinary(Uint8List bytes) async {
    // عدل هذه القيم حسب حساب Cloudinary الخاص بك
    const cloudName = 'diuwox1o6';
    const uploadPreset = 'Welcome_Image'; // إذا كنت تستخدم preset
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset; // إذا تستخدم preset (أو احذفها إذا لا)
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'upload.jpg'));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      return data['secure_url'];
    } else {
      return null;
    }
  }

  Future<void> _uploadImage() async {
    if (_webImageFile == null && _imageFile == null) {
      showSnackBar(context, 'يرجى اختيار صورة أولاً');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {

      // 👇 استرجاع رابط الصورة القديمة
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('welcomeBanner')
          .get();

      String oldImageUrl = '';
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('image')) {
          oldImageUrl = data['image'];
        }
      }

      // 👇 قراءة الصورة الجديدة
      final bytes = kIsWeb
          ? await _webImageFile!.readAsBytes()
          : await _imageFile!.readAsBytes();

      // 👇 رفع الصورة الجديدة
      final newImageUrl = await _uploadToCloudinary(bytes);
      if (newImageUrl == null) throw Exception('فشل رفع الصورة');

      // 👇 تحديث Firestore بالصورة الجديدة
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('welcomeBanner')
          .set({'image': newImageUrl});

      // 👇 حذف الصورة القديمة إذا تغيّرت
      if (oldImageUrl.isNotEmpty && oldImageUrl != newImageUrl) {
        await CloudinaryService.deleteImage(oldImageUrl);
      }

      showSnackBar(context, 'تم حفظ الصورة بنجاح');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context, 'فشل في الحفظ: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }


  Widget _previewImage() {
    if (kIsWeb && _webImageFile != null) {
      return Image.network(_webImageFile!.path, height: 250, fit: BoxFit.cover);
    } else if (!kIsWeb && _imageFile != null) {
      return Image.file(_imageFile!, height: 250, fit: BoxFit.cover);
    } else {
      return const Text('لم يتم اختيار صورة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل صورة الترحيب'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _previewImage(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('اختيار صورة'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadImage,
                icon: _isUploading ? const CircularProgressIndicator() : const Icon(Icons.upload),
                label: const Text('حفظ الصورة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
