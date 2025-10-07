import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../data/local/secure_storage/secure_storage.dart';
import '../../ui/auth/login/login_state.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  final secureStorage = GetIt.I<SecureStorage>();

  AppCubit(super.appState);

  logout() {
    secureStorage.logout();
    emit(state.removeUser());
  }
}
