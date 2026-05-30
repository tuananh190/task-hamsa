import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _error;

  // Admin Metrics
  double _todayRevenue = 0;
  int _pendingOrdersCount = 0;
  int _lowStockCount = 0;
  List<OrderModel> _recentOrders = [];

  // Employee Metrics
  int _employeeTodayOrdersCount = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;

  double get todayRevenue => _todayRevenue;
  int get pendingOrdersCount => _pendingOrdersCount;
  int get lowStockCount => _lowStockCount;
  List<OrderModel> get recentOrders => _recentOrders;
  int get employeeTodayOrdersCount => _employeeTodayOrdersCount;

  // Gọi hàm này khi load Dashboard
  Future<void> loadDashboardData({required bool isAdmin, String? employeeId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      if (isAdmin) {
        // 1. Doanh thu tổng (lấy các đơn hoàn thành, bỏ bộ lọc ngày để test số liệu)
        final revenueSnapshot = await _firestore
            .collection('orders')
            .where('status', isEqualTo: 'completed') // [UPDATE] Bỏ filter createdAt >= startOfDay
            .get();

        _todayRevenue = revenueSnapshot.docs.fold(0.0, (sum, doc) {
          return sum + (doc.data()['totalAmount'] ?? 0.0);
        });

        // 2. Đơn chờ xử lý (chỉ đếm new_order)
        final pendingSnapshot = await _firestore
            .collection('orders')
            .where('status', isEqualTo: 'new_order') // [UPDATE] Đổi thành isEqualTo: 'new_order'
            .get();
        _pendingOrdersCount = pendingSnapshot.docs.length;

        // 3. Cảnh báo tồn kho (stock <= 10)
        final lowStockSnapshot = await _firestore
            .collection('products')
            .where('stock', isLessThanOrEqualTo: 10) // [UPDATE] Bỏ where('isActive') để tránh lỗi Composite Index
            .get();
        _lowStockCount = lowStockSnapshot.docs.where((doc) => doc.data()['isActive'] == true).length; // Filter isActive ở client

        // 4. 5 Đơn hàng gần nhất
        final recentSnapshot = await _firestore
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();
        _recentOrders = recentSnapshot.docs.map((doc) => OrderModel.fromJson(doc.data(), doc.id)).toList();

      } else {
        // Employee Metrics
        if (employeeId != null) {
          final employeeOrdersSnapshot = await _firestore
              .collection('orders')
              .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
              .where('customerId', isEqualTo: employeeId) // Lưu ý: trong hệ thống này, customerId đang chứa UID của nhân viên tạo đơn
              .get();
          _employeeTodayOrdersCount = employeeOrdersSnapshot.docs.length;

          // Đơn chờ xử lý của hệ thống (nhân viên cũng cần thấy để gói hàng)
          final pendingSnapshot = await _firestore
              .collection('orders')
              .where('status', isEqualTo: 'new_order') // Nhân viên chỉ cần thấy đơn mới
              .get();
          _pendingOrdersCount = pendingSnapshot.docs.length;
        }
      }
    } catch (e) {
      _error = 'Lỗi khi tải dữ liệu Dashboard: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
