class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final double? lat;
  final double? lng;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    this.lat,
    this.lng,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'lat': lat,
      'lng': lng,
    };
  }

  UserProfile copyWith({
    String? name,
    String? photoUrl,
    double? lat,
    double? lng,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}