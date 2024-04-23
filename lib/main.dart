import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'logic/cartabloc.dart';
import 'logic/screenconfig.dart';
import 'screens/settings/settings.dart';
import 'screens/catalog/catalog.dart';
import 'screens/home/home.dart';
import 'service/audiohandler.dart';
import 'shared/apptheme.dart';
import 'shared/helpers.dart';
import 'shared/notfound.dart';
import 'shared/settings.dart';

void main() async {
  // flutter
  WidgetsFlutterBinding.ensureInitialized();

  // get screen size
  final size = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first)
      .size;
  initialWindowWidth = size.width;
  initialWindowHeight = size.height;
  isScreenWide = initialWindowWidth > 600;
  debugPrint('size: ${size.width}, ${size.height}');

  // audio handler
  final CartaAudioHandler handler = await createAudioHandler();

  // application documents directory
  final appDocDir = await getApplicationDocumentsDirectory();
  appDocDirPath = appDocDir.path;

  // start app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ScreenConfig>(
            create: (context) => ScreenConfig()),
        ChangeNotifierProvider<CartaBloc>(create: (_) => CartaBloc(handler)),
        // Provider<CartaAudioHandler>(
        //   create: (context) {
        //     handler.setLogic(context.read<CartaBloc>());
        //     return handler;
        //   },
        //   dispose: (_, __) => handler.dispose(),
        // ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      return MaterialApp(
        title: "Carta",
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name != null) {
            final uri = Uri.parse(settings.name!);
            // debugPrint('path: ${uri.path}');
            // debugPrint('params: ${uri.queryParameters}');
            if (uri.path == '/') {
              return MaterialPageRoute(builder: (context) => const HomePage());
            } else if (uri.path == '/selected') {
              return MaterialPageRoute(
                builder: (context) => const CatalogPage(),
              );
            } else if (uri.path == '/settings') {
              return MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              );
            }
          }
          return MaterialPageRoute(builder: (context) => const NotFound());
        },
        theme: AppTheme.lightTheme(lightDynamic),
        darkTheme: AppTheme.darkTheme(darkDynamic),
        // home: const Home(),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}
