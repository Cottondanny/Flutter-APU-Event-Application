import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studenthub/models/announcement_model.dart';
import 'package:studenthub/screens/registration_screen.dart';
import 'package:studenthub/services/announcement_service.dart';
import 'package:studenthub/widgets/event_map_widget.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  AnnouncementModel get a => widget.announcement;

  bool _isRegistered = false;
  bool _isRegistrationFull = false;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  //check registration status
  Future<void> _checkRegistrationStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final regDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('registrations')
        .doc(a.id)
        .get();

    // capacity null means unlimited — never full
    final isFull = a.capacity != null && a.registrations >= a.capacity!;

    if (mounted) {
      setState(() {
        _isRegistered = regDoc.exists;
        _isRegistrationFull = isFull;
      });
    }
  }

  //builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(a.clubSocietyName),
        // Back button is added automatically by Flutter
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoSection(),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDescriptionSection(),
                  const SizedBox(height: 16),
                  // Only show rewards section if rewards is not null
                  if (a.rewards != null) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildRewardsSection(),
                  ],
                  const SizedBox(height: 80), //space for the button
                ],
              ),
            ),
          ],
        ),
      ),
      //Register button pinned at the bottom
      bottomNavigationBar: _buildRegisterButton(context),
    );
  }

  //Image
  Widget _buildImage() {
    if (a.imageUrl == null) return const SizedBox.shrink();

    return Image.network(
      a.imageUrl!,
      width: double.infinity,
      fit: BoxFit.fitWidth,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stack) {
        return Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        );
      },
    );
  }

  //Title and organization name + featured badge
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured badge — only shown if isFeatured is true
        if (a.isFeatured)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFB400)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB400)),
                SizedBox(width: 4),
                Text(
                  'Featured',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),

        //Event title
        Text(
          a.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 6),

        // Org name row with avatar
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: a.clubProfilePicUrl != null
                  ? NetworkImage(a.clubProfilePicUrl!)
                  : null,
              child: a.clubProfilePicUrl == null
                  ? Text(
                      a.clubSocietyName.substring(0, 2).toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              a.clubSocietyName,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  //Date, Time and Location
  Widget _buildInfoSection() {
    // Temporarily add this before the map section:
    print('latitude: ${a.latitude}, longitude: ${a.longitude}');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Date — only if startDate exists
        if (a.formattedStartDate != null)
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            text:
                a.formattedEndDate != null &&
                    a.formattedEndDate != a.formattedStartDate
                ? '${a.formattedStartDate} – ${a.formattedEndDate}' // multi-day event
                : a.formattedStartDate!, // single day
          ),

        // Time — only if startTime exists
        if (a.formattedStartTime != null)
          _buildInfoRow(
            icon: Icons.access_time_outlined,
            text: a.formattedEndTime != null
                ? '${a.formattedStartTime} – ${a.formattedEndTime}'
                : a.formattedStartTime!,
          ),

        // Location — only if locationName exists
        if (a.locationName != null)
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            text: a.locationName!,
          ),
        
        // Map — only shown if both lat and lng exist
        if (a.latitude != null && a.longitude != null) ...[
          const SizedBox(height: 8),
          EventMapWidget(
            latitude: a.latitude!,
            longitude: a.longitude!,
            locationName: a.locationName ?? 'Event location',
          ),
          const SizedBox(height: 8),
        ],

        // Capacity — only if capacity exists
        if (a.capacity != null)
          _buildInfoRow(
            icon: Icons.people_outline,
            text: '${a.registrations} / ${a.capacity} registered',
          ),

        // Tags
        if (a.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: a.tags.map((tag) {
              return Chip(
                label: Text(tag, style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // Small helper for each icon + text row
  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  //Description
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About this event',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(a.description, style: const TextStyle(fontSize: 14, height: 1.6)),
      ],
    );
  }

  //Rewards
  //rewards — use secondary amber colour
  Widget _buildRewardsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFFFB400),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rewards',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.rewards!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Register button
  Widget _buildRegisterButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isRegistered
            // Show unregister button when already registered
            ? OutlinedButton(
                onPressed: () => _confirmUnregister(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text(
                  'Unregister',
                  style: TextStyle(color: Colors.red),
                ),
              )
            // Show register or full button when not registered
            : ElevatedButton(
                onPressed: _isRegistrationFull
                    ? null
                    : () => _openRegistration(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: _isRegistrationFull ? Colors.red[300] : null,
                ),
                child: Text(
                  _isRegistrationFull
                      ? 'Registration full'
                      : 'Register for this event',
                ),
              ),
      ),
    );
  }

  // Same pre-fill logic as the card — fetch profile then open form
  Future<void> _openRegistration(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    //check if the user already registered
    final existingRegistration = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('registrations')
        .doc(a.id) // document ID is the announcement ID
        .get();

    //if it exists, alert message will pop up
    if (existingRegistration.exists) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Already registered'),
            content: const Text('You cannot register twice 😅'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return; // stop here — don't open the form
    }

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .get();

    final data = doc.data() ?? {};

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegistrationScreen(
            announcement: a,
            prefillName: data['name'] ?? '',
            prefillTp: data['tpNumber'] ?? '',
            prefillEmail: data['email'] ?? '',
            prefillPhone: data['phoneNumber'] ?? '',
            prefillProgramme: data['programme'] ?? '',
          ),
        ),
        // When registration screen closes, re-check status
        // This refreshes the button state
      ).then((_) => _checkRegistrationStatus());
    }
  }

  //confirm unregister dialog
  void _confirmUnregister(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unregister'),
        content: Text('Are you sure you want to unregister from ${a.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await _unregister(context);
            },
            child: const Text(
              'Unregister',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  //unregister from event
  Future<void> _unregister(BuildContext context) async {
    try {
      await AnnouncementService().unregisterFromAnnouncement(a.id);

      setState(() => _isRegistered = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully unregistered'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to unregister. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
