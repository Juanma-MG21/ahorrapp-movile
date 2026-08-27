# Plan de Implementación: Acceso por Biometría

El objetivo es permitir a los usuarios autenticarse mediante huella dactilar o reconocimiento facial, integrando la librería oficial de Flutter para biometría.

## User Review Required

> [!IMPORTANT]
> Para que la biometría funcione en Android, es necesario que el dispositivo tenga configurado al menos un método de bloqueo (huella, rostro o PIN). En el emulador, esto se puede simular desde los ajustes del sistema.

## Proposed Changes

### [Dependencias]
#### [MODIFICAR] [pubspec.yaml](file:///E:/Ahorrapp-MOVIL/pubspec.yaml)
- Agregar `local_auth: ^2.3.0`.

### [Configuración Nativa]
#### [MODIFICAR] [MainActivity.kt](file:///E:/Ahorrapp-MOVIL/android/app/src/main/kotlin/com/example/ahorrapp_movil/MainActivity.kt)
- Cambiar `FlutterActivity` por `FlutterFragmentActivity` (requerido por `local_auth` para mostrar diálogos nativos).

#### [MODIFICAR] [AndroidManifest.xml](file:///E:/Ahorrapp-MOVIL/android/app/src/main/AndroidManifest.xml)
- Agregar permiso `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`.

#### [MODIFICAR] [Info.plist](file:///E:/Ahorrapp-MOVIL/ios/Runner/Info.plist)
- Agregar `NSFaceIDUsageDescription` para soporte de rostro en iOS.

### [Interfaz de Usuario]
#### [NUEVO] [biometric_access_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/biometric_access_screen.dart)
- Pantalla elegante con icono de huella dactilar.
- Lógica para activar automáticamente el sensor al entrar.
- Botón de reintento en caso de fallo.

#### [MODIFICAR] [app.dart](file:///E:/Ahorrapp-MOVIL/lib/app.dart)
- Registrar la ruta `/biometric-access`.

#### [MODIFICAR] [login_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/login_screen.dart)
- Conectar el botón de huella dactilar para que navegue a la nueva pantalla.

## Verification Plan
1. Ejecutar `flutter pub get`.
2. Probar en un dispositivo físico o emulador con biometría configurada.
3. Verificar que al presionar el icono de huella en el Login, se solicite la autenticación.
