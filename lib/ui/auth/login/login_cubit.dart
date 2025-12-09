import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../data/local/secure_storage/secure_storage.dart';
import '../../../data/remote/firebase/profile_services.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  final secureStorage = GetIt.I<SecureStorage>();
  final _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        // serverClientId: "645699802815-k86olmji8qdha8jrfnor3phdbp0sp72j.apps.googleusercontent.com",
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
        final user = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Phone User',
          email: 'phone@example.com',
          phoneNumber: phoneNumber,
          avatar: 'https://via.placeholder.com/150',
        );
        await secureStorage.setUser(user);
        emit(state.copyWith(status: LoginStatus.success, user: user));
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
      ),
    );

    try {
      // Query Firestore for user with matching displayId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('displayId', isEqualTo: displayId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        emit(state.copyWith(status: LoginStatus.failure, error: 'Invalid Display ID or password.'));
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();

      // Verify password
      if (!userData.containsKey('password') ||
          userData['password'] == null ||
          userData['password'].toString().isEmpty) {
        emit(state.copyWith(status: LoginStatus.failure, error: 'No password set. Please use social login.'));
        return;
      }

      if (userData['password'] != password) {
        emit(state.copyWith(status: LoginStatus.failure, error: 'Invalid Display ID or password.'));
        return;
      }

      // Check if user is already signed in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userDoc.id) {
        // Already signed in as this user
        print('User already signed in');
      } else {
        // Sign out current user if any
        if (currentUser != null) {
          await FirebaseAuth.instance.signOut();
        }

        // Sign in anonymously (requires Anonymous provider enabled)
        await FirebaseAuth.instance.signInAnonymously();
      }

      // Update last login
      await FirebaseFirestore.instance.collection('users').doc(userDoc.id).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Create User object
      final user = User(
        id: userDoc.id,
        displayId: userData['displayId'] ?? '',
        name: userData['displayName'] ?? 'User',
        email: userData['email'] ?? '',
        avatar: userData['photoUrl'],
        phoneNumber: userData['phoneNumber'],
      );

      await secureStorage.setUser(user);
      emit(state.copyWith(status: LoginStatus.success, user: user));
    } catch (e) {
      print('Login error: $e');
      emit(state.copyWith(status: LoginStatus.failure, error: 'Login failed. Please try again.'));
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
