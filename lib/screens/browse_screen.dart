import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studenthub/models/announcement_model.dart';
import 'package:studenthub/services/announcement_service.dart';
import 'package:studenthub/widgets/announcement_card.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final AnnouncementService _service = AnnouncementService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  Set<String> _likedIds = {};

  // Full list from Firestore — never modified after loading
  List<AnnouncementModel> _allAnnouncements = [];

  // What actually shows in the list — changes as user types
  List<AnnouncementModel> _filteredAnnouncements = [];

  // The current search text
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _loadLikedIds();
    // Listen to every keystroke in the search bar
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // Always clean up controllers to avoid memory leaks
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  //load liked ids
  Future<void> _loadLikedIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('likes')
        .get();

    setState(() {
      _likedIds = snap.docs.map((doc) => doc.id).toSet();
    });
  }

  //load announcements
  Future<void> _loadAnnouncements() async {
    try {
      final data = await _service.getAnnouncements();
      setState(() {
        _allAnnouncements = data;
        _filteredAnnouncements = data; // start by showing everything
        _isLoading = false;
      });
      await _loadLikedIds();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load. Please try again.';
        _isLoading = false;
      });
    }
  }

  //called on every keystroke
  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    // No need to refilter if the query hasn't actually changed
    if (query == _searchQuery) return;
    _searchQuery = query;

    setState(() {
      if (query.isEmpty) {
        // Empty search — show everything
        _filteredAnnouncements = _allAnnouncements;
      } else {
        _filteredAnnouncements = _allAnnouncements.where((a) {
          // Match against title OR organization name
          // toLowerCase so "flutter" matches "Flutter Workshop"
          final titleMatch = a.title.toLowerCase().contains(query);
          final orgMatch = a.clubSocietyName.toLowerCase().contains(query);
          return titleMatch || orgMatch;
        }).toList();
      }
    });
  }

  //clear search
  void _clearSearch() {
    _searchController.clear();
    // _onSearchChanged fires automatically from the listener above
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Events')),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  //search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search events or organizations...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF004AAD)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  //body
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    // Different empty messages depending on context
    if (_filteredAnnouncements.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No announcements available.'
              : 'No results for "$_searchQuery".',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        itemCount: _filteredAnnouncements.length,
        itemBuilder: (context, index) {
          return AnnouncementCard(
            announcement: _filteredAnnouncements[index],
            isLiked: _likedIds.contains(_filteredAnnouncements[index].id),
            onLikeChanged: (isLiked) {
              setState(() {
                if (isLiked) {
                  _likedIds.add(_filteredAnnouncements[index].id);
                } else {
                  _likedIds.remove(_filteredAnnouncements[index].id);
                }
              });
            },
          );
        },
      ),
    );
  }
}
