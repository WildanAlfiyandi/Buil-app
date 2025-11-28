class Category {
  final int id;
  final String name;
  final String? description;
  final int sort;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.sort = 0,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'],
        sort: json['sort'] ?? 0,
        isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'sort': sort,
        'is_active': isActive,
      };
}
