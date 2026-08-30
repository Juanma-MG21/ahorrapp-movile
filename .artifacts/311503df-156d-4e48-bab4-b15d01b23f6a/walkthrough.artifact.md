# Walkthrough - Implementación de Acceso por Biometría

Se ha integrado el soporte para autenticación biométrica (huella dactilar y reconocimiento facial) en AhorrApp, permitiendo un acceso seguro y moderno.

## Cambios Realizados

### 1. Configuración Nativa (Android e iOS)
- **Android:** Se actualizó el [MainActivity.kt](file:///E:/Ahorrapp-MOVIL/android/app/src/main/kotlin/com/example/ahorrapp_movil/MainActivity.kt) para soportar los diálogos de autenticación del sistema y se agregó el permiso necesario en el [AndroidManifest.xml](file:///E:/Ahorrapp-MOVIL/android/app/src/main/AndroidManifest.xml).
- **iOS:** Se añadió la descripción de uso de Face ID en el [Info.plist](file:///E:/Ahorrapp-MOVIL/ios/Runner/Info.plist).

### 2. Nueva Vista de Biometría
Se creó el archivo [biometric_access_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/biometric_access_screen.dart) con las siguientes características:
- **Activación Automática:** Al abrir la pantalla, se solicita inmediatamente la huella/rostro.
- **Feedback Visual:** Un icono de huella que reacciona según el estado de la autenticación.
- **Reintento:** Botón para volver a intentar si el sensor falla.

### 3. Integración en el Login
- Se conectó el icono de huella dactilar de la pantalla principal de acceso rápido para que navegue directamente a la nueva vista.

## Cómo Probar
1. Ejecuta la aplicación en un dispositivo físico o emulador con biometría activada.
2. En la pantalla de Login, presiona el icono de **Huella** en la parte inferior.
3. El sistema mostrará el diálogo nativo para que pongas tu huella.

> [!IMPORTANT]
> Si estás usando el emulador de Android, recuerda que puedes simular una huella desde el menú de los tres puntos (...) -> Fingerprint.

¿Deseas que subamos estos cambios a tu rama de GitHub ahora mismo?
