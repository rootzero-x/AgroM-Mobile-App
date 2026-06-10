import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api_service.dart';
import '../cart_manager.dart';
import '../models.dart';

// Robust cached product image builder with double slash normalizer
Widget buildProductImage(String imagePath, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
  String imageUrl = imagePath.trim();
  if (!imageUrl.startsWith('http') && imageUrl.isNotEmpty) {
    if (imageUrl.startsWith('/')) {
      imageUrl = imageUrl.substring(1);
    }
    imageUrl = 'https://api.agrom24.uz/$imageUrl';
  }
  return CachedNetworkImage(
    imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?q=80&w=300&auto=format&fit=crop',
    height: height,
    width: width,
    fit: fit,
    placeholder: (context, url) => Container(
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF2E7D32),
          ),
        ),
      ),
    ),
    errorWidget: (context, url, error) => Container(
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(
          Icons.eco_rounded,
          color: Color(0xFF2E7D32),
          size: 45,
        ),
      ),
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const DashboardScreen({super.key, required this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'Barchasi';
  int _currentPage = 1;
  int _totalPages = 1;
  List<Product> _products = [];
  bool _isLoading = false;
  bool _isLoadMoreLoading = false;

  final List<String> _categories = [
    'Barchasi',
    'Mevalar',
    'Sabzavotlar',
    'Donli mahsulotlar',
    'O\'g\'itlar',
    'Texnika',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadMoreLoading && _currentPage < _totalPages) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _fetchProducts() async {
    // Only show loading spinner if we have no products displayed yet (instant cache rendering)
    setState(() => _isLoading = _products.isEmpty);
    try {
      final result = await ApiService().getProducts(
        keyword: _searchController.text,
        category: _selectedCategory,
        pageNumber: _currentPage,
        onCacheLoaded: (cachedResult) {
          if (mounted) {
            setState(() {
              _products = List<Product>.from(cachedResult['products']);
              _currentPage = cachedResult['page'];
              _totalPages = cachedResult['pages'];
              _isLoading = false; // Hide loader early
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _products = List<Product>.from(result['products']);
          _currentPage = result['page'];
          _totalPages = result['pages'];
        });
      }
    } catch (e) {
      if (mounted && _products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mahsulotlarni yuklashda xatolik: ${e.toString().replaceAll('Exception:', '').trim()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadMoreLoading || _currentPage >= _totalPages) return;
    setState(() => _isLoadMoreLoading = true);

    try {
      final nextPage = _currentPage + 1;
      final result = await ApiService().getProducts(
        keyword: _searchController.text,
        category: _selectedCategory,
        pageNumber: nextPage,
      );

      if (mounted) {
        setState(() {
          final List<Product> newProducts = List<Product>.from(result['products']);
          final existingIds = _products.map((p) => p.id).toSet();
          final uniqueNewProducts = newProducts.where((p) => !existingIds.contains(p.id)).toList();

          _products.addAll(uniqueNewProducts);
          _currentPage = result['page'];
          _totalPages = result['pages'];
        });
      }
    } catch (e) {
      print('DashboardScreen: Error loading more products: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadMoreLoading = false);
      }
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _currentPage = 1;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _fetchProducts();
  }

  void _onSearch() {
    setState(() => _currentPage = 1);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ApiService().currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salom, ${currentUser?.name ?? "Foydalanuvchi"}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  currentUser?.isFarmer == true ? 'Dehqon profili' : 'Xaridor profili',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.74)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Wishlist Action
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/wishlist');
            },
          ),
          // Cart Icon with badge
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: CartManager(),
            builder: (context, cartItems, child) {
              final count = CartManager().itemCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () => widget.onTabChange(1), // Go to Cart tab
                  ),
                  if (count > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Premium Search Bar Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Container(
              height: 46,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _onSearch(),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: 'Mahsulotlarni qidiring...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E7D32), size: 22),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(5),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      onPressed: _onSearch,
                    ),
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 46,
                    minHeight: 46,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
          ),
          
          // Categories list
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: EdgeInsets.only(left: 16, right: index == _categories.length - 1 ? 16.0 : 0.0),
                  child: AnimatedCategoryChip(
                    label: category,
                    isSelected: isSelected,
                    onTap: () => _onCategorySelected(category),
                  ),
                );
              },
            ),
          ),
          
          // Products Grid or Loader
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchProducts,
              color: const Color(0xFF2E7D32),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                  : _products.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.agriculture_rounded, size: 70, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Mahsulotlar topilmadi',
                                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: MediaQuery.of(context).size.width > 1400
                                      ? 6
                                      : MediaQuery.of(context).size.width > 1100
                                          ? 5
                                          : MediaQuery.of(context).size.width > 800
                                              ? 4
                                              : MediaQuery.of(context).size.width > 600
                                                  ? 3
                                                  : 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final product = _products[index];
                                    return ProductCard(
                                      product: product,
                                      onReload: _fetchProducts,
                                    );
                                  },
                                  childCount: _products.length,
                                ),
                              ),
                            ),
                            if (_isLoadMoreLoading)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

// Premium animated category chip
class AnimatedCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const AnimatedCategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// Premium stateful product card with press animation
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onReload;
  const ProductCard({super.key, required this.product, required this.onReload});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: product.id,
        ).then((_) => widget.onReload());
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image with rounded corners and Badge
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Hero(
                          tag: 'product-image-${product.id}',
                          child: buildProductImage(product.image),
                        ),
                      ),
                    ),
                    // Stock Status Badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: product.countInStock > 0
                              ? const Color(0xFFE8F5E9).withOpacity(0.95)
                              : const Color(0xFFFFEBEE).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: (product.countInStock > 0 ? const Color(0xFF2E7D32) : Colors.redAccent)
                                  .withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          product.countInStock > 0 ? 'Sotuvda bor' : 'Tugagan',
                          style: TextStyle(
                            color: product.countInStock > 0
                                ? const Color(0xFF2E7D32)
                                : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Details
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          ' (${product.numReviews})',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${product.price.toStringAsFixed(0)} UZS',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        // Quick Add to Cart button
                        if (product.countInStock > 0)
                          GestureDetector(
                            onTap: () {
                              CartManager().addItem(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} savatchaga qo\'shildi!'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: const Color(0xFF2E7D32),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 14),
                            ),
                          ),
                      ],
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
