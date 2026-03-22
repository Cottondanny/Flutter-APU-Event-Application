import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/student_model.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final StudentModel student;

  const EditProfileScreen({super.key, required this.student});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late final TextEditingController _nameController;
  late final TextEditingController _tpController;
  late final TextEditingController _programmeController;
  late final TextEditingController _phoneController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  File? _pickedImage;
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _tpController = TextEditingController(text: widget.student.tpNumber);
    _programmeController = TextEditingController(text: widget.student.programme);
    _phoneController = TextEditingController(text: widget.student.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tpController.dispose();
    _programmeController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  //pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  //save changes
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    String? profilePicUrl;

    //step 1 — upload new profile pic if user picked one
    if (_pickedImage != null) {
      profilePicUrl = await _authService.uploadProfilePicture(uid, _pickedImage!);
      if (profilePicUrl == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    //step 2 — update profile fields in Firestore
    final error = await _authService.updateStudentProfile(
      uid: uid,
      name: _nameController.text.trim(),
      tpNumber: _tpController.text.trim(),
      programme: _programmeController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      profilePicUrl: profilePicUrl,
    );

    //step 3 — change password if toggle is on
    if (error == null && _changePassword) {
      final passError = await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (passError != null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(passError), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = false);

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  //builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              //avatar picker
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : widget.student.profilePicUrl != null
                              ? NetworkImage(widget.student.profilePicUrl!)
                                  as ImageProvider
                              : null,
                      child: (_pickedImage == null &&
                              widget.student.profilePicUrl == null)
                          ? Text(
                              widget.student.name.isNotEmpty
                                  ? widget.student.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                    //camera badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              //full name — same rules as register screen
              _buildField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value!.trim().isEmpty) return 'Please enter your name';
                  if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value.trim())) {
                    return 'Name should only contain letters';
                  }
                  if (value.trim().length < 2) return 'Name is too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              //tp number — same rules as register screen
              _buildField(
                controller: _tpController,
                label: 'TP Number',
                icon: Icons.badge_outlined,
                validator: (value) {
                  if (value!.trim().isEmpty) return 'Please enter your TP number';
                  if (!RegExp(r"^TP\d{6}$")
                      .hasMatch(value.trim().toUpperCase())) {
                    return 'TP number format: TP followed by 6 digits (e.g. TP081818)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              //programme
              _buildField(
                controller: _programmeController,
                label: 'Programme',
                icon: Icons.school_outlined,
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return 'Please enter your programme name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              //phone — same Malaysian number rules as register screen
              _buildField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r"^(\+?60|0)1[0-9]{8,9}$")
                      .hasMatch(value.trim())) {
                    return 'Enter a valid Malaysian number (e.g. 0141234567)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              //change password toggle
              Row(
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Switch(
                    value: _changePassword,
                    onChanged: (val) =>
                        setState(() => _changePassword = val),
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),

              //password fields — only shown when toggle is on
              if (_changePassword) ...[
                const SizedBox(height: 12),
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  obscure: _obscureCurrent,
                  onToggle: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  obscure: _obscureNew,
                  onToggle: () =>
                      setState(() => _obscureNew = !_obscureNew),
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter a new password';
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'Include at least one uppercase letter';
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Include at least one number';
                    }
                    // Prevent reusing the same password
                    if (value == _currentPasswordController.text) {
                      return 'New password must be different from current';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),

              //save button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //reusable text field
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }

  //reusable password field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }
}