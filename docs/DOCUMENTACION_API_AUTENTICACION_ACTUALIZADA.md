# Documentacion actualizada de integracion y pruebas de la API de autenticacion

**Proyecto:** AhorrApp Movil  
**Fecha:** 2026-09-16  
**Rama documentada:** `Juan_M`

## 1. Alcance

Este documento describe la integracion actual entre la aplicacion Flutter y la API REST de autenticacion. Incluye la ubicacion del codigo, los endpoints, el flujo de datos, el manejo de sesion, las pruebas realizadas y las limitaciones conocidas.

La aplicacion movil no se conecta directamente a la base de datos. El flujo es:

```text
LoginScreen
    -> AuthService
        -> ApiClient
            -> API REST en Render
                -> Base de datos del backend
```

## 2. Ubicacion de los componentes

| Componente | Archivo | Lineas actuales |
|---|---|---:|
| Aplicacion y rutas | `lib/app.dart` | 17-50 |
| Puerta de autenticacion | `lib/screens/auth/auth_gate.dart` | 9-44 |
| Pantalla de login | `lib/screens/auth/login_screen.dart` | 9 en adelante |
| Servicio central de auth | `lib/services/auth_service.dart` | 45-326 |
| Cliente HTTP | `lib/core/network/api_client.dart` | 20-226 |
| Pantalla de registro | `lib/screens/auth/register_screen.dart` | metodo `_submit`, linea 63 |
| Pantalla biometrica | `lib/screens/auth/biometric_access_screen.dart` | metodos de chequeo y autenticacion |
| Pantalla PIN | `lib/screens/auth/pin_access_screen.dart` | 17-292 |
| Dependencias | `pubspec.yaml` | 9-29 |

> Las lineas corresponden al estado del codigo usado para esta actualizacion. Si se agregan o eliminan lineas, deben volver a comprobarse las referencias.

## 3. URL base y configuracion HTTP

### Ubicacion

- Archivo: `lib/core/network/api_client.dart`
- Clase `ApiClient`: linea 20.
- URL base: lineas 23-24.

```dart
static const String _defaultBaseUrl =
    'https://ahorrapp-react.onrender.com/api';
```

Todas las rutas se concatenan con esa URL. Por ejemplo:

```text
/auth/login
```

se convierte en:

```text
https://ahorrapp-react.onrender.com/api/auth/login
```

### Headers

- Metodo `_headers()`: lineas 30-36.

La API recibe JSON mediante:

```http
Content-Type: application/json
```

Cuando una operacion necesita autenticacion, se envia:

```http
Authorization: Bearer <token>
```

## 4. Endpoints de autenticacion

| Funcion | Metodo | Endpoint | Codigo cliente |
|---|---|---|---|
| Iniciar sesion | POST | `/auth/login` | `auth_service.dart:157-160` |
| Registrar usuario | POST | `/auth/register` | `auth_service.dart:188-195` |
| Solicitar recuperacion | POST | `/auth/forgot-password` | `auth_service.dart:279-283` |
| Verificar codigo | POST | `/auth/verify-reset-code` | `auth_service.dart:289-294` |
| Cambiar contrasena | POST | `/auth/reset-password` | `auth_service.dart:300-304` |
| Login con Google | POST | `/auth/google` | `auth_service.dart:247-250` |

## 5. Flujo de login con correo y contrasena

### 5.1 Interfaz

Archivo: `lib/screens/auth/login_screen.dart`.

- Clase `LoginScreen`: linea 9.
- Carga de datos recordados: `_loadSavedCredentials()`, linea 40.
- Envio del formulario: `_submit()`, linea 80.
- Llamada al servicio: lineas 86-90.
- Navegacion exitosa a `/home`: linea 98.
- Tratamiento de errores de API: lineas 99-107.

La pantalla solo recoge datos, muestra estados de carga y presenta mensajes. No consulta la base de datos directamente.

### 5.2 Servicio de autenticacion

Archivo: `lib/services/auth_service.dart`.

Metodo `login()`: lineas 152-181.

El cuerpo enviado al backend es:

```json
{
  "Email": "correo@ejemplo.com",
  "Password_hash": "contrasena"
}
```

El codigo cliente llama:

```dart
final data = await _api.post('/auth/login', body: {
  'Email': email,
  'Password_hash': password,
});
```

Si la respuesta contiene token y usuario:

1. Valida el token: lineas 162-165.
2. Convierte el usuario con `Usuario.fromJson`: lineas 167-168.
3. Guarda token y usuario en memoria: lineas 170-171.
4. Si `rememberSession` es `true`, persiste ambos datos: lineas 173-174.
5. Si es `false`, elimina los datos persistentes: lineas 176-177.

### 5.3 Respuesta esperada

```json
{
  "ok": true,
  "token": "TOKEN_DE_AHORRAPP",
  "usuario": {
    "id": 1,
    "nombre": "Juan",
    "apellido": "Perez",
    "email": "juan@example.com",
    "roles": []
  }
}
```

## 6. Cliente HTTP y manejo de respuestas

Archivo: `lib/core/network/api_client.dart`.

