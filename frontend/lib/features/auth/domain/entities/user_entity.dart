import 'package:flutter/foundation.dart';

enum AuthProvider { email, google, kakao }

@immutable
class UserEntity {
  final String id;
  final String email;
  final String? name;
  final String? profileImageUrl;
  final AuthProvider authProvider;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.profileImageUrl,
    required this.authProvider,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
