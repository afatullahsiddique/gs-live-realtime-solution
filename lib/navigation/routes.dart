enum Routes {
  login,
  register,
  forgetPassword,
  verifyOTP,
  changePassword,
  home,
  offer,
  qrCode,
  history,
  more,
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
      case Routes.offer:
        return '/offer';
      case Routes.qrCode:
        return '/qrCode';
      case Routes.history:
        return '/history';
      case Routes.more:
        return '/more';
    }
  }
}
