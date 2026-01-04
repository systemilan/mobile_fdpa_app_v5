# Implementación de API de Récords Nacionales

## Resumen

Se ha implementado la funcionalidad completa para consumir la API de récords nacionales de atletismo.

## Archivos Creados/Modificados

### 1. Modelos de Datos
**Archivo:** `lib/models/national_record.dart`

Contiene las siguientes clases:
- `NationalRecord`: Modelo principal para un récord nacional
- `CategoryStat`: Estadística de récords por categoría
- `LastUpdate`: Información de la última actualización
- `UploadStats`: Estadísticas de carga de datos
- `NationalRecordStatistics`: Estadísticas completas del sistema

### 2. Servicio API
**Archivo:** `lib/services/national_record_service.dart`

Implementa los siguientes métodos:
- `getCategories()`: Obtiene todas las categorías disponibles
- `getRecordsByCategory(String category)`: Obtiene récords por categoría
- `searchByAthlete(String name)`: Busca récords por nombre de atleta
- `searchByEvent(String event)`: Busca récords por evento
- `getAllRecords()`: Obtiene todos los récords
- `getStatistics()`: Obtiene estadísticas del sistema

### 3. Pantalla de Récords
**Archivo:** `lib/screens/records/records_screen.dart`

Actualizada para:
- Cargar categorías dinámicamente desde la API
- Mostrar récords por categoría seleccionada
- Implementar búsqueda por atleta en tiempo real
- Mostrar fecha de última actualización
- Manejar estados de carga y error
- Animaciones suaves

### 4. Widgets Reutilizables

#### `lib/widgets/national_record_stats_widget.dart`
Widget para mostrar estadísticas completas del sistema de récords.

#### `lib/widgets/featured_record_card.dart`
Dos widgets útiles:
- `FeaturedRecordCard`: Card destacada de un récord (se puede filtrar por categoría o evento)
- `CompactRecordItem`: Item compacto para listas

### 5. Ejemplos de Navegación
**Archivo:** `lib/examples/navigation_examples.dart`

Incluye múltiples ejemplos de cómo navegar a la pantalla de récords:
- Navegación simple
- Con animaciones (slide, fade)
- Cards clickeables
- ListTiles para drawers
- Botones flotantes
- Botones elevados

## Características Implementadas

### ✅ Funcionalidades
1. **Categorías dinámicas**: Se cargan desde la API automáticamente
2. **Búsqueda inteligente**: Busca por atleta cuando se escriben 3+ caracteres
3. **Visualización de récords**: Muestra toda la información del récord
4. **Detalles completos**: Modal con información extendida al tocar un récord
5. **Estados de carga**: Indicadores visuales durante peticiones a la API
6. **Manejo de errores**: Mensajes claros y opción de reintentar
7. **Animaciones**: Transiciones suaves entre estados

### 📊 Datos Mostrados
- Nombre del atleta (con año de nacimiento)
- Evento/prueba
- Marca/récord
- Viento (si aplica)
- Lugar donde se logró
- Fecha del récord
- Nombre del entrenador
- Categoría

### 🔄 Flujo de Trabajo
1. Al abrir la pantalla:
   - Se cargan las categorías disponibles
   - Se cargan las estadísticas generales
   - Se muestran los récords de la primera categoría
2. Al cambiar de categoría:
   - Se cargan los récords de esa categoría
3. Al buscar:
   - Si tiene 3+ caracteres: busca por atleta
   - Si está vacío: recarga los récords de la categoría actual

## Endpoints de la API Utilizados

```
Base URL (Producción): https://backend.app.v5.stivou.com/v5/api
Base URL (Local): http://localhost:4000/v5/api
```

### Endpoints
1. `GET /national-records/categories` - Lista de categorías
2. `GET /national-records/category/:category` - Récords por categoría
3. `GET /national-records/search/athlete?name=X` - Buscar por atleta
4. `GET /national-records/search/event?event=X` - Buscar por evento
5. `GET /national-records` - Todos los récords
6. `GET /national-records/statistics` - Estadísticas

## Configuración del Ambiente

La aplicación utiliza `lib/config/environment.dart` para manejar URLs:
- **Local**: `http://localhost:4000/v5/api`
- **Producción**: `https://backend.app.v5.stivou.com/v5/api`

Para cambiar el ambiente, modifica la variable `current` en `Environment`:
```dart
static const EnvironmentType current = EnvironmentType.production;
```

## Ejemplos de Uso

### 1. Navegación Simple
```dart
import 'package:fdpa_nuevo_limpio/screens/records/records_screen.dart';

// En tu código
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RecordsScreen(),
  ),
);
```

### 2. Usar Widget de Estadísticas
```dart
import 'package:fdpa_nuevo_limpio/widgets/national_record_stats_widget.dart';
import 'package:fdpa_nuevo_limpio/services/national_record_service.dart';

// Cargar y mostrar estadísticas
final stats = await NationalRecordService().getStatistics();

NationalRecordStatsWidget(statistics: stats)
```

