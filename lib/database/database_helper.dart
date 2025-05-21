import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:tryon/models/user.dart';
import 'package:tryon/models/glass.dart';
import 'package:tryon/models/cart_item.dart';
import 'package:tryon/models/order.dart'; // Import Order model
import 'package:tryon/models/review.dart'; // Import Review model
import 'dart:convert'; // Import for JSON encoding/decoding

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initDb();
    return _database!;
  }

  Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), 'ecommerce_app.db');
    return await openDatabase(
      path,
      version: 5, // Increment database version to trigger onUpgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        email TEXT UNIQUE,
        passwordHash TEXT,
        address TEXT,
        phoneNumber TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE glasses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        price REAL,
        imageUrl TEXT,
        category TEXT,
        frameMaterial TEXT,
        lensType TEXT,
        stock INTEGER,
        isFeatured INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE cart_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        glassId INTEGER,
        userId TEXT, -- New column for userId
        quantity INTEGER,
        price REAL,
        FOREIGN KEY (glassId) REFERENCES glasses (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        totalAmount REAL,
        orderDate TEXT,
        items TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE reviews(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        glassId INTEGER,
        userId TEXT,
        rating INTEGER,
        comment TEXT,
        reviewDate TEXT,
        FOREIGN KEY (glassId) REFERENCES glasses (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(glassId, userId)
      )
    ''');

    await _insertInitialGlasses(db);
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE glasses ADD COLUMN isFeatured INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE reviews(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          glassId INTEGER,
          userId TEXT,
          rating INTEGER,
          comment TEXT,
          reviewDate TEXT,
          FOREIGN KEY (glassId) REFERENCES glasses (id) ON DELETE CASCADE,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
          UNIQUE(glassId, userId)
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT,
          email TEXT UNIQUE,
          passwordHash TEXT,
          address TEXT,
          phoneNumber TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      // Add userId column to cart_items table
      await db.execute('ALTER TABLE cart_items ADD COLUMN userId TEXT');
      // Add foreign key constraint (requires recreating table if data exists)
      // For simplicity, we'll assume a fresh start or handle data migration if necessary.
      // If you have existing data in cart_items, you'd need a more robust migration strategy
      // (e.g., create new table, copy data, drop old table, rename new table).
      // For now, we'll just add the column. Ensure your app logic handles existing
      // cart items that might not have a userId if you don't do a full re-creation.
      await db.execute(
        'CREATE TEMPORARY TABLE cart_items_old(id INTEGER PRIMARY KEY AUTOINCREMENT, glassId INTEGER, quantity INTEGER, price REAL)',
      );
      await db.execute(
        'INSERT INTO cart_items_old SELECT id, glassId, quantity, price FROM cart_items',
      );
      await db.execute('DROP TABLE cart_items');
      await db.execute('''
        CREATE TABLE cart_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          glassId INTEGER,
          userId TEXT,
          quantity INTEGER,
          price REAL,
          FOREIGN KEY (glassId) REFERENCES glasses (id) ON DELETE CASCADE,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'INSERT INTO cart_items (id, glassId, quantity, price) SELECT id, glassId, quantity, price FROM cart_items_old',
      );
      await db.execute('DROP TABLE cart_items_old');
    }
  }

  Future<void> _insertInitialGlasses(Database db) async {
    final List<Glass> initialGlasses = [
      Glass(
        name: 'Classic Aviator',
        description:
            'Timeless aviator style with polarized lenses. Perfect for a classic look.',
        price: 79.99,
        imageUrl: 'https://placehold.co/600x400/FF5733/FFFFFF?text=Aviator',
        category: 'Sunglasses',
        frameMaterial: 'Metal',
        lensType: 'Polarized',
        stock: 50,
        isFeatured: true,
      ),
      Glass(
        name: 'Modern Wayfarer',
        description:
            'Sleek and contemporary wayfarer design, suitable for everyday wear.',
        price: 59.99,
        imageUrl: 'https://placehold.co/600x400/33FF57/000000?text=Wayfarer',
        category: 'Sunglasses',
        frameMaterial: 'Acetate',
        lensType: 'UV Protection',
        stock: 75,
        isFeatured: true,
      ),
      Glass(
        name: 'Round Vintage',
        description:
            'Retro-inspired round frames for a unique and stylish statement.',
        price: 69.99,
        imageUrl: 'https://placehold.co/600x400/3357FF/FFFFFF?text=Round',
        category: 'Eyeglasses',
        frameMaterial: 'Plastic',
        lensType: 'Clear',
        stock: 30,
        isFeatured: true,
      ),
      Glass(
        name: 'Sporty Wrap-around',
        description:
            'Durable and comfortable, ideal for outdoor activities and sports.',
        price: 89.99,
        imageUrl: 'https://placehold.co/600x400/FF33A1/FFFFFF?text=Sporty',
        category: 'Sunglasses',
        frameMaterial: 'Nylon',
        lensType: 'Polycarbonate',
        stock: 40,
        isFeatured: true,
      ),
      Glass(
        name: 'Cat Eye Chic',
        description:
            'Elegant cat-eye frames that add a touch of sophistication.',
        price: 64.99,
        imageUrl: 'https://placehold.co/600x400/A133FF/FFFFFF?text=Cat+Eye',
        category: 'Eyeglasses',
        frameMaterial: 'Plastic',
        lensType: 'Anti-reflective',
        stock: 25,
      ),
      Glass(
        name: 'Lightweight Titanium',
        description:
            'Ultra-light and strong titanium frames for maximum comfort.',
        price: 120.00,
        imageUrl: 'https://placehold.co/600x400/33FFF5/000000?text=Titanium',
        category: 'Eyeglasses',
        frameMaterial: 'Titanium',
        lensType: 'Blue Light Filter',
        stock: 20,
      ),
      Glass(
        name: 'Square Modern',
        description:
            'Contemporary square frames, perfect for a bold statement.',
        price: 75.00,
        imageUrl: 'https://placehold.co/600x400/FFC300/000000?text=Square',
        category: 'Eyeglasses',
        frameMaterial: 'Metal',
        lensType: 'Progressive',
        stock: 35,
      ),
      Glass(
        name: 'Oversized Retro',
        description: 'Large, stylish frames reminiscent of vintage fashion.',
        price: 85.50,
        imageUrl: 'https://placehold.co/600x400/DAF7A6/000000?text=Oversized',
        category: 'Sunglasses',
        frameMaterial: 'Acetate',
        lensType: 'Gradient',
        stock: 60,
      ),
      Glass(
        name: 'Kids Fun Frames',
        description: 'Durable and colorful frames for children.',
        price: 35.00,
        imageUrl: 'https://placehold.co/600x400/FFC0CB/000000?text=Kids',
        category: 'Kids',
        frameMaterial: 'Rubber',
        lensType: 'Impact Resistant',
        stock: 45,
      ),
      Glass(
        name: 'Reading Glasses',
        description: 'Comfortable and clear reading glasses for everyday use.',
        price: 25.00,
        imageUrl: 'https://placehold.co/600x400/8B0000/FFFFFF?text=Reading',
        category: 'Reading',
        frameMaterial: 'Plastic',
        lensType: 'Single Vision',
        stock: 100,
      ),
      Glass(
        name: 'Blue Light Blockers',
        description:
            'Protect your eyes from digital strain with these blue light filtering glasses.',
        price: 45.00,
        imageUrl: 'https://placehold.co/600x400/4682B4/FFFFFF?text=Blue+Light',
        category: 'Blue Light',
        frameMaterial: 'TR90',
        lensType: 'Blue Light Filter',
        stock: 70,
      ),
    ];

    for (var glass in initialGlasses) {
      await db.insert(
        'glasses',
        glass.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [int.parse(userId)],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Glass operations
  Future<List<Glass>> getAllGlasses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('glasses');
    return List.generate(maps.length, (i) {
      return Glass.fromMap(maps[i]);
    });
  }

  Future<List<Glass>> getFeaturedGlasses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'glasses',
      where: 'isFeatured = ?',
      whereArgs: [1],
      limit: 4,
    );
    return List.generate(maps.length, (i) {
      return Glass.fromMap(maps[i]);
    });
  }

  Future<List<Glass>> getRecommendedGlasses(
    String category,
    int currentGlassId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'glasses',
      where: 'category = ? AND id != ?',
      whereArgs: [category, currentGlassId],
      limit: 6,
    );
    return List.generate(maps.length, (i) {
      return Glass.fromMap(maps[i]);
    });
  }

  Future<Glass?> getGlassById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'glasses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Glass.fromMap(maps.first);
    }
    return null;
  }

  // Cart operations
  Future<int> insertCartItem(CartItem item) async {
    final db = await database;
    final existingItems = await db.query(
      'cart_items',
      where: 'glassId = ? AND userId = ?',
      whereArgs: [item.glassId, item.userId],
    );

    if (existingItems.isNotEmpty) {
      int currentQuantity = existingItems.first['quantity'] as int;
      return await db.update(
        'cart_items',
        {'quantity': currentQuantity + item.quantity},
        where: 'glassId = ? AND userId = ?',
        whereArgs: [item.glassId, item.userId],
      );
    } else {
      return await db.insert(
        'cart_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<CartItem>> getCartItems(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_items',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    List<CartItem> cartItems = [];
    for (var map in maps) {
      CartItem item = CartItem.fromMap(map);
      Glass? glass = await getGlassById(item.glassId);
      if (glass != null) {
        cartItems.add(item.copyWith(glass: glass));
      }
    }
    return cartItems;
  }

  Future<int> updateCartItemQuantity(int id, int quantity) async {
    final db = await database;
    return await db.update(
      'cart_items',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCartItem(int id) async {
    final db = await database;
    return await db.delete('cart_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCart(String userId) async {
    final db = await database;
    await db.delete('cart_items', where: 'userId = ?', whereArgs: [userId]);
  }

  // Order operations
  Future<void> insertOrder(Order order) async {
    final db = await database;
    final orderMap = order.toMap();
    orderMap['items'] = json.encode(order.items);

    await db.insert(
      'orders',
      orderMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Order>> getOrdersForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'orderDate DESC',
    );

    return List.generate(maps.length, (i) {
      final Map<String, dynamic> orderMap = Map<String, dynamic>.from(maps[i]);
      if (orderMap['items'] is String) {
        orderMap['items'] = List<Map<String, dynamic>>.from(
          json.decode(orderMap['items'] as String),
        );
      }
      return Order.fromMap(orderMap);
    });
  }

  // Review operations
  Future<int> insertReview(Review review) async {
    final db = await database;
    return await db.insert(
      'reviews',
      review.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateReview(Review review) async {
    final db = await database;
    return await db.update(
      'reviews',
      review.toMap(),
      where: 'id = ?',
      whereArgs: [review.id],
    );
  }

  Future<Review?> getReviewByUserAndGlass(String userId, int glassId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reviews',
      where: 'userId = ? AND glassId = ?',
      whereArgs: [userId, glassId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Review.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Review>> getReviewsForGlass(int glassId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        r.id,
        r.glassId,
        r.userId,
        r.rating,
        r.comment,
        r.reviewDate,
        u.username
      FROM reviews r
      INNER JOIN users u ON r.userId = u.id
      WHERE r.glassId = ?
      ORDER BY r.reviewDate DESC
    ''',
      [glassId],
    );

    return List.generate(maps.length, (i) {
      return Review.fromMap(maps[i]);
    });
  }

  Future<double> getAverageRatingForGlass(int glassId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT AVG(rating) as avgRating FROM reviews WHERE glassId = ?',
      [glassId],
    );
    if (result.isNotEmpty && result.first['avgRating'] != null) {
      return result.first['avgRating'] as double;
    }
    return 0.0;
  }
}
