/// Configuración de ambientes para la aplicación
class Environment {
  // Ambiente actual (cambiar según necesidad)
  // IMPORTANTE: Cambiar a EnvironmentType.production antes de generar APK/Bundle
  static const EnvironmentType current = EnvironmentType.production;
  
  // URLs base por ambiente
  static String get baseUrl {
    switch (current) {
      case EnvironmentType.local:
        // Desarrollo local
        return 'http://localhost:4000/v5/api';
      case EnvironmentType.production:
        // Producción - Stivou Backend (sin /public para calendar-activities)
        return 'https://backend.app.v5.stivou.com/v5/api';
    }
  }
  
  // URL base para endpoints públicos
  static String get publicBaseUrl {
    switch (current) {
      case EnvironmentType.local:
        return 'http://localhost:4000/v5/api';
      case EnvironmentType.production:
        return 'https://backend.app.v5.stivou.com/v5/api/public';
    }
  }
  
  // Configuraciones adicionales por ambiente
  static bool get isProduction => current == EnvironmentType.production;
  static bool get enableLogs => current == EnvironmentType.local;
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

enum EnvironmentType {
  local,      // Para desarrollo con localhost
  production, // Para APK/Bundle de producción
}
