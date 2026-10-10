import 'package:equatable/equatable.dart';

/// Core User entity representing an authenticated user across AutoDoc AI.
class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final bool isEmailVerified;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.isEmailVerified = false,
    this.role = 'client',
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        phoneNumber,
        photoUrl,
        isEmailVerified,
        role,
        createdAt,
        updatedAt,
      ];
}
