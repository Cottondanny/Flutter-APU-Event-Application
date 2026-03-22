import 'package:flutter/material.dart';
import 'package:studenthub/screens/browse_screen.dart';
import 'package:studenthub/screens/calendar_screen.dart';
import 'package:studenthub/screens/feed_screen.dart';
import 'profile_screen.dart';  

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  
  late final List<Widget> _screens = [
    const FeedScreen(), // Feed we'll replace this soon
    const BrowseScreen(), // Browse coming later
    const CalendarScreen(), // Calendar  coming later
    const ProfileScreen(), // Profile  
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //shows the screen for selected index
      body: _screens[_selectedIndex],

      bottomNavigationBar: NavigationBar(
        animationDuration: const Duration(seconds: 1),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.feed), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        
        
      ),


      
    );
  }
}