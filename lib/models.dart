class User {
  final String id;
  final String name;
  final String email;
  final bool isAdmin;
  final bool isFarmer;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
    required this.isFarmer,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isAdmin: json['isAdmin'] ?? false,
      isFarmer: json['isFarmer'] ?? false,
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'isAdmin': isAdmin,
      'isFarmer': isFarmer,
      if (token != null) 'token': token,
    };
  }
}

class Product {
  final String id;
  final String user; // User ID who created the product
  final String name;
  final String image;
  final String brand;
  final String category;
  final String description;
  final double rating;
  final int numReviews;
  final double price;
  final int countInStock;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.user,
    required this.name,
    required this.image,
    required this.brand,
    required this.category,
    required this.description,
    required this.rating,
    required this.numReviews,
    required this.price,
    required this.countInStock,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      user: json['user'] is Map ? (json['user']['_id'] ?? '') : (json['user'] ?? ''),
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      numReviews: (json['numReviews'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      countInStock: (json['countInStock'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user,
      'name': name,
      'image': image,
      'brand': brand,
      'category': category,
      'description': description,
      'rating': rating,
      'numReviews': numReviews,
      'price': price,
      'countInStock': countInStock,
    };
  }
}

class CartItem {
  final String product; // Product ID
  final String name;
  final String image;
  final double price;
  int qty;
  final int countInStock;

  CartItem({
    required this.product,
    required this.name,
    required this.image,
    required this.price,
    required this.qty,
    required this.countInStock,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: json['product'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      countInStock: (json['countInStock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product,
      'name': name,
      'image': image,
      'price': price,
      'qty': qty,
      'countInStock': countInStock,
    };
  }
}

class ShippingAddress {
  final String address;
  final String city;
  final String postalCode;
  final String country;

  ShippingAddress({
    required this.address,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'country': country,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final List<CartItem> orderItems;
  final ShippingAddress shippingAddress;
  final String paymentMethod;
  final double taxPrice;
  final double shippingPrice;
  final double totalPrice;
  final bool isPaid;
  final DateTime? paidAt;
  final bool isDelivered;
  final DateTime? deliveredAt;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.orderItems,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.taxPrice,
    required this.shippingPrice,
    required this.totalPrice,
    required this.isPaid,
    this.paidAt,
    required this.isDelivered,
    this.deliveredAt,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var list = json['orderItems'] as List? ?? [];
    List<CartItem> items = list.map((i) => CartItem.fromJson(i)).toList();

    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user'] is Map ? (json['user']['_id'] ?? '') : (json['user'] ?? ''),
      orderItems: items,
      shippingAddress: ShippingAddress.fromJson(json['shippingAddress'] ?? {}),
      paymentMethod: json['paymentMethod'] ?? '',
      taxPrice: (json['taxPrice'] as num?)?.toDouble() ?? 0.0,
      shippingPrice: (json['shippingPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
      isDelivered: json['isDelivered'] ?? false,
      deliveredAt: json['deliveredAt'] != null ? DateTime.tryParse(json['deliveredAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
