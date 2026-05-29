// PHASE 0 FIX: Import Firestore để dùng Timestamp type
// Cần thiết vì Firestore không lưu DateTime trực tiếp mà lưu dưới dạng Timestamp object
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final int quantity;
  final double priceAtBuy;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtBuy,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 1,
      priceAtBuy: (json['priceAtBuy'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'priceAtBuy': priceAtBuy,
    };
  }

  OrderItemModel copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? priceAtBuy,
  }) {
    return OrderItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      priceAtBuy: priceAtBuy ?? this.priceAtBuy,
    );
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final double totalAmount;
  final double vatAmount;
  final String note;
  final String status; // 'new_order', 'processing', 'completed', 'cancelled'
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.totalAmount,
    this.vatAmount = 0.0,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, String documentId) {
    var itemsList = json['items'] as List? ?? [];
    List<OrderItemModel> parsedItems = itemsList.map((i) => OrderItemModel.fromJson(i)).toList();

    return OrderModel(
      id: documentId,
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      vatAmount: (json['vatAmount'] ?? 0.0).toDouble(),
      note: json['note'] ?? '',
      status: json['status'] ?? 'new_order',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : (json['createdAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
              : DateTime.now()),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'totalAmount': totalAmount,
      'vatAmount': vatAmount,
      'note': note,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    double? totalAmount,
    String? note,
    String? status,
    DateTime? createdAt,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
