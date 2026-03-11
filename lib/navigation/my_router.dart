import 'package:app_links/app_links.dart'; // Required: flutter pub add app_links
import 'package:cute_live/ui/apply/apply_agency.dart';
import 'package:cute_live/ui/apply/apply_hosting.dart';
import 'package:cute_live/ui/auth/registration/register_page.dart';
import 'package:cute_live/ui/earnings/earnings_page.dart';
import 'package:cute_live/ui/inbox/chat_page.dart';
import 'package:cute_live/ui/inbox/inbox_page.dart';
import 'package:cute_live/ui/status/status_page.dart';
import 'package:cute_live/ui/streaming/audio_room_page.dart';
import 'package:cute_live/data/remote/rest/models/room_response_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:cute_live/navigation/routes.dart';
import 'package:cute_live/ui/auth/change_password/change_password_page.dart';
import 'package:cute_live/ui/auth/forget_password/forget_password_page.dart';
import 'package:cute_live/ui/auth/login/login_page.dart';
import 'package:cute_live/ui/auth/verify_otp/verify_otp_page.dart';
import 'package:cute_live/ui/video_streaming/video_room_page.dart';

import '../data/local/secure_storage/secure_storage.dart';
import '../ui/feedback/feedback_page.dart';
import '../ui/games/greedy_game.dart';
import '../ui/games/spinner_game.dart';
import '../ui/home/home_page.dart';
import '../ui/host_page/host_page.dart';
import '../ui/live_streaming/live_room_page.dart';
import '../ui/main_page.dart';
import '../ui/my_invites/my_invites_page.dart';
import '../ui/my_level/my_level_page.dart';
import '../ui/profile/bloc/profile_bloc.dart';
import '../ui/profile/bloc/profile_event.dart';
import '../ui/profile/edit_profile_page.dart';
import '../ui/profile/profile_page.dart';
import '../ui/profile/repository/user_repository.dart';
import '../ui/profile_visitors/profile_visitors_page.dart';
import '../ui/ranks/ranks_page.dart';
import '../ui/settings/password_settings_page.dart';
import '../ui/settings/account_security_page.dart';
import '../ui/settings/binding_pages.dart';
import '../ui/settings/blacklist_page.dart';
import '../ui/settings/language_setting_page.dart';
import '../ui/settings/new_messages_notification_page.dart';
import '../ui/settings/privacy_page.dart';
import '../ui/settings/about_poppo_page.dart';
import '../ui/settings/privilege_settings_page.dart';
import '../ui/settings/settings_page.dart';
import '../ui/store-bag/mybag_page.dart';
import '../ui/store-bag/store_page.dart';
import '../ui/streamer_center/streamer_center_page.dart';
import '../ui/guardian/guardian_page.dart';
import '../ui/medal_wall/medal_wall_page.dart';
import '../ui/profile/profile_card_page.dart';
import '../ui/backpack/backpack_page.dart';
import '../ui/top_up/top_up_page.dart';
import '../ui/auth/auth_page.dart';
import '../ui/follow_us/follow_us_page.dart';
import '../ui/help/help_page.dart';
import '../ui/help/my_feedback_page.dart';
import '../ui/level/level_page.dart';
import '../ui/store/mall_ranking_page.dart';
import '../ui/store/store_page.dart';
import '../ui/fan_club/fan_club_page.dart';
import '../ui/my_agency/my_agency_page.dart';
import '../ui/qr_scanner/qr_scanner_page.dart';
import '../ui/reward/reward_page.dart';
import '../ui/vip_page/vip_page.dart';
import '../ui/host_page/live_application_page.dart';
import '../ui/streaming/party_room_page.dart';

class MyRouter {
  static final publicRoutes = {
    Routes.login.path,
    Routes.forgetPassword.path,
    Routes.verifyOTP.path,
    Routes.changePassword.path,
  };

  // Changed to a factory method to initialize the listener
  static final router = _createRouter();

