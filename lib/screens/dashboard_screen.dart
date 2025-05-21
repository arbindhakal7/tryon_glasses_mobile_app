import 'package:flutter/material.dart';
import 'package:tryon/services/auth_service.dart';
import 'package:tryon/database/database_helper.dart'; // Import DatabaseHelper
import 'package:tryon/models/order.dart'; // Assuming you have an Order model

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Order> _orderHistory = [];
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _loadOrderHistory();
  }

  Future<void> _loadOrderHistory() async {
    setState(() {
      _isLoadingOrders = true;
    });
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null && currentUser.id != null) {
        // Corrected: Convert currentUser.id to String
        _orderHistory = await _dbHelper.getOrdersForUser(
          currentUser.id!.toString(),
        );
      } else {
        _orderHistory = [];
        print('User not logged in or user ID not available.');
      }
    } catch (e) {
      print('Error loading order history: $e');
      _showSnackBar('Failed to load order history.');
    } finally {
      setState(() {
        _isLoadingOrders = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${currentUser?.username ?? 'Guest'}!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Account Settings'),
                    onTap: () {
                      // Navigate to profile screen, which is now part of bottom nav
                      // We don't navigate via route name here to avoid nesting AppBars
                      // Instead, the HomeScreen's BottomNavigationBar handles the tab switch.
                      // For now, we'll keep the snackbar or navigate if it's a separate route.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Go to Profile tab for settings.'),
                        ),
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Contact support at support@glasses.com',
                          ),
                        ),
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Past Orders',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _isLoadingOrders
              ? const Center(child: CircularProgressIndicator())
              : _orderHistory.isEmpty
              ? const Center(child: Text('No past orders found.'))
              : Expanded(
                child: ListView.builder(
                  itemCount: _orderHistory.length,
                  itemBuilder: (context, index) {
                    final order = _orderHistory[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.id ?? 'N/A'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Date: ${order.orderDate.substring(0, 10)}', // Format date
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Items:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            ...order.items
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      top: 4.0,
                                    ),
                                    child: Text(
                                      '${item['name']} x${item['quantity']} (\$${item['price'].toStringAsFixed(2)} each)',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}
