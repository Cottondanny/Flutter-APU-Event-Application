import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studenthub/models/announcement_model.dart';
import 'package:studenthub/services/mock_announcement_service.dart';

class AnnouncementService {
  static const bool useMockData = false;

  Future<List<AnnouncementModel>> getAnnouncements() async {
    //This will return the data eventually. Even though mock data is instant, we're forcing the ui to handle async from the start so nothing breaks when I swap to Firestore.
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      return MockAnnouncementService.getSampleAnnouncements();
    }

    final snap = await FirebaseFirestore.instance
        .collection('announcements')
        .where('isPublished', isEqualTo: true)
        .orderBy('dateCreated', descending: true)
        .get();

    return snap.docs
        .map((doc) => AnnouncementModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<List<AnnouncementModel>> getRegisteredAnnouncements() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    // Step 1 — get all registration documents for this student
    final regSnap = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('registrations')
        .get();

    if (regSnap.docs.isEmpty) return [];

    // Step 2 — extract the announcement IDs
    // Each registration document ID is the announcement ID
    final ids = regSnap.docs.map((doc) => doc.id).toList();

    // Step 3 — fetch each announcement by its ID
    // whereIn can take up to 30 IDs at once
    final announcementSnap = await FirebaseFirestore.instance
        .collection('announcements')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    return announcementSnap.docs
        .map((doc) => AnnouncementModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // Unregister from an event
  // Deletes the registration doc and decrements the count
  Future<void> unregisterFromAnnouncement(String announcementId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Delete the registration document
    await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .collection('registrations')
        .doc(announcementId)
        .delete();

    // Decrement the registrations count on the announcement
    // Only decrement if count is above 0 to avoid negative numbers
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(announcementId)
        .update({'registrations': FieldValue.increment(-1)});
  }
}
