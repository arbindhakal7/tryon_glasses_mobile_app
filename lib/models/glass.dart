class Glass {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category; // e.g., "sunglasses", "reading", "blue light"
  final String frameMaterial; // e.g., "acetate", "metal", "titanium"
  final String lensType; // e.g., "polarized", "anti-reflective", "photochromic"
  final int stock;
  final bool isFeatured; // New field: to mark if a product is featured

  Glass({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.frameMaterial,
    required this.lensType,
    required this.stock,
    this.isFeatured = false, // Default to false if not provided
  });

  // Convert a Glass object into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'frameMaterial': frameMaterial,
      'lensType': lensType,
      'stock': stock,
      'isFeatured':
          isFeatured ? 1 : 0, // SQLite stores booleans as INTEGER (0 or 1)
    };
  }

  // Convert a Map into a Glass object.
  factory Glass.fromMap(Map<String, dynamic> map) {
    return Glass(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      imageUrl: map['imageUrl'],
      category: map['category'],
      frameMaterial: map['frameMaterial'],
      lensType: map['lensType'],
      stock: map['stock'],
      isFeatured: map['isFeatured'] == 1, // Convert INTEGER back to bool
    );
  }

  @override
  String toString() {
    return 'Glass{id: $id, name: $name, price: $price, stock: $stock, isFeatured: $isFeatured}';
  }
}