  static GoRouter _createRouter() {
    final goRouter = GoRouter(
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
            } else if (state.fullPath!.contains(Routes.inbox.path)) {
              page = 3;
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
              path: Routes.inbox.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: InboxPage(),
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
                child: FutureBuilder(
                  future: GetIt.I<SecureStorage>().getToken(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final token = snapshot.data!;

                    return BlocProvider(
                      create: (context) => ProfileBloc(
                        repository: UserRepository(),
                      )..add(LoadUserProfile(token)),
                      child: const ProfilePage(),
                    );
                  },
                ),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),

            GoRoute(
              path: Routes.editProfile.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: EditProfilePage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.settingsPage.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: SettingsPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.passwordSettings.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: PasswordSettingsPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.accountSecurity.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: AccountSecurityPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.applyHosting.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: ApplyHostingPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.applyAgency.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: ApplyAgencyPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.bindSelection.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const BindingSelectionPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.bindPhone.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const BindPhonePage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.bindEmail.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const BindEmailPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.languageSetting.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const LanguageSettingPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.blacklist.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const BlacklistPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.privilegeSettings.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const PrivilegeSettingsPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.newMessagesNotification.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const NewMessagesNotificationPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.privacy.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const PrivacyPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.aboutPoppo.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const AboutPoppoPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 200),
                reverseTransitionDuration: const Duration(milliseconds: 100),
              ),
            ),
            GoRoute(
              path: Routes.liveApplication.path,
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const LiveApplicationPage(),
                transitionsBuilder: customPopTransition,
                transitionDuration: const Duration(milliseconds: 250),
                reverseTransitionDuration: const Duration(milliseconds: 200),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/room/:roomId',
          redirect: (context, state) {
            final roomId = state.pathParameters['roomId'];
            final type = state.uri.queryParameters['type']; // 'audio', 'video', 'live'

            if (roomId == null) return Routes.home.path;

            if (type == 'audio') {
              return "${Routes.audioRoom.path}?roomId=$roomId";
            } else if (type == 'video') {
              return "${Routes.videoRoom.path}?roomId=$roomId";
            } else if (type == 'live') {
              return "${Routes.liveStream.path}?roomId=$roomId";
            }

            return Routes.home.path;
          },
        ),
        GoRoute(
          path: Routes.audioRoom.path,
          pageBuilder: (context, state) {
            String roomId = '';
            bool isHost = false;
            ZegoConfig? initialZegoConfig;

            if (state.extra != null && state.extra is Map<String, dynamic>) {
              final data = state.extra as Map<String, dynamic>;
              roomId = data['roomId'] as String;
              isHost = data['isHost'] as bool;
              initialZegoConfig = data['initialZegoConfig'] as ZegoConfig? ?? data['zegoConfig'] as ZegoConfig?;
            } else {
              roomId = state.uri.queryParameters['roomId'] ?? '';
            }

            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: AudioRoomPage(roomID: roomId, isHost: isHost, initialZegoConfig: initialZegoConfig),
              transitionsBuilder: customSlideTransition,
              transitionDuration: const Duration(milliseconds: 250),
              reverseTransitionDuration: const Duration(milliseconds: 200),
            );
          },
        ),
        GoRoute(
          path: Routes.videoRoom.path,
          pageBuilder: (context, state) {
            String roomId = '';
            bool isHost = false;

            if (state.extra != null && state.extra is Map<String, dynamic>) {
              final data = state.extra as Map<String, dynamic>;
              roomId = data['roomId'] as String;
              isHost = data['isHost'] as bool;
            } else {
              roomId = state.uri.queryParameters['roomId'] ?? '';
            }

            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: VideoRoomPage(roomID: roomId, isHost: isHost),
              transitionsBuilder: customSlideTransition,
              transitionDuration: const Duration(milliseconds: 250),
              reverseTransitionDuration: const Duration(milliseconds: 200),
            );
          },
        ),
        GoRoute(
          path: Routes.liveStream.path,
          pageBuilder: (context, state) {
            String roomId = '';
            bool isHost = false;

            if (state.extra != null && state.extra is Map<String, dynamic>) {
              final data = state.extra as Map<String, dynamic>;
              roomId = data['roomId'] as String;
              isHost = data['isHost'] as bool;
            } else {
              roomId = state.uri.queryParameters['roomId'] ?? '';
            }

            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: LiveStreamPage(roomID: roomId, isHost: isHost),
              transitionsBuilder: customSlideTransition,
              transitionDuration: const Duration(milliseconds: 250),
              reverseTransitionDuration: const Duration(milliseconds: 200),
            );
          },
        ),
        GoRoute(
          path: Routes.chat.path,
          pageBuilder: (context, state) {
            final args = state.extra as Map<String, dynamic>;

            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: ChatPage(
                peerId: args['peerId'] ?? '',
                peerName: args['peerName'] ?? 'Unknown',
                peerAvatar: args['peerAvatar'] ?? '',
              ),
              transitionsBuilder: customSlideTransition,
              transitionDuration: const Duration(milliseconds: 250),
              reverseTransitionDuration: const Duration(milliseconds: 200),
            );
          },
        ),
        GoRoute(
          path: Routes.greedy.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: GreedyGamePage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.spinner.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: FruitsKingPage(),
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
          path: Routes.ranks.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: RanksPage(),
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
        GoRoute(
          path: Routes.reward.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const RewardPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.streamerCenter.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const StreamerCenterPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.guardian.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const GuardianPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.medalWall.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const MedalWallPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.profileCard.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const ProfileCardPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.auth.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const AuthPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.followUs.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const FollowUsPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.myAgency.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const MyAgencyPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.qrScanner.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const QrScannerPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.help.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const HelpPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.fanClub.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const FanClubPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.backpack.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const BackpackPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.level.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const LevelPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.myFeedback.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const MyFeedbackPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.mall.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const MallPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.mallRanking.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const MallRankingPage(),
            transitionsBuilder: customSlideTransition,
            transitionDuration: const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        ),
        GoRoute(
          path: Routes.partyRoom.path,
          pageBuilder: (context, state) {
            String roomId = '';
            bool isHost = false;
            int slotCount = 18;
            String mode = 'voice';
            ZegoConfig? zegoConfig;
            if (state.extra != null && state.extra is Map<String, dynamic>) {
              final data = state.extra as Map<String, dynamic>;
              roomId = (data['roomId'] as String?) ?? '';
              isHost = (data['isHost'] as bool?) ?? false;
              slotCount = (data['slotCount'] as int?) ?? 6;
              mode = (data['mode'] as String?) ?? 'voice';
              zegoConfig = data['zegoConfig'] as ZegoConfig?;
            }
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: PartyRoomPage(
                roomId: roomId,
                isHost: isHost,
                slotCount: slotCount,
                mode: mode,
                zegoConfig: zegoConfig,
              ),
              transitionsBuilder: customSlideTransition,
              transitionDuration: const Duration(milliseconds: 250),
              reverseTransitionDuration: const Duration(milliseconds: 200),
            );
          },
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

    // --- Setup Listener for Warm/Background Starts ---
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      final location = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      debugPrint('AppLinks stream received: $location');
      goRouter.go(location);
    });

    return goRouter;
  }
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
