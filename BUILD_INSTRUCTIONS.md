# Instrucciones para generar APK/Bundle de Producción

## 📱 Pasos antes de generar el APK/Bundle

### 1️⃣ Cambiar a ambiente de producción

**Archivo:** `lib/config/environment.dart`

Cambiar la línea:
```dart
static const EnvironmentType current = EnvironmentType.local;
```

Por:
```dart
static const EnvironmentType current = EnvironmentType.production;
```

**URL de producción configurada:**
- 🌐 Backend: `https://backend.app.v5.stivou.com/v5/api`

### 2️⃣ Verificar versión de la app

**Archivo:** `pubspec.yaml`

Actualizar el número de versión antes de cada release:
```yaml
version: 1.0.0+1  # Incrementar según corresponda
```

### 3️⃣ Limpiar el proyecto

```bash
flutter clean
flutter pub get
```

---

## 🔨 Generar APK

### APK para todas las arquitecturas (recomendado)
```bash
flutter build apk --release
```
📍 Ubicación: `build/app/outputs/flutter-apk/app-release.apk`

### APK separados por arquitectura (opcional, más ligeros)
```bash
flutter build apk --split-per-abi --release
```
📍 Ubicación: `build/app/outputs/flutter-apk/`
- `app-armeabi-v7a-release.apk` (ARM 32-bit)
- `app-arm64-v8a-release.apk` (ARM 64-bit, recomendado)
- `app-x86_64-release.apk` (x86 64-bit)

---

## 📦 Generar App Bundle (para Google Play Store)

```bash
flutter build appbundle --release
```
📍 Ubicación: `build/app/outputs/bundle/release/app-release.aab`

---

## ✅ Verificación después del build

### 1. Verificar ambiente
```bash
# El app debe conectarse a:
# https://backend.app.v5.stivou.com/v5/api
```

### 2. Verificar firma (Android)
El archivo `android/key.properties` debe existir con:
```properties
storePassword=<tu-password>
keyPassword=<tu-password>
keyAlias=<tu-alias>
storeFile=<path-al-keystore>
```

### 3. Probar el APK
```bash
# Instalar en dispositivo físico o emulador
flutter install
```

---

## 📋 Checklist antes de publicar

- [ ] Cambiar `Environment.current` a `production`
- [ ] Incrementar versión en `pubspec.yaml`
- [ ] Ejecutar `flutter clean && flutter pub get`
- [ ] Verificar que `key.properties` esté configurado
- [ ] Generar APK/Bundle con `--release`
- [ ] Probar APK en dispositivo real
- [ ] Verificar conexión a backend de producción
- [ ] Probar funcionalidades principales:
  - [ ] Login/Auth (si aplica)
  - [ ] Carga de eventos
  - [ ] Resultados de pruebas
  - [ ] Calendario de eventos

---

## 🔙 Volver a desarrollo

**Importante:** Después de generar el APK/Bundle, volver a cambiar:

```dart
// lib/config/environment.dart
static const EnvironmentType current = EnvironmentType.local;
```

---

## 📝 Notas adicionales

### Tamaño del APK
- APK completo: ~30-50 MB
- APK por arquitectura: ~15-25 MB cada uno

### Problemas comunes

**Error de firma:**
```bash
# Verificar que android/key.properties exista
# y que el archivo signing.keystore esté en android/
```

**Error de red:**
```bash
# Verificar que la URL de producción sea accesible
curl https://backend.app.v5.stivou.com/v5/api/public/events
```

**App muy pesada:**
```bash
# Usar --split-per-abi para generar APKs más pequeños
flutter build apk --split-per-abi --release
```

---

## 🚀 Comandos rápidos

```bash
# Desarrollo
flutter run -d chrome  # Web
flutter run            # Dispositivo conectado

# Producción (después de cambiar environment)
flutter build apk --release                    # APK único
flutter build apk --split-per-abi --release   # APKs separados
flutter build appbundle --release              # Bundle para Play Store
```
