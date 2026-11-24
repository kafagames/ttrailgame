import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash.dart';
import 'services/sound.dart';
import 'services/store.dart';
import 'ui/art.dart';
import 'ui/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Josefin Slab'], text);
  });
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Store.load();
  await Art.load();
  await Sound.init();
  runApp(const ThimbleTrailApp());
  Sound.syncMusic();
}

class ThimbleTrailApp extends StatefulWidget {
  const ThimbleTrailApp({super.key, this.home});

  /// Overrides the first screen (tests).
  final Widget? home;

  @override
  State<ThimbleTrailApp> createState() => _ThimbleTrailAppState();
}

class _ThimbleTrailAppState extends State<ThimbleTrailApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      Sound.pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      Sound.resumeMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thimble Trail',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: widget.home ?? const SplashScreen(),
    );
  }
}
