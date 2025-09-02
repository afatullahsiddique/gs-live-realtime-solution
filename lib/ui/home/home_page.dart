import 'package:cute_live/data/local/secure_storage/user_secure_storage_extension.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/secure_storage/secure_storage.dart';
import '../../navigation/routes.dart';
import '../../theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: GestureDetector(
            onTap: () async {
              await GetIt.I<SecureStorage>().setIsLoggedIn(false).then((v) {
                context.go(Routes.login.path);
              });
            },
            child: Text("home"),
          ),
        ),
      ),
    );
  }
}
