// =============================================================================
// CREATE ORDER SCREEN (TERMINAL POS)
// Thiết kế: Chia 2 cột. 
// Trái: Lưới sản phẩm để chọn nhanh.
// Phải: Giỏ hàng Sidebar (tính tiền + tạo đơn).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedCategory = 'Mô hình';
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

  void _submitOrder() async {
    final cart = context.read<CartProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    final orderProvider = context.read<OrderProvider>();

    if (currentUser == null) return;
    
    // Tạm tính và thuế (8%)
    final double subTotal = cart.totalAmount;
    final double vat = subTotal * 0.08;
    // Tổng cộng sẽ được tính trong logic của OrderProvider hoặc lưu cứng ở note tạm thời.
    // OrderModel hiện có vatAmount.

    bool success = await orderProvider.createOrderFromCart(
      cart: cart,
      currentUser: currentUser,
      note: 'Khách lẻ. VAT: \$vat - ' + _noteController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo đơn hàng thành công!')),
      );
    } else if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lỗi tạo đơn'),
          content: Text(orderProvider.error ?? 'Đã xảy ra lỗi'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // -----------------------------------------------------------------
          // BÊN TRÁI: Tìm kiếm & Lưới Sản phẩm
          // -----------------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Title, Search, Tabs)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NEO-TOKYO POS', style: AppTextStyles.headlineLarge),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Tìm kiếm sản phẩm, SKU...',
                                prefixIcon: Icon(Icons.search, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Tabs danh mục
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                _buildTab('Mô hình'),
                                _buildTab('Áo thun'),
                                _buildTab('Phụ kiện'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Lưới sản phẩm
                Expanded(
                  child: Consumer<ProductProvider>(
                    builder: (context, productProvider, child) {
                      if (productProvider.isLoading && productProvider.products.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      // Filter logic
                      final filteredProducts = productProvider.products.where((p) {
                        return p.tradeName.toLowerCase().contains(_searchQuery) ||
                               p.barcode.toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (filteredProducts.isEmpty) {
                        return const Center(child: Text('Không tìm thấy sản phẩm', style: TextStyle(color: AppColors.textSecondary)));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, 
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final isOutOfStock = product.stock <= 0;
                          final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ảnh sản phẩm
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                          image: product.imageUrl.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(product.imageUrl),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: product.imageUrl.isEmpty
                                            ? const Icon(Icons.image, size: 48, color: AppColors.neutral)
                                            : null,
                                      ),
                                      // Stock badge
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isOutOfStock 
                                                ? AppColors.surface.withOpacity(0.8) 
                                                : AppColors.secondary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: isOutOfStock ? AppColors.neutral : AppColors.secondary,
                                            ),
                                          ),
                                          child: Text(
                                            isOutOfStock ? 'HẾT HÀNG' : 'IN STOCK',
                                            style: AppTextStyles.labelMonoSmall.copyWith(
                                              color: isOutOfStock ? AppColors.neutral : AppColors.secondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isOutOfStock)
                                        Container(
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                    ],
                                  ),
                                ),
                                // Thông tin sản phẩm
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.barcode.isNotEmpty ? product.barcode : 'SKU-${product.id.substring(0,4)}',
                                        style: AppTextStyles.labelMonoSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.tradeName,
                                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            currencyFormat.format(product.price),
                                            style: AppTextStyles.labelMono.copyWith(color: AppColors.primary),
                                          ),
                                          InkWell(
                                            onTap: isOutOfStock ? null : () {
                                              context.read<CartProvider>().addItem(product, 1);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: isOutOfStock ? Colors.transparent : AppColors.primary.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isOutOfStock ? AppColors.neutral : AppColors.primary,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                size: 16,
                                                color: isOutOfStock ? AppColors.neutral : AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // BÊN PHẢI: Sidebar Giỏ Hàng
          // -----------------------------------------------------------------
          Container(
            width: 360,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(left: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Consumer<CartProvider>(
              builder: (context, cart, child) {
                final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
                final subTotal = cart.totalAmount;
                final vat = subTotal * 0.08; // VAT 8%
                final total = subTotal + vat;

                return Column(
                  children: [
                    // Header giỏ hàng
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                          const SizedBox(width: 12),
                          const Text('Giỏ hàng', style: AppTextStyles.headlineMedium),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '${cart.itemCount} MÓN',
                              style: AppTextStyles.labelMonoSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 1),

                    // Danh sách item
                    Expanded(
                      child: cart.items.isEmpty
                          ? Center(
                              child: Text(
                                'Giỏ hàng trống',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: cart.items.length,
                              itemBuilder: (context, index) {
                                final item = cart.items.values.elementAt(index);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      // Image
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.image, color: AppColors.neutral, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              currencyFormat.format(item.priceAtBuy),
                                              style: AppTextStyles.labelMono.copyWith(color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Tăng giảm SL & Xóa
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 16),
                                            onPressed: () => cart.updateQuantity(item.productId, item.quantity - 1),
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                          Text('${item.quantity}', style: AppTextStyles.labelMono),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 16),
                                            onPressed: () => cart.updateQuantity(item.productId, item.quantity + 1),
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: AppColors.tertiary, size: 16),
                                            onPressed: () => cart.updateQuantity(item.productId, 0),
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Phần tính toán (Tổng tiền)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.border, style: BorderStyle.solid)), // Fallback dashed
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tạm tính', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                              Text(currencyFormat.format(subTotal), style: AppTextStyles.labelMono),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Thuế (VAT 8%)', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                              Text(currencyFormat.format(vat), style: AppTextStyles.labelMono),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: AppColors.neutral),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng\ncộng', style: AppTextStyles.bodyLarge),
                              Text(
                                currencyFormat.format(total),
                                style: AppTextStyles.headlineLarge.copyWith(fontSize: 28),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Nút tạo đơn
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: (cart.items.isEmpty || context.watch<OrderProvider>().isLoading)
                                  ? null
                                  : _submitOrder,
                              icon: context.watch<OrderProvider>().isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.background))
                                  : const Icon(Icons.check_circle_outline, color: AppColors.background),
                              label: Text(
                                context.watch<OrderProvider>().isLoading ? 'Đang tạo...' : 'Xác nhận tạo đơn',
                              ),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        margin: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
