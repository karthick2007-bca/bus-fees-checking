enum AdminRole { superAdmin, finance, route }

class AdminUser {
  final String id;
  final String username;
  final AdminRole role;

  AdminUser({
    required this.id,
    required this.username,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'role': role.toString().split('.').last,
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'],
      username: map['username'],
      role: AdminRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
      ),
    );
  }
}