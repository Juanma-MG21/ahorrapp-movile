# Walkthrough - Conexión de Vistas y Nueva Contraseña

Se ha solucionado el problema de conexión entre las vistas y se ha implementado la siguiente pantalla en tu lista: **Nueva Contraseña**.

## Cambios Realizados

### 1. Conexión de Vistas (Login -> Registro/Olvido)
Se han actualizado las rutas en [app.dart](file:///E:/Ahorrapp-MOVIL/lib/app.dart) y se han agregado logs de depuración en [login_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/login_screen.dart).

> [!TIP]
> Si los botones no responden al ejecutarlos, revisa la consola de depuración para ver si aparece el mensaje "Navegando a...". Si aparece pero no cambia la pantalla, asegúrate de hacer un **Hot Restart** (presiona 'R' en la terminal o el botón de rayo en Android Studio).

### 2. Implementación de "Nueva Contraseña"
Se ha creado el archivo [reset_password_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/reset_password_screen.dart) con el siguiente diseño:
- Campos para **Nueva Contraseña** y **Confirmar Contraseña**.
- Validación de coincidencia entre claves.
- Estética consistente con `AuthPageShell`.

### 3. Flujo Completo de Recuperación
Se ha modificado [forgot_password_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/forgot_password_screen.dart) para que, al presionar "Enviar enlace", simule el envío y te redirija automáticamente a la pantalla de **Nueva Contraseña** después de 1 segundo.

## Próximos Pasos Recomendados
- **Logueo Rápido / PIN / Biometría:** Son las siguientes en tu lista.
- **Limpiar Debug Prints:** Una vez confirmes que la navegación funciona en tu dispositivo, puedes borrar los `debugPrint` que agregamos.

Para probar ahora:
```bash
flutter run -d chrome  # O usa tu emulador
```
Luego, en el Login, haz clic en **"Olvidaste tu contrasena?"**, escribe un correo y presiona **"Enviar enlace"**. Verás cómo te lleva a la nueva pantalla.
