import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../local_storage/app_storage.dart';

final authGuard = Provider((ref) => AuthGuard(ref.read(appStorage)));

class AuthGuard extends AutoRouteGuard {
  final AppStorage storage;

  AuthGuard(this.storage);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    //todo: populate isLoggedIn correctly
    final isLoggedIn = false;

    if (isLoggedIn) {
      resolver.next(true);
    } else {
      // Save the intended route
      final targetRoute = resolver.route;
      /*
      router.push(
        LoginRoute(
          onLoginSuccess: () {
            // After login, navigate to the originally intended route
            router.replacePath(targetRoute.path);
            //TODO: we are using just path, any parameters will be lost.
          },
        ),
      );

       */
    }
  }
}