import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'models/user.dart' as models;
import 'models/category.dart' as models;
import 'models/product.dart' as models;
import 'models/order.dart' as models;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMM Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
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
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data == true) return const MainScreen();
        return const LoginScreen();
      },
    );
  }
}

// Settings Screen for API configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlC = TextEditingController();
  bool _isTesting = false;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _urlC.text = ApiService().getBaseUrl() ?? '';
  }

  Future<void> _saveSettings() async {
    final url = _urlC.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter API URL')),
      );
      return;
    }
    await ApiService().setBaseUrl(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    final url = _urlC.text.trim();
    if (url.isEmpty) {
      setState(() => _testResult = 'Please enter API URL first');
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = '';
    });

    try {
      await ApiService().setBaseUrl(url);
      final categories = await ApiService().getCategories();
      setState(() {
        _testResult = 'Connection successful! Found ${categories.length} categories.';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Connection failed: $e';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'API Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlC,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'https://your-smm-panel.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label: const Text('Test Connection'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
            if (_testResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult.contains('successful')
                      ? Colors.green.withAlpha(26)
                      : Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _testResult,
                  style: TextStyle(
                    color: _testResult.contains('successful')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ],
            const Spacer(),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offline Mode',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'If no API is configured, the app will work in offline mode with local storage.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _nameC = TextEditingController();
  final _confirmPassC = TextEditingController();
  String _error = '';
  bool _isLoading = false;

  // Default admin credentials for offline mode
  final _adminEmail = 'admin@admin.com';
  final _adminPass = 'admin123';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailC.dispose();
    _passC.dispose();
    _nameC.dispose();
    _confirmPassC.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _error = '';
      _isLoading = true;
    });

    final email = _emailC.text.trim();
    final pass = _passC.text;

    try {
      // Try API login first if configured
      if (ApiService().getBaseUrl() != null) {
        await ApiService().login(email, pass);
        final sp = await SharedPreferences.getInstance();
        await sp.setBool('is_logged', true);
        await sp.setString('user_email', email);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
        return;
      }
    } catch (e) {
      // Fall through to offline mode check
    }

    // Offline mode: check default credentials
    if (email == _adminEmail && pass == _adminPass) {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('is_logged', true);
      await sp.setString('user_email', email);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      setState(() => _error = 'Invalid email or password');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _register() async {
    setState(() {
      _error = '';
      _isLoading = true;
    });

    final name = _nameC.text.trim();
    final email = _emailC.text.trim();
    final pass = _passC.text;
    final confirmPass = _confirmPassC.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() {
        _error = 'Please fill all fields';
        _isLoading = false;
      });
      return;
    }

    if (pass != confirmPass) {
      setState(() {
        _error = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    try {
      if (ApiService().getBaseUrl() != null) {
        await ApiService().register(name, email, pass);
        final sp = await SharedPreferences.getInstance();
        await sp.setBool('is_logged', true);
        await sp.setString('user_email', email);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        setState(() => _error = 'Please configure API URL in settings first');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMM Panel'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.shopping_cart, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'SMM Panel',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                ApiService().getBaseUrl() != null
                    ? 'Connected to server'
                    : 'Offline Mode',
                style: TextStyle(
                  color: ApiService().getBaseUrl() != null
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Login'),
                  Tab(text: 'Register'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Login Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailC,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passC,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          if (_error.isNotEmpty)
                            Text(_error, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Login'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Offline: admin@admin.com / admin123',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    // Register Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameC,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailC,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passC,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPassC,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          if (_error.isNotEmpty)
                            Text(_error, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Register'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Main Screen with Bottom Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ServicesScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.category), label: 'Services'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _completedOrders = 0;
  double _balance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      if (ApiService().getBaseUrl() != null && ApiService().isLoggedIn) {
        final orders = await ApiService().getOrders();
        final user = await ApiService().getMe();
        setState(() {
          _totalOrders = orders.length;
          _pendingOrders = orders.where((o) =>
              o.status.toLowerCase() == 'pending' ||
              o.status.toLowerCase() == 'new' ||
              o.status.toLowerCase() == 'processing').length;
          _completedOrders = orders.where((o) =>
              o.status.toLowerCase() == 'completed' ||
              o.status.toLowerCase() == 'done').length;
          _balance = user?.balance ?? 0.0;
        });
      } else {
        // Load from local storage for offline mode
        final sp = await SharedPreferences.getInstance();
        final raw = sp.getString('local_orders');
        if (raw != null) {
          final list = jsonDecode(raw) as List;
          setState(() {
            _totalOrders = list.length;
            _pendingOrders = list.where((o) => o['status'] == 'pending').length;
            _completedOrders = list.where((o) => o['status'] == 'done').length;
          });
        }
      }
    } catch (e) {
      // Handle error silently for dashboard
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet, size: 40),
                  title: const Text('Balance'),
                  subtitle: Text(
                    'Rp ${_balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Top up coming soon')),
                      );
                    },
                    child: const Text('Top Up'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Stats Grid
              const Text(
                'Order Statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      title: 'Total Orders',
                      value: _totalOrders.toString(),
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: 'Pending',
                      value: _pendingOrders.toString(),
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: 'Completed',
                      value: _completedOrders.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: 'In Progress',
                      value: (_totalOrders - _pendingOrders - _completedOrders)
                          .toString(),
                      icon: Icons.autorenew,
                      color: Colors.purple,
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: 'New Order',
                      icon: Icons.add_shopping_cart,
                      onTap: () {
                        // Navigate to services tab
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      title: 'View Orders',
                      icon: Icons.list_alt,
                      onTap: () {
                        // Navigate to orders tab
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}

// Services Screen
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<models.Category> _categories = [];
  List<models.Product> _products = [];
  models.Category? _selectedCategory;
  bool _isLoading = true;
  String _error = '';

  // Local demo services for offline mode
  final List<Map<String, dynamic>> _demoServices = [
    {'id': 1, 'name': 'Instagram', 'products': [
      {'id': 1, 'name': 'Instagram Followers', 'price': 10000.0, 'min': 100, 'max': 10000},
      {'id': 2, 'name': 'Instagram Likes', 'price': 5000.0, 'min': 50, 'max': 5000},
      {'id': 3, 'name': 'Instagram Views', 'price': 3000.0, 'min': 100, 'max': 50000},
    ]},
    {'id': 2, 'name': 'TikTok', 'products': [
      {'id': 4, 'name': 'TikTok Followers', 'price': 15000.0, 'min': 100, 'max': 10000},
      {'id': 5, 'name': 'TikTok Likes', 'price': 8000.0, 'min': 50, 'max': 10000},
      {'id': 6, 'name': 'TikTok Views', 'price': 2000.0, 'min': 500, 'max': 100000},
    ]},
    {'id': 3, 'name': 'YouTube', 'products': [
      {'id': 7, 'name': 'YouTube Subscribers', 'price': 50000.0, 'min': 50, 'max': 5000},
      {'id': 8, 'name': 'YouTube Views', 'price': 10000.0, 'min': 1000, 'max': 100000},
      {'id': 9, 'name': 'YouTube Likes', 'price': 20000.0, 'min': 50, 'max': 5000},
    ]},
    {'id': 4, 'name': 'Twitter/X', 'products': [
      {'id': 10, 'name': 'Twitter Followers', 'price': 12000.0, 'min': 100, 'max': 10000},
      {'id': 11, 'name': 'Twitter Likes', 'price': 6000.0, 'min': 50, 'max': 5000},
      {'id': 12, 'name': 'Twitter Retweets', 'price': 8000.0, 'min': 50, 'max': 5000},
    ]},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      if (ApiService().getBaseUrl() != null) {
        _categories = await ApiService().getCategories();
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
          _products = await ApiService().getProducts(
            categoryId: _selectedCategory!.id,
          );
        }
      } else {
        // Use demo data for offline mode
        _categories = _demoServices.map((s) => models.Category(
          id: s['id'],
          name: s['name'],
        )).toList();
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
          _loadDemoProducts();
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
      // Fall back to demo data
      _categories = _demoServices.map((s) => models.Category(
        id: s['id'],
        name: s['name'],
      )).toList();
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
        _loadDemoProducts();
      }
    }

    setState(() => _isLoading = false);
  }

  void _loadDemoProducts() {
    if (_selectedCategory == null) return;
    final service = _demoServices.firstWhere(
      (s) => s['id'] == _selectedCategory!.id,
      orElse: () => {'products': []},
    );
    final productsList = service['products'] as List;
    _products = productsList.map((p) => models.Product(
      id: p['id'],
      name: p['name'],
      price: p['price'],
      minQuantity: p['min'],
      maxQuantity: p['max'],
      categoryId: _selectedCategory!.id,
    )).toList();
  }

  Future<void> _selectCategory(models.Category category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      if (ApiService().getBaseUrl() != null) {
        _products = await ApiService().getProducts(categoryId: category.id);
      } else {
        _loadDemoProducts();
      }
    } catch (e) {
      _loadDemoProducts();
    }

    setState(() => _isLoading = false);
  }

  void _showOrderDialog(models.Product product) {
    final qtyC = TextEditingController(text: product.minQuantity.toString());
    final linkC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Price: Rp ${product.price.toStringAsFixed(0)} per 1000',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Min: ${product.minQuantity} • Max: ${product.maxQuantity}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: linkC,
              decoration: const InputDecoration(
                labelText: 'Link / URL',
                hintText: 'https://instagram.com/username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyC,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: qtyC,
              builder: (context, value, child) {
                final qty = int.tryParse(value.text) ?? 0;
                final total = (qty / 1000) * product.price;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 16)),
                        Text(
                          'Rp ${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _createOrder(product, qtyC.text, linkC.text),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Create Order'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _createOrder(
    models.Product product,
    String qtyStr,
    String link,
  ) async {
    final qty = int.tryParse(qtyStr) ?? 0;

    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a link')),
      );
      return;
    }

    if (qty < product.minQuantity || qty > product.maxQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quantity must be between ${product.minQuantity} and ${product.maxQuantity}',
          ),
        ),
      );
      return;
    }

    Navigator.pop(context);

    try {
      if (ApiService().getBaseUrl() != null && ApiService().isLoggedIn) {
        await ApiService().createOrder(
          productId: product.id,
          quantity: qty,
          link: link,
        );
      } else {
        // Save to local storage for offline mode
        final sp = await SharedPreferences.getInstance();
        final raw = sp.getString('local_orders');
        List orders = raw != null ? jsonDecode(raw) : [];
        orders.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch,
          'product_name': product.name,
          'quantity': qty,
          'amount': (qty / 1000) * product.price,
          'link': link,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        });
        await sp.setString('local_orders', jsonEncode(orders));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Row(
        children: [
          // Categories sidebar
          SizedBox(
            width: 100,
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory?.id == cat.id;
                return InkWell(
                  onTap: () => _selectCategory(cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      border: Border(
                        left: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      cat.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          // Products list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error))
                    : _products.isEmpty
                        ? const Center(child: Text('No services available'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _products.length,
                            itemBuilder: (context, i) {
                              final product = _products[i];
                              return Card(
                                child: ListTile(
                                  title: Text(product.name),
                                  subtitle: Text(
                                    'Rp ${product.price.toStringAsFixed(0)} / 1K\n'
                                    'Min: ${product.minQuantity} • Max: ${product.maxQuantity}',
                                  ),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_shopping_cart),
                                    onPressed: () => _showOrderDialog(product),
                                  ),
                                  onTap: () => _showOrderDialog(product),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// Orders Screen
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<models.Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      if (ApiService().getBaseUrl() != null && ApiService().isLoggedIn) {
        _orders = await ApiService().getOrders();
      } else {
        // Load from local storage
        final sp = await SharedPreferences.getInstance();
        final raw = sp.getString('local_orders');
        if (raw != null) {
          final list = jsonDecode(raw) as List;
          _orders = list.map((o) => models.Order.fromJson(o)).toList();
        }
      }
    } catch (e) {
      // Load local orders as fallback
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('local_orders');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _orders = list.map((o) => models.Order.fromJson(o)).toList();
      }
    }

    setState(() => _isLoading = false);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return Colors.green;
      case 'processing':
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      case 'partial':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No orders yet'),
                        Text(
                          'Go to Services to create your first order',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _orders.length,
                    itemBuilder: (context, i) {
                      final order = _orders[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(order.status)
                                .withAlpha(26),
                            child: Text(
                              '#${order.id}',
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusColor(order.status),
                              ),
                            ),
                          ),
                          title: Text(order.productName ?? 'Order #${order.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Qty: ${order.quantity}'),
                              Text('Rp ${order.amount.toStringAsFixed(0)}'),
                              if (order.link != null)
                                Text(
                                  order.link!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.statusDisplay,
                              style: TextStyle(
                                color: _getStatusColor(order.status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

// Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _email = '';
  String _name = '';
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _email = sp.getString('user_email') ?? 'admin@admin.com';
      _name = _email.split('@').first;
    });

    try {
      if (ApiService().getBaseUrl() != null && ApiService().isLoggedIn) {
        final user = await ApiService().getMe();
        if (user != null) {
          setState(() {
            _email = user.email;
            _name = user.name;
            _balance = user.balance;
          });
        }
      }
    } catch (e) {
      // Use local data
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService().clearToken();
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('is_logged', false);
      await sp.remove('user_email');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(_email, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Balance Card
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Balance'),
                      Text(
                        'Rp ${_balance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Top up coming soon')),
                      );
                    },
                    child: const Text('Top Up'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Menu Items
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help coming soon')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SMM Panel',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 SMM Panel',
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
