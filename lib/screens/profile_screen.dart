import 'package:flutter/material.dart';
import 'package:tryon/services/auth_service.dart';
import 'package:tryon/models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState(); // Changed to return public state
}

class ProfileScreenState extends State<ProfileScreen> {
  // Removed underscore to make it public
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isEditing = false; // Controls if fields are editable

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  // Flag to track if any changes have been made to the text fields
  bool _hasPendingChanges = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadInitialUserData();

    // Add listeners to text controllers to detect changes
    _usernameController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);
    _phoneNumberController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_checkForChanges);
    _addressController.removeListener(_checkForChanges);
    _phoneNumberController.removeListener(_checkForChanges);
    _usernameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  // Load initial user data into controllers
  void _loadInitialUserData() {
    if (_currentUser != null) {
      _usernameController.text = _currentUser!.username;
      _emailController.text = _currentUser!.email; // Email is not editable
      _addressController.text = _currentUser!.address ?? '';
      _phoneNumberController.text = _currentUser!.phoneNumber ?? '';
      _hasPendingChanges = false; // Reset pending changes flag
    }
  }

  // Check if current controller values differ from initial user data
  bool get hasUnsavedChanges {
    if (_currentUser == null) return false;
    // Compare current controller text with the original user data
    return _usernameController.text != _currentUser!.username ||
        _addressController.text != (_currentUser!.address ?? '') ||
        _phoneNumberController.text != (_currentUser!.phoneNumber ?? '');
  }

  // Callback for text field listeners to update _hasPendingChanges
  void _checkForChanges() {
    // Update _hasPendingChanges based on the actual state of unsaved changes
    // This will trigger a rebuild if the value changes, updating the button.
    if (_isEditing) {
      // Only track changes when in editing mode
      final bool newHasPendingChanges = hasUnsavedChanges;
      if (_hasPendingChanges != newHasPendingChanges) {
        setState(() {
          _hasPendingChanges = newHasPendingChanges;
        });
        print(
          'ProfileScreen: _hasPendingChanges updated to $_hasPendingChanges',
        ); // Debug print
      }
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // If exiting edit mode (e.g., by pressing 'Update Profile' again)
        // Discard changes only if we were editing and there were pending changes
        if (_hasPendingChanges) {
          _loadInitialUserData(); // Revert to original data
        }
      }
      // Re-evaluate pending changes after toggling editing mode
      _hasPendingChanges = hasUnsavedChanges;
    });
  }

  void _saveProfile() async {
    if (_currentUser == null) return;

    // Show confirmation dialog before saving
    final bool? confirmSave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text('Confirm Save'),
            content: const Text('Are you sure you want to save these changes?'),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.of(context).pop(false), // Cancel save
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    () => Navigator.of(context).pop(true), // Confirm save
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (confirmSave == true) {
      final updatedUser = _currentUser!.copyWith(
        username: _usernameController.text,
        address: _addressController.text,
        phoneNumber: _phoneNumberController.text,
      );

      bool success = await _authService.updateUserDetails(updatedUser);

      if (success) {
        setState(() {
          _currentUser = updatedUser;
          _isEditing = false; // Exit editing mode on successful save
          _hasPendingChanges = false; // No pending changes after saving
        });
        _showSnackBar('Profile updated successfully!');
      } else {
        _showSnackBar('Failed to update profile.');
      }
    } else {
      _showSnackBar('Save operation cancelled.');
    }
  }

  // Method to discard changes and revert to original data
  void discardChanges() {
    _loadInitialUserData();
    setState(() {
      _isEditing = false;
      _hasPendingChanges = false;
    });
    _showSnackBar('Changes discarded.');
  }

  // Method to show confirmation dialog when trying to leave with unsaved changes
  Future<bool> showUnsavedChangesDialog() async {
    if (!hasUnsavedChanges) {
      return true; // No unsaved changes, allow navigation
    }

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes. Do you want to save them before leaving?',
            ),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.of(context).pop(false), // Discard changes
                child: const Text('Discard'),
              ),
              ElevatedButton(
                onPressed:
                    () => Navigator.of(context).pop(true), // Save changes
                child: const Text('Save'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(context).pop(null), // Cancel navigation
                child: const Text('Cancel'),
              ),
            ],
          ),
    );

    if (shouldSave == true) {
      _saveProfile(); // This will set _isEditing and _hasPendingChanges to false on success
      return true; // Allow navigation after saving
    } else if (shouldSave == false) {
      discardChanges(); // Discard changes and reset state
      return true; // Allow navigation after discarding
    } else {
      return false; // Cancel navigation
    }
  }

  // Method to show a SnackBar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 24),
          _buildProfileField(
            'Username',
            _usernameController,
            Icons.person,
            editable: _isEditing,
          ),
          const SizedBox(height: 16),
          _buildProfileField(
            'Email',
            _emailController,
            Icons.email,
            editable: false,
          ), // Email usually not editable
          const SizedBox(height: 16),
          _buildProfileField(
            'Address',
            _addressController,
            Icons.location_on,
            editable: _isEditing,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildProfileField(
            'Phone Number',
            _phoneNumberController,
            Icons.phone,
            editable: _isEditing,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            // Button's onPressed logic:
            // If currently editing AND there are pending changes, allow saving.
            // Otherwise (not editing, or editing but no changes yet), toggle editing mode.
            onPressed:
                _isEditing && hasUnsavedChanges ? _saveProfile : _toggleEditing,
            // Button's icon:
            // If currently editing AND there are pending changes, show save icon.
            // Otherwise (not editing, or editing but no changes yet), show edit icon.
            icon: Icon(
              _isEditing && hasUnsavedChanges ? Icons.save : Icons.edit,
            ),
            // Button's label:
            // If currently editing AND there are pending changes, show 'Save Profile'.
            // Otherwise (not editing, or editing but no changes yet), show 'Update Profile'.
            label: Text(
              _isEditing && hasUnsavedChanges
                  ? 'Save Profile'
                  : 'Update Profile',
            ),
            style: ElevatedButton.styleFrom(
              // Button's color:
              // If currently editing AND there are pending changes, use green (for save).
              // Otherwise, use primary color (for update or disabled save).
              backgroundColor:
                  _isEditing && hasUnsavedChanges
                      ? Colors.green
                      : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool editable = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: !editable,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: editable ? Colors.white : Colors.grey[100],
      ),
      style: TextStyle(color: editable ? Colors.black : Colors.grey[700]),
    );
  }
}