### Metodos

- `post()`: lineas 38-50.
- `get()`: lineas 53-57.
- `put()`: lineas 60-73.
- `delete()`: lineas 76-79.
- `patch()`: lineas 81-94.
- `getList()`: lineas 97-132.
- `_send()`: lineas 135-173.
- `postRaw()`: lineas 176-226.

### Flujo de `_send()`

1. Ejecuta la peticion con timeout de 45 segundos: lineas 140-149.
2. Decodifica la respuesta JSON: lineas 156-162.
3. Comprueba `decoded['ok']`: linea 165.
4. Si hay error, crea `ApiException`: lineas 167-171.
5. Si es correcta, devuelve el mapa JSON: linea 174.

La excepcion `ApiException` esta definida en las lineas 6-17 y conserva el mensaje y el codigo HTTP.

## 7. Persistencia y ciclo de sesion

### Servicio central

Archivo: `lib/services/auth_service.dart`.

- Instancia compartida: linea 51.
- Dependencia HTTP: linea 53.
- Almacenamiento seguro: linea 54.
- Clave del token: linea 63.
- Clave del usuario: linea 64.
- Clave del PIN: linea 65.

### Comprobar si existe sesion

`hasSession()` esta en las lineas 70-78. Primero revisa `_memoryToken`; si no existe, lee `auth_token` desde `FlutterSecureStorage`.

### Obtener token

`getToken()` esta en las lineas 95-100. Los servicios de gastos, ingresos, deudas, ahorros y presupuestos lo usan para enviar el token al backend.

### Obtener usuario actual

`getCurrentUser()` esta en las lineas 105-124. Recupera el usuario cacheado desde `auth_user` cuando no existe en memoria.

### Cerrar sesion

`logout()` esta en las lineas 306-326. Limpia memoria, cierra la sesion local de Google y elimina token, usuario y PIN del almacenamiento seguro.

## 8. AuthGate

Archivo: `lib/screens/auth/auth_gate.dart`.

- Clase `AuthGate`: linea 9.
- Consulta de sesion: linea 22.
- `FutureBuilder`: linea 27.
- Decision de navegacion: lineas 39-40.

```dart
return loggedIn ? const MainScreen() : const LoginScreen();
```

En `lib/app.dart`, `AuthGate` se establece como pantalla inicial en la linea 36.

## 9. Registro y recuperacion de contrasena

### Registro

- Pantalla: `lib/screens/auth/register_screen.dart`.
- Metodo de envio de la pantalla: `_submit()`, linea 63.
- Servicio: `AuthService.register()`, lineas 183-196.
- Endpoint: `POST /auth/register`.

Cuerpo enviado:

```json
{
  "Nombre": "Juan",
  "Apellido": "Perez",
  "Email": "juan@example.com",
  "Password_hash": "contrasena"
}
```

### Recuperacion

- `forgotPassword()`: `auth_service.dart:278-283`.
- `verifyResetCode()`: `auth_service.dart:285-294`.
- `resetPassword()`: `auth_service.dart:296-304`.
- Pantallas relacionadas: `forgot_password_screen.dart` y `reset_password_screen.dart`.

## 10. Biometria

### Regla de disponibilidad

`canUseBiometricAccess()` esta en `auth_service.dart:84-92`.

Solo devuelve `true` cuando:

1. existe una sesion
2. el dispositivo permite comprobar biometria
3. el dispositivo es compatible

La implementacion utiliza `local_auth`, importado en `auth_service.dart:6`.

La pantalla que ejecuta la autenticacion esta en:

```text
lib/screens/auth/biometric_access_screen.dart
```

La biometria no valida credenciales contra la base de datos ni crea una sesion nueva. Desbloquea una sesion local que ya tenia token.

## 11. PIN para acciones sensibles

### Servicio

- `hasPinSet()`: `auth_service.dart:127-134`.
- `savePin()`: `auth_service.dart:137-140`.
- `verifyPin()`: `auth_service.dart:142-145`.
- `clearPin()`: `auth_service.dart:147-150`.

El PIN se guarda en `FlutterSecureStorage` y no se envia a la API.

### Pantalla

Archivo: `lib/screens/auth/pin_access_screen.dart`.

- Clase: linea 17.
- Validacion de sesion: lineas 37-45.
- Comprobacion de PIN existente: lineas 47-54.
- Procesamiento: `_processPin()`, lineas 72-122.
- Confirmacion exitosa: lineas 108-112.

El PIN es una segunda verificacion para acciones sensibles. No sustituye el login por correo y contrasena.

## 12. Login con Google

### Dependencia y configuracion

- Dependencia `google_sign_in`: `pubspec.yaml:29`.
- Importacion: `auth_service.dart:5`.
- Instancia del SDK: `auth_service.dart:60`.
- Inicializacion de una sola vez: `auth_service.dart:61` y lineas 224-230.

### Flujo

1. `LoginScreen._handleGoogleSignIn()`, linea 120, inicia el flujo.
2. `AuthService.loginWithGoogle()`, linea 209, inicializa el SDK.
3. Google devuelve un `idToken`, lineas 232-239.
4. El token se envia a `/auth/google`, lineas 247-250.
5. El backend debe validar el token y devolver token y usuario.
6. El cliente guarda la sesion, lineas 268-276.

