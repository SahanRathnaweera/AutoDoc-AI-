import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:autodoc_ai/features/authentication/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    super.displayName,
    super.phoneNumber,
    super.photoUrl,
    super.isEmailVerified = false,
    super.role = 'client',
    super.createdAt,
    super.updatedAt,
  });

  /// Creates a [UserModel] from a Firebase [fb_auth.User].
  factory UserModel.fromFirebaseUser(
    fb_auth.User user, {
    String role = 'client',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a [UserModel] from a Firestore document map.
  factory UserModel.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserModel(
      uid: uid ?? (map['uid'] as String? ?? ''),
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String? ?? map['profileImageUrl'] as String?,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      role: map['role'] as String? ?? 'client',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  /// Converts the [UserModel] to a JSON/Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'isEmailVerified': isEmailVerified,
      'role': role,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    bool? isEmailVerified,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
