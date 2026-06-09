import 'package:flutter/material.dart';
import '../api_service.dart';
import '../cart_manager.dart';
import '../models.dart';
import 'dashboard_screen.dart'; // import buildProductImage

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _productId;
  Product? _product;
  bool _isLoading = true;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isWishlistLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_productId == null) {
      _productId = ModalRoute.of(context)!.settings.arguments as String;
      _loadProductDetails();
      _checkWishlist();
    }
  }

  Future<void> _loadProductDetails() async {
    try {
      final product = await ApiService().getProductById(_productId!);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xatolik: ${e.toString().replaceAll('Exception:', '').trim()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _checkWishlist() async {
    try {
      final wishlist = await ApiService().getWishlist();
      setState(() {
        _isFavorite = wishlist.any((item) => item.id == _productId);
      });
    } catch (_) {
      // Wishlist check failed, default to false
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isWishlistLoading) return;
    setState(() => _isWishlistLoading = true);
    
    try {
      if (_isFavorite) {
        await ApiService().removeFromWishlist(_productId!);
        setState(() => _isFavorite = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saralanganlardan o\'chirildi'), duration: Duration(seconds: 1)),
          );
        }
      } else {
        await ApiService().addToWishlist(_productId!);
        setState(() => _isFavorite = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saralanganlarga qo\'shildi'), duration: Duration(seconds: 1), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _isWishlistLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }

    final product = _product!;
    final totalPrice = product.price * _quantity;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: CustomScrollView(
        slivers: [
          // Banner Image AppBar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFavorite ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-image-${product.id}',
                child: buildProductImage(product.image, fit: BoxFit.cover),
              ),
            ),
          ),
          
          // Content Detail overlapping sheets
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0.0, -28.0, 0.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand & Category Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          product.brand,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    
                    // Product Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Ratings & Reviews & Stock Status
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.numReviews} ta sharh)',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: product.countInStock > 0
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            product.countInStock > 0
                                ? 'Sotuvda: ${product.countInStock} dona'
                                : 'Tugagan',
                            style: TextStyle(
                              color: product.countInStock > 0
                                  ? const Color(0xFF2E7D32)
                                  : Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const Divider(height: 40, thickness: 1, color: Color(0xFFF1F5F9)),
                    
                    // Description
                    const Text(
                      'Mahsulot haqida tavsif',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Order Bar
      bottomNavigationBar: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price and Quantity
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Jami summa', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    '${totalPrice.toStringAsFixed(0)} UZS',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              
              if (product.countInStock > 0) ...[
                // Quantity Counter Widget
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 20, color: Color(0xFF475569)),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF2E7D32)),
                        onPressed: _quantity < product.countInStock
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Add to Cart Button with Gradient and Shadow
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        CartManager().addItem(product, qty: _quantity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} (${_quantity} dona) savatchaga qo\'shildi!'),
                            backgroundColor: const Color(0xFF2E7D32),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'Yopish',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Savatchaga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Text(
                      'Hozirda sotuvda mavjud emas',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
