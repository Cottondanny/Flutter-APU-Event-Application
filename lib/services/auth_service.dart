import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/student_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  //REGISTER
  //Returns null if it is sucessful, returns an error message, if it is wrong
  Future<String?> registerStudent({
    required String name,
    required String tpNumber,
    required String email,
    required String programme,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // Step 1: Create the login account in Firebase Auth
      // This gives us a unique uid for the user
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2: Build the student profile using that uid
      StudentModel student = StudentModel(
        uid: credential.user!.uid,
        name: name,
        tpNumber: tpNumber,
        email: email,
        programme: programme,
        phoneNumber: phoneNumber,
      );

      // Step 3: Save the profile to Firestore under 'students' collection
      // Each student gets their own document named by their uid
      await _firestore
          .collection('students')
          .doc(credential.user!.uid)
          .set(student.toMap());

      return null; // null means success
    } on FirebaseAuthException catch (e) {
      // Firebase gives us error codes we can translate into friendly messages
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
  }

  //LOGIN
  Future<String?> loginStudent({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
      //null is success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
  }

  // FETCH student profile from Firestore
  Future<StudentModel?> getStudentProfile(String uid) async {
    try {
      final doc = await _firestore.collection('students').doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return StudentModel(
        uid: uid,
        name: data['name'] ?? '',
        tpNumber: data['tpNumber'] ?? '',
        email: data['email'] ?? '',
        programme: data['programme'] ?? '',
        phoneNumber: data['phoneNumber'] ?? '',
        profilePicUrl: data['profilePicUrl'],
      );
    } catch (e) {
      return null;
    }
  }

  // UPLOAD Profile picture to Firebase Storage
  // It will return the download URL if it succeeds and null if it fails
  Future<String?> uploadProfilePicture(String uid, File imageFile) async {
    try {
      // Creates a path in Storage: profilePictures/uid.jpg
      final ref = _storage.ref().child('profilePictures/$uid.jpg');
      await ref.putFile(imageFile);
      // Get the public URL of the uploaded image
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  //UPDATE student profile in Firestore
  // Returns null on success, error message when failure

  Future<String?> updateStudentProfile({
    required String uid,
    required String name,
    required String tpNumber,
    required String programme,
    required String phoneNumber,
    String? profilePicUrl,
  }) async {
    try {
      // Only update the fields that changed
      // We build the map manually so we don't accidentally overwrite other fields
      final Map<String, dynamic> updates = {
        'name': name,
        'tpNumber': tpNumber,
        'programme': programme,
        'phoneNumber': phoneNumber,
      };

      // Only include profilePicUrl if it was actually changed
      if (profilePicUrl != null) {
        updates['profilePicUrl'] = profilePicUrl;
      }

      await _firestore
          .collection('students')
          .doc(uid)
          .set(updates, SetOptions(merge: true));

    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Please log out and log back in before changing your email.';
      }
      return 'Failed to update email. Please try again.';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
    return null;
  }

  //Change password
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser!;
      // Firebase requires you to re-authenticate before changing password
      // Why? Security so someone who finds your unlocked phone can't change your password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') return 'Current password is incorrect.';
      return 'Failed to change password. Please try again.';
    }
  }
}
