import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:cactus_shop/Widgets/ShowSnackBar.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

import '../services/cloudinaryServices.dart';
import 'editCategoryPage.dart';

class AddCategoryPage extends StatefulWidget {
  final User user;
  const AddCategoryPage({super.key, required this.user});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final TextEditingController _nameController = TextEditingController();

  File? _imageFile; // للأندرويد
  XFile? _webImageFile; // للويب
  final ImagePicker _picker = ImagePicker();

  late Stream<QuerySnapshot> _categoriesStream;

  @override
  void initState() {
    super.initState();
    _categoriesStream = FirebaseFirestore.instance
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _pickImage() async {
    if (!kIsWeb) {
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
      if (await Permission.storage.isPermanentlyDenied) {
        showSnackBar(
            context, "تم رفض صلاحية الوصول للصور. يرجى تفعيلها من الإعدادات.");
        return;
      }
    }

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

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

  Future<String?> uploadImageToCloudinary(
      Uint8List imageBytes, String fileName) async {
    const cloudName = 'diuwox1o6';
    const uploadPreset = 'Category_Image'; // عدل حسب إعداداتك في Cloudinary
    final url =
    Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
          http.MultipartFile.fromBytes('file', imageBytes, filename: fileName));

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

  Future<void> _uploadCategory() async {
    if (_nameController.text.trim().isEmpty ||
        (_imageFile == null && _webImageFile == null)) {
      showSnackBar(context, "يرجى إدخال اسم التصنيف واختيار صورة");
      return;
    }

    try {
      Uint8List imageBytes;
      String fileName;

      if (kIsWeb) {
        imageBytes = await _webImageFile!.readAsBytes();
        fileName = _webImageFile!.name;
      } else {
        imageBytes = await _imageFile!.readAsBytes();
        fileName = _imageFile!.path.split('/').last;
      }

      final imageUrl = await uploadImageToCloudinary(imageBytes, fileName);
      if (imageUrl == null) {
        showSnackBar(context, 'فشل رفع الصورة إلى Cloudinary');
        return;
      }
      final name = _nameController.text.trim();

      final exists = await FirebaseFirestore.instance
          .collection('categories')
          .where('userId', isEqualTo: widget.user.uid)
          .where('name', isEqualTo: name)
          .get();

      if (exists.docs.isNotEmpty) {
        showSnackBar(context, 'اسم التصنيف مستخدم مسبقًا');
        return;
      }

      await FirebaseFirestore.instance.collection('categories').add({
        'userId': widget.user.uid,
        'name': _nameController.text.trim(),
        'image': imageUrl,
        'createdAt': Timestamp.now(),
      });

      showSnackBar(context, 'تم إضافة التصنيف بنجاح');

      _nameController.clear();
      setState(() {
        _imageFile = null;
        _webImageFile = null;
      });
    } catch (e) {
      showSnackBar(context, 'فشل في الإضافة: $e');
    }
  }

  Future<void> deleteCategoryAndProductImages(String categoryId) async {
    try {
      // 1. جلب جميع المنتجات التي تحتوي على هذا التصنيف فقط
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('categories', isEqualTo: [categoryId]).get();

      // 2. حذف صور المنتجات من Cloudinary
      for (final productDoc in productsSnapshot.docs) {
        final productId = productDoc.id; // هذا هو doc.id وليس productNumber
        await CloudinaryService.deleteAllProductImages(productId);

        // 3. حذف المنتج من قاعدة البيانات بعد حذف الصور
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .delete();
      }

      print('✅ تم حذف جميع صور ومنتجات التصنيف بنجاح.');
    } catch (e) {
      print('❌ حدث خطأ أثناء حذف صور المنتجات أو المنتجات: $e');
    }
  }

  Future<void> _deleteCategory(String docId, String imageUrl) async {
    try {
      final categorySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(docId)
          .get();

      if (!categorySnapshot.exists) {
        showSnackBar(context, 'الفئة غير موجودة.');
        return;
      }

      final categoryName = categorySnapshot['name'];

      // الحصول على كل المنتجات المرتبطة بهذه الفئة
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('categories', arrayContains: categoryName)
          .get();

      if (docId == "QRF5qE5EyeLEXK6JzcFS") {
        // ممنوع حذف فئة "جميع المنتجات"
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("تنبيه"),
            content: Text("لا يمكن حذف فئة جميع المنتجات."),
            actions: [
              TextButton(
                child: Text("حسنًا"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
        return;
      }


      for (final productDoc in productsSnapshot.docs) {
        final productData = productDoc.data();
        final List categories = List.from(productData['categories'] ?? []);
        final List<dynamic> imageUrls = productData['images'] ?? [];

        if (categories.length == 2) {
          // المنتج مرتبط فقط بهذه الفئة وفئة جميع المنتجات

          // حذف الصور من Cloudinary
          for (final imageUrl in imageUrls) {
            if (imageUrl is String && imageUrl.contains("res.cloudinary.com")) {
              await CloudinaryService.deleteImage(imageUrl);
            }
          }

          // حذف المنتج نفسه
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productDoc.id)
              .delete();
        } else {
          // المنتج مرتبط بأكثر من فئة: فقط نحذف الفئة من القائمة
          categories.remove(categoryName);
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productDoc.id)
              .update({'categories': categories});
        }
      }

      // حذف صورة الفئة من Cloudinary إن وُجدت
      if (imageUrl.isNotEmpty) {
        await CloudinaryService.deleteImage(imageUrl);
      }

      // حذف الفئة من Firestore
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(docId)
          .delete();

      showSnackBar(
          context, '✅ تم حذف الفئة وكل المنتجات المرتبطة بها وصورها بنجاح');
    } catch (e) {
      showSnackBar(context, '❌ فشل في الحذف: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة تصنيف'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          textDirection: TextDirection.rtl,
          children: [
            if (kIsWeb && _webImageFile != null)
              Image.network(_webImageFile!.path, height: 100),
            if (!kIsWeb && _imageFile != null)
              Image.file(_imageFile!, height: 100),
            TextButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text('اختيار صورة'),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'اسم التصنيف'),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: CircularProgressIndicator(),
                    ));
                await _uploadCategory();
                Navigator.pop(context);
              },
              style:
              ElevatedButton.styleFrom(backgroundColor: Color(0xFF795548)),
              child: Text('إضافة التصنيف'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _categoriesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(child: Text('لا توجد فئات حتى الآن'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data()! as Map<String, dynamic>;
                      final docId = docs[index].id;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: data['image'] != null
                              ? Image.network(
                            data['image'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                              : Icon(Icons.category, size: 60),
                          title: Row(
                            children: [
                              Text(data['name'] ?? ''),
                              if (docId == "QRF5qE5EyeLEXK6JzcFS")
                                Icon(Icons.lock, color: Colors.grey, size: 18),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditCategoryPage(
                                        categoryId: docId,
                                        currentName: data['name'],
                                        currentImageUrl: data['image'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('تأكيد الحذف'),
                                      content: Text('هل تريد حذف هذا التصنيف؟'),
                                      actions: [
                                        TextButton(
                                          child: Text('لا'),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                        TextButton(
                                          child: Text('نعم'),
                                          onPressed: () async {
                                            Navigator.pop(context); // close confirm dialog
                                              await _deleteCategory(docId, data['image'] ?? '');

                                          },

                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
