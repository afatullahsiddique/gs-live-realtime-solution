import 'package:equatable/equatable.dart';

enum LoginStatus { initial, loading, success, failure }

enum LoginMethod { phone, credentials, google, facebook }

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.method = LoginMethod.phone,
    this.phoneNumber = '',
    this.userId = '',
    this.password = '',
    this.error,
    this.user,
  });

  final LoginStatus status;
  final LoginMethod method;
  final String phoneNumber;
  final String userId;
  final String password;
  final String? error;
  final User? user;

  bool get isLoading => status == LoginStatus.loading;

  bool get isSuccess => status == LoginStatus.success;

  bool get isFailure => status == LoginStatus.failure;

  bool get isInitial => status == LoginStatus.initial;

  LoginState copyWith({
    LoginStatus? status,
    LoginMethod? method,
    String? phoneNumber,
    String? userId,
    String? password,
    String? error,
    User? user,
  }) {
    return LoginState(
      status: status ?? this.status,
      method: method ?? this.method,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userId: userId ?? this.userId,
      password: password ?? this.password,
      error: error,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [status, method, phoneNumber, userId, password, error, user];
}

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.displayId,
    this.avatar,
    this.phoneNumber,
    this.token,
    this.refreshToken,
  });

  final String id;
  final String name;
  final String email;
  final String? displayId;
  final String? avatar;
  final String? phoneNumber;
  final String? token;
  final String? refreshToken;

  /// Create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      displayId: json['displayId'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayId': displayId,
      'name': name,
      'email': email,
      'avatar': avatar,
      'phoneNumber': phoneNumber,
      'token': token,
      'refreshToken': refreshToken,
    };
  }

  /// Copy the user with new values
  User copyWith({
    String? id,
    String? displayId,
    String? name,
    String? email,
    String? avatar,
    String? phoneNumber,
    String? token,
    String? refreshToken,
  }) {
    return User(
      id: id ?? this.id,
      displayId: displayId ?? this.displayId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayId,
    name,
    email,
    avatar,
    phoneNumber,
    token,
    refreshToken,
  ];
}