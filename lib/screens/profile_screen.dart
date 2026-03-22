import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studenthub/main.dart';
import 'package:studenthub/models/announcement_model.dart';
import 'package:studenthub/models/student_model.dart';
import 'package:studenthub/screens/announcement_detail_screen.dart';
import 'package:studenthub/screens/edit_profile_screen.dart';
import 'package:studenthub/services/announcement_service.dart';
import 'package:studenthub/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final AnnouncementService _announcementService = AnnouncementService();

  StudentModel? _student;
  List<AnnouncementModel> _registeredEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  //load student profile and registered events together
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final results = await Future.wait([
      _authService.getStudentProfile(uid),
      _announcementService.getRegisteredAnnouncements(),
    ]);

    setState(() {
      _student = results[0] as StudentModel?;
      _registeredEvents = results[1] as List<AnnouncementModel>;
      _isLoading = false;
    });
  }

  //builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // ValueListenableBuilder ensures the menu icon updates
          // when theme toggles
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.menu),
                onSelected: (value) => _handleMenuAction(value, context),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 12),
                        Text('Edit profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'darkmode',
                    child: Row(
                      children: [
                        Icon(
                          mode == ThemeMode.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          mode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Log out', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                children: [
                  _buildProfileHeader(),
                  const Divider(height: 1),
                  _buildRegisteredEventsSection(),
                  const Divider(height: 1),
                  _buildUpcomingEventsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  //profile header — avatar, name, tp number, programme
  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(height: 4),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFDBEAFE),
                  backgroundImage: _student?.profilePicUrl != null
                      ? NetworkImage(_student!.profilePicUrl!)
                      : null,
                  child: _student?.profilePicUrl == null
                      ? Text(
                          _student?.name.isNotEmpty == true
                              ? _student!.name.substring(0, 2).toUpperCase()
                              : '??',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004AAD),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _student?.name ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _student?.tpNumber ?? '',
                              style: const TextStyle(
                                color: Color(0xFF004AAD),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _student?.programme ?? '',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //registered events — horizontal scrollable cards
  Widget _buildRegisteredEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Registered events',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_registeredEvents.length} total',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),

        if (_registeredEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'No registered events yet.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: _registeredEvents.length,
              itemBuilder: (context, index) {
                return _buildEventCard(_registeredEvents[index]);
              },
            ),
          ),
      ],
    );
  }

  //upcoming events — registered events filtered to future dates only
  Widget _buildUpcomingEventsSection() {
    final upcoming = _registeredEvents.where((a) {
      final date = a.startDateTimeAsDate;
      if (date == null) return false;
      return date.isAfter(DateTime.now());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming events',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${upcoming.length} upcoming',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),

        if (upcoming.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'No upcoming events.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: upcoming.length,
              itemBuilder: (context, index) {
                return _buildEventCard(upcoming[index]);
              },
            ),
          ),
      ],
    );
  }

  //individual horizontal scrollable event card
  Widget _buildEventCard(AnnouncementModel a) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailScreen(announcement: a),
          ),
        );
        _loadData();
      },
      child: Container(
        width: 160,
        height: 148, // fixed height on the card itself
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: a.imageUrl != null
                  ? Image.network(
                      a.imageUrl!,
                      height: 90, // reduced from 80 to give consistent space
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _cardPlaceholder(),
                    )
                  : _cardPlaceholder(),
            ),

            // Title and date — fixed padding so it never overflows
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      a.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.formattedStartDate ?? 'No date',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardPlaceholder() {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: const BoxDecoration(
        // Gradient from APU blue to a slightly lighter blue
        // gives enough contrast for the white icon on top
        color: Color(0xFF004AAD),
      ),
      child: const Icon(
        Icons.event_rounded,
        color: Colors.white, // white icon on blue — always visible
        size: 32,
      ),
    );
  }

  //handle hamburger menu actions
  Future<void> _handleMenuAction(String value, BuildContext context) async {
    switch (value) {
      case 'edit':
        if (_student != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(student: _student!),
            ),
          );
          // Reload profile when returning — name or pic may have changed
          _loadData();
        }
        break;
      case 'darkmode':
        // Toggle between light and dark
        themeNotifier.value = themeNotifier.value == ThemeMode.dark
            ? ThemeMode.light
            : ThemeMode.dark;
        break;
      case 'logout':
        _confirmLogout(context);
        break;
    }
  }

  //logout confirmation dialog
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // AuthGate handles navigation back to login automatically
            },
            child: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
