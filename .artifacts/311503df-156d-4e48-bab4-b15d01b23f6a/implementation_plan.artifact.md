# Plan de Unificación Visual y Estilo "Juan" (Claymorphism)

El objetivo es aplicar una simetría estética total entre las vistas de autenticación y el resto del proyecto, utilizando los tokens de diseño y el estilo Claymorphism.

## Proposed Changes

### [Sistema de Diseño]
#### [MODIFICAR] [app_theme.dart](file:///E:/Ahorrapp-MOVIL/lib/core/theme/app_theme.dart)
- Sincronizar `AppColors` con `design_tokens.dart` (Fondo: `0xFF0E1124`, Superficie: `0xFF141730`, Acento: `0xFFFFB800`).
- Actualizar el tema global para usar estas constantes de forma estricta.

### [Widgets de Autenticación]
#### [MODIFICAR] [auth_widgets.dart](file:///E:/Ahorrapp-MOVIL/lib/widgets/auth_widgets.dart)
- **`AuthPageShell`**: Eliminar el degradado antiguo y usar el color de fondo unificado (`kBgColor`).
- **`PrimaryAuthButton`**: Rediseñar el botón para usar `clayGlow` y el nuevo acento.

### [Pantallas de Autenticación]
#### [MODIFICAR] [login_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/login_screen.dart)
- Migrar el cuerpo principal a `AuthPageShell`.
- Rediseñar `_AccessTile` (Huella/PIN) con `clayRaised`.
- Ajustar colores de texto y divisores a `kTextSecondary`.

#### [MODIFICAR] Otras pantallas de Auth
- Asegurar que `Register`, `Forgot Password`, `Reset Password`, `PIN` y `Fast Login` usen los componentes unificados y no tengan colores "hardcoded".
- Aplicar `clayRaised` a los botones numéricos del teclado en la pantalla de PIN.

## Verification Plan
1. Verificar visualmente que el color de fondo sea idéntico entre el Login y el Módulo de Gastos.
2. Comprobar que los botones tengan el efecto de brillo/relieve característico del Claymorphism.
3. Asegurar que no hay errores de análisis de código.
