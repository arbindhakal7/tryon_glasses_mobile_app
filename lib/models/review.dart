class Review {
  final int? id;
  final int glassId;
  final String userId;
  final int rating; // Rating from 1 to 5
  final String comment;
  final String reviewDate; // Store as ISO 8601 string
  final String? username; // New field to store the associated username

  Review({
    this.id,
    required this.glassId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.reviewDate,
    this.username, // Initialize the new field
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'glassId': glassId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'reviewDate': reviewDate,
      // Username is not stored in the reviews table itself,
      // it's fetched via join, so no need to include in toMap for insertion
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      glassId: map['glassId'],
      userId: map['userId'],
      rating: map['rating'],
      comment: map['comment'],
      reviewDate: map['reviewDate'],
      username:
          map['username'], // Populate username from the joined query result
    );
  }

  Review copyWith({
    int? id,
    int? glassId,
    String? userId,
    int? rating,
    String? comment,
    String? reviewDate,
    String? username, // Allow copying with a new username
  }) {
    return Review(
      id: id ?? this.id,
      glassId: glassId ?? this.glassId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      reviewDate: reviewDate ?? this.reviewDate,
      username: username ?? this.username,
    );
  }

  @override
  String toString() {
    return 'Review{id: $id, glassId: $glassId, userId: $userId, rating: $rating, comment: $comment, reviewDate: $reviewDate, username: $username}';
  }
}
