import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models.dart';
import 'dashboard_screen.dart'; // import buildProductImage

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditProfileDialog(BuildContext context) {
    final user = ApiService().currentUser;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool updating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profil sozlamalari',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Foydalanuvchi ismi',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF2E7D32)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ism kiriting' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email pochta',
                          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF2E7D32)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email kiriting';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                            return 'To\'g\'ri email formatini kiriting';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Yangi parol (ixtiyoriy)',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF2E7D32)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF2E7D32),
                            ),
                            onPressed: () {
                              setModalState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) {
                          if (v != null && v.isNotEmpty && v.length < 6) {
                            return 'Parol kamida 6 belgidan iborat bo\'lishi kerak';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: updating ? null : () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          final profileData = {
                            'name': nameController.text.trim(),
                            'email': emailController.text.trim(),
                          };
                          if (passwordController.text.isNotEmpty) {
                            profileData['password'] = passwordController.text;
                          }

                          setModalState(() => updating = true);
                          try {
                            await ApiService().updateProfile(profileData);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profil muvaffaqiyatli yangilandi!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            // Force rebuild ProfileScreen to reflect updated details
                            setState(() {});
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception:', '').trim()),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } finally {
                            setModalState(() => updating = false);
                          }
                        },
                        child: updating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
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
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Card Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.person, color: Color(0xFF2E7D32), size: 40),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Foydalanuvchi',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'email@example.com',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user?.isAdmin == true
                                ? 'Admin'
                                : (user?.isFarmer == true ? 'Dehqon' : 'Xaridor'),
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Farmer dashboard access button
            if (user?.isFarmer == true || user?.isAdmin == true) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.dashboard_customize_rounded, color: Colors.white),
                  title: const Text(
                    'Dehqon boshqaruv paneli',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('O\'z mahsulotlaringizni boshqaring', style: TextStyle(color: Colors.white.withOpacity(0.74), fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  onTap: () {
                    Navigator.pushNamed(context, '/farmer-panel');
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Other settings/actions
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shopping_bag_rounded, color: Color(0xFF2E7D32)),
                    title: Text(user?.isAdmin == true ? 'Buyurtmalar boshqaruvi' : 'Mening buyurtmalarim'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.pushNamed(context, '/orders'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.favorite_rounded, color: Color(0xFF2E7D32)),
                    title: const Text('Saralangan mahsulotlar'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.pushNamed(context, '/wishlist'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF2E7D32)),
                    title: const Text('Profil sozlamalari'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => _showEditProfileDialog(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Logout
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              onPressed: widget.onLogout,
              child: const Text('Tizimdan chiqish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class FarmerPanelScreen extends StatefulWidget {
  const FarmerPanelScreen({super.key});

  @override
  State<FarmerPanelScreen> createState() => _FarmerPanelScreenState();
}

class _FarmerPanelScreenState extends State<FarmerPanelScreen> {
  List<Product> _myProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyProducts();
  }

  Future<void> _loadMyProducts() async {
    // Only show loading spinner if we have no products displayed yet (instant cache rendering)
    setState(() => _isLoading = _myProducts.isEmpty);
    try {
      final result = await ApiService().getProducts(
        myProducts: true,
        onCacheLoaded: (cachedResult) {
          if (mounted) {
            setState(() {
              _myProducts = cachedResult['products'];
              _isLoading = false; // Hide loader early
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _myProducts = result['products'];
        });
      }
    } catch (e) {
      if (mounted && _myProducts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: ${e.toString().replaceAll('Exception:', '').trim()}'),
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

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlash'),
        content: const Text('Haqiqatan ham ushbu mahsulotni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor qilish')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('O\'chirish', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService().deleteProduct(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mahsulot muvaffaqiyatli o\'chirildi'), backgroundColor: Colors.green),
      );
      _loadMyProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: ${e.toString().replaceAll('Exception:', '').trim()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showAddProductDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final brandController = TextEditingController(text: 'Agrom Fermer');
    final stockController = TextEditingController(text: '100');
    final descController = TextEditingController();
    final imageController = TextEditingController(text: 'https://images.unsplash.com/photo-1592417817098-8f3d6eb19675?q=80&w=400&auto=format&fit=crop');
    String category = 'Mevalar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Yangi mahsulot qo\'shish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Mahsulot nomi'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nom kiriting' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Narxi (UZS)'),
                              validator: (v) => v == null || double.tryParse(v) == null ? 'To\'g\'ri narx kiriting' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Soni (Omborda)'),
                              validator: (v) => v == null || int.tryParse(v) == null ? 'Son kiriting' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: brandController,
                        decoration: const InputDecoration(labelText: 'Brend / Fermer nomi'),
                        validator: (v) => v == null || v.isEmpty ? 'Kiritish majburiy' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(labelText: 'Kategoriya'),
                        items: ['Mevalar', 'Sabzavotlar', 'Donli mahsulotlar', 'O\'g\'itlar', 'Texnika'].map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => category = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: imageController,
                        decoration: const InputDecoration(labelText: 'Rasm URL manzili'),
                        validator: (v) => v == null || v.isEmpty ? 'Rasm havolasini kiriting' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Mahsulot haqida tavsif'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Tavsif yozing' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          final productData = {
                            'name': nameController.text.trim(),
                            'price': double.parse(priceController.text),
                            'brand': brandController.text.trim(),
                            'category': category,
                            'countInStock': int.parse(stockController.text),
                            'image': imageController.text.trim(),
                            'description': descController.text.trim(),
                          };

                          try {
                            await ApiService().createProduct(productData);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mahsulot yaratildi!'), backgroundColor: Colors.green),
                              );
                            }
                            _loadMyProducts();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim()), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                        child: const Text('Qo\'shish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProductDialog(Product product) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toStringAsFixed(0));
    final brandController = TextEditingController(text: product.brand);
    final stockController = TextEditingController(text: product.countInStock.toString());
    final descController = TextEditingController(text: product.description);
    final imageController = TextEditingController(text: product.image);
    String category = product.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mahsulotni tahrirlash', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Mahsulot nomi'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nom kiriting' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Narxi (UZS)'),
                              validator: (v) => v == null || double.tryParse(v) == null ? 'To\'g\'ri narx kiriting' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Soni (Omborda)'),
                              validator: (v) => v == null || int.tryParse(v) == null ? 'Son kiriting' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: brandController,
                        decoration: const InputDecoration(labelText: 'Brend / Fermer nomi'),
                        validator: (v) => v == null || v.isEmpty ? 'Kiritish majburiy' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: ['Mevalar', 'Sabzavotlar', 'Donli mahsulotlar', 'O\'g\'itlar', 'Texnika'].contains(category) ? category : 'Mevalar',
                        decoration: const InputDecoration(labelText: 'Kategoriya'),
                        items: ['Mevalar', 'Sabzavotlar', 'Donli mahsulotlar', 'O\'g\'itlar', 'Texnika'].map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => category = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: imageController,
                        decoration: const InputDecoration(labelText: 'Rasm URL manzili'),
                        validator: (v) => v == null || v.isEmpty ? 'Rasm havolasini kiriting' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Mahsulot haqida tavsif'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Tavsif yozing' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          final productData = {
                            'name': nameController.text.trim(),
                            'price': double.parse(priceController.text),
                            'brand': brandController.text.trim(),
                            'category': category,
                            'countInStock': int.parse(stockController.text),
                            'image': imageController.text.trim(),
                            'description': descController.text.trim(),
                          };

                          try {
                            await ApiService().updateProduct(product.id, productData);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mahsulot yangilandi!'), backgroundColor: Colors.green),
                              );
                            }
                            _loadMyProducts();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim()), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                        child: const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('Mening Mahsulotlarim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _myProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Sizda mahsulotlar mavjud emas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                        icon: const Icon(Icons.add),
                        label: const Text('Birinchi mahsulotni qo\'shish'),
                        onPressed: _showAddProductDialog,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myProducts.length,
                  itemBuilder: (context, index) {
                    final product = _myProducts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(width: 60, height: 60, child: buildProductImage(product.image)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${product.price.toStringAsFixed(0)} UZS • Omborda: ${product.countInStock} dona',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Color(0xFF2E7D32)),
                                onPressed: () => _showEditProductDialog(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                onPressed: () => _deleteProduct(product.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: _myProducts.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF2E7D32),
              onPressed: _showAddProductDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Product> _wishlist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final list = await ApiService().getWishlist();
      setState(() {
        _wishlist = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeWish(String id) async {
    try {
      final list = await ApiService().removeFromWishlist(id);
      setState(() {
        _wishlist = list;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('Saralanganlar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _wishlist.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border_rounded, size: 70, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Saralangan mahsulotlar yo\'q', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _wishlist.length,
                  itemBuilder: (context, index) {
                    final product = _wishlist[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/product-detail', arguments: product.id).then((_) => _loadWishlist());
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(width: 60, height: 60, child: buildProductImage(product.image)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${product.price.toStringAsFixed(0)} UZS',
                                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                              onPressed: () => _removeWish(product.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
