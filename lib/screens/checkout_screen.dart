import 'package:flutter/material.dart';
import 'package:tryon/database/database_helper.dart';
import 'package:tryon/models/cart_item.dart';
import 'package:tryon/services/auth_service.dart'; // Import AuthService

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService(); // Initialize AuthService
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  String? _currentUserId; // To store the ID of the currently logged-in user

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCheckout();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initializeCheckout() async {
    // Ensure authService has initialized and current user is set
    await _authService.initAuthService();
    _currentUserId = _authService.currentUser?.id?.toString();

    if (_currentUserId == null) {
      _showSnackBar('Please log in to proceed to checkout.');
      setState(() {
        _isLoading = false;
        _cartItems = [];
      });
      // Optionally navigate back to login or home
      Navigator.pop(context);
      return;
    }
    await _loadUserDataAndCart();
  }

  Future<void> _loadUserDataAndCart() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_currentUserId != null) {
        final user = await _dbHelper.getUserById(_currentUserId!);
        if (user != null) {
          _nameController.text = user.username;
          _addressController.text = user.address ?? '';
          _phoneController.text = user.phoneNumber ?? '';
        }
        _cartItems = await _dbHelper.getCartItems(_currentUserId!);
      }
    } catch (e) {
      print('Error loading checkout data: $e');
      _showSnackBar('Failed to load checkout data.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double get _totalPrice {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.price),
    );
  }

  void _proceedToPayment() {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showSnackBar('Please fill in all delivery details.');
      return;
    }
    if (_cartItems.isEmpty) {
      _showSnackBar('Your cart is empty. Cannot proceed to payment.');
      return;
    }

    // Pass total amount and cart items to the PaymentScreen
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {'totalAmount': _totalPrice, 'cartItems': _cartItems},
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Order Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.glass?.name ?? 'Unknown'} (x${item.quantity})',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '\$${(item.quantity * item.price).toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 32, thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${_totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Delivery Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _proceedToPayment,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Proceed to Payment'),
                    ),
                  ],
                ),
              ),
    );
  }
}
