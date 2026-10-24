# CLAUDE.md

Guía de referencia para trabajar en este repo. Mantenerla actualizada cuando cambie la arquitectura.

## Qué es la app

**Biker / Bike Meteor**: app Flutter para planificar salidas en bici. Muestra el pronóstico **por hora** (estado del cielo, temperatura, viento, ráfagas y dirección) para **Venado Tuerto, Santa Fe, Argentina**, con filtros por fecha y por horas, y un mapa con una flecha que indica hacia dónde sopla el viento.

- Ubicación fija: lat `-33.7456`, lon `-61.9688`, zona horaria `America/Argentina/Cordoba` (hardcodeadas en `lib/services/open_meteo_service.dart`).
- Fuente de datos: API pública de [Open-Meteo](https://open-meteo.com/) (sin API key), 10 días de pronóstico horario.
- Idioma de la UI: **español** (textos hardcodeados, sin i18n). Unidades: °C y km/h (defaults de Open-Meteo).

## Comandos

```bash
flutter pub get
flutter run                     # dispositivo/emulador conectado
flutter run -d chrome           # web
flutter analyze                 # lints: flutter_lints (analysis_options.yaml)
flutter test                    # ver nota sobre tests más abajo
flutter build apk --release     # firma con la debug key (ver "Pendientes")
flutter build web --release     # salida en build/web; agregar --base-href /ruta/ si se sirve en un subdirectorio

# Regenerar íconos (Android, iOS y web) y splash tras cambiar assets/icons/icon.png
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Stack

- Flutter, Dart SDK `^3.7.0`, Material 3 (`ColorScheme.fromSeed(seedColor: Colors.teal)`).
- `flutter_riverpod` ^2.6 — estado con `StateNotifierProvider` (API clásica, sin code-gen).
- `dio` ^5.7 — HTTP.
- `intl` ^0.20 — formato de fechas (`dd/MM/yyyy`, `HH:mm`).
- Dev: `flutter_launcher_icons`, `flutter_native_splash` (color de fondo `#7FFFD4`).

## Arquitectura

Flujo: `OpenMeteoService` → `WeatherNotifier` (parsea a `WeatherRecord`) → `HomeScreen` (filtra y arma la UI) → widgets.

```
lib/
├── main.dart                       # ProviderScope + MaterialApp → HomeScreen
├── models/weather_record.dart      # Modelo de un registro horario
├── services/open_meteo_service.dart# Llamada GET a Open-Meteo, devuelve el JSON crudo
├── providers/weather_provider.dart # openMeteoServiceProvider, weatherProvider, WeatherState, WeatherNotifier
├── screens/home_screen.dart        # Única pantalla: filtros, mapa, tabla
└── widgets/
    ├── weather_icon.dart           # WeatherCondition (código WMO → ícono/color/descripción) + WeatherIcon
    ├── weather_table.dart          # DataTable con scroll vertical+horizontal, fila seleccionable
    └── wind_map_card.dart          # Imagen del mapa + flecha rotada según el viento
```

### Datos (`services` + `providers`)

- `OpenMeteoService.fetchForecast()` pide `hourly=temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,weather_code,is_day`, `forecast_days=10`. Acepta un `Dio` inyectado (útil para tests).
- `WeatherNotifier` carga automáticamente al crearse (`Future.microtask(loadWeather)`); `refresh()` vuelve a llamar a `loadWeather()`.
- `_parseWeatherRecords` toma los arrays paralelos de `json['hourly']` y usa la **longitud mínima** entre ellos para no salirse de rango.
- `WeatherState` es inmutable: `isLoading`, `error` (String?), `records`. En `copyWith`, para limpiar el error hay que pasar `clearError: true` (pasar `error: null` no lo borra).
- Errores: se guarda `e.toString()` y la pantalla lo muestra tal cual.

### Modelo (`WeatherRecord`)

Campos: `dateTime`, `temperature`, `windSpeed`, `windGust`, `windDirection` (grados, **de dónde viene** el viento, convención meteorológica), `cardinalDirection`, `weatherCode` (código WMO), `isDay` (`is_day == 1`).
- `degreesToCardinal()` usa 8 rumbos en **español**: `N, NE, E, SE, S, SO, O, NO`.
- `fromJson`/`toJson` existen pero hoy no se usan (el parseo real está en el notifier). No hay persistencia ni caché.

### UI (`HomeScreen`)

`ConsumerStatefulWidget`; el estado de filtros es **local** (no en Riverpod):
- `_selectedDayKey` (`'yyyy-MM-dd'` o `null` = todas las fechas) → `DropdownButtonFormField`.
- `_selectedHours` (`Set<int>`, vacío = sin filtro) → `FilterChip` por hora dentro de un `ExpansionTile`.
- `_hourProfiles`: perfiles rápidos que reemplazan la selección de horas:
  - `MTB`: 16, 17, 18
  - `Mañana`: 8, 9, 10
  - `Tarde`: 15–19
- `_selectedRecord`: fila tocada en la tabla. Si no está en el filtro actual, se usa el registro **más reciente** del filtro (`_latestRecord`) y se resetea la selección en un post-frame callback.
- `_sanitizeSelections` se llama en `build` y descarta día/horas que ya no existen tras un refresh.

Layout: el body está centrado con `maxWidth: 900` para que en web/escritorio no se estire. Dentro hay una `Column` con una parte superior scrolleable (contadores, `WindMapCard`, filtros) y la tabla fija abajo con alto `maxHeight * 0.38` acotado a `[180, 320]`.

### `WeatherIcon` / `WeatherCondition`

- `WeatherCondition.fromCode(code, isDay:)` traduce el código WMO a Material Icon + color + descripción en español. De noche, los códigos 0–2 usan luna (`nightlight_round` / `nights_stay`) en vez de sol. Los códigos no contemplados muestran `help_outline` y "Desconocido".
- `WeatherIcon` lo dibuja con un `Tooltip` que muestra la descripción. Se usa en la celda "Temp." de `WeatherTable`.
- Para agregar o ajustar un estado, editar el `switch` de `fromCode` y los tests de `test/weather_icon_test.dart`.

### `WindMapCard`

- Fondo: `assets/images/venado_tuerto_map.png` (asumido orientado al norte arriba).
- La flecha (`Icons.navigation`, que apunta hacia arriba) rota `(windDirection + 180) % 360` → muestra **hacia dónde va** el viento, no de dónde viene. Animada con `AnimatedRotation`.

## Convenciones

- Imports relativos dentro de `lib/` (no `package:`).
- Textos de UI en español; nombres de código en inglés.
- Constructores `const` y `super.key`; listas con `toList(growable: false)`.
- Colores con `withValues(alpha: ...)` (no el deprecado `withOpacity`).
- Mantener la separación: el servicio devuelve JSON crudo, el parseo vive en el provider, la pantalla solo filtra/presenta.

## Cómo hacer cambios comunes

- **Nueva variable meteorológica** (ej. precipitación, humedad): agregarla a `hourly` en `open_meteo_service.dart` → campo en `WeatherRecord` (+ `fromJson`/`toJson`) → leer el array en `_parseWeatherRecords` e incluirlo en el cálculo de `count` → nueva `DataColumn`/`DataCell` en `weather_table.dart`.
- **Nuevo perfil horario**: agregar una entrada en `_hourProfiles` de `home_screen.dart`.
- **Cambiar ubicación**: latitud/longitud/timezone en el servicio, la imagen del mapa en `assets/images/` (y en `pubspec.yaml`), y el título `'Venado Tuerto | ...'` en `wind_map_card.dart`.
- **Cambiar días de pronóstico**: `forecast_days` en el servicio (Open-Meteo permite hasta 16).
- **Nuevo asset**: declararlo en `flutter.assets` de `pubspec.yaml`.

## Plataformas y build

- Objetivos reales: **Android**, **iOS** y **web**. Las carpetas `linux/`, `macos/`, `windows/` son las del template.
- Web: Open-Meteo responde con `Access-Control-Allow-Origin: *`, así que Dio funciona desde el navegador sin proxy. No usar `dart:io` en `lib/` porque rompe el build web. El título y la descripción están en `web/index.html` y `web/manifest.json`. Los íconos web los genera `flutter_launcher_icons` (sección `web:` en `pubspec.yaml`). El splash nativo está desactivado para web.
- Android: `android/app/build.gradle.kts` (Kotlin DSL), `applicationId`/`namespace` = `com.example.bike_meteor`, label `"Biker"`. El manifest **debe** tener `INTERNET` (y tiene `ACCESS_NETWORK_STATE`); sin eso falla en release.
- Versión en `pubspec.yaml` (`version: x.y.z+build`); subir el build number para cada publicación.

## Pendientes / cosas a tener en cuenta

- `test/widget_test.dart` es el test del contador del template y **falla**, así que `flutter test` sin argumentos falla. El único test real es `test/weather_icon_test.dart` (correr con `flutter test test/weather_icon_test.dart`). Los tests importan con `package:Biker/...`. Faltan tests para: `WeatherRecord.degreesToCardinal`, `_parseWeatherRecords` (con un JSON de ejemplo) y el notifier con `ProviderScope(overrides: [openMeteoServiceProvider.overrideWithValue(...)])` o un `Dio` mockeado.
- `pubspec.yaml` tiene `name: Biker` (con mayúscula); los nombres de paquete Dart deberían ser `lowercase_with_underscores`. Los imports `package:` usan ese nombre tal cual. El `README.md` sigue siendo el del template.
- Release firmado con la debug key (`signingConfigs.getByName("debug")`); falta configurar keystore propio y cambiar `com.example.*` antes de publicar en tiendas.
- No hay caché offline, manejo de reintentos ni mensajes de error amigables (se muestra la excepción cruda).
- Las horas se parsean con `DateTime.parse` sin zona → quedan como hora local de Córdoba tal como las devuelve la API (correcto mientras el dispositivo use esos valores "naive"; no convertir a UTC).
- Si en un build **release** no aparecen el mapa ni los íconos (se ven cuadraditos) pero en debug sí, es la caché de build corrupta: el APK sale sin `flutter_assets/assets/images/*` ni `fonts/MaterialIcons-Regular.otf`. Se arregla con `flutter clean && flutter pub get` y volviendo a compilar. Para verificar: `unzip -l build/app/outputs/flutter-apk/app-release.apk | grep flutter_assets`.
- `.github/modernize/` contiene scripts de una herramienta externa (java-upgrade), no es CI del proyecto.
