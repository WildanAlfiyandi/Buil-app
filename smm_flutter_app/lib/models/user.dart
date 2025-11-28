class User {
  final int id;
  final String name;
  final String email;
  final double balance;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.balance = 0.0,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'balance': balance,
      };
}
