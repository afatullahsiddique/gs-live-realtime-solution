import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends ProfileEvent {
  final String token;

  LoadUserProfile(this.token);

  @override
  List<Object?> get props => [token];
}
