import 'package:flutter/material.dart';
import '../api_service.dart';
import '../cart_manager.dart';
import '../models.dart';
import 'dashboard_screen.dart'; // import buildProductImage

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('Xarid savatchasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartManager(),
        builder: (context, cartItems, child) {
          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Savatchangiz bo\'sh',
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Do\'kondan mahsulotlarni tanlab qo\'shing',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Cart items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return _buildCartItemCard(item);
                  },
                ),
              ),

              // Totals summary panel
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Orqaga (Mahsulotlar summasi)', '${CartManager().subtotal.toStringAsFixed(0)} UZS'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('QQS (12%)', '${CartManager().taxPrice.toStringAsFixed(0)} UZS'),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Yetkazib berish',
                      CartManager().shippingPrice == 0 ? 'Bepul' : '${CartManager().shippingPrice.toStringAsFixed(0)} UZS',
                      valueColor: CartManager().shippingPrice == 0 ? Colors.green : Colors.black87,
                    ),
                    const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                    _buildSummaryRow(
                      'Jami summa',
                      '${CartManager().totalPrice.toStringAsFixed(0)} UZS',
                      isBold: true,
                      valueColor: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.25),
                            blurRadius: 12,
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
                          Navigator.pushNamed(context, '/checkout');
                        },
                        child: const Text(
                          'Rasmiylashtirishga o\'tish',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color valueColor = Colors.black87}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 80,
              height: 80,
              child: buildProductImage(item.image),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(0)} UZS',
                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity adjuster
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (item.qty > 1) {
                                CartManager().updateQty(item.product, item.qty - 1);
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Icon(Icons.remove_rounded, size: 14, color: Color(0xFF475569)),
                            ),
                          ),
                          Text(
                            '${item.qty}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (item.qty < item.countInStock) {
                                CartManager().updateQty(item.product, item.qty + 1);
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Icon(Icons.add_rounded, size: 14, color: Color(0xFF2E7D32)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Remove button
                    GestureDetector(
                      onTap: () => CartManager().removeItem(item.product),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  final _countryController = TextEditingController();
  String _paymentMethod = 'Naqd pul (Eshik oldida)';
  bool _isPlacingOrder = false;

  final List<String> _paymentMethods = [
    'Naqd pul (Eshik oldida)',
    'Payme / Click',
    'PayPal',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPlacingOrder = true);

    try {
      final cart = CartManager();
      
      final orderData = {
        'orderItems': cart.value.map((item) => {
          'product': item.product,
          'name': item.name,
          'image': item.image,
          'price': item.price,
          'qty': item.qty,
        }).toList(),
        'shippingAddress': {
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'postalCode': _postalController.text.trim(),
          'country': _countryController.text.trim(),
        },
        'paymentMethod': _paymentMethod,
        'itemsPrice': cart.subtotal,
        'taxPrice': cart.taxPrice,
        'shippingPrice': cart.shippingPrice,
        'totalPrice': cart.totalPrice,
      };

      await ApiService().createOrder(orderData);
      
      // Success clearing and routing
      cart.clear();
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2E7D32),
                        size: 80,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Buyurtma qabul qilindi!',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Tez orada operatorlarimiz siz bilan bog\'lanishadi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    ),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Close checkout screen
                    },
                    child: const Text('Bosh sahifaga', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Buyurtma xatoligi: ${e.toString().replaceAll('Exception:', '').trim()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('Buyurtma berish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Shipping info Section
                const Text(
                  'Yetkazib berish manzili',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _addressController,
                  decoration: _buildInputDecoration('Ko\'cha, uy, kvartira raqami', Icons.home_outlined),
                  validator: (value) => value == null || value.isEmpty ? 'Manzilni kiriting' : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _cityController,
                  decoration: _buildInputDecoration('Shahar / Viloyat', Icons.location_city),
                  validator: (value) => value == null || value.isEmpty ? 'Shahar nomini kiriting' : null,
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _postalController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration('Pochta indeksi', Icons.markunread_mailbox),
                        validator: (value) => value == null || value.isEmpty ? 'Pochta indeksini kiriting' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: _buildInputDecoration('Mamlakat', Icons.public),
                        validator: (value) => value == null || value.isEmpty ? 'Mamlakatni kiriting' : null,
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 40, thickness: 1, color: Color(0xFFE2E8F0)),
                
                // Payment method section
                const Text(
                  'To\'lov turi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _paymentMethod,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2E7D32)),
                      items: _paymentMethods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentMethod = val);
                      },
                    ),
                  ),
                ),
                
                const Divider(height: 40, thickness: 1, color: Color(0xFFE2E8F0)),
                
                // Totals
                const Text(
                  'Buyurtma hisobi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Column(
                    children: [
                      _buildTotalRow('Mahsulotlar summasi:', '${CartManager().subtotal.toStringAsFixed(0)} UZS'),
                      const SizedBox(height: 8),
                      _buildTotalRow('Yetkazib berish:', CartManager().shippingPrice == 0 ? 'Bepul' : '${CartManager().shippingPrice.toStringAsFixed(0)} UZS'),
                      const SizedBox(height: 8),
                      _buildTotalRow('QQS (12%):', '${CartManager().taxPrice.toStringAsFixed(0)} UZS'),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                      _buildTotalRow('Jami:', '${CartManager().totalPrice.toStringAsFixed(0)} UZS', isBold: true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Container(
                  height: 52,
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
                    onPressed: _isPlacingOrder ? null : _submitOrder,
                    child: _isPlacingOrder
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Buyurtma berish',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? const Color(0xFF2E7D32) : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? const Color(0xFF2E7D32) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
