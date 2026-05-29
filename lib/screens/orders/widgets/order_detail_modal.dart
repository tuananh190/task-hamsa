import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as Math;

import '../../../core/theme/app_theme.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_provider.dart';

void showOrderDetailModal(BuildContext context, OrderModel order, bool isAdmin) {
  showDialog(
    context: context,
    builder: (ctx) => _OrderDetailModal(order: order, isAdmin: isAdmin),
  );
}

class _OrderDetailModal extends StatelessWidget {
  final OrderModel order;
  final bool isAdmin;

  const _OrderDetailModal({required this.order, required this.isAdmin});

  String _translateStatus(String status) {
    switch (status) {
      case 'new_order': return 'Mới tạo';
      case 'processing': return 'Chờ xử lý';
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new_order': return AppColors.primary;
      case 'processing': return AppColors.secondary;
      case 'completed': return Colors.blue;
      case 'cancelled': return AppColors.error;
      default: return AppColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final statusColor = _getStatusColor(order.status);
    final isNew = order.status == 'new_order';
    final isProcessing = order.status == 'processing';

    return Center(
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 40,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Text('Chi Tiết Đơn Hàng', style: AppTextStyles.headlineMedium),
                  const SizedBox(width: 16),
                  // Badge Mã đơn
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                    ),
                    child: Text(
                      '#${order.id.substring(Math.max(0, order.id.length - 6)).toUpperCase()}',
                      style: AppTextStyles.labelMono.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const Spacer(),
                  // Badge Trạng thái
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          _translateStatus(order.status),
                          style: AppTextStyles.labelMono.copyWith(color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Nút đóng
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.neutral),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),

            // BODY SCROLLABLE
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // THÔNG TIN KHÁCH HÀNG
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
                        color: AppColors.surfaceElevated,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Khách Hàng', style: AppTextStyles.labelMonoSmall),
                                const SizedBox(height: 4),
                                Text(order.customerName, style: AppTextStyles.bodyLarge),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Số Điện Thoại', style: AppTextStyles.labelMonoSmall),
                                const SizedBox(height: 4),
                                Text(
                                  order.customerPhone.isNotEmpty ? order.customerPhone : 'Không có',
                                  style: AppTextStyles.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: AppColors.textPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text('Sản Phẩm', style: AppTextStyles.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // DANH SÁCH SẢN PHẨM
                    ...order.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Ảnh giả lập
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.image, color: AppColors.neutral),
                          ),
                          const SizedBox(width: 16),
                          // Tên & Giá
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  'Phân loại: Mặc định', // Placeholder
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          // SL & Thành tiền
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('x${item.quantity}', style: AppTextStyles.bodyMedium),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(item.priceAtBuy * item.quantity),
                                style: AppTextStyles.labelMono.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )).toList(),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // TỔNG CỘNG
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Tổng Cộng', style: AppTextStyles.labelMonoSmall),
                            Text(
                              currencyFormat.format(order.totalAmount),
                              style: AppTextStyles.displayLarge.copyWith(fontSize: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const Divider(height: 1),
            
            // FOOTER ACTIONS
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Nút Hủy Đơn (hiện khi new hoặc processing)
                  if (isNew || (isAdmin && isProcessing))
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<OrderProvider>().cancelOrder(order.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đơn hàng!')));
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Hủy Đơn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.tertiary,
                        side: const BorderSide(color: AppColors.tertiary),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  
                  const SizedBox(width: 16),
                  
                  // Nút Xử lý (dành cho Admin)
                  if (isAdmin && isNew)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<OrderProvider>().updateOrderStatus(order.id, 'processing');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.hourglass_bottom, size: 18),
                      label: const Text('Xử Lý Ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                    
                  // Nút Hoàn thành (dành cho Admin khi đang xử lý)
                  if (isAdmin && isProcessing)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<OrderProvider>().updateOrderStatus(order.id, 'completed');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Hoàn Thành'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
