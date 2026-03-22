import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studenthub/models/announcement_model.dart';

class MockAnnouncementService {
  static List<AnnouncementModel> getSampleAnnouncements() {
    return [
      AnnouncementModel(
        id: '1',
        clubSocietyName: 'Computer Science Club',
        clubProfilePicUrl: 'https://robohash.org/csclub?set=set4',
        title: 'Flutter Workshop 2026',
        description:
            'Learn Flutter from scratch! This hands-on workshop will cover everything from basic widgets to state management.',
        startDateTime: Timestamp.fromDate(DateTime(2026, 4, 15, 14, 0)),
        endDateTime: Timestamp.fromDate(DateTime(2026, 4, 15, 17, 0)),
        dateCreated: Timestamp.now(),
        imageUrl: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=400&h=200&fit=crop',
        locationName: 'Engineering Building, Room 201',
        latitude: 3.0469,
        longitude: 101.7003,
        link: 'https://forms.google.com/register',
        tags: ['Workshop', 'Technical', 'Flutter'],
        capacity: 50,
        likes: 23,
        registrations: 15,
        producerId: 'user123',
        status: 'upcoming',
        isPublished: true,
        isFeatured: true,
        rewards: 'Certificate of Participation + Swag',
        approvedBy: 'admin1',
        approvedAt: Timestamp.now(),
      ),
      AnnouncementModel(
        id: '2',
        clubSocietyName: 'Basketball Club',
        clubProfilePicUrl: null,
        title: 'Inter-University Basketball Tournament',
        description:
            'Annual basketball tournament between universities. Come show your skills or cheer for your team!',
        startDateTime: Timestamp.fromDate(DateTime(2026, 5, 20, 9, 0)),
        endDateTime: Timestamp.fromDate(DateTime(2026, 5, 22, 18, 0)),
        dateCreated: Timestamp.now(),
        imageUrl: 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400&h=200&fit=crop',
        locationName: 'University Sports Complex',
        latitude: 3.0465,
        longitude: 101.6998,
        link: null,
        tags: ['Sports', 'Tournament', 'Competition'],
        capacity: 200,
        likes: 45,
        registrations: 78,
        producerId: 'user456',
        status: 'upcoming',
        isPublished: true,
        isFeatured: false,
        rewards: 'Trophies + Prize Money',
        approvedBy: 'admin1',
        approvedAt: Timestamp.now(),
      ),
      AnnouncementModel(
        id: '3',
        clubSocietyName: 'Music Society',
        clubProfilePicUrl: null,
        title: 'Spring Music Festival',
        description:
            'Join us for a day of live music featuring student bands and special guests. Food and drinks available!',
        startDateTime: Timestamp.fromDate(DateTime(2026, 6, 10, 16, 0)),
        endDateTime: Timestamp.fromDate(DateTime(2026, 6, 10, 23, 0)),
        dateCreated: Timestamp.now(),
        imageUrl: null,
        locationName: 'University Amphitheater',
        latitude: 3.0472,
        longitude: 101.7010,
        link: 'https://tickets.com/musicfest',
        tags: ['Music', 'Festival', 'Social'],
        capacity: 500,
        likes: 89,
        registrations: 120,
        producerId: 'user789',
        status: 'upcoming',
        isPublished: true,
        isFeatured: true,
        rewards: null,
        approvedBy: 'admin2',
        approvedAt: Timestamp.now(),
      ),
    ];
  }

  static List<AnnouncementModel> getFeaturedAnnouncements() {
    return getSampleAnnouncements()
        .where((a) => a.isFeatured)
        .toList();
  }

  static List<AnnouncementModel> getUpcomingAnnouncements() {
    return getSampleAnnouncements()
        .where((a) => a.status == 'upcoming')
        .toList();
  }
}