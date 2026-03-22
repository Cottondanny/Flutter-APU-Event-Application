import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studenthub/models/announcement_model.dart';

class RegistrationScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  // Pre-fill parameters
  final String prefillName;
  final String prefillTp;
  final String prefillEmail;
  final String prefillPhone;
  final String prefillProgramme;

  const RegistrationScreen({
    super.key,
    required this.announcement,
    this.prefillName = '',
    this.prefillTp = '',
    this.prefillEmail = '',
    this.prefillPhone = '',
    this.prefillProgramme = '',
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Declared as late so we can initialise them in initState with pre-fill values

  late final TextEditingController _nameController;
  late final TextEditingController _tpController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _programmeController;

  @override
  void initState() {
    super.initState();
    // Each controller starts with the pre-filled value
    // If it's empty string, the field just appears blank
    _nameController = TextEditingController(text: widget.prefillName);
    _tpController = TextEditingController(text: widget.prefillTp);
    _emailController = TextEditingController(text: widget.prefillEmail);
    _phoneController = TextEditingController(text: widget.prefillPhone);
    _programmeController = TextEditingController(text: widget.prefillProgramme);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tpController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _programmeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register for event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Show which event they're registering for
            Text(
              widget.announcement.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.announcement.clubSocietyName,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 8),

            //Pre-filled text
            const Text(
              'Please review your information before confirming.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            _buildField(
              controller: _nameController,
              label: 'Full name',
              hint: 'As per student ID',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter your name'
                  : null,
            ),

            const SizedBox(height: 16),

            _buildField(
              controller: _tpController,
              label: 'TP number',
              hint: 'e.g. TP012345',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter your TP number'
                  : null,
            ),
            const SizedBox(height: 16),

            _buildField(
              controller: _emailController,
              label: 'Email',
              hint: 'your@mail.apu.edu.my',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Please enter your email';
                if (!v.contains('@')) return 'Please enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildField(
              controller: _phoneController,
              label: 'Phone number',
              hint: 'e.g. 0123456789',
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter your phone number'
                  : null,
            ),

            const SizedBox(height: 16),

            _buildField(
              controller: _programmeController,
              label: 'Programme',
              hint: 'e.g. BSc Computer Science',
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter your programme'
                  : null,
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    //Disable the button while submitting so the student can't tap it twice
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _submit() async {
    // validate() runs every validator, if any fail it shows the error text and returns false
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');

      // Write to students/{uid}/registrations/{announcementId}
      // The document ID being the announcement ID makes it easy to check later: "is this student already registered?"
      // just check if this document exists
      await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .collection('registrations')
          .doc(widget.announcement.id)
          .set({
            'announcementId': widget.announcement.id,
            'announcementTitle': widget.announcement.title,
            'clubSocietyName': widget.announcement.clubSocietyName,
            'registeredAt': FieldValue.serverTimestamp(),
            // Store what they submitted, not just what was pre-filled
            // in case they edited any field
            'name': _nameController.text.trim(),
            'tpNumber': _tpController.text.trim(),
            'email': _emailController.text.trim(),
            'phoneNumber': _phoneController.text.trim(),
            'programme': _programmeController.text.trim(),
          });

      // Increment the registrations count on the announcement
      // FieldValue.increment(1) is atomic — safe even if two
      // students register at the exact same time
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(widget.announcement.id)
          .update({'registrations': FieldValue.increment(1)});

      if (mounted) _showSuccessDialog();
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Registration Complete!'),
        content: Text(
          'You have successfully registered for ${widget.announcement.title}.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to feed
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
