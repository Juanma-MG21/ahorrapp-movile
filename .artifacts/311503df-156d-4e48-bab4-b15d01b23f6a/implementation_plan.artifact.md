# Plan de Implementación: Logueo Rápido

El objetivo es crear la última vista de la lista: **Logueo Rápido**. Esta pantalla está diseñada para usuarios que ya han iniciado sesión previamente en el dispositivo, ofreciendo una entrada ágil mediante PIN o Biometría sin tener que escribir su correo y contraseña nuevamente.

## Proposed Changes

### [Vistas de Autenticación]

#### [NUEVO] [fast_login_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/fast_login_screen.dart)
- Interfaz personalizada con un mensaje de "Bienvenido de vuelta".
- Visualización de la cuenta del usuario (Avatar/Icono y Correo oculto).
- Botones prominentes para acceder directamente a las pantallas de **PIN** y **Biometría**.
- Opción de "Usar otra cuenta" para regresar al Login tradicional.

#### [MODIFICAR] [app.dart](file:///E:/Ahorrapp-MOVIL/lib/app.dart)
- Registrar la ruta `/fast-login`.

#### [MODIFICAR] [login_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/login_screen.dart)
- Agregar un acceso temporal al "Logueo Rápido" para pruebas, o configurar que sea la pantalla inicial si se detecta un usuario previo (opcional para el prototipo).

## Verification Plan

### Manual
1. Iniciar la app y navegar a "Logueo Rápido".
2. Verificar que se muestre correctamente el nombre/correo simulado.
3. Probar que los botones de PIN y Huella lleven a sus respectivas pantallas.
4. Verificar que "Usar otra cuenta" regrese al Login.
