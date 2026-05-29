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

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String get searchType => _searchType;

  // Load danh sách trang đầu tiên (reset data)
  Future<void> loadProducts({String? query, String? type}) async {
    _isLoading = true;
    _error = null;
    if (query != null) _searchQuery = query;
    if (type != null) _searchType = type;
    
    _hasMore = true;
    _lastDoc = null;
    notifyListeners();

    try {
      final result = await _productService.getProducts(
        limit: 20,
        searchQuery: _searchQuery,
        searchType: _searchType,
      );

      _products = result['products'] as List<ProductModel>;
      _lastDoc = result['lastDoc'] as DocumentSnapshot?;
      
      if (_products.length < 20) {
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load thêm dữ liệu (Pagination)
  Future<void> loadMoreProducts() async {
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      final result = await _productService.getProducts(
        limit: 20,
        startAfter: _lastDoc,
        searchQuery: _searchQuery,
        searchType: _searchType,
      );

      final newProducts = result['products'] as List<ProductModel>;
      _lastDoc = result['lastDoc'] as DocumentSnapshot?;

      if (newProducts.isEmpty || newProducts.length < 20) {
        _hasMore = false;
      }

      _products.addAll(newProducts);
    } catch (e) {
      _error = e.toString();
    }

    _isFetchingMore = false;
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
