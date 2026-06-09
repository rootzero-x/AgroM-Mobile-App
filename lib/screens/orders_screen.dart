import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Order> _orders = [];
  bool _isLoading = true;
  String _statusFilter = 'Barchasi';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      final statuses = ['Barchasi', 'To\'lanmagan', 'Kutilmoqda', 'Yetkazilgan'];
      setState(() {
        _statusFilter = statuses[_tabController.index];
      });
    });
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService().getOrders();
      setState(() {
        _orders = list;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buyurtmalarni yuklashda xatolik: ${e.toString().replaceAll('Exception:', '').trim()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Order> get _filteredOrders {
    if (_statusFilter == 'Barchasi') return _orders;
    if (_statusFilter == 'To\'lanmagan') {
      return _orders.where((o) => !o.isPaid).toList();
    }
    if (_statusFilter == 'Kutilmoqda') {
      return _orders.where((o) => o.isPaid && !o.isDelivered).toList();
    }
    if (_statusFilter == 'Yetkazilgan') {
      return _orders.where((o) => o.isDelivered).toList();
    }
    return _orders;
  }

  void _showOrderDetails(Order order) {
    final isAdmin = ApiService().currentUser?.isAdmin == true;
    bool updating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pull handler line
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Buyurtma #${order.id.substring(order.id.length - 8).toUpperCase()}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),
                  
                  // Meta Address details card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, color: Color(0xFF2E7D32), size: 18),
                            const SizedBox(width: 8),
                            Text('Yetkazib berish manzili:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${order.shippingAddress.address}, ${order.shippingAddress.city}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                        ),
                        Text(
                          '${order.shippingAddress.postalCode}, ${order.shippingAddress.country}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Payment method card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payment_rounded, color: Color(0xFF2E7D32), size: 18),
                        const SizedBox(width: 8),
                        Text('To\'lov turi:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
                        const Spacer(),
                        Text(
                          order.paymentMethod,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Order Items List
                  const Text('Mahsulotlar:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: order.orderItems.length,
                      itemBuilder: (context, index) {
                        final item = order.orderItems[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          subtitle: Text('${item.price.toStringAsFixed(0)} UZS x ${item.qty}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          trailing: Text(
                            '${(item.price * item.qty).toStringAsFixed(0)} UZS',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Breakdown pricing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('QQS (12%):', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                      Text('${order.taxPrice.toStringAsFixed(0)} UZS', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Yetkazib berish:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                      Text(
                        order.shippingPrice == 0 ? 'Bepul' : '${order.shippingPrice.toStringAsFixed(0)} UZS',
                        style: TextStyle(fontWeight: FontWeight.bold, color: order.shippingPrice == 0 ? Colors.green : const Color(0xFF334155)),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jami summa:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2E7D32))),
                      Text(
                        '${order.totalPrice.toStringAsFixed(0)} UZS',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Admin Action Buttons
                  if (isAdmin) ...[
                    if (!order.isPaid) ...[
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(colors: [Colors.green, Color(0xFF1B5E20)]),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: updating ? null : () async {
                            setModalState(() => updating = true);
                            try {
                              await ApiService().markOrderAsPaid(order.id, byAdmin: true);
                              if (context.mounted) Navigator.pop(context);
                              _loadOrders();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            } finally {
                              setModalState(() => updating = false);
                            }
                          },
                          child: updating
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('To\'lovni tasdiqlash', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order.isPaid && !order.isDelivered) ...[
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: updating ? null : () async {
                            setModalState(() => updating = true);
                            try {
                              await ApiService().markOrderAsDelivered(order.id);
                              if (context.mounted) Navigator.pop(context);
                              _loadOrders();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            } finally {
                              setModalState(() => updating = false);
                            }
                          },
                          child: updating
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Yetkazilgan deb belgilash', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService().currentUser;
    final isAdmin = user?.isAdmin == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Buyurtmalar boshqaruvi' : 'Buyurtmalar tarixi',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.white),
            insets: EdgeInsets.symmetric(horizontal: 16.0),
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Barchasi'),
            Tab(text: 'To\'lovsiz'),
            Tab(text: 'Kutilmoqda'),
            Tab(text: 'Etkazildi'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 70, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Buyurtmalar topilmadi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: const Color(0xFF2E7D32),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final dateStr = order.createdAt != null
        ? '${order.createdAt!.day.toString().padLeft(2, '0')}.${order.createdAt!.month.toString().padLeft(2, '0')}.${order.createdAt!.year} ${order.createdAt!.hour.toString().padLeft(2, '0')}:${order.createdAt!.minute.toString().padLeft(2, '0')}'
        : 'Sana aniqlanmadi';

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#${order.id.substring(order.id.length - 8).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32)),
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 12),
                Text(
                  '${order.orderItems.length} xil mahsulot',
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${order.totalPrice.toStringAsFixed(0)} UZS',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2E7D32), fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Payment Status Badge
                _buildBadge(
                  order.isPaid ? 'To\'langan' : 'To\'lanmagan',
                  order.isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                // Delivery Status Badge
                _buildBadge(
                  order.isDelivered 
                      ? 'Yetkazildi' 
                      : (order.isPaid ? 'Kutilmoqda' : 'Kutilmoqda (To\'lovsiz)'),
                  order.isDelivered 
                      ? const Color(0xFF10B981) 
                      : (order.isPaid ? const Color(0xFFF59E0B) : const Color(0xFF64748B)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
