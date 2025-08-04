import 'dart:convert';
import 'package:cactus_shop/Widgets/ShowSnackBar.dart';

import 'package:cactus_shop/helper/permission.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../services/cloudinaryServices.dart';

class EditProductPage extends StatefulWidget {
  final String productId;

  const EditProductPage({super.key, required this.productId});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _usageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _sizeSingleController = TextEditingController();
  final _priceSingleController = TextEditingController();
  bool _isLoading = false;


  // لتخزين الصور الجديدة (XFile للويب و bytes للأندرويد)
  List<Uint8List> _mobileImageBytes = [];
  List<XFile> _webImages = [];

  // تصنيفات مختارة وقائمة احجام واسعار
  List<String> selectedCategories = [];
  List<Map<String, dynamic>> sizePriceList = [];
  List<String> allCategories = [];

  // روابط الصور القديمة
  List<String> existingImageUrls = [];

  // روابط الصور الجديدة بعد رفعها (سنستخدمها في التحديث)
  List<String> newUploadedImageUrls = [];

  // صور سيتم حذفها (روابط)
  List<String> imagesToDelete = [];

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _fetchProductData();
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      allCategories = snapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  Future<void> _fetchProductData() async {
    final productDoc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
    if (productDoc.exists) {
      final data = productDoc.data()!;
      _nameController.text = data['name'];
      _descriptionController.text = data['description'];
      _usageController.text = data['usage'];
      _quantityController.text = data['quantity'].toString();
      sizePriceList = List<Map<String, dynamic>>.from(data['sizesWithPrices']);
      selectedCategories = List<String>.from(data['categories']);
      existingImageUrls = List<String>.from(data['images'] ?? []);
      setState(() {});
    }
  }

  Future<void> _pickImages() async {
    if (!kIsWeb) {
      await requestStoragePermission();
      if (await Permission.storage.isPermanentlyDenied || await Permission.photos.isPermanentlyDenied) {
       showSnackBar(context,'تم رفض صلاحية الوصول للصور. يرجى تفعيلها من الإعدادات.');
        return;
      }
    }

    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      if (!kIsWeb) {
        _mobileImageBytes.clear();
        for (var xfile in pickedFiles) {
          final bytes = await xfile.readAsBytes();
          _mobileImageBytes.add(bytes);
        }
        _webImages.clear();
      } else {
        _webImages = pickedFiles;
        _mobileImageBytes.clear();
      }
      setState(() {});
    }
  }

  // رفع صورة واحدة إلى Cloudinary وإرجاع رابطها
  Future<String?> uploadImageToCloudinary(Uint8List imageBytes, String fileName) async {
    const cloudName = 'diuwox1o6'; // عدل هذا حسب حسابك
    const uploadPreset = 'Products_Image'; // عدل حسب ما أنشأت في Cloudinary
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

  // رفع جميع الصور الجديدة إلى Cloudinary وجلب روابطها
  Future<void> _uploadNewImages() async {
    newUploadedImageUrls.clear();

    try {
      if (kIsWeb) {
        for (var xfile in _webImages) {
          final bytes = await xfile.readAsBytes();
          final url = await uploadImageToCloudinary(bytes, xfile.name);
          if (url != null) {
            newUploadedImageUrls.add(url);
          }
        }
      } else {
        int counter = 0;
        for (var bytes in _mobileImageBytes) {
          // اسم ملف مؤقت
          final fileName = 'mobile_image_$counter.jpg';
          final url = await uploadImageToCloudinary(bytes, fileName);
          if (url != null) {
            newUploadedImageUrls.add(url);
          }
          counter++;
        }
      }
    } catch (e) {
      print('Error uploading images: $e');
    }
  }


  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      showSnackBar(context, 'يرجى تعبئة جميع الحقول المطلوبة');
      return;
    }
