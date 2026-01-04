# 🏃 Quick Start - API de Récords Nacionales

## ⚡ Uso Rápido

### Navegar a la Pantalla de Récords
```dart
import 'package:fdpa_nuevo_limpio/screens/records/records_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const RecordsScreen()),
);
```

### Obtener Datos de la API

```dart
import 'package:fdpa_nuevo_limpio/services/national_record_service.dart';

final service = NationalRecordService();

// Obtener categorías
final categories = await service.getCategories();

// Obtener récords por categoría
final records = await service.getRecordsByCategory('DAMAS MAYORES');

// Buscar por atleta
final results = await service.searchByAthlete('Cayetana');

// Obtener estadísticas
final stats = await service.getStatistics();
```

### Widgets Listos para Usar

```dart
// Card destacada de récord
FeaturedRecordCard(category: 'DAMAS SUB 18')

// Estadísticas
NationalRecordStatsWidget(statistics: stats)

// Item compacto
CompactRecordItem(record: record, onTap: () {})
```

## 📁 Archivos Principales

| Archivo | Descripción |
|---------|-------------|
| `lib/models/national_record.dart` | Modelos de datos |
| `lib/services/national_record_service.dart` | Servicio API |
| `lib/screens/records/records_screen.dart` | Pantalla principal |
| `lib/widgets/featured_record_card.dart` | Widgets de récords |
| `lib/widgets/national_record_stats_widget.dart` | Widget de estadísticas |
| `lib/examples/navigation_examples.dart` | Ejemplos de navegación |

## 🌐 Endpoints API

```
GET /national-records/categories
GET /national-records/category/:category
GET /national-records/search/athlete?name=X
GET /national-records/search/event?event=X
GET /national-records
GET /national-records/statistics
```

## ⚙️ Configuración

Cambiar ambiente en `lib/config/environment.dart`:
```dart
static const EnvironmentType current = EnvironmentType.production;
// o
static const EnvironmentType current = EnvironmentType.local;
```

## 📊 Estructura de Datos

```dart
class NationalRecord {
  final String id;
  final String category;      // "DAMAS SUB 18"
  final String event;         // "100 metros planos"
  final String record;        // "11.79"
  final String? wind;         // "v.v.2.0"
  final String athlete;       // "Cayetana Chirinos(08)"
  final String place;         // "Lima-PER"
  final DateTime recordDate;  // Fecha del récord
  final String coach;         // "Katsuhico Nakaya"
  // ... más campos
}
```

## 🎨 Categorías Disponibles

```
DAMAS MAYORES
DAMAS SUB 18
DAMAS SUB 20
DAMAS SUB 23
VARONES MAYORES
VARONES SUB 18
VARONES SUB 20
VARONES SUB 23
```

## 🚀 Comandos Útiles

```bash
# Ejecutar la app
flutter run

# Analizar código
flutter analyze

# Compilar para producción
flutter build apk --release
flutter build appbundle --release
```

## 📖 Documentación Completa

Ver [NATIONAL_RECORDS_API.md](NATIONAL_RECORDS_API.md) para documentación completa con todos los detalles y ejemplos.
