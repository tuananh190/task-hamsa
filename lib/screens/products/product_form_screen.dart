import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product; // Null = Thêm mới, Not null = Edit

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  String _imageUrl = ''; 
  bool _isUploading = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.tradeName;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _imageUrl = widget.product!.imageUrl;
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final productProvider = context.read<ProductProvider>();
    final isAdd = widget.product == null;
    
    final newProduct = ProductModel(
      id: isAdd ? const Uuid().v4() : widget.product!.id,
      internalName: _nameController.text, // Tạm dùng chung tên
      tradeName: _nameController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      stock: int.tryParse(_stockController.text) ?? 0,
      barcode: widget.product?.barcode ?? const Uuid().v4().substring(0, 8),
      isActive: true,
      imageUrl: _imageUrl,
    );

    bool success;
    if (isAdd) {
      success = await productProvider.addProduct(newProduct);
    } else {
      success = await productProvider.updateProduct(newProduct);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAdd ? 'Thêm thành công!' : 'Sửa thành công!')),
      );
      context.pop(); // Đóng modal
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dùng UI giả lập Modal Center Screen
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.6), // Nền mờ đen
      body: Center(
        child: Container(
          width: 600,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.product == null ? 'Thêm Sản Phẩm Mới' : 'Sửa Sản Phẩm',
                      style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.neutral),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // BODY
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TÊN SP
                      Text('TÊN SẢN PHẨM', style: AppTextStyles.labelMonoSmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'Nhập tên sản phẩm...'),
                        validator: (val) => (val == null || val.isEmpty) ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 24),
                      
                      // GIÁ BÁN & TỒN KHO
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GIÁ BÁN', style: AppTextStyles.labelMonoSmall),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '\$ 0.00',
                                    prefixText: 'đ ',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SỐ LƯỢNG TỒN KHO (STOCK)', style: AppTextStyles.labelMonoSmall),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _stockController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: '0'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // UPLOAD ẢNH
                      Text('HÌNH ẢNH SẢN PHẨM', style: AppTextStyles.labelMonoSmall),
                      const SizedBox(height: 8),

                      InkWell(
                        onTap: () async {
                          if (_isUploading) return;
                          
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                          
                          if (pickedFile != null) {
                            setState(() => _isUploading = true);
                            try {
                              Uint8List bytes = await pickedFile.readAsBytes();
                              
                              // Bước 1: Thay API Key của bạn vào đây
                              const String imgbbApiKey = "baced8954215221e4686fc77f51f50ab"; 
                              
                              // Bước 2: Gọi API ImgBB để upload
                              final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
                              final request = http.MultipartRequest('POST', uri);
                              request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'upload.png'));
                              
                              final response = await request.send();
                              final responseData = await response.stream.bytesToString();
                              final jsonResponse = jsonDecode(responseData);
                              
                              if (jsonResponse['success'] == true) {
                                // Lấy được link ảnh thành công
                                String downloadUrl = jsonResponse['data']['url'];
                                
                                if (mounted) {
                                  setState(() {
                                    _imageUrl = downloadUrl;
                                    _isUploading = false;
                                  });
                                }
                              } else {
                                throw Exception(jsonResponse['error']['message'] ?? 'Upload thất bại');
                              }
                            } catch (e) {
                              if (mounted) {
                                setState(() => _isUploading = false);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi upload: $e')));
                              }
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.border, 
                              style: BorderStyle.none, 
                            ),
                          ),
                          // Sử dụng custom painter để vẽ đường viền đứt đoạn
                          child: CustomPaint(
                            painter: _DashedBorderPainter(),
                            child: Center(
                              child: _isUploading
                                  ? const CircularProgressIndicator()
                                  : _imageUrl.isEmpty
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.cloud_upload_outlined, color: AppColors.neutral, size: 48),
                                            const SizedBox(height: 16),
                                            const Text('Kéo thả hoặc Upload Hình ảnh', style: TextStyle(color: Colors.white)),
                                            const SizedBox(height: 8),
                                            Text('PNG, JPG, WEBP (Max 5MB)', style: AppTextStyles.labelMonoSmall),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_circle, color: AppColors.primary, size: 48),
                                            const SizedBox(height: 8),
                                            const Text('Đã tải ảnh lên thành công', style: TextStyle(color: AppColors.primary)),
                                          ],
                                        ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // FOOTER (Actions)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save, size: 18, color: AppColors.background),
                      label: const Text('Lưu'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Vẽ viền đứt nét (Dashed Border) cho khối Upload
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashWidth = 8.0;
    final dashSpace = 6.0;
    
    // Đơn giản hóa: Vẽ viền chữ nhật nét đứt
    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)));
    
    // Dùng PathMetrics để cắt path thành các dash, nhưng vì Flutter không có sẵn drawDashedPath,
    // đây là cách đơn giản vẽ viền tay hoặc dùng package. Ở đây ta vẽ viền đặc mờ làm fallback.
    paint.color = AppColors.neutral.withOpacity(0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
