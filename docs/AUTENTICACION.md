# Autenticacion de AhorrApp

Este documento describe la estructura actual de autenticacion del proyecto movil y ubica cada responsabilidad en su archivo y linea.

> Las referencias de linea corresponden al estado actual del proyecto al momento de crear este documento. Si se modifica el codigo, las lineas pueden cambiar.

## 1. Resumen de la arquitectura

El flujo general es:

```text
LoginScreen
    -> AuthService
        -> ApiClient
            -> API REST de Render
                -> Base de datos del backend
```

La aplicacion Flutter no se conecta directamente a la base de datos. Flutter envia peticiones HTTP al backend; el backend valida los datos, consulta su base de datos y devuelve una respuesta JSON.

Archivos principales:

| Responsabilidad | Archivo | Ubicacion actual |
|---|---|---|
| Pantalla de login | `lib/screens/auth/login_screen.dart` | Clase `LoginScreen`, linea 9 |
| Puerta de entrada | `lib/screens/auth/auth_gate.dart` | Clase `AuthGate`, linea 9 |
| Logica central de auth | `lib/services/auth_service.dart` | Clase `AuthService`, linea 45 |
| Cliente HTTP | `lib/core/network/api_client.dart` | Clase `ApiClient`, linea 20 |
| Rutas de navegacion | `lib/app.dart` | `MaterialApp`, lineas 32-47 |
| Dependencias | `pubspec.yaml` | Dependencias, lineas 9-29 |

## 2. Entrada de la aplicacion y AuthGate

### Ubicacion

- Archivo: `lib/app.dart`
- `home: const AuthGate()` en la linea 36.
- Las rutas de login, registro, recuperacion y biometria estan entre las lineas 37-47.

### Funcion

`AuthGate` decide que pantalla se muestra al abrir la aplicacion:

```text
Se abre la app
    -> AuthGate revisa si existe auth_token
        -> Hay token: MainScreen
        -> No hay token: LoginScreen
```

### Codigo importante

- Archivo: `lib/screens/auth/auth_gate.dart`
- Clase `AuthGate`: linea 9.
- En `initState`, linea 22, se ejecuta `AuthService.instance.hasSession()`.
- El `FutureBuilder<bool>` comienza en la linea 27.
- La decision final se realiza en las lineas 39-40:

```dart
return loggedIn ? const MainScreen() : const LoginScreen();
```

Mientras se consulta el almacenamiento seguro, muestra un indicador de carga en las lineas 29-35.

## 3. Pantalla de login

### Ubicacion

- Archivo: `lib/screens/auth/login_screen.dart`
- Clase `LoginScreen`: linea 9.
- Estado de la pantalla: linea 14.

### Responsabilidad

La pantalla se encarga de la interfaz y de recoger:

- correo
- contrasena
- opcion de recordar sesion
- resultado de carga
- errores para mostrar al usuario

La pantalla no consulta la base de datos directamente.

### Carga inicial

- `_loadSavedCredentials()` esta en la linea 40.
- Recupera `remember_me` y `saved_email` usando `SharedPreferences` entre las lineas 42-49.
- Consulta si se puede usar biometria mediante `AuthService.instance.canUseBiometricAccess()` en la linea 54.

### Login con correo y contrasena

- `_submit()` esta en la linea 80.
- Valida el formulario en la linea 81.
- Activa el estado de carga en la linea 83.
- Llama a `AuthService.instance.login(...)` entre las lineas 86-90.
- Si el login es exitoso, navega a `/home` en la linea 98.
- Los errores de API se muestran entre las lineas 99-107.
- El estado de carga se desactiva en las lineas 114-115.

El flujo de la pantalla es:

```text
Usuario escribe correo y contrasena
    -> LoginScreen valida el formulario
    -> AuthService.login()
    -> respuesta exitosa: /home
    -> ApiException: SnackBar con el mensaje del backend
```

### Google

- `_handleGoogleSignIn()` esta en la linea 120.
- Llama a `AuthService.instance.loginWithGoogle()` en la linea 125.
- Si tiene exito, navega a `/home` en la linea 132.
- Los errores se muestran entre las lineas 133-150.

La implementacion de Google necesita client IDs y un endpoint backend que valide el `idToken`. La logica del cliente se encuentra en `auth_service.dart`, lineas 198-276.

## 4. AuthService: servicio central

### Ubicacion

- Archivo: `lib/services/auth_service.dart`
- Clase `Usuario`: lineas 8-39.
- Clase `AuthService`: linea 45.
- Instancia compartida: linea 51.

`AuthService` centraliza toda la logica de autenticacion para que las pantallas no repitan peticiones HTTP ni reglas de sesion.

### Dependencias y estado

