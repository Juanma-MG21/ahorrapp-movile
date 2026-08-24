# Plan de Conexión Real con Supabase

Este plan describe los cambios necesarios para que las pantallas de Login y Registro se conecten a la API de Supabase, permitiendo autenticación real de usuarios.

## User Review Required

> [!IMPORTANT]
> Por defecto, Supabase requiere confirmación por correo electrónico para que el usuario sea marcado como activo. Asegúrate de configurar esto en tu panel de Supabase si deseas que el login funcione inmediatamente tras el registro.

## Proposed Changes

### [Autenticación]

#### [MODIFICAR] [login_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/login_screen.dart)
- Importar `package:supabase_flutter/supabase_flutter.dart`.
- Reemplazar la lógica de simulación en `_submit` por una llamada real a `Supabase.instance.client.auth.signInWithPassword`.
- Implementar manejo de excepciones (`AuthException`) para mostrar mensajes de error claros al usuario.
- Redirigir a `/home` tras un inicio de sesión exitoso.

#### [MODIFICAR] [register_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/register_screen.dart)
- Importar `package:supabase_flutter/supabase_flutter.dart`.
- Reemplazar la lógica de simulación en `_submit` por una llamada real a `Supabase.instance.client.auth.signUp`.
- Pasar el nombre del usuario como metadato (`data: {'full_name': _nameController.text}`).
- Manejar errores y mostrar un mensaje informativo sobre la confirmación de correo (si aplica).

## Verification Plan

### Manual
1. Abrir la app y navegar a la pantalla de Registro.
2. Crear un nuevo usuario con un correo válido.
3. Verificar en el panel de Supabase que el usuario aparezca en la tabla de `auth.users`.
4. Intentar iniciar sesión con credenciales incorrectas y verificar que aparezca el error.
5. Iniciar sesión con las credenciales correctas y verificar la entrada al Home.
