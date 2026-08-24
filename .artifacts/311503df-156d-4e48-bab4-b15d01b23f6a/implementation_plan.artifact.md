# Plan de Implementación: Acceso por PIN

El objetivo es crear una nueva pantalla de acceso rápido mediante un código PIN de 4 dígitos, manteniendo la estética visual del proyecto (AhorrApp).

## User Review Required

> [!IMPORTANT]
> Definiremos un PIN de 4 dígitos por defecto. ¿Deseas que incluya lógica para "Olvidé mi PIN" que regrese al Login tradicional?

## Proposed Changes

### [Vistas de Autenticación]

#### [NUEVO] [pin_access_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/pin_access_screen.dart)
- Diseño con teclado numérico personalizado (0-9, borrar, confirmar).
- Indicadores visuales (puntos) para el PIN ingresado.
- Animaciones para transiciones entre dígitos.

#### [MODIFICAR] [app.dart](file:///E:/Ahorrapp-MOVIL/lib/app.dart)
- Registrar la ruta `/pin-access` vinculada a la nueva pantalla.

#### [MODIFICAR] [login_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/login_screen.dart)
- Actualizar el botón de "PIN" en el acceso rápido para que navegue a la nueva pantalla.

## Verification Plan

### Manual
1. Abrir la app y hacer clic en el botón "PIN" del Login.
2. Verificar que se abra la pantalla de PIN.
3. Probar el teclado numérico y el botón de borrar.
4. Simular un acceso exitoso al completar los 4 dígitos.
