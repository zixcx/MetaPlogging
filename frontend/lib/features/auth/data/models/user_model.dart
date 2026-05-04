// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta_plogging/features/auth/domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    String? name,
    @JsonKey(name: 'profile_image_url') String? profileImageUrl,
    @JsonKey(name: 'auth_provider') required String authProvider,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

extension UserModelX on UserModel {
  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        name: name,
        profileImageUrl: profileImageUrl,
        authProvider: AuthProvider.values.byName(authProvider),
      );
}
