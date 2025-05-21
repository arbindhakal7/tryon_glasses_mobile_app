import 'package:flutter/material.dart';
import 'package:tryon/database/database_helper.dart';
import 'package:tryon/models/cart_item.dart';
import 'package:tryon/services/auth_service.dart'; // Import AuthService

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService(); // Initialize AuthService
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  String? _currentUserId; // To store the ID of the currently logged-in user

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    // Ensure authService has initialized and current user is set
    await _authService
        .initAuthService(); // Call initAuthService if not already done in main.dart
    _currentUserId = _authService.currentUser?.id?.toString();

    if (_currentUserId == null) {
      // Handle case where user is not logged in (e.g., show a message, navigate to login)
      _showSnackBar('Please log in to view your cart.');
      setState(() {
        _isLoading = false;
        _cartItems = []; // Clear cart items if no user is logged in
      });
      return;
    }
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    if (_currentUserId == null) return; // Do not load if no user is logged in

    setState(() {
      _isLoading = true;
    });
    try {
      _cartItems = await _dbHelper.getCartItems(_currentUserId!); // Pass userId
    } catch (e) {
      print('Error loading cart items: $e');
      _showSnackBar('Failed to load cart items.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateQuantity(CartItem item, int change) async {
    final newQuantity = item.quantity + change;
    if (newQuantity <= 0) {
      _confirmAndDeleteItem(item.id!, item.glass?.name ?? 'item');
    } else {
      try {
        await _dbHelper.updateCartItemQuantity(item.id!, newQuantity);
        _loadCartItems(); // Reload to reflect changes
      } catch (e) {
        print('Error updating quantity: $e');
        _showSnackBar('Failed to update quantity.');
      }
    }
  }

  Future<void> _confirmAndDeleteItem(int itemId, String itemName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Remove Item?'),
          content: Text(
            'Are you sure you want to remove "$itemName" from your cart?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User cancels
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // User confirms
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red color for delete action
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteItem(itemId);
    }
  }

  void _deleteItem(int itemId) async {
    try {
      await _dbHelper.deleteCartItem(itemId);
      _loadCartItems(); // Reload to reflect changes
      _showSnackBar('Item removed from cart.');
    } catch (e) {
      print('Error deleting item: $e');
      _showSnackBar('Failed to remove item.');
    }
  }

  double get _totalPrice {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.price),
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
      appBar: AppBar(title: const Text('Your Cart'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cartItems.isEmpty &&
                  _currentUserId !=
                      null // Show empty cart message only if user is logged in
              ? const Center(child: Text('Your cart is empty.'))
              : _currentUserId == null
              ? const Center(
                child: Text('Please log in to view your cart.'),
              ) // Message if not logged in
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.glass?.imageUrl ??
                                        'https://placehold.co/100x100?text=No+Image',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.glass?.name ?? 'Unknown Glass',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${item.price.toStringAsFixed(2)} per item',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                            onPressed:
                                                () => _updateQuantity(item, -1),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                            onPressed:
                                                () => _updateQuantity(item, 1),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Total: \$${(item.quantity * item.price).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _confirmAndDeleteItem(
                                        item.id!,
                                        item.glass?.name ?? 'item',
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${_totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              _cartItems.isEmpty
                                  ? null
                                  : () {
                                    Navigator.pushNamed(context, '/checkout');
                                  },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              50,
                            ), // Make button full width
                          ),
                          child: const Text('Proceed to Checkout'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
