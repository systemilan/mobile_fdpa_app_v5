import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/update_service.dart';
import 'services/socket_service.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Detectar idioma del sistema y cargar preferencia guardada
  final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final savedLocale = await LocaleProvider.loadSavedLocale(systemLocale);

  runApp(MyApp(initialLocale: savedLocale));
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;
  const MyApp({super.key, required this.initialLocale});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    SocketService().connect();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdatesOnStartup(context);
    });
  }

  @override
  void dispose() {
    SocketService().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider(widget.initialLocale)),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: localeProvider.strings.appTitle,
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            // Idioma activo
            locale: localeProvider.locale,
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Fijar escala de texto a 1.0 para toda la app
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: child!,
              );
            },
            home: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarColor: const Color(0xFF040512),
                systemNavigationBarIconBrightness: Brightness.light,
              ),
              child: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
