import 'package:flutter/material.dart';
import '../screens/records/records_screen.dart';

/// Ejemplos de cómo navegar a la pantalla de récords nacionales

class NavigationExamples {
  /// Ejemplo 1: Navegación simple a récords nacionales
  static void navigateToRecords(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecordsScreen(),
      ),
    );
  }

  /// Ejemplo 2: Navegación con animación de slide
  static void navigateToRecordsWithAnimation(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecordsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// Ejemplo 3: Navegación con fade
  static void navigateToRecordsWithFade(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecordsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Ejemplo 4: Navegación y reemplazar pantalla actual
  static void navigateToRecordsAndReplace(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RecordsScreen(),
      ),
    );
  }

  /// Ejemplo 5: Card clickeable para navegar a récords
  static Widget buildRecordsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateToRecordsWithAnimation(context),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 40,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Récords Nacionales',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ver todos los récords de atletismo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Ejemplo 6: ListTile para usar en un Drawer o ListView
  static Widget buildRecordsListTile(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.emoji_events,
        color: Color(0xFFE74C3C),
      ),
      title: const Text(
        'Récords Nacionales',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text('Ver récords de atletismo'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context); // Cerrar drawer si está abierto
        navigateToRecords(context);
      },
    );
  }

  /// Ejemplo 7: Botón flotante
  static Widget buildRecordsFloatingButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => navigateToRecords(context),
      backgroundColor: const Color(0xFFE74C3C),
      icon: const Icon(Icons.emoji_events),
      label: const Text('Récords'),
    );
  }

  /// Ejemplo 8: Botón elevado personalizado
  static Widget buildRecordsButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => navigateToRecordsWithAnimation(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE74C3C),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      icon: const Icon(Icons.emoji_events),
      label: const Text(
        'Ver Récords Nacionales',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Ejemplo de uso completo en una pantalla
class HomeScreenExample extends StatelessWidget {
  const HomeScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: const Color(0xFF040512),
      ),
      body: Container(
        color: const Color(0xFF040512),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card grande para récords
            NavigationExamples.buildRecordsCard(context),
            
            const SizedBox(height: 16),
            
            // Botón elevado
            NavigationExamples.buildRecordsButton(context),
            
            const SizedBox(height: 16),
            
            // Otros contenidos...
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido a FDPA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Explora los récords nacionales de atletismo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: NavigationExamples.buildRecordsFloatingButton(context),
    );
  }
}
