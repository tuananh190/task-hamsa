import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy danh sách sản phẩm với Pagination và Search
  Future<Map<String, dynamic>> getProducts({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? searchQuery,
    String? searchType, // 'name' hoặc 'barcode'
  }) async {
    try {
      // BỎ where('isActive') ở đây để tránh lỗi đòi Composite Index của Firestore
      Query query = _firestore.collection('products');

      // Xử lý tìm kiếm
      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (searchType == 'barcode') {
          query = query.where('barcode', isEqualTo: searchQuery);
        } else if (searchType == 'name') {
          // [UPDATE] Đảm bảo query đúng vào trường tradeName theo spec
          query = query
              .where('tradeName', isGreaterThanOrEqualTo: searchQuery)
              .where('tradeName', isLessThan: searchQuery! + '\uf8ff');
        }
      } else {
        // Sắp xếp mặc định nếu không search: Mới nhất lên đầu
        query = query.orderBy('createdAt', descending: true); // [UPDATE] Đổi từ tradeName sang createdAt để SP mới luôn hiện trang 1
      }

      query = query.limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      QuerySnapshot snapshot = await query.get();

      List<ProductModel> products = snapshot.docs.map((doc) {
        return ProductModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).where((product) => product.isActive).toList(); // Lọc isActive ở phía Client

      DocumentSnapshot? lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return {
        'products': products,
        'lastDoc': lastDoc,
        'snapshotSize': snapshot.docs.length, // [UPDATE] Trả về size gốc của query để Provider check hasMore
      };
    } catch (e) {
      throw Exception("Lỗi khi tải danh sách sản phẩm: $e");
    }
  }

  // Thêm mới sản phẩm
  Future<void> addProduct(ProductModel product) async {
    try {
      final Map<String, dynamic> data = product.toJson();
      // [UPDATE] Bắt buộc ghi nhận thời gian tạo bằng serverTimestamp
      data['createdAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('products').doc(product.id).set(data);
    } catch (e) {
      throw Exception("Lỗi khi thêm sản phẩm: $e");
    }
  }

  // Cập nhật sản phẩm
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore.collection('products').doc(product.id).update(product.toJson());
    } catch (e) {
      throw Exception("Lỗi khi cập nhật sản phẩm: $e");
    }
  }

  // Xóa mềm (Soft delete)
  Future<void> softDeleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({'isActive': false});
    } catch (e) {
      throw Exception("Lỗi khi xóa sản phẩm: $e");
    }
  }
}