Cuerpo enviado:

```json
{
  "idToken": "TOKEN_DE_GOOGLE",
  "provider": "google"
}
```

### Requisitos externos

Para completar el flujo de extremo a extremo se necesitan:

- `GOOGLE_WEB_CLIENT_ID`.
- `GOOGLE_SERVER_CLIENT_ID`.
- endpoint publico `/auth/google` en el backend.
- validacion del token de Google en el backend.
- respuesta con token de AhorrApp y usuario.
- CORS configurado para la web.

## 13. Supabase

La dependencia aparece en `pubspec.yaml:23`:

```yaml
supabase_flutter: ^2.8.1
```

Pero el login actual no usa Supabase Auth. No hay llamadas actuales a:

```dart
Supabase.initialize(...)
Supabase.instance.client.auth.signInWithPassword(...)
```

La autenticacion actual utiliza la API REST de Render. La base de datos se consulta desde el backend, no desde Flutter.

## 14. Pruebas de API

### Prueba directa de login

Desde PowerShell se puede probar la API sin navegador:

```powershell
$body = '{"Email":"invalid@example.com","Password_hash":"invalid"}'
curl.exe -i -X POST `
  "https://ahorrapp-react.onrender.com/api/auth/login" `
  -H "Content-Type: application/json" `
  --data $body
```

Resultado esperado con credenciales invalidas:

```text
HTTP 401
{"ok":false,"mensaje":"Correo o contraseña incorrectos"}
```

Esto demuestra que el backend esta activo y procesa la ruta de login.

### Prueba de preflight CORS

```powershell
curl.exe -i -X OPTIONS `
  "https://ahorrapp-react.onrender.com/api/auth/login" `
  -H "Origin: http://localhost:50655" `
  -H "Access-Control-Request-Method: POST" `
  -H "Access-Control-Request-Headers: content-type"
```

La respuesta debe incluir:

```http
Access-Control-Allow-Origin: http://localhost:50655
Access-Control-Allow-Methods: GET,POST,PUT,PATCH,DELETE,OPTIONS
Access-Control-Allow-Headers: Content-Type,Authorization
```

En la prueba realizada, el backend devolvio los metodos y headers permitidos, pero no devolvio `Access-Control-Allow-Origin`. Por eso Chrome puede mostrar `ClientException: Failed to fetch`, aunque la API responda correctamente fuera del navegador.

### Interpretacion del error `Failed to fetch`

Si la aplicacion web muestra:

```text
ClientException: Failed to fetch
```

las causas principales son:

- CORS no permite el origen local de Chrome.
- el backend esta caido o iniciandose.
- existe un problema de red.
- la URL base no coincide con el despliegue actual.

En la prueba actual, Render respondio directamente con `401 Correo o contraseña incorrectos`, por lo que el problema observado en Chrome corresponde a CORS y no a credenciales invalidas.

## 15. Ejecucion local

Para ejecutar la aplicacion:

```powershell
cd E:\Ahorrapp-MOVIL
flutter run -d chrome
```

Para Google, cuando existan credenciales reales:

```powershell
flutter run -d chrome `
  --dart-define=GOOGLE_WEB_CLIENT_ID=CLIENT_ID_WEB `
  --dart-define=GOOGLE_SERVER_CLIENT_ID=CLIENT_ID_SERVIDOR
```

## 16. Estado actual

| Area | Estado | Evidencia |
|---|---|---|
| Login email/contrasena | Implementado en cliente | `auth_service.dart:152-181` |
| Registro | Implementado en cliente | `auth_service.dart:183-196` |
| Recuperacion | Implementada en cliente | `auth_service.dart:278-304` |
| Persistencia de sesion | Implementada | `auth_service.dart:63-78`, `162-177` |
| AuthGate | Implementado | `auth_gate.dart:22-40` |
| Biometria | Implementada en cliente | `auth_service.dart:84-92` y pantalla biometrica |
| PIN de confirmacion | Implementado localmente | `auth_service.dart:127-150` |
| Google cliente | Preparado | `auth_service.dart:198-276` |
| Google extremo a extremo | Pendiente de backend/configuracion | endpoint, client IDs y CORS |
| Supabase Auth | No utilizado | solo dependencia en `pubspec.yaml:23` |

## 17. Explicacion para presentar

> La autenticacion esta organizada por capas. `LoginScreen` recoge las credenciales y muestra el resultado. `AuthService` centraliza login, registro, recuperacion, tokens, biometria, PIN y Google. `ApiClient` ejecuta las peticiones HTTP contra la API REST de Render, agrega headers, decodifica JSON, maneja errores y aplica un timeout. El backend valida las credenciales contra su base de datos y devuelve un token. La app guarda ese token con `FlutterSecureStorage`, y `AuthGate` decide si mostrar el login o la pantalla principal.

La idea clave es:

> Flutter no se conecta directamente a la base de datos; se conecta al backend mediante una API REST.
