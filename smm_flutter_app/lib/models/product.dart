class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int minQuantity;
  final int maxQuantity;
  final int categoryId;
  final int sort;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.minQuantity = 1,
    this.maxQuantity = 10000,
    required this.categoryId,
    this.sort = 0,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'],
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        minQuantity: json['min_quantity'] ?? 1,
        maxQuantity: json['max_quantity'] ?? 10000,
        categoryId: json['category_id'] ?? 0,
        sort: json['sort'] ?? 0,
        isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'min_quantity': minQuantity,
        'max_quantity': maxQuantity,
        'category_id': categoryId,
        'sort': sort,
        'is_active': isActive,
      };
}
