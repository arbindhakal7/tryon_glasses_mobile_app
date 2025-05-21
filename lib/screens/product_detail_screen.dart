import 'package:flutter/material.dart';
import 'package:tryon/models/glass.dart';
import 'package:tryon/database/database_helper.dart';
import 'package:tryon/models/cart_item.dart';
import 'package:tryon/models/review.dart'; // Import Review model
import 'package:tryon/screens/camera_screen.dart';
import 'package:tryon/services/auth_service.dart'; // Import AuthService
import 'package:permission_handler/permission_handler.dart'; // Import for camera permission

class ProductDetailScreen extends StatefulWidget {
  final Glass glass;

  const ProductDetailScreen({super.key, required this.glass});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService(); // Initialize AuthService
  int _quantity = 1;
  List<Glass> _recommendedGlasses = []; // New list for recommended items
  bool _isLoadingRecommended = true; // Loading state for recommended items

  List<Review> _reviews = []; // List to hold reviews for this product
  double _averageRating = 0.0; // Average rating for this product
  bool _isLoadingReviews = true; // Loading state for reviews
  Review? _userReview; // To store the current user's review if it exists

  final TextEditingController _reviewCommentController =
      TextEditingController();
  int _currentRating = 0; // For user's rating input
  String? _currentUserId; // To store the ID of the currently logged-in user

  @override
  void initState() {
    super.initState();
    _currentUserId =
        _authService.currentUser?.id?.toString(); // Get user ID on init
    _loadProductData(); // Load all necessary data
  }

  @override
  void dispose() {
    _reviewCommentController.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    await _loadRecommendedGlasses();
    await _loadReviews();
  }

