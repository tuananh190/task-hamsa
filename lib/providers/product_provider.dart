import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> _products = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  // Trạng thái tìm kiếm
  String _searchQuery = '';
  String _searchType = 'name'; // 'name' hoặc 'barcode'

  // [NEW] Trạng thái Pagination
  int _currentPage = 1;
  final List<DocumentSnapshot?> _pageCursors = [null]; // Lưu trữ vị trí (cursor) bắt đầu của từng trang

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String get searchType => _searchType;

  // [NEW] Getters cho Pagination
  int get currentPage => _currentPage;
  int get totalKnownPages => _pageCursors.length; // Số trang tối đa có thể điều hướng

  // Load danh sách trang đầu tiên (reset data)
  Future<void> loadProducts({String? query, String? type}) async {
    if (query != null) _searchQuery = query;
    if (type != null) _searchType = type;
    
    _pageCursors.clear();
    _pageCursors.add(null); // Trang 1 bắt đầu không có cursor (null)
    
    await goToPage(1);
  }

  // [NEW] Hàm điều hướng trang (Thay thế loadMoreProducts)
  Future<void> goToPage(int page) async {
    // Chỉ cho phép chuyển tới những trang đã biết cursor
    if (page < 1 || page > _pageCursors.length) return; 

    _isLoading = true;
    _currentPage = page;
    _error = null;
    notifyListeners();

    try {
      final startAfter = _pageCursors[page - 1]; // Index bắt đầu từ 0
      final result = await _productService.getProducts(
        limit: 8, // [UPDATE] Đổi thành 8 sản phẩm / trang
        startAfter: startAfter,
        searchQuery: _searchQuery,
        searchType: _searchType,
      );

      _products = result['products'] as List<ProductModel>;
      final lastDoc = result['lastDoc'] as DocumentSnapshot?;

      // Nếu trang hiện tại tải đủ 8 items và có lastDoc, lưu cursor cho trang kế tiếp
      if (_products.length == 8 && lastDoc != null) {
        _hasMore = true;
        if (_pageCursors.length <= page) {
          _pageCursors.add(lastDoc);
        } else {
          _pageCursors[page] = lastDoc;
        }
      } else {
        _hasMore = false;
        // Xóa bỏ các cursor dư thừa phía sau nếu trang này không đủ 8 items (trang cuối)
        if (_pageCursors.length > page) {
          _pageCursors.removeRange(page, _pageCursors.length);
        }
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Thay đổi tiêu chí tìm kiếm và reload
  void setSearch(String query, String type) {
    _searchQuery = query;
    _searchType = type;
    loadProducts();
  }

  // Thêm mới sản phẩm
  Future<bool> addProduct(ProductModel product) async {
    try {
      await _productService.addProduct(product);
      // Có thể thêm vào đầu list hoặc gọi load lại
      _products.insert(0, product);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cập nhật sản phẩm
  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _productService.updateProduct(product);
      int index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Soft Delete
  Future<bool> deleteProduct(String productId) async {
    try {
      await _productService.softDeleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
