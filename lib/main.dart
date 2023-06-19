import 'package:cartaapp/shared/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'logic/cartabloc.dart';
import 'logic/screenconfig.dart';
import 'model/cartaplayer.dart';
import 'screens/catalog/catalog.dart';
import 'screens/home/home.dart';
import 'screens/booksite/booksite.dart';
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

  // just audio
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    // check https://github.com/ryanheise/just_audio/issues/619
    androidNotificationIcon: 'drawable/app_icon',
  );

  // application documents directory
  final appDocDir = await getApplicationDocumentsDirectory();
  appDocDirPath = appDocDir.path;

  // start app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ScreenConfig>(
            create: (context) => ScreenConfig()),
        ChangeNotifierProvider<CartaBloc>(create: (context) => CartaBloc()),
        Provider<CartaPlayer>(
            create: (context) => CartaPlayer(bloc: context.read<CartaBloc>()),
            dispose: (_, player) => player.dispose()),
      ],
      child: MaterialApp(
        title: "Carta",
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name != null) {
            final uri = Uri.parse(settings.name!);
            debugPrint('path: ${uri.path}');
            debugPrint('params: ${uri.queryParameters}');

            if (uri.path == '/') {
              return MaterialPageRoute(builder: (context) => const HomePage());
            } else if (uri.path == '/selected') {
              return MaterialPageRoute(
                builder: (context) => const CatalogPage(),
              );
            } else if (uri.path == '/newbook') {
              // this is for the deeplink now broken in Android 12
              final bookUrl = uri.queryParameters[0];
              return MaterialPageRoute(
                builder: (context) => BookSitePage(
                  url: bookUrl,
                ),
              );
            }
          }
          return MaterialPageRoute(builder: (context) => const NotFound());
        },
        theme: ThemeData(
          colorScheme: lightColorScheme,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme,
          useMaterial3: true,
        ),
        // home: const Home(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
