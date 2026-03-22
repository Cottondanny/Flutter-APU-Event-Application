import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:studenthub/models/announcement_model.dart';
import 'package:studenthub/services/announcement_service.dart';
import 'package:studenthub/widgets/announcement_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _name = '';
  List<String> _selectedTags = []; // tracks which tags are active
  Set<String> _likedIds = {}; //Set makes the searching faster than list
  bool _showLikedOnly = false;

  bool _isLoading = true; //used for loading
  List<AnnouncementModel> _announcements =
      []; //used for successful announcements
  String? _errorMessage; //used for error messages

  final AnnouncementService _service = AnnouncementService();
  final List<String> _allTags = [
    'Workshop',
    'Sports',
    'Music',
    'Technical',
    'Social',
    'Competition',
    'Festival',
    'Tournament',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadAnnouncements();
    _loadLikedIds();
  }

  Future<void> _loadUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .get();

    setState(() {
      _name = doc.data()?['name'] ?? 'Student';
    });
  }

  Future<void> _loadAnnouncements() async {
    try {
      final data = await _service.getAnnouncements();
      setState(() {
        _announcements = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLikedIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('likes')
        .get();

    setState(() {
      // Each document ID in the likes sub-collection is an announcement ID
      _likedIds = snap.docs.map((doc) => doc.id).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $_name 👋'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _showLikedOnly = !_showLikedOnly);
            },
            icon: Icon(
              _showLikedOnly ? Icons.favorite : Icons.favorite_border,
              color: _showLikedOnly ? Colors.red : null,
            ),
          ),
          IconButton(onPressed: _showFilterSheet, icon: const Icon(Icons.tune)),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_announcements.isEmpty) {
      return const Center(child: Text('No announcements yet.'));
    }

    // Apply tag filter, if nothing selected, show everything
    var filtered = _selectedTags.isEmpty
        ? _announcements
        : _announcements.where((a) {
            // Show announcement if it has ANY of the selected tags
            return a.tags.any((tag) => _selectedTags.contains(tag));
          }).toList();

    //Liked announcement only
    if (_showLikedOnly) {
      filtered = filtered.where((a) => _likedIds.contains(a.id)).toList();
    }
    // Handle the case where filters produce zero results
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _showLikedOnly
              ? 'You haven\'t liked any posts yet.'
              : 'No announcements match your filters.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadAnnouncements();
        await _loadLikedIds();
      },
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return AnnouncementCard(
            announcement: filtered[index],
            isLiked: _likedIds.contains(filtered[index].id),
            // When card reports a like change, update _likedIds immediately
            onLikeChanged: (isLiked) {
              setState(() {
                if (isLiked) {
                  _likedIds.add(filtered[index].id);
                } else {
                  _likedIds.remove(filtered[index].id);
                }
              });
              // setState here triggers a rebuild of the feed
              // so the heart filter re-evaluates instantly
            },
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // StatefulBuilder lets the chips update INSIDE the sheet
        // without rebuilding the whole FeedScreen
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by tag',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _allTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          // Update both the sheet AND the feed list
                          setSheetState(() {});
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Clear all button
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedTags.clear());
                      setSheetState(() {});
                    },
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
