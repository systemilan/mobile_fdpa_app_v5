import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/update_service.dart';
import 'services/socket_service.dart';
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge: Flutter reporta correctamente los insets de la barra de
  // navegación (viewPadding.bottom > 0), el Scaffold los consume y el
  // contenido nunca queda detrás de la barra. Necesario con targetSdk ≥ 35.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Conectar Socket.IO para actualizaciones en tiempo real
    SocketService().connect();
    // Verificar actualizaciones al iniciar la app
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
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FDPA Atletismo',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            // Fijar escala de texto a 1.0 para toda la app — consistencia entre dispositivos
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
