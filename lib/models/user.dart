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
    print('DEBUG: User.fromJson input: $json');

    return User(
      id: json['id'] as int? ?? -1,
      name: json['name'] as String? ?? 'Unknown User',
      username: json['username'] as String?,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'avatar': avatar,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, username: $username, email: $email)';
  }
}
