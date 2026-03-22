import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:studenthub/models/announcement_model.dart';
import 'package:studenthub/screens/announcement_detail_screen.dart';
import 'package:studenthub/screens/registration_screen.dart';
import 'package:studenthub/services/announcement_service.dart';

class AnnouncementCard extends StatefulWidget {
  final AnnouncementModel announcement;
  final bool isLiked;

  // Called when user likes or unlikes, it passes the new state back up
  // The ? means it's optional — browse page doesn't need to pass it
  final void Function(bool isLiked)? onLikeChanged;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.isLiked = false,
    this.onLikeChanged,
  });

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  AnnouncementModel get a => widget.announcement;

  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLikeLoading = false;
  bool _isRegistered = false;
  bool _isRegistrationFull = false;

  @override
  void initState() {
    super.initState();
    _likeCount = a.likes;
    _isLiked = widget.isLiked;
    _checkRegistrationStatus();
  }

  //Checking the registration status
  Future<void> _checkRegistrationStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Check 1 has this student registered?
    final regDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('registrations')
        .doc(a.id)
        .get();

    // Check 2 is the event full?
    // capacity null means unlimited — never full
    final isFull = a.capacity != null && a.registrations >= a.capacity!;

    if (mounted) {
      setState(() {
        _isRegistered = regDoc.exists;
        _isRegistrationFull = isFull;
      });
    }
  }

  // Toggle like / unlike
  Future<void> _toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_isLikeLoading) return;

    // Prevent double tapping
    if (_isLikeLoading) return;
    setState(() => _isLikeLoading = true);

    final likeRef = FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('likes')
        .doc(a.id);

    final announcementRef = FirebaseFirestore.instance
        .collection('announcements')
        .doc(a.id);

    try {
      if (_isLiked) {
        // Unlike will delete the doc and decrement count
        await likeRef.delete();
        await announcementRef.update({'likes': FieldValue.increment(-1)});
        setState(() {
          _isLiked = false;
          _likeCount--;
        });
        //tells the parent the new state of disliking
        widget.onLikeChanged?.call(false);
      } else {
        // Like will create the doc and increment count
        await likeRef.set({
          'announcementId': a.id,
          'likedAt': FieldValue.serverTimestamp(),
        });
        await announcementRef.update({'likes': FieldValue.increment(1)});
        setState(() {
          _isLiked = true;
          _likeCount++;
        });

        //tells the parent the new state of liking
        widget.onLikeChanged?.call(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLikeLoading = false);
    }
  }

  //confirm unregister dialog
  void _confirmUnregister(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unregister'),
        content: Text('Unregister from ${a.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
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

      setState(() {
        _isRegistered = false;
        _isRegistrationFull = false;
      });

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailScreen(
              announcement: widget.announcement, // fixed: was announcement
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrgRow(),
            _buildImage(),
            _buildContent(),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // Organization + avatar row

  Widget _buildOrgRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFDBEAFE),
            backgroundImage: a.clubProfilePicUrl != null
                ? NetworkImage(a.clubProfilePicUrl!)
                : null,
            child: a.clubProfilePicUrl == null
                ? Text(
                    a.clubSocietyName.substring(0, 2).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004AAD),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            a.clubSocietyName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF004AAD),
            ),
          ),
        ],
      ),
    );
  }

  //  Poster only shown if imageUrl is not null

  Widget _buildImage() {
    if (a.imageUrl == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 300, minHeight: 100),
      child: Image.network(
        a.imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 180,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stack) {
          return Container(
            height: 180,
            color: Colors.grey[200],
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined, color: Colors.grey),
                Text('Image failed to load', style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Title, date, location, description, tags

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          if (a.formattedStartDate != null)
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  a.formattedStartDate!,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                if (a.formattedStartTime != null) ...[
                  const Text('  ·  ', style: TextStyle(color: Colors.grey)),
                  Text(
                    a.formattedStartTime!,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ],
            ),

          const SizedBox(height: 4),

          if (a.locationName != null)
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    a.locationName!,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          Text(
            a.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),

          const SizedBox(height: 10),

          if (a.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: a.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Footer like button, registrations count, register button

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          // Like button — tappable, shows live state
          GestureDetector(
            onTap: _toggleLike,
            child: Row(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  // Red when liked, grey when not
                  color: _isLiked ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_likeCount',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isLiked ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Registrations count — static display
          const Icon(Icons.people_outline, size: 20, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            '${a.registrations}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),

          const Spacer(),

          // Replace the ElevatedButton in _buildFooter with this:
          _isRegistered
              ? OutlinedButton(
                  onPressed: () => _confirmUnregister(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text(
                    'Unregister',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                )
              : ElevatedButton(
                  onPressed: (_isRegistrationFull)
                      ? null
                      : () => _openRegistration(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRegistrationFull
                        ? Colors.red[300]
                        : null,
                  ),
                  child: Text(
                    _isRegistrationFull ? 'Full' : 'Register',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
        ],
      ),
    );
  }

  //  Open registration checks for existing registration first

  Future<void> _openRegistration(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking registration...'),
        duration: Duration(seconds: 2),
      ),
    );

    final existingRegistration = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('registrations')
        .doc(a.id)
        .get();

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

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
      return;
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
      ).then((_) {
        // When the registration screen closes, re-check status
        // This refreshes the button state on the card
        _checkRegistrationStatus();
      });
    }
  }
}
