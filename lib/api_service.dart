import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiService {
  static const String baseUrl = 'https://api.agrom24.uz/api';
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;
  String? get token => _token;

  // Initialize service, load token and current user if they exist
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    _token = prefs.getString('agrom_token');
    final userJson = prefs.getString('agrom_user');
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
      } catch (e) {
        // Clear corrupt data
        await logout();
      }
    }
  }

  // Get common headers
  Map<String, String> _headers([bool withToken = true]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withToken && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Exception parser
  void _handleError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        if (body['errors'] is List && (body['errors'] as List).isNotEmpty) {
          throw Exception(body['errors'][0]['msg'] ?? 'Validation error');
        }
        throw Exception(body['message'] ?? 'API Error (${response.statusCode})');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Server error: ${response.statusCode}');
      }
      rethrow;
    }
    throw Exception('Request failed with status ${response.statusCode}');
  }

  // Login User
  Future<User> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: _headers(false),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final user = User.fromJson(userData);
      
      _token = user.token;
      _currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('agrom_token', _token!);
      await prefs.setString('agrom_user', jsonEncode(user.toJson()));
      
      return user;
    } else {
      _handleError(response);
      throw Exception('Login failed');
    }
  }

  // Register User
  Future<User> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth');
    final response = await http.post(
      url,
      headers: _headers(false),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final user = User.fromJson(userData);
      
      _token = user.token;
      _currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('agrom_token', _token!);
      await prefs.setString('agrom_user', jsonEncode(user.toJson()));
      
      return user;
    } else {
      _handleError(response);
      throw Exception('Registration failed');
    }
  }

  // Fetch updated Profile
  Future<User> getProfile() async {
    final url = Uri.parse('$baseUrl/auth/profile');
    final response = await http.get(url, headers: _headers());

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      // Backend does not return token in profile response, merge with existing token
      final user = User.fromJson({...userData, 'token': _token});
      _currentUser = user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('agrom_user', jsonEncode(user.toJson()));
      return user;
    } else {
      _handleError(response);
      throw Exception('Failed to load profile');
    }
  }

  // Update Profile Info
  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    final url = Uri.parse('$baseUrl/auth/profile');
    final response = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final oldIsFarmer = _currentUser?.isFarmer ?? false;
      final oldIsAdmin = _currentUser?.isAdmin ?? false;
      
      // Merge properties safely
      final user = User.fromJson({
        ...userData,
        'isFarmer': userData['isFarmer'] ?? oldIsFarmer,
        'isAdmin': userData['isAdmin'] ?? oldIsAdmin,
        'token': userData['token'] ?? _token,
      });
      _currentUser = user;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('agrom_user', jsonEncode(user.toJson()));
      if (user.token != null) {
        _token = user.token;
        await prefs.setString('agrom_token', _token!);
      }
      return user;
    } else {
      _handleError(response);
      throw Exception('Failed to update profile');
    }
  }

  // Helper to clear products cache on mutation
  Future<void> _clearProductsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('agrom_products_cache_')) {
        await prefs.remove(key);
      }
    }
  }

  // Fetch Products with Cache-First, Network-Second logic
  Future<Map<String, dynamic>> getProducts({
    String? keyword,
    String? category,
    int pageNumber = 1,
    bool myProducts = false,
    void Function(Map<String, dynamic>)? onCacheLoaded,
  }) async {
    final queryParams = <String, String>{
      'pageNumber': pageNumber.toString(),
    };
    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParams['keyword'] = keyword.trim();
    }
    if (category != null && category.isNotEmpty && category != 'All' && category != 'Barchasi') {
      queryParams['category'] = category;
    }
    if (myProducts) {
      queryParams['myproducts'] = 'true';
    }

    final cacheKey = 'agrom_products_cache_${keyword ?? ''}_${category ?? ''}_${pageNumber}_$myProducts';
    final prefs = await SharedPreferences.getInstance();

    // 1. Try reading from local cache immediately
    final cachedJson = prefs.getString(cacheKey);
    if (cachedJson != null && onCacheLoaded != null) {
      try {
        final data = jsonDecode(cachedJson);
        final productsList = data['products'] as List? ?? [];
        final products = productsList.map((p) => Product.fromJson(p)).toList();
        onCacheLoaded({
          'products': products,
          'page': data['page'] ?? 1,
          'pages': data['pages'] ?? 1,
        });
      } catch (_) {
        // Corrupt cache, ignore
      }
    }

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    
    // 2. Fetch fresh data from network
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final responseBody = response.body;
      
      // Save/update cache only if it changed
      if (cachedJson != responseBody) {
        await prefs.setString(cacheKey, responseBody);
      }

      final data = jsonDecode(responseBody);
      final productsList = data['products'] as List? ?? [];
      final products = productsList.map((p) => Product.fromJson(p)).toList();
      return {
        'products': products,
        'page': data['page'] ?? 1,
        'pages': data['pages'] ?? 1,
      };
    } else {
      _handleError(response);
      throw Exception('Failed to load products');
    }
  }

  // Fetch Product by ID
  Future<Product> getProductById(String id) async {
    final url = Uri.parse('$baseUrl/products/$id');
    final response = await http.get(url, headers: _headers(false));

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Product not found');
    }
  }

  // Create Product (Farmers/Admins) and invalidate cache
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final url = Uri.parse('$baseUrl/products');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(productData),
    );

    if (response.statusCode == 201) {
      await _clearProductsCache(); // Clear stale cache
      return Product.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to create product');
    }
  }

  // Update Product (Farmers/Admins) and invalidate cache
  Future<Product> updateProduct(String id, Map<String, dynamic> productData) async {
    final url = Uri.parse('$baseUrl/products/$id');
    final response = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode(productData),
    );

    if (response.statusCode == 200) {
      await _clearProductsCache(); // Clear stale cache
      return Product.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to update product');
    }
  }

  // Delete Product and invalidate cache
  Future<void> deleteProduct(String id) async {
    final url = Uri.parse('$baseUrl/products/$id');
    final response = await http.delete(url, headers: _headers());

    if (response.statusCode == 200) {
      await _clearProductsCache(); // Clear stale cache
    } else {
      _handleError(response);
    }
  }

  // Place Order and track locally
  Future<Order> createOrder(Map<String, dynamic> orderData) async {
    final url = Uri.parse('$baseUrl/orders');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 201) {
      final order = Order.fromJson(jsonDecode(response.body));
      // Save order ID to local preferences for history tracking if the user is a buyer
      if (_currentUser?.isAdmin != true) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'agrom_placed_orders_${_currentUser?.id}';
        final list = prefs.getStringList(key) ?? [];
        list.add(order.id);
        await prefs.setStringList(key, list);
      }
      return order;
    } else {
      _handleError(response);
      throw Exception('Failed to place order');
    }
  }

  // Get orders list (full for Admin, tracked for standard Users)
  Future<List<Order>> getOrders() async {
    final isAdmin = _currentUser?.isAdmin == true;
    
    if (isAdmin) {
      try {
        final url = Uri.parse('$baseUrl/orders');
        final response = await http.get(url, headers: _headers());
        if (response.statusCode == 200) {
          final list = jsonDecode(response.body) as List? ?? [];
          final orders = list.map((o) => Order.fromJson(o)).toList();
          orders.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
          return orders;
        } else {
          _handleError(response);
          throw Exception('Failed to load admin orders');
        }
      } catch (e) {
        return [];
      }
    } else {
      // Standard user: Try fetching from database endpoint GET /api/orders/my first
      try {
        final url = Uri.parse('$baseUrl/orders/my');
        final response = await http.get(url, headers: _headers());
        
        if (response.statusCode == 200) {
          final list = jsonDecode(response.body) as List? ?? [];
          final orders = list.map((o) => Order.fromJson(o)).toList();
          orders.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
          return orders;
        } else {
          // If 404 or any other error (e.g. endpoint not deployed yet), fall back to local preferences
          return _getLocalOrdersFallback();
        }
      } catch (e) {
        // Fetch failed (network error, timeout, etc.), fall back to local preferences
        return _getLocalOrdersFallback();
      }
    }
  }

  Future<List<Order>> _getLocalOrdersFallback() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'agrom_placed_orders_${_currentUser?.id}';
    final cacheKey = 'agrom_cached_orders_${_currentUser?.id}';
    
    // Revert migration: recover IDs from agrom_cached_orders if it exists
    if (prefs.containsKey(cacheKey)) {
      final cachedList = prefs.getStringList(cacheKey) ?? [];
      final currentIds = prefs.getStringList(key) ?? [];
      for (final orderJson in cachedList) {
        try {
          final orderId = jsonDecode(orderJson)['_id'];
          if (orderId != null && !currentIds.contains(orderId)) {
            currentIds.add(orderId);
          }
        } catch (_) {}
      }
      await prefs.setStringList(key, currentIds);
      await prefs.remove(cacheKey);
    }
    
    // Migrate legacy non-namespaced orders if any exist
    final legacyKey = 'agrom_placed_orders';
    if (prefs.containsKey(legacyKey)) {
      final legacyIds = prefs.getStringList(legacyKey) ?? [];
      if (legacyIds.isNotEmpty && _currentUser?.id != null && _currentUser!.id.isNotEmpty) {
        final currentIds = prefs.getStringList(key) ?? [];
        final merged = {...currentIds, ...legacyIds}.toList();
        await prefs.setStringList(key, merged);
        await prefs.remove(legacyKey);
      }
    }

    final ids = prefs.getStringList(key) ?? [];
    final List<Order> list = [];
    for (final id in ids) {
      try {
        final order = await getOrderById(id);
        list.add(order);
      } catch (_) {
        // Stale ID, ignore
      }
    }
    list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return list;
  }

  // Get Order details by ID
  Future<Order> getOrderById(String id) async {
    final url = Uri.parse('$baseUrl/orders/$id');
    final response = await http.get(url, headers: _headers());

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Order not found');
    }
  }

  // Update order to paid
  Future<Order> markOrderAsPaid(String id, {bool byAdmin = false}) async {
    final endpoint = byAdmin ? '$baseUrl/orders/$id/pay/admin' : '$baseUrl/orders/$id/pay';
    final url = Uri.parse(endpoint);
    final response = await http.put(
      url,
      headers: _headers(),
      body: byAdmin ? null : jsonEncode({
        'id': 'app_marked_payment',
        'status': 'success',
        'update_time': DateTime.now().toIso8601String(),
        'payer': {'email_address': _currentUser?.email ?? 'user@agrom'}
      }),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to mark order as paid');
    }
  }

  // Update order to delivered (Admin only)
  Future<Order> markOrderAsDelivered(String id) async {
    final url = Uri.parse('$baseUrl/orders/$id/deliver');
    final response = await http.put(url, headers: _headers());

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      _handleError(response);
      throw Exception('Failed to mark order as delivered');
    }
  }

  // Fetch Wishlist
  Future<List<Product>> getWishlist() async {
    final url = Uri.parse('$baseUrl/wishlist');
    final response = await http.get(url, headers: _headers());

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List? ?? [];
      return list.map((p) => Product.fromJson(p)).toList();
    } else {
      _handleError(response);
      throw Exception('Failed to load wishlist');
    }
  }

  // Add to Wishlist
  Future<List<Product>> addToWishlist(String productId) async {
    final url = Uri.parse('$baseUrl/wishlist');
    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({'productId': productId}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final list = jsonDecode(response.body) as List? ?? [];
      return list.map((p) => Product.fromJson(p)).toList();
    } else {
      _handleError(response);
      throw Exception('Failed to add to wishlist');
    }
  }

  // Remove from Wishlist
  Future<List<Product>> removeFromWishlist(String productId) async {
    final url = Uri.parse('$baseUrl/wishlist/$productId');
    final response = await http.delete(url, headers: _headers());

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List? ?? [];
      return list.map((p) => Product.fromJson(p)).toList();
    } else {
      _handleError(response);
      throw Exception('Failed to remove from wishlist');
    }
  }

  // Log Out
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('agrom_token');
    await prefs.remove('agrom_user');
  }
}
