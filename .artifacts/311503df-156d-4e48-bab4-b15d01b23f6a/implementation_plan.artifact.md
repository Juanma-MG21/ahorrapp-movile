# Plan de Resolución de Conflictos (Merge de Juan-M)

El merge de la rama `Juan-M` ha generado múltiples conflictos debido a cambios en la estructura de carpetas (renombrado de paquete Android) y la eliminación de la carpeta `ios` en la rama actual, además de cambios concurrentes en archivos centrales como `main.dart`, `app.dart` y `pubspec.yaml`.

## User Review Required

> [!IMPORTANT]
> He detectado que en tu rama se había eliminado la carpeta `ios`. Juan ha realizado cambios importantes en ella para el soporte de widgets y configuración de la app. Procederé a restaurarla aceptando la versión de Juan para no perder su trabajo.

> [!WARNING]
> Juan ha introducido un nuevo sistema de diseño ("claymorphism"). Integraré este sistema manteniendo tus pantallas de autenticación pero asegurando que la app inicialice Supabase correctamente en `main.dart`.

## Proposed Changes

### [Infraestructura y Configuración]

#### [MODIFICAR] [main.dart](file:///E:/Ahorrapp-MOVIL/lib/main.dart)
- Aceptar la inicialización de Supabase con las credenciales proporcionadas por Juan.

#### [MODIFICAR] [pubspec.yaml](file:///E:/Ahorrapp-MOVIL/lib/pubspec.yaml)
- Combinar dependencias: `supabase_flutter`, `mobile_scanner`, `image_picker`, `speech_to_text`, `home_widget`, y los assets/iconos nuevos.

#### [RESTAURAR] Carpeta `ios/`
- Aceptar la versión de la rama `Juan-M` para todos los archivos en `ios/`.

#### [MOVER] Archivos Kotlin de Android
- Mover `AhorrAppMediumWidgetProvider.kt` y `AhorrAppSmallWidgetProvider.kt` de `com.example.ahorrapp` a `com.example.ahorrapp_movil` para que coincidan con tu nuevo nombre de paquete.

### [Arquitectura de la App]

#### [MODIFICAR] [app.dart](file:///E:/Ahorrapp-MOVIL/lib/app.dart)
- Integrar las rutas de autenticación de Manuel (`/login`, `/register`, etc.) con la nueva ruta de `/gastos` de Juan.
- Mantener `LoginScreen` como pantalla de inicio (Home) para el flujo de autenticación.

#### [MODIFICAR] [app_theme.dart](file:///E:/Ahorrapp-MOVIL/lib/core/theme/app_theme.dart)
- Combinar los estilos "claymorphism" de Juan con las configuraciones de `InputDecoration` de Manuel para asegurar que los formularios de login sigan viéndose bien.

## Verification Plan

### Automatizado
- Ejecutar `flutter pub get` para regenerar `pubspec.lock`.
- Ejecutar `flutter analyze` para verificar errores de importación.

### Manual
- Iniciar la app en modo debug.
- Verificar que la pantalla de Login cargue correctamente (usando el nuevo tema).
- Navegar hacia el módulo de gastos para asegurar que la conexión con Supabase no falle.
