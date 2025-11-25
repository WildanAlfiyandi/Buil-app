import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class Order {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String status;

  Order({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'price': price,
        'status': status,
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        name: j['name'],
        quantity: (j['quantity'] as num).toInt(),
        price: (j['price'] as num).toDouble(),
        status: j['status'] ?? 'pending',
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMM App',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent)),
      home: const Splash(),
    );
  }
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  Future<bool> checkLogin() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool('is_logged') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkLogin(),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snap.data == true) return const Dashboard();
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  String _error = '';

  // Default admin credentials
  final _adminEmail = 'admin@admin.com';
  final _adminPass = 'admin123';

  Future<void> _login() async {
    setState(() => _error = '');
    final email = _emailC.text.trim();
    final pass = _passC.text;
    if (email == _adminEmail && pass == _adminPass) {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('is_logged', true);
      await sp.setString('user_email', email);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Dashboard()));
    } else {
      setState(() => _error = 'Email atau password salah');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const FlutterLogo(size: 96),
              const SizedBox(height: 16),
              const Text('SMM Manager', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Admin login', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              TextField(controller: _emailC, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: _passC, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 12),
              if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _login, child: const Text('Login')),
              ),
              const Spacer(),
              Text('Default admin: admin@admin.com / admin123', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Order> orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('orders');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() => orders = list.map((e) => Order.fromJson(e)).toList());
    }
  }

  Future<void> _saveOrders() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('orders', jsonEncode(orders.map((o) => o.toJson()).toList()));
  }

  Future<void> _addOrder() async {
    final nameC = TextEditingController();
    final qtyC = TextEditingController(text: '1');
    final priceC = TextEditingController(text: '0');

    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nama Paket')),
            TextField(controller: qtyC, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            TextField(controller: priceC, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              final ord = Order(
                id: id,
                name: nameC.text.trim().isEmpty ? 'Untitled' : nameC.text.trim(),
                quantity: int.tryParse(qtyC.text) ?? 1,
                price: double.tryParse(priceC.text) ?? 0.0,
              );
              setState(() => orders.insert(0, ord));
              _saveOrders();
              Navigator.of(context).pop(true);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );

    if (res == true) {
      // nothing
    }
  }

  Future<void> _logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('is_logged', false);
    await sp.remove('user_email');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addOrder, child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.analytics, color: Colors.blueAccent),
                title: const Text('Total Orders'),
                subtitle: Text('${orders.length} orders'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('Belum ada order. Tekan + untuk menambah.'))
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, i) {
                        final o = orders[i];
                        return Card(
                          child: ListTile(
                            title: Text(o.name),
                            subtitle: Text('Qty: ${o.quantity} • Rp ${o.price.toStringAsFixed(0)}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'delete') {
                                  setState(() => orders.removeAt(i));
                                  _saveOrders();
                                } else if (v == 'done') {
                                  setState(() => orders[i] = Order(id: o.id, name: o.name, quantity: o.quantity, price: o.price, status: 'done'));
                                  _saveOrders();
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'done', child: Text('Mark Done')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
