class User {
  final int? id;
  final String username;
  final String email;
  final String passwordHash; // Store hashed password, not plain text
  final String? address;
  final String? phoneNumber;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    this.address,
    this.phoneNumber,
  });

  // Convert a User object into a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'passwordHash': passwordHash,
      'address': address,
      'phoneNumber': phoneNumber,
    };
  }

  // Convert a Map into a User object.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      passwordHash: map['passwordHash'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
    );
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email}';
  }
}
