import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../providers/cart_provider.dart';
import '../models/user_model.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<OrderModel>> get ordersStream => _orderService.getOrdersStream();

  Future<bool> createOrderFromCart({
    required CartProvider cart,
    required UserModel currentUser,
    required String customerName, // [NEW] Tên khách lẻ do UI truyền vào
    required String note,
  }) async {
    if (cart.items.isEmpty) {
      _error = "Giỏ hàng trống";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {

      final newOrder = OrderModel(
        id: '',
        customerId: currentUser.id,
        customerName: customerName, // [UPDATE] Dùng tên do UI truyền vào thay vì currentUser.name
        totalAmount: cart.totalAmount,
        note: note,
        status: 'new_order',
        createdAt: DateTime.now(),
        items: cart.items.values.toList(),
      );

      await _orderService.createOrder(newOrder);
      
      // Xóa giỏ hàng sau khi tạo đơn thành công
      cart.clearCart();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _orderService.cancelOrder(orderId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
