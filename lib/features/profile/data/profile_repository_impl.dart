import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_profile.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Stream<UserProfile> watchProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => UserProfile.fromMap(doc.data()!),
        );
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
  }
}