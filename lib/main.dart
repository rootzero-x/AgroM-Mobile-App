import 'package:flutter/material.dart';
import 'api_service.dart';
import 'cart_manager.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/cart_checkout_screens.dart';
import 'screens/profile_farmer_screens.dart';
import 'screens/orders_screen.dart';
import 'notification_service.dart';
import 'order_tracker.dart';
import 'background_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service (loads local token & profile)
  final apiService = ApiService();
  await apiService.init();
  
  // Initialize notifications
  await NotificationService().init();

  // Initialize background service
  await initializeBackgroundService();
  
  // Initialize Cart Manager (loads local saved cart)
  CartManager();

  // Request notifications permission if already authenticated
  if (apiService.isAuthenticated) {
    NotificationService().requestPermissions();
  }

  runApp(const AgromApp());
}

class AgromApp extends StatelessWidget {
  const AgromApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ApiService().isAuthenticated;

    return MaterialApp(
      title: 'AgroM',
      debugShowCheckedModeBanner: false,
      
      // Premium Professional Agrom Design Theme
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF4F6F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF10B981),
          surface: Colors.white,
          background: const Color(0xFFF4F6F4),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      
      initialRoute: isAuthenticated ? '/dashboard' : '/login',
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget screen;
    switch (settings.name) {
      case '/login':
        screen = const LoginScreen();
        break;
      case '/register':
        screen = const RegisterScreen();
        break;
      case '/dashboard':
        screen = const MainTabController();
        break;
      case '/product-detail':
        screen = const ProductDetailScreen();
        break;
      case '/checkout':
        screen = const CheckoutScreen();
        break;
      case '/farmer-panel':
        screen = const FarmerPanelScreen();
        break;
      case '/wishlist':
        screen = const WishlistScreen();
        break;
      case '/orders':
        screen = const OrdersScreen();
        break;
      default:
        return null;
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.06);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

class MainTabController extends StatefulWidget {
  const MainTabController({super.key});

  @override
  State<MainTabController> createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _selectedIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, {bool isCart = false}) {
    final isSelected = _selectedIndex == index;
    final primaryColor = const Color(0xFF2E7D32);
    
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isCart
                ? ValueListenableBuilder(
                    valueListenable: CartManager(),
                    builder: (context, value, child) {
                      final count = CartManager().itemCount;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            isSelected ? filledIcon : outlineIcon,
                            color: isSelected ? primaryColor : Colors.grey[500],
                            size: 24,
                          ),
                          if (count > 0)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                : Icon(
                    isSelected ? filledIcon : outlineIcon,
                    color: isSelected ? primaryColor : Colors.grey[500],
                    size: 24,
                  ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onTabChange: _onTabChanged),
      const CartScreen(),
      ProfileScreen(
        onLogout: () async {
          // Stop background service on logout
          FlutterBackgroundService().invoke("stopService");
          await ApiService().logout();
          CartManager().clear();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.storefront_outlined, Icons.storefront_rounded, 'Do\'kon'),
                _buildNavItem(1, Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, 'Savatcha', isCart: true),
                _buildNavItem(2, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