// تحقق من عدم وجود منتج آخر بنفس الاسم
    final existing = await FirebaseFirestore.instance
        .collection('products')
        .where('name', isEqualTo: _nameController.text.trim())
        .get();

    final isDuplicate = existing.docs.any((doc) => doc.id != widget.productId);
    if (isDuplicate) {
      showSnackBar(context, '❗ يوجد منتج آخر بنفس الاسم مسبقًا');
      return;
    }

    setState(() {

    });

    try {
      // رفع الصور الجديدة أولاً
      await _uploadNewImages();

      // جهز قائمة الصور النهائية بعد حذف الصور التي تم اختيار حذفها و إضافة الصور الجديدة
      List<String> finalImageUrls = existingImageUrls.where((url) => !imagesToDelete.contains(url)).toList();
      finalImageUrls.addAll(newUploadedImageUrls);

      // تحقق من وجود صورة واحدة على الأقل بعد رفع الصور الجديدة
      if (finalImageUrls.isEmpty) {
        showSnackBar(context, '❗ يجب الإبقاء على صورة واحدة على الأقل.');
        return;
      }

      final currentDoc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
      final currentData = currentDoc.data() ?? {};

      final name = _nameController.text.trim().isEmpty ? currentData['name'] : _nameController.text.trim();
      final description = _descriptionController.text.trim().isEmpty ? currentData['description'] : _descriptionController.text.trim();
      final usage = _usageController.text.trim().isEmpty ? currentData['usage'] : _usageController.text.trim();
      final quantityText = _quantityController.text.trim();
      final quantity = quantityText.isEmpty ? currentData['quantity'] : int.tryParse(quantityText) ?? currentData['quantity'];
      final updatedSizes = sizePriceList.isEmpty ? currentData['sizesWithPrices'] : sizePriceList;
      final updatedCategories = selectedCategories.isEmpty ? currentData['categories'] : selectedCategories;

      // تحديث المستند
      await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
        'images': finalImageUrls,
        'name': name,
        'description': description,
        'usage': usage,
        'quantity': quantity,
        'sizesWithPrices': updatedSizes,
        'categories': updatedCategories,
        'updatedAt': Timestamp.now(),
      });

      // حذف الصور من Cloudinary بعد التحديث (لأننا تأكدنا من وجود صور)
      for (var url in imagesToDelete) {

        await CloudinaryService.deleteImage(url);

      }
      imagesToDelete.clear();

      showSnackBar(context, '✅ تم تحديث المنتج بنجاح');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context, '❌ فشل التحديث: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  void _addSizePrice() {
    if (_sizeSingleController.text.isNotEmpty && _priceSingleController.text.isNotEmpty) {
      setState(() {
        if (!sizePriceList.any((item) => item['size'] == _sizeSingleController.text.trim())) {
          sizePriceList.add({
            'size': _sizeSingleController.text.trim(),
            'price': int.tryParse(_priceSingleController.text) ?? 0.0,
          });
        }
        _sizeSingleController.clear();
        _priceSingleController.clear();
      });
    }
  }

  void _removeSize(String size) {
    setState(() {
      sizePriceList.removeWhere((item) => item['size'] == size);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _usageController.dispose();
    _quantityController.dispose();
    _sizeSingleController.dispose();
    _priceSingleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل منتج'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // عرض الصور القديمة (روابط)
                Text('الصور الحالية:', style: TextStyle(fontSize: 16)),
                Wrap(
                  spacing: 8,
                  children: existingImageUrls.map((url) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.network(url, height: 100, width: 100, fit: BoxFit.cover),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              imagesToDelete.add(url);
                              existingImageUrls.remove(url);
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                ),

                const SizedBox(height: 10),

                // عرض الصور الجديدة التي اختيرت لكن لم ترفع بعد
                Text('صور جديدة:', style: TextStyle(fontSize: 16)),
                Wrap(
                  spacing: 8,
                  children: [
                    ..._mobileImageBytes.map((bytes) => Image.memory(bytes, height: 100, width: 100, fit: BoxFit.cover)),
                    ..._webImages.map((xfile) => FutureBuilder<Uint8List>(
                      future: xfile.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          return Image.memory(snapshot.data!, height: 100, width: 100, fit: BoxFit.cover);
                        } else {
                          return SizedBox(
                            height: 100,
                            width: 100,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                      },
                    )),
                  ],
                ),

                ElevatedButton(onPressed: _pickImages, child: Text('إضافة صور جديدة')),

                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'اسم المنتج'),
                  textAlign: TextAlign.right,
                  validator: (value) => value == null || value.isEmpty ? 'أدخل اسم المنتج' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'الوصف'),
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 1,
                ),
                TextFormField(
                  controller: _usageController,
                  decoration: InputDecoration(labelText: 'طريقة الاستخدام'),
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 1,
                ),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'الكمية'),
                  textAlign: TextAlign.right,
                ),

                const SizedBox(height: 10),

                // إضافة حجم وسعر
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sizeSingleController,
                        decoration: InputDecoration(labelText: 'الحجم'),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _priceSingleController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'السعر'),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addSizePrice,
                    )
                  ],
                ),

                // عرض الاحجام والأسعار
                ...sizePriceList.map((item) => ListTile(
                  title: Text('${item['size']} - ${item['price']} شيكل', textDirection: TextDirection.rtl),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _removeSize(item['size']);
                    },
                  ),
                )),

                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text('اختر التصنيفات:', style: TextStyle(fontSize: 16)),
                ),

                Wrap(
                  spacing: 8.0,
                  children: allCategories.map((category) {
                    final isSelected = selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCategories.add(category);
                          } else {
                            selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF795548),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text('تحديث المنتج'),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
