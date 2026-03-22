import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String clubSocietyName;
  final String? clubProfilePicUrl;
  final String title;
  final String description;
  final Timestamp? startDateTime;
  final Timestamp? endDateTime;
  final Timestamp? dateCreated;
  final String? imageUrl;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? link;
  final List<String> tags;
  final int? capacity;
  final int likes;
  final int registrations;
  final String? producerId;
  final String status;
  final bool isPublished;
  final bool isFeatured;
  final String? rewards;
  final String? approvedBy;
  final Timestamp? approvedAt;

  AnnouncementModel({
    required this.id,
    required this.clubSocietyName,
    this.clubProfilePicUrl,
    required this.title,
    required this.description,
    this.startDateTime,
    this.endDateTime,
    this.dateCreated,
    this.imageUrl,
    this.locationName,
    this.latitude,
    this.longitude,
    this.link,
    required this.tags,
    this.capacity,
    required this.likes,
    required this.registrations,
    this.producerId,
    required this.status,
    required this.isPublished,
    required this.isFeatured,
    this.rewards,
    this.approvedBy,
    this.approvedAt,
  });

  /*
  factory keyword is used for more control. Null checks, and type casting before creating objects is used here so factory is neccessary. It acts as a constructor instead of a static method. 
  */
  factory AnnouncementModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return AnnouncementModel(
      id: id,
      clubSocietyName:
          data['clubSocietyName'] ??
          'Unknown Club', //?? tells if the data is null, we use 'Unkown Club'
      clubProfilePicUrl: data['clubProfilePicUrl'],
      title: data['title'] ?? 'Untitled Event',
      description: data['description'] ?? '',
      startDateTime: data['startDateTime'],
      endDateTime: data['endDateTime'],
      dateCreated: data['dateCreated'],
      imageUrl: data['imageUrl'],
      locationName: data['locationName'],
      // Firestore stores numbers as num, so we cast safely as Double
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      link: data['link'],
      // Firestore arrays come back as List<dynamic>, so we cast each item
      tags: List<String>.from(data['tags'] ?? []),
      capacity: data['capacity'],
      likes: data['likes'] ?? 0,
      registrations: data['registrations'] ?? 0,
      producerId: data['producerId'],
      status: data['status'] ?? 'upcoming',
      isPublished: data['isPublished'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      rewards: data['rewards'],
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'],
    );
  }

  // Converts Timestamp to DateTime for calendar and comparison logic
  DateTime? get startDateTimeAsDate => startDateTime?.toDate();
  DateTime? get endDateTimeAsDate => endDateTime?.toDate();

  // Formatted strings for display in the UI
  String? get formattedStartDate {
    final date = startDateTime?.toDate().toLocal(); // .toLocal()
    if (date == null) return null;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String? get formattedEndDate {
    final date = endDateTime?.toDate().toLocal();
    if (date == null) return null;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String? get formattedStartTime {
    final date = startDateTime?.toDate().toLocal();
    if (date == null) return null;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String? get formattedEndTime {
    final date = endDateTime?.toDate().toLocal();
    if (date == null) return null;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Used by feed screen to update like count without refetching
  AnnouncementModel copyWith({int? likes, int? registrations}) {
    return AnnouncementModel(
      id: id,
      clubSocietyName: clubSocietyName,
      clubProfilePicUrl: clubProfilePicUrl,
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      dateCreated: dateCreated,
      imageUrl: imageUrl,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      link: link,
      tags: tags,
      capacity: capacity,
      likes: likes ?? this.likes,
      registrations: registrations ?? this.registrations,
      producerId: producerId,
      status: status,
      isPublished: isPublished,
      isFeatured: isFeatured,
      rewards: rewards,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
    );
  }
}
