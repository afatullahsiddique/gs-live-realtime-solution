import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../local/secure_storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final String baseUrl = "https://gs-live-backend.vercel.app/api/v1";

  ApiClient() {
    print('🏗️ [API_CLIENT] Initializing ApiClient singleton...');
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final secureStorage = GetIt.instance<SecureStorage>();
        final token = await secureStorage.getToken();
        print('🌐 [API_CLIENT] Request: ${options.method} ${options.baseUrl}${options.path}');
        if (token != null) {
          print('🌐 [API_CLIENT] Using token: $token');
          options.headers["authorization"] = token;
        } else {
          print('🌐 [API_CLIENT] No token found in secure storage');
        }
        return handler.next(options);
      },
    ));
  }
}
