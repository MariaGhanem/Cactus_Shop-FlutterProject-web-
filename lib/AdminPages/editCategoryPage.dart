import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../Widgets/ShowSnackBar.dart';
import '../services/cloudinaryServices.dart';

class EditCategoryPage extends StatefulWidget {
  final String categoryId;
  final String currentName;
  final String currentImageUrl;

  const EditCategoryPage({
    super.key,
    required this.categoryId,
    required this.currentName,
    required this.currentImageUrl,
  });

  @override
  State<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  final TextEditingController _nameController = TextEditingController();
  File? _imageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (kIsWeb) {
          _webImageBytes = bytes;
          _imageFile = null;
        } else {
          _imageFile = File(pickedFile.path);
          _webImageBytes = null;
        }
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(Uint8List imageBytes) async {
    const cloudName = 'diuwox1o6';
    const uploadPreset = 'Category_Image';

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.jpg'));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseBody);
      return jsonResponse['secure_url'];
    } else {
      debugPrint('رفع الصورة فشل: $responseBody');
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final oldImageUrl = widget.currentImageUrl; // ✅ حفظ الرابط القديم هنا
      String imageUrl = oldImageUrl;
      bool imageChanged = false;

      if (_imageFile != null || _webImageBytes != null) {
        Uint8List bytes = _webImageBytes ?? await _imageFile!.readAsBytes();
        final uploadedUrl = await _uploadImageToCloudinary(bytes);

        if (uploadedUrl == null) {
          throw Exception('فشل في رفع الصورة الجديدة');
        }

        imageUrl = uploadedUrl;
        imageChanged = true;
      }

      final newName = _nameController.text.trim();

// تحقق من أن الاسم الجديد غير مستخدم من قبل فئة أخرى
      if (newName != widget.currentName) {
        final existing = await FirebaseFirestore.instance
            .collection('categories')
            .where('name', isEqualTo: newName)
            .get();

        if (existing.docs.isNotEmpty) {
          showSnackBar(context, 'اسم الفئة مستخدم مسبقًا');
          setState(() => _isLoading = false);
          return;
        }
      }
// Update category name in the categories collection
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId)
          .update({
        'name': newName,
        'image': imageUrl,
      });

// Update all products that have the old category name
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('categories', arrayContains: widget.currentName)
          .get();

      for (var doc in productsSnapshot.docs) {
        List<dynamic> categories = doc['categories'];
        categories = categories.map((c) => c == widget.currentName ? newName : c).toList();
        await doc.reference.update({'categories': categories});
      }


      if (imageChanged && oldImageUrl.isNotEmpty) {
        await CloudinaryService.deleteImage(oldImageUrl); // ✅ استخدم القديم
      }

      if (mounted) {
        showSnackBar(context, 'تم تحديث الفئة بنجاح');
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
      if (mounted) {
        showSnackBar(context, 'حدث خطأ أثناء التحديث: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (kIsWeb && _webImageBytes != null) {
      imageProvider = MemoryImage(_webImageBytes!);
    } else if (!kIsWeb && _imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else {
      imageProvider = NetworkImage(widget.currentImageUrl);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الفئة')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: imageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 18,
                    child: Icon(Icons.edit, color: Colors.blue.shade700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الفئة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    );
  }
}
