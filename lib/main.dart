import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home/home_screen.dart';
import 'services/update_service.dart';
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
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
    // Verificar actualizaciones al iniciar la app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdatesOnStartup(context);
    });
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
                statusBarIconBrightness: themeProvider.isDarkMode 
                  ? Brightness.light 
                  : Brightness.dark,
                systemNavigationBarColor: themeProvider.isDarkMode 
                  ? const Color(0xFF040512) 
                  : const Color(0xFFF8F9FA),
                systemNavigationBarIconBrightness: themeProvider.isDarkMode 
                  ? Brightness.light 
                  : Brightness.dark,
              ),
              child: const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}
