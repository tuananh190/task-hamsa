// =============================================================================
// PRODUCT LIST SCREEN (INVENTORY)
// Thiết kế: 
// Trên: Title, Tổng Stock, Danh sách
// Dưới: Grid View các sản phẩm (ảnh, tag in stock, tên, giá, nút sửa/xoá)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
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
                          hintText: 'Search inventory...',
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
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // Thay đổi nếu cần responsive
                          childAspectRatio: 0.65, // Chiều cao thẻ hình dài hơn
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
}
