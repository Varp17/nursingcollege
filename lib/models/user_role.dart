// lib/models/user_role.dart
enum UserRole {
  student,
  security,
  admin,
  superadmin,
}

// Convert from string (Firestore) to UserRole
UserRole userRoleFromString(String role) {
  switch (role.toLowerCase()) {
    case 'student':
      return UserRole.student;
    case 'security':
      return UserRole.security;
    case 'admin':
      return UserRole.admin;
    case 'superadmin':
      return UserRole.superadmin;
    default:
      return UserRole.student; // fallback
  }
}

// Convert UserRole to string (Firestore)
String userRoleToString(UserRole role) => role.name;
