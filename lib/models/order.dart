class Order {
  final int? id;
  final String userId;
  final double totalAmount;
  final String orderDate; // Store as ISO 8601 string
  final List<Map<String, dynamic>>
  items; // List of items in the order, each item being a map

  Order({
    this.id,
    required this.userId,
    required this.totalAmount,
    required this.orderDate,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'totalAmount': totalAmount,
      'orderDate': orderDate,
      // SQLite stores lists/maps as strings, so we need to convert to JSON string
      'items':
          items
              .map(
                (item) => {
                  'glassId': item['glassId'],
                  'quantity': item['quantity'],
                  'price': item['price'],
                  'name': item['name'],
                  'imageUrl': item['imageUrl'],
                },
              )
              .toList(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      userId: map['userId'],
      totalAmount: map['totalAmount'],
      orderDate: map['orderDate'],
      // When reading from DB, items might be a JSON string, so parse it
      items: List<Map<String, dynamic>>.from(map['items'] as List<dynamic>),
    );
  }
}
