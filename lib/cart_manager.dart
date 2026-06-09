import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class CartManager extends ValueNotifier<List<CartItem>> {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;

  CartManager._internal() : super([]) {
    _loadCart();
  }

  // Load cart from local storage
  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('agrom_cart');
    if (cartJson != null) {
      try {
        final List<dynamic> list = jsonDecode(cartJson);
        value = list.map((item) => CartItem.fromJson(item)).toList();
      } catch (e) {
        value = [];
      }
    }
  }

  // Save cart to local storage
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = value.map((item) => item.toJson()).toList();
    await prefs.setString('agrom_cart', jsonEncode(listJson));
    notifyListeners();
  }

  // Add Item to Cart
  void addItem(Product product, {int qty = 1}) {
    final list = List<CartItem>.from(value);
    final existingIndex = list.indexWhere((item) => item.product == product.id);

    if (existingIndex >= 0) {
      // Check stock limits
      int newQty = list[existingIndex].qty + qty;
      if (newQty <= product.countInStock) {
        list[existingIndex].qty = newQty;
      } else {
        list[existingIndex].qty = product.countInStock;
      }
    } else {
      list.add(CartItem(
        product: product.id,
        name: product.name,
        image: product.image,
        price: product.price,
        qty: qty > product.countInStock ? product.countInStock : qty,
        countInStock: product.countInStock,
      ));
    }
    value = list;
    _saveCart();
  }

  // Update item quantity
  void updateQty(String productId, int qty) {
    final list = List<CartItem>.from(value);
    final index = list.indexWhere((item) => item.product == productId);

    if (index >= 0) {
      if (qty <= list[index].countInStock && qty > 0) {
        list[index].qty = qty;
        value = list;
        _saveCart();
      }
    }
  }

  // Remove item
  void removeItem(String productId) {
    final list = List<CartItem>.from(value);
    list.removeWhere((item) => item.product == productId);
    value = list;
    _saveCart();
  }

  // Clear Cart
  void clear() {
    value = [];
    _saveCart();
  }

  // Getters
  int get itemCount => value.fold(0, (sum, item) => sum + item.qty);
  
  double get subtotal => value.fold(0.0, (sum, item) => sum + (item.price * item.qty));
  
  double get taxPrice => subtotal * 0.12; // 12% VAT in Uzbekistan
  
  double get shippingPrice => subtotal > 100000 ? 0.0 : 15000.0; // Free shipping over 100,000 UZS, else 15,000 UZS
  
  double get totalPrice => subtotal + taxPrice + shippingPrice;
}
