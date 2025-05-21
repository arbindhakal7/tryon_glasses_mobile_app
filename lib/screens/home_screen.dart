import 'package:flutter/material.dart';
import 'package:tryon/database/database_helper.dart';
import 'package:tryon/models/glass.dart';
import 'package:tryon/models/cart_item.dart';
import 'package:tryon/services/auth_service.dart';
import 'package:tryon/screens/dashboard_screen.dart';
import 'package:tryon/screens/profile_screen.dart';
import 'package:tryon/screens/auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService();
  List<Glass> _glasses = [];
  List<Glass> _featuredGlasses = [];
  bool _isLoading = true;
  int _cartItemCount = 0;
  String? _currentUserId; // Store current user ID

  int _selectedIndex = 0;

  final GlobalKey<ProfileScreenState> _profileScreenKey =
      GlobalKey<ProfileScreenState>();

  final List<String> _screenTitles = const [
    'Glasses Store',
    'Dashboard',
    'Profile',
    'Logout',
  ];

  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _currentUserId =
        _authService.currentUser?.id?.toString(); // Get user ID on init
    _loadGlassesAndFeatured();
    _updateCartItemCount();
  }

  Future<void> _loadGlassesAndFeatured() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _glasses = await _dbHelper.getAllGlasses();
      _featuredGlasses = await _dbHelper.getFeaturedGlasses();
      print('Loaded ${_featuredGlasses.length} featured glasses.');
    } catch (e) {
      print('Error loading glasses: $e');
      _showSnackBar('Failed to load products.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCartItemCount() async {
    if (_currentUserId == null) {
      setState(() {
        _cartItemCount = 0;
      });
      return;
    }
    try {
      final cartItems = await _dbHelper.getCartItems(
        _currentUserId!,
      ); // Pass userId
      setState(() {
        _cartItemCount = cartItems.length;
      });
    } catch (e) {
      print('Error updating cart item count: $e');
    }
  }

  void _addToCart(Glass glass) async {
    if (_currentUserId == null) {
      _showSnackBar('Please log in to add items to your cart.');
      return;
    }
    try {
      final cartItem = CartItem(
        glassId: glass.id!,
        userId: _currentUserId!, // Pass the current user's ID
        quantity: 1,
        price: glass.price,
      );
      await _dbHelper.insertCartItem(cartItem);
      _showSnackBar('${glass.name} added to cart!');
      _updateCartItemCount();
    } catch (e) {
      print('Error adding to cart: $e');
      _showSnackBar('Failed to add to cart.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<Glass> get _filteredGlasses {
    List<Glass> filtered =
        _glasses.where((glass) {
          final matchesSearch =
              _searchQuery.isEmpty ||
              glass.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              glass.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
          final matchesCategory =
              _selectedCategory == 'All' ||
              glass.category.toLowerCase() == _selectedCategory.toLowerCase();
          return matchesSearch && matchesCategory;
        }).toList();
    return filtered;
  }

  Widget _buildProductGridContent() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search for glasses...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 15.0,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Categories',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('All'),
                    _buildCategoryChip('Sunglasses'),
                    _buildCategoryChip('Eyeglasses'),
                    _buildCategoryChip('Kids'),
                    _buildCategoryChip('Reading'),
                    _buildCategoryChip('Blue Light'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_featuredGlasses.isNotEmpty) ...[
                Text(
                  'Featured Items',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _featuredGlasses.length,
                    itemBuilder: (context, index) {
                      final glass = _featuredGlasses[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: SizedBox(
                          width: 180,
                          child: _buildGlassCard(glass),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                _selectedCategory == 'All' && _searchQuery.isEmpty
                    ? 'All Products'
                    : 'Filtered Products',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _filteredGlasses.isEmpty
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No products found matching your criteria.'),
                    ),
                  )
                  : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: _filteredGlasses.length,
                    itemBuilder: (context, index) {
                      final glass = _filteredGlasses[index];
                      return _buildGlassCard(glass);
                    },
                  ),
            ],
          ),
        );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color:
                isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(Glass glass) {
    return GestureDetector(
      onTap: () {
        print('Tapped on glass: ${glass.name}, ID: ${glass.id}');
        Navigator.pushNamed(context, '/product_detail', arguments: glass);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  glass.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, size: 50),
                      ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    glass.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${glass.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _addToCart(glass),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(30),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) async {
    if (_selectedIndex == 2 &&
        _profileScreenKey.currentState != null &&
        _profileScreenKey.currentState!.hasUnsavedChanges) {
      print(
        'HomeScreen: Unsaved changes detected in ProfileScreen. Showing dialog.',
      );
      final bool? allowNavigation =
          await _profileScreenKey.currentState!.showUnsavedChangesDialog();
      if (allowNavigation == false) {
        print('HomeScreen: Navigation cancelled by user.');
        return;
      }
    }

    if (index == 3) {
      await _confirmLogout();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _confirmLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _authService.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex]),
        centerTitle: true,
        actions: [
          if (_selectedIndex == 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/cart');
                    _updateCartItemCount();
                  },
                ),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildProductGridContent(),
          const DashboardScreen(),
          ProfileScreen(key: _profileScreenKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
