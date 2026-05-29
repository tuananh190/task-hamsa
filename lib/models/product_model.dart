class ProductModel {
  final String id;
  final String internalName;
  final String tradeName;
  final double price;
  final int stock;
  final bool isActive;
  final String barcode;
  final String imageUrl;

  ProductModel({
    required this.id,
    required this.internalName,
    required this.tradeName,
    required this.price,
    required this.stock,
    required this.isActive,
    required this.barcode,
    this.imageUrl = '',
  });

  factory ProductModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ProductModel(
      id: documentId,
      internalName: json['internalName'] ?? '',
      tradeName: json['tradeName'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
      isActive: json['isActive'] ?? true,
      barcode: json['barcode'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'internalName': internalName,
      'tradeName': tradeName,
      'price': price,
      'stock': stock,
      'isActive': isActive,
      'barcode': barcode,
      'imageUrl': imageUrl,
    };
  }

  ProductModel copyWith({
    String? id,
    String? internalName,
    String? tradeName,
    double? price,
    int? stock,
    bool? isActive,
    String? barcode,
    String? imageUrl,
  }) {
    return ProductModel(
      id: id ?? this.id,
      internalName: internalName ?? this.internalName,
      tradeName: tradeName ?? this.tradeName,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
