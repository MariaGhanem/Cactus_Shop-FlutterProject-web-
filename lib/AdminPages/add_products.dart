import 'package:cactus_shop/Widgets/ShowSnackBar.dart';

import 'package:cactus_shop/helper/permission.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../helper/Uploda_to_Cloudinary.dart';

class AddProduct extends StatefulWidget {
  final User user;
  const AddProduct({super.key, required this.user});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _usageController = TextEditingController();
  final _quantityController = TextEditingController();
  final _sizeSingleController = TextEditingController();
  final _priceSingleController = TextEditingController();

  List<Uint8List> _mobileImageBytes = [];
  List<XFile> _webImages = [];

  List<String> selectedCategories = [];
  List<Map<String, dynamic>> sizePriceList = [];
  List<String> allCategories = [];

  final picker = ImagePicker();

  bool _isPickingImages = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      allCategories =
          snapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  Future<void> _pickImages() async {
    if (_isPickingImages) return;
    setState(() => _isPickingImages = true);

    try {
      if (!kIsWeb) {
        await requestStoragePermission();
        if (await Permission.storage.isPermanentlyDenied ||
            await Permission.photos.isPermanentlyDenied) {
          showSnackBar(context,
              'تم رفض صلاحية الوصول للصور. يرجى تفعيلها من الإعدادات.');
          return;
        }
      }

      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          if (kIsWeb) {
            _webImages = pickedFiles;
            _mobileImageBytes.clear();
          } else {
            _mobileImageBytes.clear();
            for (var xfile in pickedFiles) {
              xfile.readAsBytes().then((bytes) {
                setState(() {
                  _mobileImageBytes.add(bytes);
                });
              });
            }
            _webImages.clear();
          }
        });
      }
    } catch (e) {
      print('فشل اختيار الصور: $e');
      showSnackBar(context, 'فشل في اختيار الصور');
    } finally {
      setState(() => _isPickingImages = false);
    }
  }

  Future<List<String>> _uploadAllImages() async {
    List<String> uploadedUrls = [];

    if (kIsWeb) {
      for (var xfile in _webImages) {
        final bytes = await xfile.readAsBytes();
        final url =
            await CloudinaryHelper.uploadImageToCloudinary(bytes, xfile.name);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }
    } else {
      int count = 0;
      for (var bytes in _mobileImageBytes) {
        final fileName = 'mobile_image_$count.jpg';
        final url =
            await CloudinaryHelper.uploadImageToCloudinary(bytes, fileName);
        if (url != null) {
          uploadedUrls.add(url);
        }
        count++;
      }
    }

    return uploadedUrls;
  }

  Future<void> _uploadProduct() async {
    if (_isUploading) return;

    if (!_formKey.currentState!.validate() ||
        (kIsWeb ? _webImages.isEmpty : _mobileImageBytes.isEmpty) ||
        selectedCategories.isEmpty ||
        sizePriceList.isEmpty) {
      showSnackBar(context, 'يرجى تعبئة جميع الحقول وإضافة صورة وحجم وسعر');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // تحقق من عدم وجود منتج بنفس الاسم
      final existing = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: _nameController.text.trim())
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        showSnackBar(context, '❗ يوجد منتج بنفس الاسم مسبقًا');
        setState(() => _isUploading = false);
        return;
      }

      final uploadedImageUrls = await _uploadAllImages();

      if (uploadedImageUrls.isEmpty) {
        showSnackBar(context, '❗ يجب رفع صورة واحدة على الأقل.');
        setState(() => _isUploading = false);
        return;
      }

      final countersRef =
          FirebaseFirestore.instance.collection('counters').doc('products');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final counterSnapshot = await transaction.get(countersRef);
        int newProductNumber = 1;
        if (counterSnapshot.exists &&
            counterSnapshot.data()!.containsKey('lastProductNumber')) {
          newProductNumber = (counterSnapshot['lastProductNumber'] as int) + 1;
        }

        transaction.set(countersRef, {'lastProductNumber': newProductNumber},
            SetOptions(merge: true));

        final productRef =
            FirebaseFirestore.instance.collection('products').doc();
        transaction.set(productRef, {
          'userId': widget.user.uid,
          'images': uploadedImageUrls,
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'usage': _usageController.text.trim(),
          'quantity': int.tryParse(_quantityController.text) ?? 0,
          'sizesWithPrices': sizePriceList,
          'categories': selectedCategories,
          'createdAt': Timestamp.now(),
          'productNumber': newProductNumber,
        });
      });

      showSnackBar(context, 'تم إضافة المنتج بنجاح');
      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context, 'فشل الإضافة: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _addSizePrice() {
    if (_sizeSingleController.text.isNotEmpty &&
        _priceSingleController.text.isNotEmpty) {
      setState(() {
        sizePriceList.add({
          'size': _sizeSingleController.text.trim(),
          'price': int.tryParse(_priceSingleController.text) ?? 0.0,
        });
        _sizeSingleController.clear();
        _priceSingleController.clear();
      });
    }
  }

  void _removeSizePrice(Map<String, dynamic> item) {
    setState(() {
      sizePriceList.remove(item);
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

  Widget _buildSelectedImages() {
    if (kIsWeb) {
      return Wrap(
        spacing: 8,
        children: _webImages.map((xfile) {
          return FutureBuilder<Uint8List>(
            future: xfile.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.memory(snapshot.data!,
                        width: 100, height: 100, fit: BoxFit.cover),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _webImages.remove(xfile);
                        });
                      },
                    )
                  ],
                );
              } else {
                return SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(child: CircularProgressIndicator()));
              }
            },
          );
        }).toList(),
      );
    } else {
      return Wrap(
        spacing: 8,
        children: _mobileImageBytes.map((bytes) {
          return Stack(
            alignment: Alignment.topRight,
            children: [
              Image.memory(bytes, width: 100, height: 100, fit: BoxFit.cover),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _mobileImageBytes.remove(bytes);
                  });
                },
              )
            ],
          );
        }).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إضافة منتج'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if ((kIsWeb ? _webImages.length : _mobileImageBytes.length) > 0)
                  _buildSelectedImages()
                else
                  Text("لم يتم اختيار صور", textAlign: TextAlign.right),
                ElevatedButton(
                  onPressed: _isPickingImages ? null : _pickImages,
                  child: _isPickingImages
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('اختيار صور'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'اسم المنتج'),
                  textAlign: TextAlign.right,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'أدخل اسم المنتج' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'الوصف'),
                  textAlign: TextAlign.right,
                ),
                TextFormField(
                  controller: _usageController,
                  decoration: InputDecoration(labelText: 'طريقة الاستخدام'),
                  textAlign: TextAlign.right,
                ),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'الكمية'),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 10),
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
                    IconButton(icon: Icon(Icons.add), onPressed: _addSizePrice),
                  ],
                ),
                ...sizePriceList.map((item) => ListTile(
                      title: Text('${item['size']} - ${item['price']} شيكل',
                          textDirection: TextDirection.rtl),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _removeSizePrice(item),
                      ),
                    )),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child:
                      Text('اختر التصنيفات:', style: TextStyle(fontSize: 16)),
                ),
                Wrap(
                  spacing: 8,
                  children: allCategories.map((cat) {
                    final isSelected = selectedCategories.contains(cat);
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCategories.add(cat);
                          } else {
                            selectedCategories.remove(cat);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadProduct,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF795548)),
                  child: _isUploading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            ),
                            SizedBox(width: 12),
                            Text('جاري الإضافة...',
                                style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : Text('إضافة المنتج'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