- `ApiClient _api`: linea 53. Comunica el servicio con el backend.
- `FlutterSecureStorage _storage`: linea 54. Guarda token, usuario y PIN local.
- `LocalAuthentication _localAuth`: linea 59. Consulta soporte y ejecuta biometria.
- `GoogleSignIn _googleSignIn`: linea 60. Gestiona la autenticacion de Google.
- `_googleInitialization`: linea 61. Evita inicializar Google mas de una vez.

Claves de almacenamiento:

- `_tokenKey = 'auth_token'`: linea 63.
- `_userKey = 'auth_user'`: linea 64.
- `_pinKey = 'auth_pin'`: linea 65.

Estado en memoria:

- `_memoryToken`: linea 67.
- `_memoryUser`: linea 68.
- `_memoryPin`: linea 69.

## 5. Sesion y token

### Comprobar sesion

- Metodo: `hasSession()`.
- Archivo: `lib/services/auth_service.dart`.
- Lineas 70-78.

Primero revisa `_memoryToken`. Si no existe, lee `auth_token` desde `FlutterSecureStorage`. Si encuentra un token, lo carga en memoria y devuelve `true`.

### Obtener token

- Metodo: `getToken()`.
- Lineas 95-100.

Los otros servicios usan este metodo antes de llamar endpoints protegidos. El token se envia mediante `ApiClient` como:

```http
Authorization: Bearer TOKEN
```

### Usuario actual

- Metodo: `getCurrentUser()`.
- Lineas 105-124.

Primero revisa el usuario en memoria. Si no existe, recupera `auth_user` del almacenamiento seguro, lo convierte desde JSON y crea un objeto `Usuario`.

### Logout

- Metodo: `logout()`.
- Lineas 306-326.

El logout:

1. Limpia token, usuario y PIN de memoria.
2. Cierra la sesion local de Google.
3. Borra `auth_token`, `auth_user` y `auth_pin` del almacenamiento seguro.

## 6. Login contra el backend

### Metodo cliente

- Archivo: `lib/services/auth_service.dart`.
- Metodo `login()`: lineas 152-181.

El cuerpo enviado es:

```json
{
  "Email": "correo@ejemplo.com",
  "Password_hash": "contrasena"
}
```

La llamada se realiza en las lineas 157-160:

```dart
final data = await _api.post('/auth/login', body: {
  'Email': email,
  'Password_hash': password,
});
```

Si el backend devuelve token y usuario:

- valida el token en las lineas 162-165
- convierte el usuario en las lineas 167-168
- guarda ambos en memoria en las lineas 170-171
- guarda token y usuario si `rememberSession` es `true`, lineas 173-174
- borra los datos persistentes si no se debe recordar la sesion, lineas 176-177

### URL completa

- Archivo: `lib/core/network/api_client.dart`.
- Clase `ApiClient`: linea 20.
- URL base: lineas 23-24.

```text
https://ahorrapp-react.onrender.com/api
```

Por tanto, el login completo es:

```text
POST https://ahorrapp-react.onrender.com/api/auth/login
```

La aplicacion movil no conoce las consultas SQL ni las credenciales de la base de datos. Esa parte pertenece al backend.

## 7. ApiClient

### Ubicacion

- Archivo: `lib/core/network/api_client.dart`.
- Clase `ApiClient`: linea 20.

### Responsabilidad

`ApiClient` centraliza:

- URL base
- headers JSON
- token Bearer
- metodos HTTP
- decodificacion JSON
- errores del servidor
- timeout de red

### Headers

- Metodo `_headers()`: lineas 30-36.

Siempre agrega:

```dart
Content-Type: application/json
```

Cuando recibe un token, agrega:

```dart
Authorization: Bearer TOKEN
```

### Metodos HTTP

- `post()`: lineas 38-50.
- `get()`: lineas 53-57.
- `put()`: lineas 60-73.
- `delete()`: lineas 76-79.
- `patch()`: lineas 81-94.
- `getList()`: lineas 97-132.
- `_send()`: lineas 135-173.
- `postRaw()`: lineas 176-226.

### Manejo normal de respuestas

`_send()` ejecuta la peticion con timeout de 45 segundos en las lineas 140-149.

Luego:

1. Convierte el cuerpo a JSON, lineas 156-162.
2. Revisa `decoded['ok']`, linea 165.
3. Si hay error, crea `ApiException`, lineas 167-171.
4. Si la respuesta es correcta, devuelve el JSON en la linea 174.

`ApiException` esta definida en las lineas 6-17 y contiene:

- mensaje del error
- codigo HTTP opcional

## 8. Endpoints de autenticacion

Los endpoints se llaman desde `lib/services/auth_service.dart`:

