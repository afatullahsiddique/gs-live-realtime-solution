import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../data/local/secure_storage/secure_storage.dart';
import '../../../data/remote/firebase/profile_services.dart';
import 'login_state.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  final secureStorage = GetIt.I<SecureStorage>();
  final _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: "44126273424-6veicbgnmabtdh414egeo26a6ivuer0i.apps.googleusercontent.com",
      );
      _isGoogleSignInInitialized = true;
    } catch (e) {
      print('Failed to initialize Google Sign-In: $e');
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _initializeGoogleSignIn();
    }
  }

  Future<void> loginWithGoogle() async {
    emit(state.copyWith(status: LoginStatus.loading, method: LoginMethod.google));
    try {
      await _ensureGoogleSignInInitialized();

      // Authenticate with Google
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(scopeHint: ['email', 'profile']);

      // Get authorization for Firebase scopes if needed
      final authClient = _googleSignIn.authorizationClient;
      final authorization = await authClient.authorizationForScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleUser.authentication.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      try {
        await ProfileService.syncUserProfile();
      } catch (profileError) {
        print("Error syncing user profile: $profileError");
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

      final userData = userDoc.data();

      final User? user = User(
        id: userCredential.user!.uid,
        // Try to get the displayId from Firestore, fallback to empty if something failed
        displayId: userData?['displayId'] ?? "",
        name: userData?['displayName'] ?? userCredential.user!.displayName ?? "Unknown",
        email: userCredential.user!.email!,
        avatar: userData?['photoUrl'] ?? userCredential.user!.photoURL,
      );

      secureStorage.setUser(user!);
      emit(state.copyWith(status: LoginStatus.success, user: user));
    } catch (e) {
      print(e.toString());
      emit(state.copyWith(status: LoginStatus.failure, error: 'Google sign-in failed. Please try again.'));
    }
  }

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
        // final user = User(
        //   id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        //   name: 'Phone User',
        //   email: 'phone@example.com',
        //   phoneNumber: phoneNumber,
        //   avatar: 'https://via.placeholder.com/150',
        // );
        // await secureStorage.setUser(user);
        // emit(state.copyWith(status: LoginStatus.success, user: user));
      } else {
        emit(state.copyWith(status: LoginStatus.failure, error: 'Invalid phone number. Please try again.'));
      }
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, error: 'Network error. Please check your connection.'));
    }
  }

  Future<void> loginWithCredentials(String displayId, String password) async {
    if (displayId.isEmpty || password.isEmpty) {
      emit(state.copyWith(status: LoginStatus.failure, error: 'Please fill in all fields'));
      return;
    }

    emit(
      state.copyWith(
        status: LoginStatus.loading,
        method: LoginMethod.credentials,
        userId: displayId,
        password: password,
        error: null,
      ),
    );

    try {
      final response = await http.post(
        Uri.parse('https://gf-live-backend.onrender.com/api/v1/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'displayId': displayId,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      debugPrint("Status code: ${response.statusCode}");
      debugPrint("Url: ${response.request?.url}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200 && data['status'] == true) {
        final userData = data['data'];

        final user = User(
          id: userData['id'],
          displayId: userData['displayId'],
          name: userData['name'] ?? 'User',
          email: userData['email'] ?? '',
          token: userData['token'], // ✅ now exists
        );

        await secureStorage.setUser(user); // store login info

        emit(state.copyWith(status: LoginStatus.success, user: user));
      }
      else {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            error: data['message'] ?? 'Invalid User ID or password.',
          ),
        );
      }
    } catch (e) {
      print('Login error: $e');
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          error: 'Login failed. Please try again.',
        ),
      );
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
