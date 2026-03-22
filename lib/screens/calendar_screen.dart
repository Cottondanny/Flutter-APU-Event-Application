import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:studenthub/models/announcement_model.dart';
import 'package:studenthub/services/announcement_service.dart';
import 'package:studenthub/widgets/announcement_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final AnnouncementService _service = AnnouncementService();

  bool _isLoading = true;
  String? _errorMessage;

  List<AnnouncementModel> _registeredAnnouncements = [];
  Set<String> _likedIds = {};

  // table_calendar needs these three
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  //load registered announcements and liked ids together
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getRegisteredAnnouncements(),
        _loadLikedIds(),
      ]);

      setState(() {
        _registeredAnnouncements = results[0];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load. Please try again.';
        _isLoading = false;
      });
    }
  }

  //load liked ids
  Future<List<AnnouncementModel>> _loadLikedIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('likes')
        .get();

    if (mounted) {
      setState(() {
        _likedIds = snap.docs.map((doc) => doc.id).toSet();
      });
    }

    return [];
  }

  // table_calendar calls this to know which dates have events
  // It expects a List — we return the announcements for that day
  List<AnnouncementModel> _getEventsForDay(DateTime day) {
    return _registeredAnnouncements.where((a) {
      if (a.formattedStartDate == null) return false;
      try {
        final eventDate = DateTime.parse(a.formattedStartDate!);
        return isSameDay(eventDate, day); // isSameDay comes from table_calendar
      } catch (_) {
        return false;
      }
    }).toList();
  }

  //builder
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildCalendar(),
                  const Divider(height: 1),
                  Expanded(child: _buildEventsList()),
                ],
              ),
            ),
    );
  }

  //table_calendar widget
  Widget _buildCalendar() {
    return TableCalendar<AnnouncementModel>(
      // Date boundaries
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,

      // Which format is currently shown
      calendarFormat: _calendarFormat,

      // Tell table_calendar which days have events
      // The dots under dates are drawn automatically
      eventLoader: _getEventsForDay,

      // Called when user taps a date
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },

      // Called when user switches between month/week/2week
      onFormatChanged: (format) {
        setState(() => _calendarFormat = format);
      },

      // Called when user swipes to a different month
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },

      // Tells the calendar which day is currently selected
      // so it knows which one to highlight
      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),

      // Available format options the user can toggle between
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.twoWeeks: '2 Weeks',
        CalendarFormat.week: 'Week',
      },

      calendarStyle: CalendarStyle(
        // Event dot colour — APU secondary amber/gold
        markerDecoration: const BoxDecoration(
          color: Color(0xFFFFB400),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  //events list for the selected day
  Widget _buildEventsList() {
    final events = _getEventsForDay(_selectedDay);

    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No registered events on this date.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return AnnouncementCard(
          announcement: event,
          isLiked: _likedIds.contains(event.id),
          onLikeChanged: (isLiked) {
            setState(() {
              if (isLiked) {
                _likedIds.add(event.id);
              } else {
                _likedIds.remove(event.id);
              }
            });
          },
        );
      },
    );
  }
}
