import 'package:cute_live/ui/auth/registration/register_page.dart';
import 'package:cute_live/ui/earnings/earnings_page.dart';
import 'package:cute_live/ui/live_streaming/live_room_page.dart';
import 'package:cute_live/ui/my_invites/my_invites_page.dart';
import 'package:cute_live/ui/profile_visitors/profile_visitors_page.dart';
import 'package:cute_live/ui/status/status_page.dart';
import 'package:cute_live/ui/store-bag/mybag_page.dart';
import 'package:cute_live/ui/streaming/audio_room_page_v2.dart';
import 'package:cute_live/ui/top_up/top_up_page.dart';
import 'package:cute_live/ui/vip_page/vip_page.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:cute_live/navigation/routes.dart';
import 'package:cute_live/ui/auth/change_password/change_password_page.dart';
import 'package:cute_live/ui/auth/forget_password/forget_password_page.dart';
import 'package:cute_live/ui/auth/login/login_page.dart';
import 'package:cute_live/ui/auth/verify_otp/verify_otp_page.dart';

import '../data/local/secure_storage/secure_storage.dart';
import '../ui/feedback/feedback_page.dart';
import '../ui/home/home_page.dart';
import '../ui/host_page/host_page.dart';
import '../ui/main_page.dart';
import '../ui/my_level/my_level_page.dart';
import '../ui/profile/profile_page.dart';
import '../ui/store-bag/store_page.dart';
import '../ui/video_streaming/video_room_page.dart';

class MyRouter {
  static final publicRoutes = {
    Routes.login.path,
    Routes.forgetPassword.path,
    Routes.verifyOTP.path,
    Routes.changePassword.path,
  };

  static final router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: Routes.home.path,
    redirect: (context, state) async {
      if (publicRoutes.any((route) => state.fullPath!.endsWith(route))) {
        return null;
      }
      final isLoggedIn = await GetIt.I<SecureStorage>().isLoggedIn;
      if (!isLoggedIn) return Routes.login.path;
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          int page = 0;
          if (state.fullPath!.contains(Routes.status.path)) {
            page = 1;
          } else if (state.fullPath!.contains(Routes.hostPage.path)) {
            page = 2;
            // } else if (state.fullPath!.contains(Routes.home.path)) {
            //   page = 3;
          } else if (state.fullPath!.contains(Routes.profile.path)) {
            page = 4;
          }
          return MainPage(selectedPageNo: page, child: child);
        },
        routes: [
          GoRoute(
            path: Routes.home.path,
            pageBuilder: (context, state) => NoTransitionPage<void>(key: state.pageKey, child: HomePage()),
          ),
          GoRoute(
            path: Routes.status.path,
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: StatusPage(),
              transitionsBuilder: customPopTransition,
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 100),
            ),
          ),
          GoRoute(
            path: Routes.hostPage.path,
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: HostPage(),
              transitionsBuilder: customPopTransition,
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 100),
            ),
          ),
          GoRoute(
            path: Routes.history.path,
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const Scaffold(body: Center(child: Text("history"))),
              transitionsBuilder: customPopTransition,
              transitionDuration: const Duration(milliseconds: 200),
              reverseTransitionDuration: const Duration(milliseconds: 100),
            ),
          ),
          GoRoute(
            path: Routes.profile.path,
            pageBuilder: (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: ProfilePage(),
              transitionsBuilder: customPopTransition,
              transitionDuration: const Duration(milliseconds: 200),
              reverseTransitionDuration: const Duration(milliseconds: 100),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.audioRoom.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: AudioRoomPage(
              roomID: (state.extra as Map<String, dynamic>)['roomId'] as String,
              isHost: (state.extra as Map<String, dynamic>)['isHost'] as bool
          ),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.videoRoom.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: VideoRoomPage(
            roomID: (state.extra as Map<String, dynamic>)['roomId'] as String,
            isHost: (state.extra as Map<String, dynamic>)['isHost'] as bool,
          ),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.liveStream.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: LiveStreamPage(
            roomID: (state.extra as Map<String, dynamic>)['roomId'] as String,
            isHost: (state.extra as Map<String, dynamic>)['isHost'] as bool,
          ),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.topUp.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: TopUpPage(beansCount: 12745),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.earnings.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: EarningsPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.vip.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: VIPPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.myInvites.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: MyInvitesPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.visitors.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: ProfileVisitorsPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.store.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: StorePage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.myBag.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: MyBagPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.myLevel.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: MyLevelPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.feedback.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: FeedbackPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.login.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: LoginPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.register.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: RegisterPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.forgetPassword.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: ForgetPasswordPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.verifyOTP.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: VerifyOTPPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: Routes.changePassword.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: ChangePasswordPage(),
          transitionsBuilder: customSlideTransition,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      child: Scaffold(
        appBar: AppBar(backgroundColor: Colors.red, title: const Text("Error 404")),
        body: const Center(child: Text("Page not found.")),
      ),
    ),
  );
}

Widget customPopTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return ScaleTransition(
    scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.ease)),
    child: child,
  );
}

Widget customSlideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.decelerate)),
    child: child,
  );
}

Widget noTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return child;
}
