import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Verifica si hay actualizaciones disponibles en el Play Store
  Future<void> checkForUpdates(BuildContext context, {bool forceCheck = false}) async {
    // Solo funciona en Android real, no en emuladores ni web
    if (!Platform.isAndroid) {
      developer.log('Verificación de actualizaciones no disponible en esta plataforma');
      if (forceCheck) {
        _showPlatformNotSupportedDialog(context);
      }
      return;
    }

    try {
      // Verificar conectividad
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (forceCheck) {
          _showNoInternetDialog(context);
        }
        return;
      }

      // Obtener información del paquete actual
      final packageInfo = await PackageInfo.fromPlatform();
      developer.log('Versión actual: ${packageInfo.version} (${packageInfo.buildNumber})');

      // Verificar disponibilidad de actualizaciones
      final appUpdateInfo = await InAppUpdate.checkForUpdate();
      
      if (appUpdateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        developer.log('Actualización disponible');
        await _handleUpdateAvailable(context, appUpdateInfo, packageInfo);
      } else {
        developer.log('No hay actualizaciones disponibles');
        if (forceCheck) {
          _showNoUpdatesDialog(context);
        }
      }
    } catch (e) {
      developer.log('Error al verificar actualizaciones: $e');
      if (forceCheck) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  /// Muestra diálogo para plataformas no soportadas
  void _showPlatformNotSupportedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1F28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'ℹ️ Función No Disponible',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'La verificación automática de actualizaciones solo está disponible en dispositivos Android reales con Play Store instalado.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  /// Maneja cuando hay una actualización disponible
  Future<void> _handleUpdateAvailable(
    BuildContext context, 
    AppUpdateInfo updateInfo, 
    PackageInfo packageInfo
  ) async {
    // Determinar si es una actualización crítica
    final bool isCriticalUpdate = _isCriticalUpdate(updateInfo);
    
    if (isCriticalUpdate) {
      // Actualización inmediata obligatoria
      await _performImmediateUpdate(context, updateInfo);
    } else {
      // Actualización flexible (opcional)
      await _showFlexibleUpdateDialog(context, updateInfo, packageInfo);
    }
  }

  /// Determina si la actualización es crítica
  bool _isCriticalUpdate(AppUpdateInfo updateInfo) {
    // Aquí puedes definir tu lógica para determinar actualizaciones críticas
    // Por ejemplo, basándote en la diferencia de versiones
    
    // Por ahora, consideramos críticas las actualizaciones que han estado
    // disponibles por más de 7 días (staleness)
    if (updateInfo.clientVersionStalenessDays != null) {
      return updateInfo.clientVersionStalenessDays! > 7;
    }
    
    return false;
  }

  /// Realiza una actualización inmediata (obligatoria)
  Future<void> _performImmediateUpdate(BuildContext context, AppUpdateInfo updateInfo) async {
    try {
      await _showImmediateUpdateDialog(context);
      
      final result = await InAppUpdate.performImmediateUpdate();
      
      if (result == AppUpdateResult.success) {
        developer.log('Actualización inmediata exitosa');
      } else {
        developer.log('Actualización inmediata falló: $result');
      }
    } catch (e) {
      developer.log('Error en actualización inmediata: $e');
      _showErrorDialog(context, 'Error al actualizar: $e');
    }
  }

  /// Muestra diálogo para actualización flexible
  Future<void> _showFlexibleUpdateDialog(
    BuildContext context, 
    AppUpdateInfo updateInfo, 
    PackageInfo packageInfo
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1F28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.system_update,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '🚀 Nueva Actualización',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¡Hay una nueva versión de FDPA Atletismo disponible!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2F36),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFE74C3C),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Versión actual: ${packageInfo.version}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.new_releases,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Nueva versión disponible',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '✨ Mejoras incluidas:\n• Corrección de errores\n• Mejor rendimiento\n• Nuevas funcionalidades',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Más tarde',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performFlexibleUpdate(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Actualizar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Realiza una actualización flexible
  Future<void> _performFlexibleUpdate(BuildContext context) async {
    try {
      // Mostrar indicador de descarga
      _showDownloadDialog(context);

      final result = await InAppUpdate.startFlexibleUpdate();
      
      // Cerrar diálogo de descarga
      Navigator.of(context).pop();
      
      if (result == AppUpdateResult.success) {
        // Mostrar diálogo para completar la instalación
        _showInstallDialog(context);
      } else {
        developer.log('Actualización flexible falló: $result');
        _showErrorDialog(context, 'No se pudo descargar la actualización');
      }
    } catch (e) {
      // Cerrar diálogo de descarga si está abierto
      Navigator.of(context).pop();
      developer.log('Error en actualización flexible: $e');
      _showErrorDialog(context, 'Error al actualizar: $e');
    }
  }

  /// Muestra diálogo de actualización inmediata
  Future<void> _showImmediateUpdateDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1F28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.priority_high,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '⚠️ Actualización Requerida',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Esta actualización es necesaria para continuar usando la aplicación. La app se actualizará automáticamente.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra diálogo de descarga
  void _showDownloadDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1F28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE74C3C)),
              ),
              SizedBox(height: 16),
              Text(
                'Descargando actualización...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Muestra diálogo para instalar actualización
  void _showInstallDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1F28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.download_done,
                color: Colors.green,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '✅ Descarga Completa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'La actualización se ha descargado correctamente. ¿Deseas instalarla ahora?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Más tarde',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                InAppUpdate.completeFlexibleUpdate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Instalar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra diálogo de no hay actualizaciones
  void _showNoUpdatesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1F28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '✅ Actualizado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Tienes la versión más reciente de FDPA Atletismo.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra diálogo de error de conexión
  void _showNoInternetDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1F28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '📶 Sin Conexión',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'No se puede verificar actualizaciones sin conexión a internet.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra diálogo de error
  void _showErrorDialog(BuildContext context, String error) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1F28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '❌ Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Error al verificar actualizaciones:\n$error',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Verificar actualizaciones al iniciar la app
  Future<void> checkForUpdatesOnStartup(BuildContext context) async {
    // Esperar 3 segundos después de que la app inicie para verificar
    await Future.delayed(const Duration(seconds: 3));
    await checkForUpdates(context, forceCheck: false);
  }
}