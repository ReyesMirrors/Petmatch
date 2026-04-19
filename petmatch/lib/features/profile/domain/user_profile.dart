class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String bio;
  final double? lat;
  final double? lng;
  final List<String> favorites;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.bio,
    this.lat,
    this.lng,
    required this.favorites,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      bio: map['bio'] ?? '',
      lat: map['lat'],
      lng: map['lng'],
      favorites: List<String>.from(map['favorites'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'lat': lat,
      'lng': lng,
      'favorites': favorites,
    };
  }
}