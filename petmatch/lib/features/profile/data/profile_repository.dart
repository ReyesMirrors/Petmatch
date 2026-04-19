import '../domain/user_profile.dart';

abstract class ProfileRepository {
  Stream<UserProfile> watchProfile(String uid);
  Future<void> updateProfile(UserProfile profile);
}