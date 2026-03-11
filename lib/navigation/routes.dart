enum Routes {
  login,
  register,
  forgetPassword,
  verifyOTP,
  changePassword,
  home,
  audioRoom,
  status,
  offer,
  qrCode,
  history,
  more,
  profile,
  topUp,
  earnings,
  store,
  myBag,
  myLevel,
  feedback,
  vip,
  myInvites,
  visitors,
  hostPage,
  videoRoom,
  liveStream,
  greedy,
  spinner,
  editProfile,
  applyHosting,
  applyAgency,
  inbox,
  chat,
  settingsPage,
  passwordSettings,
  ranks,
  reward,
  streamerCenter,
  guardian,
  medalWall,
  profileCard,
  auth,
  followUs,
  myAgency,
  qrScanner,
  help,
  fanClub,
  backpack,
  level,
  myFeedback,
  mall,
  mallRanking,
  accountSecurity,
  bindSelection,
  bindPhone,
  bindEmail,
  languageSetting,
  blacklist,
  privilegeSettings,
  newMessagesNotification,
  privacy,
  aboutPoppo,
  liveApplication,
  partyRoom,
}

extension RoutesExtension on Routes {
  String get path {
    switch (this) {
      case Routes.login:
        return '/login';
      case Routes.register:
        return '/register';
      case Routes.forgetPassword:
        return '/forgetPassword';
      case Routes.verifyOTP:
        return '/verifyOTP';
      case Routes.changePassword:
        return '/changePassword';
      case Routes.home:
        return '/home';
      case Routes.status:
        return '/status';
      case Routes.audioRoom:
        return '/audioRoom';
      case Routes.offer:
        return '/offer';
      case Routes.qrCode:
        return '/qrCode';
      case Routes.history:
        return '/history';
      case Routes.more:
        return '/more';
      case Routes.profile:
        return '/profile';
      case Routes.topUp:
        return '/topUp';
      case Routes.earnings:
        return '/earnings';
      case Routes.store:
        return '/store';
      case Routes.myBag:
        return '/my-bag';
      case Routes.myLevel:
        return '/my-level';
      case Routes.feedback:
        return '/feedback';
      case Routes.vip:
        return '/vip';
      case Routes.myInvites:
        return '/myInvites';
      case Routes.visitors:
        return '/visitors';
      case Routes.hostPage:
        return '/hostPage';
      case Routes.videoRoom:
        return '/videoRoom';
      case Routes.liveStream:
        return '/liveStream';
      case Routes.greedy:
        return '/greedy';
      case Routes.spinner:
        return '/spinner';
      case Routes.editProfile:
        return '/editProfile';
      case Routes.applyHosting:
        return '/applyHosting';
      case Routes.applyAgency:
        return '/applyAgency';
      case Routes.inbox:
        return '/inbox';
      case Routes.chat:
        return '/chat';
      case Routes.settingsPage:
        return '/settingsPage';
      case Routes.passwordSettings:
        return '/passwordSettings';
      case Routes.ranks:
        return '/ranks';
      case Routes.reward:
        return '/reward';
      case Routes.streamerCenter:
        return '/streamer-center';
      case Routes.guardian:
        return '/guardian';
      case Routes.medalWall:
        return '/medal-wall';
      case Routes.profileCard:
        return '/profile-card';
      case Routes.auth:
        return '/auth';
      case Routes.followUs:
        return '/follow-us';
      case Routes.myAgency:
        return '/my-agency';
      case Routes.qrScanner:
        return '/qr-scanner';
      case Routes.help:
        return '/help';
      case Routes.fanClub:
        return '/fan-club';
      case Routes.backpack:
        return '/backpack';
      case Routes.level:
        return '/level';
      case Routes.myFeedback:
        return '/my-feedback';
      case Routes.mall:
        return '/mall';
      case Routes.mallRanking:
        return '/mall-ranking';
      case Routes.accountSecurity:
        return '/accountSecurity';
      case Routes.bindSelection:
        return '/bindSelection';
      case Routes.bindPhone:
        return '/bindPhone';
      case Routes.bindEmail:
        return '/bindEmail';
      case Routes.languageSetting:
        return '/languageSetting';
      case Routes.blacklist:
        return '/blacklist';
      case Routes.privilegeSettings:
        return '/privilegeSettings';
      case Routes.newMessagesNotification:
        return '/newMessagesNotification';
      case Routes.privacy:
        return '/privacy';
      case Routes.aboutPoppo:
        return '/aboutPoppo';
      case Routes.liveApplication:
        return '/liveApplication';
      case Routes.partyRoom:
        return '/partyRoom';
    }
  }
}
