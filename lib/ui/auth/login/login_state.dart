import 'package:equatable/equatable.dart';

enum LoginStatus {
  initial,
  loading,
  success,
  failure,
}

enum LoginMethod {
  phone,
  credentials,
  google,
  facebook,
}

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.method = LoginMethod.phone,
    this.phoneNumber = '',
    this.userId = '',
    this.password = '',
    this.error = '',
    this.user,
  });

  final LoginStatus status;
  final LoginMethod method;
  final String phoneNumber;
  final String userId;
  final String password;
  final String error;
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
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
    status,
    method,
    phoneNumber,
    userId,
    password,
    error,
    user,
  ];
}

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.phoneNumber,
  });

  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? phoneNumber;

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  List<Object?> get props => [id, name, email, avatar, phoneNumber];
}