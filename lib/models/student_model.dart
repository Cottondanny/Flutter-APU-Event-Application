class StudentModel{
  final String uid;
  final String name;
  final String tpNumber;
  final String email;
  final String programme;
  final String phoneNumber;
  final String? profilePicUrl; 

  StudentModel({
    required this.uid,
    required this.name,
    required this.tpNumber,
    required this.email,
    required this.programme,
    required this.phoneNumber,
    this.profilePicUrl,
  });

  // Converts StudentModel into a Map so Firestore can store it
  // Firestore does not understand dart, it only understands key-value pairs so we use toMap() to convert object into something firestore can store
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'tpNumber': tpNumber,
      'email': email,
      'programme': programme,
      'phoneNumber': phoneNumber,
      'profilePicUrl': profilePicUrl, 
    };
  }

}

