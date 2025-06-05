class User {
  final int id;
  final String name;
  final String? username;
  final String? email;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      avatar: json['avatar'],
    );
  }
}
