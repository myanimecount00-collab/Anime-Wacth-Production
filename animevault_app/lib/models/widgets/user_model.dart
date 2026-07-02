class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photo;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photo,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photo': photo,
      'createdAt': createdAt,
    };
  }
}