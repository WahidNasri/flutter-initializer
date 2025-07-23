import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.gr.dart';
import 'guards/auth_guard.dart';

final appRouter = Provider((ref) => AppRouter(authGuard: ref.read(authGuard)));

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  final AuthGuard authGuard;

  AppRouter({required this.authGuard});

  @override
  RouteType get defaultRouteType => RouteType.material(); //.cupertino, .adaptive ..etc

  @override
  List<AutoRoute> get routes => [
  ];

  @override
  List<AutoRouteGuard> get guards => [
    // optionally add root guards here
  ];
}
