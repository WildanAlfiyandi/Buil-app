import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart';

class ApiService {
  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  String? _baseUrl;
  String? _token;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey);
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl!);
  }

  String? getBaseUrl() => _baseUrl;

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return jsonDecode(response.body);
    } else {
      final error = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {'message': 'Unknown error'};
      throw ApiException(
        message: error['message'] ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (_baseUrl == null) throw ApiException(message: 'API URL not configured');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = await _handleResponse(response);
    if (data['access_token'] != null) {
      await setToken(data['access_token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    if (_baseUrl == null) throw ApiException(message: 'API URL not configured');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );

    final data = await _handleResponse(response);
    if (data['access_token'] != null) {
      await setToken(data['access_token']);
    }
    return data;
  }

  Future<User?> getMe() async {
    if (_baseUrl == null || _token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/me'),
        headers: _headers,
      );
      final data = await _handleResponse(response);
      return User.fromJson(data['data'] ?? data);
    } catch (e) {
      return null;
    }
  }

  // Products endpoints
  Future<List<Product>> getProducts({int? categoryId}) async {
    if (_baseUrl == null) throw ApiException(message: 'API URL not configured');

    String url = '$_baseUrl/api/products';
    if (categoryId != null) {
      url += '?category_id=$categoryId';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);
    final data = await _handleResponse(response);

    final List productsJson = data['data'] ?? data;
    return productsJson.map((json) => Product.fromJson(json)).toList();
  }

  // Categories endpoints
  Future<List<Category>> getCategories() async {
    if (_baseUrl == null) throw ApiException(message: 'API URL not configured');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/categories'),
      headers: _headers,
    );
    final data = await _handleResponse(response);

    final List categoriesJson = data['data'] ?? data;
    return categoriesJson.map((json) => Category.fromJson(json)).toList();
  }

  // Orders endpoints
  Future<List<Order>> getOrders() async {
    if (_baseUrl == null) throw ApiException(message: 'API URL not configured');
    if (_token == null) throw ApiException(message: 'Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/orders'),
      headers: _headers,
    );
    final data = await _handleResponse(response);

    final List ordersJson = data['data'] ?? data;
    return ordersJson.map((json) => Order.fromJson(json)).toList();
  }

  Future<Order> createOrder({
    required int productId,
    required int quantity,
    required String link,
    int? paymentSystemId,
  }) async {
    if (_baseUrl == null) throw ApiException(message: 'API URL not configured');
    if (_token == null) throw ApiException(message: 'Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/orders/create'),
      headers: _headers,
      body: jsonEncode({
        'products': {productId.toString(): productId},
        'counts': {productId.toString(): quantity},
        'url': link,
        'payment_system_id': paymentSystemId ?? 1,
      }),
    );

    final data = await _handleResponse(response);
    return Order.fromJson(data['data'] ?? data);
  }

  // Balance order
  Future<Map<String, dynamic>> createBalanceOrder({
    required double amount,
    required int paymentSystemId,
  }) async {
    if (_baseUrl == null) throw ApiException(message: 'API URL not configured');
    if (_token == null) throw ApiException(message: 'Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/orders/create/balance'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'payment_system_id': paymentSystemId,
      }),
    );

    return await _handleResponse(response);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
