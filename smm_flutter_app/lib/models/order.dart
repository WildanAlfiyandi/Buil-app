class Order {
  final int id;
  final int? productId;
  final String? productName;
  final int quantity;
  final double amount;
  final String status;
  final String? link;
  final DateTime? createdAt;

  Order({
    required this.id,
    this.productId,
    this.productName,
    required this.quantity,
    required this.amount,
    this.status = 'pending',
    this.link,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] ?? 0,
        productId: json['product_id'],
        productName: json['product_name'] ?? json['product']?['name'],
        quantity: json['quantity'] ?? json['count'] ?? 1,
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] ?? 'pending',
        link: json['link'] ?? json['url'],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'amount': amount,
        'status': status,
        'link': link,
        'created_at': createdAt?.toIso8601String(),
      };

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'new':
      case 'pending':
        return 'Pending';
      case 'processing':
      case 'in_progress':
        return 'Processing';
      case 'completed':
      case 'done':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'partial':
        return 'Partial';
      default:
        return status;
    }
  }
}
