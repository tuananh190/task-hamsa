import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy danh sách đơn hàng
  Stream<List<OrderModel>> getOrdersStream() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  // Tạo đơn hàng (Transaction bắt buộc)
  Future<void> createOrder(OrderModel order) async {
    // FIX BUG 3 (phần 2/2): Để Firestore tự sinh ID thay vì dùng ID truyền vào
    // _firestore.collection('orders').doc()  → TẠO document với UUID mới (duy nhất)
    // _firestore.collection('orders').doc(id) → dùng ID chỉ định (có thể trùng)
    // Sau khi tạo ref, orderRef.id chứa UUID thật → dùng để set vào data
    final orderRef = _firestore.collection('orders').doc();

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Chuẩn bị danh sách Refs cần đọc
        List<DocumentReference> productRefs = [];
        for (var item in order.items) {
          productRefs.add(_firestore.collection('products').doc(item.productId));
        }

        // 2. THỰC HIỆN TOÀN BỘ LỆNH ĐỌC (READ) TRƯỚC
        List<DocumentSnapshot> productSnapshots = [];
        for (var ref in productRefs) {
          DocumentSnapshot snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw Exception("Sản phẩm không tồn tại hoặc đã bị xóa.");
          }
          productSnapshots.add(snapshot);
        }

        // 3. Kiểm tra logic kho (Business Logic)
        for (int i = 0; i < order.items.length; i++) {
          int currentStock = productSnapshots[i]['stock'] ?? 0;
          if (currentStock < order.items[i].quantity) {
            throw Exception("Sản phẩm '${order.items[i].productName}' không đủ tồn kho (Chỉ còn $currentStock).");
          }
        }

        // 4. THỰC HIỆN TOÀN BỘ LỆNH GHI (WRITE/UPDATE) SAU CÙNG
        for (int i = 0; i < order.items.length; i++) {
          int currentStock = productSnapshots[i]['stock'] ?? 0;
          transaction.update(productRefs[i], {
            'stock': currentStock - order.items[i].quantity
          });
        }

        // Tạo đơn với ID thật từ Firestore (orderRef.id là UUID duy nhất)
        // copyWith để gán ID thật vào model trước khi lưu
        transaction.set(orderRef, order.copyWith(id: orderRef.id).toJson());
      });
    } catch (e) {
      throw Exception("Tạo đơn hàng thất bại: $e");
    }
  }

  // Cập nhật trạng thái (Tiến tới)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({'status': newStatus});
    } catch (e) {
      throw Exception("Lỗi cập nhật trạng thái đơn hàng: $e");
    }
  }

  // Hủy đơn hàng (Hoàn lại kho)
  Future<void> cancelOrder(String orderId) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    try {
      await _firestore.runTransaction((transaction) async {
        // Đọc Order
        DocumentSnapshot orderSnap = await transaction.get(orderRef);
        if (!orderSnap.exists) throw Exception("Đơn hàng không tồn tại");

        OrderModel order = OrderModel.fromJson(orderSnap.data() as Map<String, dynamic>, orderSnap.id);

        if (order.status != 'new_order') {
          throw Exception("Chỉ có thể hủy đơn hàng ở trạng thái Mới tạo.");
        }

        // Chuẩn bị ds sản phẩm
        List<DocumentReference> productRefs = [];
        for (var item in order.items) {
          productRefs.add(_firestore.collection('products').doc(item.productId));
        }

        // Đọc Products
        List<DocumentSnapshot> productSnapshots = [];
        for (var ref in productRefs) {
          DocumentSnapshot snapshot = await transaction.get(ref);
          productSnapshots.add(snapshot);
        }

        // Hoàn kho (Write)
        for (int i = 0; i < order.items.length; i++) {
          if (productSnapshots[i].exists) {
            int currentStock = productSnapshots[i]['stock'] ?? 0;
            transaction.update(productRefs[i], {
              'stock': currentStock + order.items[i].quantity
            });
          }
        }

        // Cập nhật trạng thái hủy
        transaction.update(orderRef, {'status': 'cancelled'});
      });
    } catch (e) {
      throw Exception("Hủy đơn hàng thất bại: $e");
    }
  }
}
