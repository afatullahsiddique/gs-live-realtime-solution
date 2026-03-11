import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cute_live/theme/app_theme.dart';

import 'core/cubits/app_cubit.dart';
import 'di/get_it.dart';
import 'firebase_options.dart';
import 'navigation/my_router.dart';
import 'navigation/routes.dart';
import 'notifications/notification_for_fcm_token.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await registerDI();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.I<AppCubit>()),
        BlocProvider(create: (_) => GetIt.I<NotificationCubit>()),
      ],
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          return MaterialApp.router(
            routerConfig: MyRouter.router,
            debugShowCheckedModeBanner: false,
            title: 'GS LIVE',
            themeMode: ThemeMode.light,
            theme: AppTheme.themeData(),
          );
        },
      ),
    );
  }
}
