import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  // Map để truy xuất nhanh sản phẩm trong giỏ hàng theo productId
  final Map<String, OrderItemModel> _items = {};

  Map<String, OrderItemModel> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.priceAtBuy * item.quantity;
    });
    return total;
  }

  void addItem(ProductModel product, int quantity) {
    if (_items.containsKey(product.id)) {
      // Đã có trong giỏ, tăng/giảm số lượng
      _items.update(
        product.id,
        (existingItem) => existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      // Chưa có trong giỏ, thêm mới
      _items.putIfAbsent(
        product.id,
        () => OrderItemModel(
          productId: product.id,
          productName: product.tradeName.isNotEmpty ? product.tradeName : product.internalName,
          quantity: quantity,
          priceAtBuy: product.price,
        ),
      );
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (!_items.containsKey(productId)) return;
    
    if (newQuantity <= 0) {
      _items.remove(productId);
    } else {
      _items.update(
        productId,
        (existingItem) => existingItem.copyWith(quantity: newQuantity),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
