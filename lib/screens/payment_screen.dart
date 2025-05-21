import 'package:flutter/material.dart';
import 'package:tryon/database/database_helper.dart';
import 'package:tryon/models/cart_item.dart'; // Import CartItem
import 'package:tryon/models/order.dart'; // Import Order model
import 'package:tryon/services/auth_service.dart'; // Import AuthService

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final List<CartItem> cartItems; // New: Receive cart items

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.cartItems,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'Credit Card';
  bool _isProcessingPayment = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService(); // Initialize AuthService

  void _processPayment() async {
    setState(() {
      _isProcessingPayment = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, integrate with a payment gateway (e.g., Stripe, PayPal)
    // This is a placeholder for successful payment.
    bool paymentSuccessful = true; // Assume success for demonstration

    setState(() {
      _isProcessingPayment = false;
    });

    if (paymentSuccessful) {
      // Get current user ID
      final currentUser = _authService.currentUser;
      print('PaymentScreen: Current User: $currentUser'); // Debug print
      print(
        'PaymentScreen: Current User ID: ${currentUser?.id}',
      ); // Debug print

      if (currentUser != null && currentUser.id != null) {
        // Prepare items for the order (extract relevant details from CartItem)
        final List<Map<String, dynamic>> orderItems =
            widget.cartItems
                .map(
                  (item) => {
                    'glassId': item.glassId,
                    'quantity': item.quantity,
                    'price': item.price,
                    'name':
                        item.glass?.name ??
                        'Unknown', // Include name for display in order history
                    'imageUrl':
                        item.glass?.imageUrl ??
                        '', // Include image URL for display
                  },
                )
                .toList();

        // Create an Order object
        final order = Order(
          userId: currentUser.id!.toString(), // Convert user ID to string
          totalAmount: widget.totalAmount,
          orderDate:
              DateTime.now().toIso8601String(), // Current date as ISO string
          items: orderItems,
        );

        try {
          // Insert the order into the database
          await _dbHelper.insertOrder(order);
          print('Order inserted successfully for user: ${currentUser.id}');
        } catch (e) {
          print(
            'PaymentScreen: Error inserting order into database: $e',
          ); // Specific error for database insert
          _showSnackBar('Failed to save order to database.');
          // Do not proceed to success dialog if database save failed
          return;
        }
      } else {
        print(
          'Error: Current user not found or ID is null, cannot save order.',
        );
        _showSnackBar(
          'Order could not be saved: User not logged in or ID missing.',
        );
        return; // Do not proceed to success dialog if user is not logged in
      }

      // Clear the cart after successful payment and order saving
      await _dbHelper.clearCart(
        currentUser!.id!.toString(),
      ); // Pass userId to clearCart
      _showSuccessDialog();
    } else {
      _showSnackBar('Payment failed. Please try again.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 10),
              Text('Payment Successful!', textAlign: TextAlign.center),
            ],
          ),
          content: Text(
            'Your order of \$${widget.totalAmount.toStringAsFixed(2)} has been placed successfully.',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Continue Shopping'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ); // Go to home and clear stack
              },
            ),
          ],
        );
      },
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
      appBar: AppBar(title: const Text('Payment'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Total Amount: \$${widget.totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Select Payment Method',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: RadioListTile<String>(
                title: const Text('Credit Card'),
                value: 'Credit Card',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                secondary: const Icon(Icons.credit_card),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: RadioListTile<String>(
                title: const Text('PayPal'),
                value: 'PayPal',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                secondary: const Icon(
                  Icons.paypal,
                ), // Requires a custom icon or font awesome
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: RadioListTile<String>(
                title: const Text('Google Pay'),
                value: 'Google Pay',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                secondary: const Icon(Icons.payment),
              ),
            ),
            const SizedBox(height: 32),
            _isProcessingPayment
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Pay Now'),
                ),
          ],
        ),
      ),
    );
  }
}
