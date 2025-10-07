import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';

import '../../data/local/secure_storage/secure_storage.dart';
import '../auth/login/login_state.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());
  final secureStorage = GetIt.instance<SecureStorage>();

  init() async {
    final user = await secureStorage.getUser();
    emit(state.copyWith(user: user, isLoading: false));
  }
}
