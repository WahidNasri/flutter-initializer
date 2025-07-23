import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'base/router/app_router.dart';
import 'base/styles.dart';
import 'base/widgets/jailbreak_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();


  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        startLocale: Locale('ar'),
        path: 'assets/translations',
        fallbackLocale: const Locale('ar'),
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

GlobalKey appKey = GlobalKey();

class _MyAppState extends ConsumerState<MyApp> {
  late AppRouter _appRouter;
  bool _hasJailbreak = false;

  @override
  void initState() {
    super.initState();
    _appRouter = ref.read(appRouter);
    _checkJailbreak();
  }

  @override
  Widget build(BuildContext context) {
    return _hasJailbreak ? JailbreakErrorView() : MaterialApp.router(
      key: appKey,
      routerConfig: _appRouter.config(),
      theme: appTheme,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
    );
  }

  Future<void> _checkJailbreak() async {
    bool jailbreak = false;
    try {
      jailbreak = await FlutterJailbreakDetection.jailbroken;
    } on PlatformException {
      jailbreak = true;
    } finally {
      setState(() {
        _hasJailbreak = jailbreak;
      });
    }
  }
}
