import 'package:get_it/get_it.dart';

import '../core/cubits/app_cubit.dart';
import '../data/local/secure_storage/secure_storage.dart';

import '../data/remote/rest/api_client.dart';
import '../data/remote/rest/room_api_service.dart';
import '../notifications/notification_for_fcm_token.dart';
import '../data/remote/socket/socket_service.dart';

final getIt = GetIt.instance;

Future<void> registerDI() async {
  getIt.registerSingleton<SecureStorage>(SecureStorage());
  getIt.registerSingleton<ApiClient>(ApiClient());
  getIt.registerLazySingleton<RoomApiService>(() => RoomApiService(getIt<ApiClient>()));
  getIt.registerSingleton<NotificationCubit>(NotificationCubit());
  getIt.registerSingleton<SocketService>(SocketService());
  getIt.registerSingleton<AppCubit>(AppCubit(await retrieveAppState()));
}

Future<AppState> retrieveAppState() async {
  return AppState();
}
