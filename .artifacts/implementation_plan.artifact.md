# Plan de Actualización de Dependencias y Optimización de Código

Este plan aborda las advertencias de Gradle relacionadas con Kotlin y las observaciones del analizador de Flutter para mejorar la estabilidad y calidad del código.

## User Review Required

> [!WARNING]
> La actualización de plugins y la configuración de Gradle a la nueva arquitectura de Kotlin ("built-in Kotlin") es necesaria para la compatibilidad con versiones futuras de Flutter. Esto implica cambiar flags en `gradle.properties` y actualizar archivos `.kts`.

## Proposed Changes

### Dependencias y Configuración de Android

#### [MODIFY] [pubspec.yaml](file:///C:/ahorrappmovil/ahorrapp-movile/pubspec.yaml)
* Actualizar `home_widget` a `^0.10.0` (o superior).
* Actualizar `speech_to_text` a `^7.2.2`.

#### [MODIFY] [gradle.properties](file:///C:/ahorrappmovil/ahorrapp-movile/android/gradle.properties)
* Cambiar `android.builtInKotlin=false` a `true`.

#### [MODIFY] [build.gradle.kts (app)](file:///C:/ahorrappmovil/ahorrapp-movile/android/app/build.gradle.kts)
* Asegurar que el plugin de Kotlin se aplique correctamente en el bloque `plugins`.

### Optimización de Código (Linter)

#### [MODIFY] [supabase_service.dart](file:///C:/ahorrappmovil/ahorrapp-movile/lib/services/supabase_service.dart)
* Reemplazar `print` con `debugPrint` o un log adecuado para evitar la advertencia `avoid_print`.

#### [MODIFY] [agregar_gasto_screen.dart](file:///C:/ahorrappmovil/ahorrapp-movile/lib/screens/gastos/agregar_gasto_screen.dart)
* Corregir el uso de guiones bajos dobles en los parámetros de los callbacks (`unnecessary_underscores`).

#### [MODIFY] [main.dart](file:///C:/ahorrappmovil/ahorrapp-movile/lib/main.dart)
* Usar `publishableKey` en lugar de `anonKey` para evitar la advertencia de deprecación.

## Verification Plan

### Manual Verification
1. Ejecutar `flutter pub get` para actualizar los plugins.
2. Ejecutar `flutter analyze` y verificar que el número de advertencias haya disminuido drásticamente.
3. Intentar una compilación con `flutter build bundle` para asegurar que los cambios en Gradle sean correctos.
