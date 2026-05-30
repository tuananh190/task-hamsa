// =============================================================================
// PRODUCT LIST SCREEN (INVENTORY)
// Thiết kế: 
// Trên: Title, Tổng Stock, Danh sách
// Dưới: Grid View các sản phẩm (ảnh, tag in stock, tên, giá, nút sửa/xoá)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math; // [NEW] Dành cho random test
import 'package:cloud_firestore/cloud_firestore.dart'; // [NEW] Dành cho batch commit

import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import 'product_form_screen.dart'; // Modal form

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isSeeding = false; // [NEW] Trạng thái nút test seed
  bool _isSubmittingSeed = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    // Lắng nghe scroll đã bị loại bỏ

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() { // [NEW]
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showProductForm(BuildContext context, [dynamic product]) {
    showDialog(
      context: context,
      builder: (ctx) => ProductFormScreen(product: product),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: const Text('Hành động này sẽ ẩn sản phẩm khỏi hệ thống, bạn có chắc không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProductProvider>().deleteProduct(id);
            },
            child: const Text('XÓA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          final allProducts = productProvider.products;
          
          final products = allProducts.where((p) {
            return p.tradeName.toLowerCase().contains(_searchQuery) ||
                   p.barcode.toLowerCase().contains(_searchQuery);
          }).toList();
          
          // Tính tổng stock
          int totalStock = 0;
          for (var p in allProducts) { totalStock += p.stock; }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER (Top bar)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Search bar
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm theo tên hoặc mã vạch...',
                          prefixIcon: Icon(Icons.search, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Filter button
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text('Filter'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    // [UPDATE] Ẩn hoàn toàn nút Thêm sản phẩm nếu không phải là Admin
                    if (isAdmin) ...[
                      const SizedBox(width: 16),
                      // Add Product button
                      ElevatedButton.icon(
                        onPressed: () => _showProductForm(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Product'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // [NEW] Nút tạo 100 SP ảo để test Pagination
                      ElevatedButton.icon(
                        onPressed: _isSeeding ? null : _seedProducts,
                        icon: _isSeeding 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.bug_report, size: 18),
                        label: Text(_isSubmittingSeed ? 'Đang tạo...' : 'Tạo 100 SP Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Tiêu đề & Thống kê
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Product Inventory', style: AppTextStyles.headlineLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Manage and track ${products.length} active merchandise listings.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildStatCard('TOTAL STOCK', totalStock.toString()),
                        const SizedBox(width: 16),
                        _buildStatCard('ACTIVE LISTINGS', products.length.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Lưới Sản phẩm
              Expanded(
                child: productProvider.isLoading && products.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4, // [UPDATE] 4 Cột hiển thị
                                childAspectRatio: 0.75, // [UPDATE] Đổi từ 0.65 sang 0.75 để 2 hàng gọn gàng trên màn hình
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                              ),
                              itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
                          final isOutOfStock = product.stock <= 0;
                          final isLowStock = product.stock > 0 && product.stock <= 10;
                          
                          String stockLabel = 'IN STOCK';
                          Color stockColor = AppColors.secondary;
                          if (isOutOfStock) { stockLabel = 'OUT OF STOCK'; stockColor = AppColors.neutral; }
                          else if (isLowStock) { stockLabel = 'LOW STOCK'; stockColor = Colors.orange; }

                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Khu vực ảnh
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                          image: product.imageUrl.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(product.imageUrl),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: product.imageUrl.isEmpty
                                            ? const Icon(Icons.image, size: 64, color: AppColors.neutral)
                                            : null,
                                      ),
                                      // Nhãn Trạng thái Tồn kho
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: stockColor),
                                          ),
                                          child: Text(
                                            stockLabel,
                                            style: AppTextStyles.labelMonoSmall.copyWith(color: stockColor),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Thông tin Text
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product.tradeName,
                                              style: AppTextStyles.headlineSmall,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            currencyFormat.format(product.price),
                                            style: AppTextStyles.labelMono.copyWith(color: AppColors.primary, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Số lượng
                                      Row(
                                        children: [
                                          Icon(
                                            isLowStock || isOutOfStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined, 
                                            size: 16, 
                                            color: stockColor
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${product.stock} in stock',
                                            style: AppTextStyles.bodySmall.copyWith(color: stockColor),
                                          ),
                                        ],
                                      ),
                                      // [UPDATE] Ẩn nút Edit và Thùng rác đối với tài khoản Employee
                                      if (isAdmin) ...[
                                        const SizedBox(height: 16),
                                        // Action Buttons
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => _showProductForm(context, product),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.textPrimary,
                                                  side: const BorderSide(color: AppColors.border),
                                                ),
                                                child: const Text('Edit'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              onPressed: () => _confirmDelete(context, product.id),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.neutral,
                                                side: const BorderSide(color: AppColors.border),
                                                padding: const EdgeInsets.all(12),
                                                minimumSize: const Size(0, 0),
                                              ),
                                              child: const Icon(Icons.delete_outline, size: 20),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // BỎ loading indicator cũ của infinite scroll
                  ],
                ),
              ),
              
              // [NEW] Thanh Phân trang (Pagination Bar) ở ngoài lưới sản phẩm
              if (!productProvider.isLoading && (productProvider.totalKnownPages > 1 || productProvider.products.isNotEmpty))
                _buildPaginationBar(context, productProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelMonoSmall),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  // [NEW] Hàm tự động tạo 100 sản phẩm test
  Future<void> _seedProducts() async {
    setState(() {
      _isSeeding = true;
      _isSubmittingSeed = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      for (int i = 1; i <= 100; i++) {
        final docRef = firestore.collection('products').doc(); // Tự render ID
        final price = (math.Random().nextInt(50) + 1) * 10000.0; // Random 10k - 500k
        final stock = math.Random().nextInt(100) + 1; // Random 1-100
        
        batch.set(docRef, {
          'tradeName': 'Sản phẩm test #$i',
          'barcode': 'TEST-BC-${DateTime.now().millisecondsSinceEpoch}-$i',
          'price': price,
          'costPrice': price * 0.7,
          'stock': stock,
          'category': 'Test Category',
          'imageUrl': 'https://placehold.co/400x400/png?text=Test+Item+$i',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Firestore batch giới hạn tối đa 500 thao tác/lần, 100 là an toàn.
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo thành công 100 sản phẩm test!')),
        );
        // Refresh lại danh sách
        context.read<ProductProvider>().loadProducts(); // [UPDATE] Đổi từ fetchInitialProducts sang loadProducts
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo SP test: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
          _isSubmittingSeed = false;
        });
      }
    }
  }

  // [NEW] Widget Thanh phân trang chuẩn Web
  Widget _buildPaginationBar(BuildContext context, ProductProvider provider) {
    final currentPage = provider.currentPage;
    final totalKnown = provider.totalKnownPages;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nút Trang trước
          OutlinedButton.icon(
            onPressed: currentPage > 1 ? () => provider.goToPage(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Trang trước'),
          ),
          const SizedBox(width: 16),
          
          // Các nút số trang [1] [2] [3]...
          ...List.generate(totalKnown, (index) {
            final page = index + 1;
            final isCurrent = page == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: isCurrent ? null : () => provider.goToPage(page),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent ? AppColors.primary : AppColors.surfaceElevated,
                  foregroundColor: isCurrent ? AppColors.background : AppColors.textPrimary,
                  minimumSize: const Size(40, 40),
                  padding: EdgeInsets.zero,
                  elevation: isCurrent ? 2 : 0,
                ),
                child: Text('$page', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          }),

          const SizedBox(width: 16),
          // Nút Trang sau
          OutlinedButton.icon(
            onPressed: provider.hasMore ? () => provider.goToPage(currentPage + 1) : null,
            label: const Text('Trang sau'),
            icon: const Icon(Icons.chevron_right, size: 18),
            iconAlignment: IconAlignment.end, 
          ),
        ],
      ),
    );
  }
}
