import 'package:tryon/models/glass.dart'; // Import Glass model

class CartItem {
  final int? id;
  final int glassId;
  final String userId; // New field: ID of the user who added the item
  final int quantity;
  final double price; // Price at the time of adding to cart
  Glass? glass; // To store the associated Glass object for display

  CartItem({
    this.id,
    required this.glassId,
    required this.userId,
    required this.quantity,
    required this.price,
    this.glass,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'glassId': glassId,
      'userId': userId, // Include userId in the map
      'quantity': quantity,
      'price': price,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      glassId: map['glassId'],
      userId: map['userId'], // Retrieve userId from the map
      quantity: map['quantity'],
      price: map['price'],
    );
  }

  CartItem copyWith({
    int? id,
    int? glassId,
    String? userId,
    int? quantity,
    double? price,
    Glass? glass,
  }) {
    return CartItem(
      id: id ?? this.id,
      glassId: glassId ?? this.glassId,
      userId: userId ?? this.userId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      glass: glass ?? this.glass,
    );
  }

  @override
  String toString() {
    return 'CartItem{id: $id, glassId: $glassId, userId: $userId, quantity: $quantity, price: $price, glass: ${glass?.name}}';
  }
}
