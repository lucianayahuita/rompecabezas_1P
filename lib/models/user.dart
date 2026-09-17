class User {
  final int? id;
  final String email;
  final String password;
  final String username;

  User({
    this.id,
    required this.email,
    required this.password,
    String? username,
  }) : username = username ?? email.split('@')[0];

  // Convierte el objeto a un Map para insertarlo en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'username': username,
    };
  }

  // Crea un objeto User a partir de un Map devuelto por SQLite
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      username: map['username'],
    );
  }
}