### 3. Mostrar Récord Destacado
```dart
import 'package:fdpa_nuevo_limpio/widgets/featured_record_card.dart';

// Mostrar un récord de una categoría específica
FeaturedRecordCard(
  category: 'DAMAS MAYORES',
)

// O filtrar por evento
FeaturedRecordCard(
  event: '100 metros planos',
)
```

### 4. Lista Compacta de Récords
```dart
import 'package:fdpa_nuevo_limpio/widgets/featured_record_card.dart';
import 'package:fdpa_nuevo_limpio/services/national_record_service.dart';

// Cargar récords
final records = await NationalRecordService().getRecordsByCategory('DAMAS SUB 18');

// Mostrar en lista
ListView.builder(
  itemCount: records.length,
  itemBuilder: (context, index) {
    return CompactRecordItem(
      record: records[index],
      onTap: () {
        // Acción al tocar
      },
    );
  },
)
```

### 5. Card en Home Screen
```dart
import 'package:fdpa_nuevo_limpio/examples/navigation_examples.dart';

// En tu pantalla principal
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: ListView(
      children: [
        NavigationExamples.buildRecordsCard(context),
        // Más widgets...
      ],
    ),
  );
}
```

## Estructura de Respuesta de la API

### Récord Nacional
```json
{
  "id": "uuid",
  "category": "DAMAS SUB 18",
  "event": "100 metros planos",
  "record": "11.79",
  "wind": "v.v.2.0",
  "athlete": "Cayetana Chirinos(08)",
  "place": "Lima-PER",
  "recordDate": "2024-06-14T00:00:00.000Z",
  "coach": "Katsuhico Nakaya",
  "rowOrder": 2,
  "status": true,
  "position": 0,
  "createdAt": "2026-01-04T06:30:15.123Z",
  "updatedAt": "2026-01-04T06:30:15.123Z"
}
```

### Estadísticas
```json
{
  "totalRecords": 275,
  "categories": [
    { "category": "DAMAS MAYORES", "count": "46" },
    { "category": "VARONES MAYORES", "count": "47" }
  ],
  "lastUpdate": {
    "date": "2026-01-04T06:30:15.123Z",
    "fileName": "RECORDS NACIONALES OFICIAL 2025 - FINAL.xlsx",
    "uploadedBy": "dmilan",
    "totalRecords": 275,
    "processingTime": 1234
  },
  "uploadStats": {
    "total": 5,
    "successful": 4,
    "failed": 1
  }
}
```

## Próximas Mejoras Posibles

1. ✨ Implementar búsqueda por evento en la UI
2. 📥 Implementar descarga a PDF
3. 📊 Agregar gráficos de estadísticas
4. 🔍 Filtros avanzados (por año, lugar, etc.)
5. ⭐ Marcadores/favoritos de récords
6. 📱 Compartir récords en redes sociales
7. 🔔 Notificaciones de nuevos récords
8. 💾 Caché local para modo offline
9. 📈 Comparación de récords
10. 🏆 Rankings y podios

## Testing

### En Local
1. Asegúrate de que el backend esté corriendo en `localhost:4000`
2. Cambia el ambiente a `EnvironmentType.local` en `environment.dart`
3. Ejecuta la app

### En Producción
1. Cambia el ambiente a `EnvironmentType.production` en `environment.dart`
2. Compila y ejecuta la app

### Verificar Errores
```bash
# Analizar código
flutter analyze

# Ejecutar tests (cuando estén implementados)
flutter test
```

## Notas Técnicas

- **Timeout**: 30 segundos para conexión y recepción
- **Logs**: Habilitados solo en ambiente local
- **Encoding**: URLs se codifican automáticamente para espacios y caracteres especiales
- **Formato de fechas**: ISO 8601 de la API, mostrado como DD/MM/YYYY en la UI
- **Singleton Pattern**: El servicio usa singleton para optimizar memoria
- **Error Handling**: Todos los métodos capturan excepciones y las propagan
- **Estado Reactivo**: La UI se actualiza automáticamente con `setState()`

## Solución de Problemas

### Error de conexión
- Verifica que el backend esté corriendo
- Verifica la URL en `environment.dart`
- Revisa la conectividad de red

### Categorías vacías
- Verifica que el endpoint `/categories` retorne datos
- Revisa los logs (solo en modo local)

### Búsqueda no funciona
- Mínimo 3 caracteres requeridos
- Verifica que el endpoint `/search/athlete` esté disponible

### Animaciones lentas
- Puede ser por dispositivo antiguo
- Ajusta duración en `_RecordsScreenState.initState()`

## Contribuir

Para agregar nuevas funcionalidades:
1. Crea modelos en `lib/models/`
2. Implementa métodos en `NationalRecordService`
3. Actualiza la UI según necesidades
4. Documenta cambios en este archivo

## Licencia

Este código es parte de la aplicación FDPA (Federación Deportiva Peruana de Atletismo).

