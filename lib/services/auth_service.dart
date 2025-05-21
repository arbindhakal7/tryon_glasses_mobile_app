import 'package:crypto/crypto.dart';
import 'dart:convert'; // For utf8.encode
import 'package:tryon/database/database_helper.dart';
import 'package:tryon/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static User? _currentUser; // Simple in-memory current user
  static const String _loggedInUserIdKey =
      'loggedInUserId'; // Key for SharedPreferences

  User? get currentUser => _currentUser;

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Initialize the Auth Service by trying to load a saved user session
  Future<void> initAuthService() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_loggedInUserIdKey);
    if (userId != null) {
      // Attempt to retrieve the full user object from the database
      final user = await _dbHelper.getUserById(userId);
      if (user != null) {
        _currentUser = user;
        print('AuthService: Restored user session for ID: $userId');
      } else {
        // User ID found in prefs but not in DB (e.g., DB cleared separately)
        await prefs.remove(_loggedInUserIdKey); // Clean up invalid ID
        print('AuthService: Cleared invalid user ID from preferences.');
      }
    } else {
      print('AuthService: No saved user session found.');
    }
  }

  Future<bool> signup(String username, String email, String password) async {
    try {
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        // User with this email already exists
        return false;
      }

      final hashedPassword = _hashPassword(password);
      final newUser = User(
        username: username,
        email: email,
        passwordHash: hashedPassword,
      );
      // Insert user and get the auto-generated ID
      final id = await _dbHelper.insertUser(newUser);
      if (id > 0) {
        // Successfully signed up, log them in and save ID
        // Create a new User object with the generated ID
        _currentUser = User(
          id: id,
          username: newUser.username,
          email: newUser.email,
          passwordHash: newUser.passwordHash,
          address: newUser.address,
          phoneNumber: newUser.phoneNumber,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_loggedInUserIdKey, _currentUser!.id!.toString());
        print('AuthService: Signed up and logged in user: ${_currentUser!.id}');
        return true;
      }
      return false;
    } catch (e) {
      print('Error during signup: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await _dbHelper.getUserByEmail(email);
      if (user != null && user.passwordHash == _hashPassword(password)) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_loggedInUserIdKey, _currentUser!.id!.toString());
        print('AuthService: Logged in user: ${_currentUser!.id}');
        return true;
      }
      return false;
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  void logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserIdKey); // Clear saved user ID
    print('AuthService: User logged out and session cleared.');
  }

  // Helper to update user details in the database
  Future<bool> updateUserDetails(User user) async {
    try {
      final rowsAffected = await _dbHelper.updateUser(user);
      if (rowsAffected > 0) {
        _currentUser = user; // Update the in-memory current user
        // No need to update SharedPreferences here as ID doesn't change
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating user details: $e');
      return false;
    }
  }
}

// Extension to allow copying User object with new ID
// This extension is no longer strictly necessary if User.copyWith is used,
// but it's good practice to keep it if you need flexible copying.
extension UserCopyWith on User {
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? passwordHash,
    String? address,
    String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
