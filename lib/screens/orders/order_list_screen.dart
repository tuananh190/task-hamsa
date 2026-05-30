// =============================================================================
// ORDER LIST SCREEN (ORDERS)
// Thiết kế: 
// Trên: Tiêu đề, Search, Dropdown Filter trạng thái.
// Giữa: Bảng danh sách đơn hàng.
// Dưới: Phân trang.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/order_detail_modal.dart';
import 'dart:math' as Math;

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all';
  String _searchQuery = ''; // [NEW]
  DateTimeRange? _filterDateRange; // [NEW] Lọc theo khoảng thời gian

  @override
  void initState() { // [NEW] Lắng nghe thay đổi tìm kiếm
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Danh sách Đơn hàng', style: AppTextStyles.headlineLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Quản lý và theo dõi trạng thái đơn hàng',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // SEARCH & FILTER
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Mã đơn / Tên khách hàng...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  height: 48,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      dropdownColor: AppColors.surfaceElevated,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.neutral),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                        DropdownMenuItem(value: 'new_order', child: Text('Mới tạo')),
                        DropdownMenuItem(value: 'processing', child: Text('Chờ xử lý')),
                        DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Đã hủy')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _filterStatus = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // [NEW] Nút chọn khoảng thời gian
                Container(
                  decoration: BoxDecoration(
                    color: _filterDateRange == null ? AppColors.surfaceElevated : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _filterDateRange == null ? AppColors.border : AppColors.primary),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.calendar_month_outlined,
                      color: _filterDateRange == null ? AppColors.neutral : AppColors.primary,
                    ),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: _filterDateRange,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primary,
                                onPrimary: AppColors.background,
                                surface: AppColors.surfaceElevated,
                                onSurface: AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        // Kéo dài đến cuối ngày cho endDate
                        setState(() {
                          _filterDateRange = DateTimeRange(
                            start: picked.start,
                            end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
                          );
                        });
                      } else {
                        // Xóa filter nếu người dùng cancel và muốn reset
                        // (Thực tế người dùng có thể muốn giữ cũ, ở đây ta cứ giữ hoặc xóa tùy ý. Để xóa thì thêm nút X ở UI)
                      }
                    },
                  ),
                ),
                if (_filterDateRange != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.error),
                      onPressed: () => setState(() => _filterDateRange = null),
                    ),
                  ),
              ],
            ),
          ),

          // BẢNG DỮ LIỆU
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // TH HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('MÃ ĐƠN', style: AppTextStyles.labelMonoSmall)),
                        Expanded(flex: 3, child: Text('TÊN KH', style: AppTextStyles.labelMonoSmall)),
                        Expanded(flex: 2, child: Text('TỔNG TIỀN', style: AppTextStyles.labelMonoSmall)),
                        Expanded(flex: 3, child: Text('NGÀY TẠO', style: AppTextStyles.labelMonoSmall)),
                        Expanded(flex: 2, child: Text('TRẠNG THÁI', style: AppTextStyles.labelMonoSmall)),
                        const SizedBox(width: 60, child: Text('THAO TÁC', style: AppTextStyles.labelMonoSmall, textAlign: TextAlign.center)),
                      ],
                    ),
                  ),

                  // TBODY LIST
                  Expanded(
                    child: StreamBuilder(
                      stream: context.read<OrderProvider>().ordersStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        var orders = snapshot.data ?? [];
                        // Áp dụng bộ lọc trạng thái
                        if (_filterStatus != 'all') {
                          orders = orders.where((o) => o.status == _filterStatus).toList();
                        }
                        // [NEW] Áp dụng bộ lọc search theo mã đơn hoặc tên KH
                        if (_searchQuery.isNotEmpty) {
                          orders = orders.where((o) =>
                            o.id.toLowerCase().contains(_searchQuery) ||
                            o.customerName.toLowerCase().contains(_searchQuery),
                          ).toList();
                        }
                        // [NEW] Áp dụng bộ lọc thời gian
                        if (_filterDateRange != null) {
                          orders = orders.where((o) =>
                            o.createdAt.isAfter(_filterDateRange!.start) &&
                            o.createdAt.isBefore(_filterDateRange!.end)
                          ).toList();
                        }

                        if (orders.isEmpty) {
                          return Center(
                            child: Text('Không tìm thấy đơn hàng nào', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                          );
                        }

                        final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
                        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

                        return ListView.separated(
                          itemCount: orders.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            final statusColor = _getStatusColor(order.status);
                            
                            return InkWell(
                              onTap: () => showOrderDetailModal(context, order, isAdmin),
                              hoverColor: AppColors.primary.withOpacity(0.05),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: SelectableText(
                                        '#${order.id.substring(Math.max(0, order.id.length - 6)).toUpperCase()}',
                                        style: AppTextStyles.labelMono.copyWith(color: AppColors.primary),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: SelectableText(order.customerName, style: AppTextStyles.bodyMedium),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: SelectableText(currencyFormat.format(order.totalAmount), style: AppTextStyles.labelMono),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(dateFormat.format(order.createdAt), style: AppTextStyles.bodyMedium),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: statusColor.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.circle, size: 6, color: statusColor),
                                                const SizedBox(width: 6),
                                                Text(_translateStatus(order.status), style: AppTextStyles.labelMonoSmall.copyWith(color: statusColor)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // [UPDATE] Nút ✔: Chỉ hiện duy nhất khi đơn đang "Chờ xử lý" (processing)
                                          if (isAdmin && order.status == 'processing')
                                            InkWell(
                                              onTap: () {
                                                context.read<OrderProvider>().updateOrderStatus(order.id, 'completed');
                                              },
                                              child: const Icon(Icons.check, color: AppColors.secondary, size: 20),
                                            ),
                                          
                                          // [UPDATE] Nút X (Hủy đơn): Tuyệt đối chỉ hiện khi đơn là "new_order"
                                          if (order.status == 'new_order')
                                            Padding(
                                              padding: EdgeInsets.only(left: (isAdmin && order.status == 'processing') ? 8.0 : 0.0),
                                              child: InkWell(
                                                onTap: () {
                                                  context.read<OrderProvider>().cancelOrder(order.id);
                                                },
                                                child: const Icon(Icons.close, color: AppColors.tertiary, size: 20),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // FOOTER PAGINATION
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hiển thị 1-4 trên 120 đơn hàng', style: AppTextStyles.bodySmall),
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: () {}),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                border: Border.all(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('1', style: TextStyle(color: AppColors.primary)),
                            ),
                            const SizedBox(width: 8),
                            const Text('2', style: TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(width: 8),
                            IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: () {}),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

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
      case 'cancelled': return AppColors.tertiary;
      default: return AppColors.neutral;
    }
  }
}
