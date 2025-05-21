import 'package:flutter/material.dart';
import 'package:tryon/screens/auth/login_screen.dart';
import 'package:tryon/screens/auth/signup_screen.dart';
import 'package:tryon/screens/home_screen.dart';
import 'package:tryon/screens/product_detail_screen.dart';
import 'package:tryon/screens/cart_screen.dart';
import 'package:tryon/screens/checkout_screen.dart';
import 'package:tryon/screens/payment_screen.dart';
import 'package:tryon/models/glass.dart';
import 'package:tryon/models/cart_item.dart'; // Import CartItem

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glasses E-commerce App',
      theme: ThemeData(
        // New primary color swatch (teal for a fresh look)
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal, // AppBar background
          foregroundColor: Colors.white, // AppBar text/icon color
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal, // Primary button background
            foregroundColor: Colors.white, // Primary button text/icon color
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100], // Light grey for input fields
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Add text theme for consistent typography
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16.0),
          bodyMedium: TextStyle(fontSize: 14.0),
          labelLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        // Define an accent color if needed for specific widgets (e.g., progress indicators)
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
        ).copyWith(
          secondary: Colors.orangeAccent, // Accent color
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/product_detail': (context) {
          final glass = ModalRoute.of(context)!.settings.arguments as Glass;
          return ProductDetailScreen(glass: glass);
        },
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        // Correctly handle arguments for PaymentScreen
        '/payment': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          final totalAmount = args['totalAmount'] as double;
          final cartItems = args['cartItems'] as List<CartItem>;
          return PaymentScreen(totalAmount: totalAmount, cartItems: cartItems);
        },
      },
    );
  }
}
