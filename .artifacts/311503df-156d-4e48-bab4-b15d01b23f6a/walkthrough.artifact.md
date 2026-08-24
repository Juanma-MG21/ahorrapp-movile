# Walkthrough - Conexión Real de API (Autenticación Supabase)

Se ha implementado la conexión real de las pantallas de Login y Registro con la API de Supabase. Con esto, tu aplicación ya no usa simulaciones, sino que realiza peticiones reales a un servidor en la nube.

## Cambios Realizados

### 1. Inicio de Sesión Real ([login_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/login_screen.dart))
- Se reemplazó el retardo simulado por una llamada asíncrona a `Supabase.instance.client.auth.signInWithPassword`.
- **Manejo de Errores:** Si el usuario ingresa mal el correo o la contraseña, la app ahora muestra el mensaje de error real devuelto por la API de Supabase en un SnackBar rojo.
- **Éxito:** Si los datos son correctos, se redirige automáticamente al Inicio (`/home`).

### 2. Registro de Usuarios Real ([register_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/auth/register_screen.dart))
- Implementación de `auth.signUp`.
- Se envía el nombre completo del usuario como metadatos para que se guarde en la base de datos de Supabase.
- Al registrarse, el usuario vuelve a la pantalla de login y recibe un aviso para confirmar su correo electrónico (requisito de seguridad de Supabase).

## Guía de Sustentación (Lo que debes explicar al instructor)

Si el instructor te pregunta sobre la API, esta es tu base técnica:

1.  **¿Qué API usas?**: "Uso la API de Autenticación de Supabase (GoTrue), que es un servicio de Backend as a Service (BaaS)".
2.  **¿Cómo funciona el flujo?**:
    - "El usuario ingresa sus datos en la **Capa de Presentación** (UI)".
    - "La aplicación usa el **SDK de Supabase** para enviar una petición cifrada por HTTPS a los endpoints de la API".
    - "La API valida las credenciales contra la **Base de Datos PostgreSQL** y nos devuelve un JSON con el token de sesión (JWT)".
3.  **Manejo de estados**: "Gestionamos el estado asíncrono con `isLoading` para mostrar el indicador de carga y usamos bloques `try-catch` específicos para `AuthException`, permitiendo una experiencia de usuario robusta ante errores de red o credenciales inválidas".

## Cómo Probar
1. Ejecuta la app en Chrome o Emulador.
2. Intenta loguearte con un correo falso (ej: `test@test.com`) y verás el error de la API.
3. Regístrate como nuevo usuario y verifica que te devuelva el mensaje de éxito.

> [!TIP]
> Recuerda que ya tienes todo subido y listo para sustentar. ¡Mucha suerte con el instructor!