| Funcion | Metodo | Ruta | Ubicacion |
|---|---|---|---|
| Login | POST | `/auth/login` | `auth_service.dart:157` |
| Registro | POST | `/auth/register` | `auth_service.dart:188` |
| Recuperar contrasena | POST | `/auth/forgot-password` | `auth_service.dart:279` |
| Verificar codigo | POST | `/auth/verify-reset-code` | `auth_service.dart:289` |
| Cambiar contrasena | POST | `/auth/reset-password` | `auth_service.dart:300` |
| Google | POST | `/auth/google` | `auth_service.dart:247` |

## 9. Registro y recuperacion

### Registro

- Metodo `register()`: lineas 183-196 de `auth_service.dart`.
- Pantalla de registro: `lib/screens/auth/register_screen.dart`, metodo `_submit()` en la linea 63.

El registro envia nombre, apellido, correo y contrasena a `/auth/register`.

### Recuperacion

- `forgotPassword()`: lineas 278-283.
- `verifyResetCode()`: lineas 285-294.
- `resetPassword()`: lineas 296-304.
- Pantalla de recuperacion: `lib/screens/auth/forgot_password_screen.dart`.
- Pantalla de cambio: `lib/screens/auth/reset_password_screen.dart`, metodo `_submit()` en la linea 31.

## 10. Biometria

### Regla de disponibilidad

- `AuthService.canUseBiometricAccess()`: lineas 84-92.

La biometria solo se ofrece si:

1. existe una sesion guardada
2. el dispositivo permite comprobar biometria
3. el dispositivo es compatible

### Pantalla de biometria

- Archivo: `lib/screens/auth/biometric_access_screen.dart`.
- La pantalla inicia el chequeo en `_checkBiometricSupport()`, aproximadamente lineas 28-46.
- El proceso de autenticacion esta en `_authenticate()`, aproximadamente lineas 49-107.
- La llamada a `local_auth` esta alrededor de las lineas 65-71.
- Si la autenticacion tiene exito y la sesion sigue activa, navega a `/home` alrededor de las lineas 78-89.

La biometria no consulta la base de datos directamente y no crea una cuenta nueva. Desbloquea una sesion que ya existe.

## 11. PIN para acciones sensibles

### Servicio

- `hasPinSet()`: lineas 127-134 de `auth_service.dart`.
- `savePin()`: lineas 137-140.
- `verifyPin()`: lineas 142-145.
- `clearPin()`: lineas 147-150.

El PIN se almacena localmente y no se envia al backend.

### Pantalla

- Archivo: `lib/screens/auth/pin_access_screen.dart`.
- La pantalla esta declarada en la linea 17.
- Revisa si existe sesion en las lineas 37-45.
- Revisa si ya hay PIN en las lineas 47-54.
- Procesa la configuracion o validacion en `_processPin()`, lineas 72-122.
- Cuando el PIN es correcto, cierra la pantalla con `Navigator.pop(true)` alrededor de las lineas 108-112.

El PIN no es el login principal. Es una segunda verificacion para acciones sensibles.

## 12. Google Sign-In

### Dependencia

- Archivo: `pubspec.yaml`.
- `google_sign_in` esta declarado en la linea 29.

### Cliente

- Importacion y objetos de Google: `auth_service.dart`, lineas 5 y 60-61.
- Configuracion de client IDs: lineas 198-207.
- Metodo `loginWithGoogle()`: lineas 209-276.

Flujo:

```text
Usuario pulsa Google
    -> Google devuelve idToken
    -> AuthService envia idToken a /auth/google
    -> Backend valida Google
    -> Backend devuelve token de AhorrApp y usuario
    -> AuthService guarda la sesion
```

El cuerpo enviado aparece en las lineas 247-250:

```json
{
  "idToken": "TOKEN_DE_GOOGLE",
  "provider": "google"
}
```

El flujo de Google requiere:

- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`
- endpoint backend `/auth/google`
- validacion del token en el backend
- CORS correcto para la web

## 13. Supabase

- Dependencia declarada en `pubspec.yaml`, linea 23.
- No hay una llamada actual a `Supabase.initialize()` en `lib/`.
- No hay una llamada actual a `Supabase.instance.client.auth.signInWithPassword()`.

Por tanto, el login actual no usa Supabase Auth. Usa la API REST de Render:

```text
Flutter -> ApiClient -> API de Render -> Base de datos del backend
```

Supabase esta instalado como dependencia, pero no participa en el flujo de autenticacion actual.

## 14. Explicacion corta para presentar

> La autenticacion esta organizada por capas. `LoginScreen` muestra el formulario y recoge las credenciales. `AuthService` concentra la logica de login, registro, recuperacion, tokens, biometria, PIN y Google. `ApiClient` ejecuta las peticiones HTTP contra la API REST de Render, maneja JSON, headers, errores y timeout. El backend valida las credenciales contra su base de datos y devuelve un token. `FlutterSecureStorage` conserva ese token y `AuthGate` decide si se muestra el login o la pantalla principal.

La frase clave es:

> Flutter no se conecta directamente a la base de datos; se conecta al backend mediante una API REST.