  Future<void> _loadRecommendedGlasses() async {
    setState(() {
      _isLoadingRecommended = true;
    });
    try {
      _recommendedGlasses = await _dbHelper.getRecommendedGlasses(
        widget.glass.category,
        widget.glass.id!, // Pass the current product's ID to exclude it
      );
      print(
        'Loaded ${_recommendedGlasses.length} recommended glasses for category ${widget.glass.category}.',
      );
    } catch (e) {
      print('Error loading recommended glasses: $e');
      _showSnackBar('Failed to load recommended products.');
    } finally {
      setState(() {
        _isLoadingRecommended = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
    });
    try {
      _reviews = await _dbHelper.getReviewsForGlass(widget.glass.id!);
      _averageRating = await _dbHelper.getAverageRatingForGlass(
        widget.glass.id!,
      );

      final currentUser = _authService.currentUser;
      if (currentUser != null && currentUser.id != null) {
        _userReview = await _dbHelper.getReviewByUserAndGlass(
          currentUser.id!.toString(),
          widget.glass.id!,
        );
        if (_userReview != null) {
          _reviewCommentController.text = _userReview!.comment;
          _currentRating = _userReview!.rating;
        } else {
          _reviewCommentController.clear();
          _currentRating = 0;
        }
      }
    } catch (e) {
      print('Error loading reviews: $e');
      _showSnackBar('Failed to load reviews.');
    } finally {
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  void _submitReview() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || currentUser.id == null) {
      _showSnackBar('Please log in to submit a review.');
      return;
    }
    if (_currentRating == 0) {
      _showSnackBar('Please select a rating (1-5 stars).');
      return;
    }
    if (_reviewCommentController.text.trim().isEmpty) {
      _showSnackBar('Please enter a comment for your review.');
      return;
    }

    final newReview = Review(
      glassId: widget.glass.id!,
      userId: currentUser.id!.toString(),
      rating: _currentRating,
      comment: _reviewCommentController.text.trim(),
      reviewDate: DateTime.now().toIso8601String(),
    );

    try {
      if (_userReview == null) {
        // New review
        await _dbHelper.insertReview(newReview);
        _showSnackBar('Review submitted successfully!');
      } else {
        // Update existing review
        final updatedReview = newReview.copyWith(id: _userReview!.id);
        await _dbHelper.updateReview(updatedReview);
        _showSnackBar('Review updated successfully!');
      }
      _loadReviews(); // Reload reviews to update UI
    } catch (e) {
      print('Error submitting/updating review: $e');
      _showSnackBar('Failed to submit review.');
    }
  }

  void _addToCart() async {
    if (_authService.currentUser?.id == null) {
      // Check if user is logged in
      _showSnackBar('Please log in to add items to your cart.');
      return;
    }
    try {
      final cartItem = CartItem(
        glassId: widget.glass.id!,
        userId:
            _authService.currentUser!.id!
                .toString(), // Pass the current user's ID
        quantity: _quantity,
        price: widget.glass.price,
      );
      await _dbHelper.insertCartItem(cartItem);
      _showSnackBar('${widget.glass.name} (x$_quantity) added to cart!');
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

  // Helper widget to build a recommended item card
  Widget _buildRecommendedItemCard(Glass glass) {
    return GestureDetector(
      onTap: () {
        // Navigate to the detail screen of the recommended product
        Navigator.pushReplacementNamed(
          context,
          '/product_detail',
          arguments: glass,
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 140, // Fixed width for recommended item cards
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    glass.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image, size: 40),
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
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${glass.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to handle the "Try On" button press
  void _onTryOnPressed() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
      );
    } else {
      _showSnackBar(
        'Camera permission denied. Please enable it in settings to use Try-On.',
      );
      // Optionally, open app settings if permission is permanently denied
      // openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.glass.name), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.glass.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 250,
                errorBuilder:
                    (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 100),
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // Product Name and Average Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.glass.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!_isLoadingReviews)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 4),
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Product Price
            Text(
              '\$${widget.glass.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Product Description
            Text(
              widget.glass.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Product Specifications
            Text(
              'Specifications',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSpecRow('Category:', widget.glass.category),
            _buildSpecRow('Frame Material:', widget.glass.frameMaterial),
            _buildSpecRow('Lens Type:', widget.glass.lensType),
            _buildSpecRow('Available Stock:', '${widget.glass.stock} units'),
            const SizedBox(height: 32),

            // Quantity Selector and Add to Cart Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 30),
                  onPressed: () {
                    setState(() {
                      if (_quantity > 1) _quantity--;
                    });
                  },
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 30),
                  onPressed: () {
                    setState(() {
                      if (_quantity < widget.glass.stock) _quantity++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.glass.stock > 0 ? _addToCart : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                widget.glass.stock > 0 ? 'Add to Cart' : 'Out of Stock',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(
                  50,
                ), // Make button full width
              ),
            ),
            const SizedBox(height: 16), // Space between Add to Cart and Try-On
            // Try-On Button
            ElevatedButton.icon(
              onPressed: _onTryOnPressed,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Try On Virtually'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.secondary, // Use accent color
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),

            const SizedBox(height: 32),

            // User Review Section
            Text(
              'Your Review',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _authService.currentUser == null
                ? const Text('Please log in to leave a review.')
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _currentRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 30,
                          ),
                          onPressed: () {
                            setState(() {
                              _currentRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reviewCommentController,
                      decoration: const InputDecoration(
                        labelText: 'Write your review...',
                        hintText: 'Share your thoughts on this product',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitReview,
                      child: Text(
                        _userReview == null ? 'Submit Review' : 'Update Review',
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 32),

            // All Reviews Section
            Text(
              'Customer Reviews (${_reviews.length})',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isLoadingReviews
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                ? const Center(
                  child: Text('No reviews yet. Be the first to review!'),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    // Display username instead of truncated user ID
                    final displayedUserName =
                        review.username ?? 'Anonymous User';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'User: $displayedUserName', // Use the username
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < review.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 18,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              review.comment,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                '${DateTime.parse(review.reviewDate).toLocal().day}/${DateTime.parse(review.reviewDate).toLocal().month}/${DateTime.parse(review.reviewDate).toLocal().year}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            const SizedBox(height: 32), // Space before recommended items
            // Recommended Items Section
            Text(
              'Recommended Items',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isLoadingRecommended
                ? const Center(child: CircularProgressIndicator())
                : _recommendedGlasses.isEmpty
                ? const Center(
                  child: Text('No recommendations found for this category.'),
                )
                : SizedBox(
                  height:
                      200, // Fixed height for the horizontal list of recommended items
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendedGlasses.length,
                    itemBuilder: (context, index) {
                      final recommendedGlass = _recommendedGlasses[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: 16.0,
                        ), // Space between cards
                        child: _buildRecommendedItemCard(recommendedGlass),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
