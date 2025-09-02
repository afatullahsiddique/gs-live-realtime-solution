import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cute_live/data/local/secure_storage/user_secure_storage_extension.dart';

import '../../data/local/secure_storage/secure_storage.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit(super.appState);

  final secureStorage = GetIt.I<SecureStorage>();

  logout() {
    secureStorage.setIsLoggedIn(false);
    emit(state);
  }
}
