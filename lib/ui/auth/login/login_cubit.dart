import 'package:cute_live/data/local/secure_storage/user_secure_storage_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../data/local/secure_storage/secure_storage.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  final secureStorage = GetIt.I<SecureStorage>();

  // Dummy API service simulation
  Future<void> _simulateApiCall() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> loginWithPhone(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      emit(state.copyWith(status: LoginStatus.failure, error: 'Please enter a valid phone number'));
      return;
    }

    emit(state.copyWith(status: LoginStatus.loading, method: LoginMethod.phone, phoneNumber: phoneNumber, error: ''));

    try {
      await _simulateApiCall();

      // Simulate successful login
      if (phoneNumber.contains('123')) {
        final user = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Phone User',
          email: 'phone@example.com',
          phoneNumber: phoneNumber,
          avatar: 'https://via.placeholder.com/150',
        );
        await secureStorage.setIsLoggedIn(true);
        emit(state.copyWith(status: LoginStatus.success, user: user));
      } else {
        emit(state.copyWith(status: LoginStatus.failure, error: 'Invalid phone number. Please try again.'));
      }
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, error: 'Network error. Please check your connection.'));
    }
  }

  Future<void> loginWithCredentials(String userId, String password) async {
    if (userId.isEmpty || password.isEmpty) {
      emit(state.copyWith(status: LoginStatus.failure, error: 'Please fill in all fields'));
      return;
    }

    emit(state.copyWith(status: LoginStatus.loading, method: LoginMethod.credentials, userId: userId, password: password, error: ''));

    try {
      await _simulateApiCall();

      // Simulate successful login
      if (userId.toLowerCase() == 'demo' && password == 'password') {
        final user = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Demo User',
          email: 'demo@cutelive.com',
          avatar: 'https://via.placeholder.com/150',
        );

        emit(state.copyWith(status: LoginStatus.success, user: user));
      } else {
        emit(state.copyWith(status: LoginStatus.failure, error: 'Invalid credentials. Please try again.'));
      }
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, error: 'Network error. Please check your connection.'));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(state.copyWith(status: LoginStatus.loading, method: LoginMethod.google, error: ''));

    try {
      await _simulateApiCall();

      // Simulate successful Google login
      final user = User(
        id: 'google_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Google User',
        email: 'google@gmail.com',
        avatar: 'https://via.placeholder.com/150',
      );

      emit(state.copyWith(status: LoginStatus.success, user: user));
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, error: 'Google sign-in failed. Please try again.'));
    }
  }

  Future<void> loginWithFacebook() async {
    emit(state.copyWith(status: LoginStatus.loading, method: LoginMethod.facebook, error: ''));

    try {
      await _simulateApiCall();

      // Simulate successful Facebook login
      final user = User(
        id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Facebook User',
        email: 'facebook@facebook.com',
        avatar: 'https://via.placeholder.com/150',
      );

      emit(state.copyWith(status: LoginStatus.success, user: user));
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, error: 'Facebook sign-in failed. Please try again.'));
    }
  }

  void resetError() {
    emit(state.copyWith(error: ''));
  }

  void resetState() {
    emit(const LoginState());
  }

  void updatePhoneNumber(String phoneNumber) {
    emit(state.copyWith(phoneNumber: phoneNumber));
  }

  void updateUserId(String userId) {
    emit(state.copyWith(userId: userId));
  }

  void updatePassword(String password) {
    emit(state.copyWith(password: password));
  }
}
