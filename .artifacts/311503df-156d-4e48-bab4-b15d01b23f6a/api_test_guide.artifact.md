# Guía de Pruebas de API - AhorrApp (Postman / Thunder Client)

Esta guía detalla cómo realizar pruebas externas a la API de autenticación de Supabase utilizada en el proyecto.

## 1. Configuración Inicial
Para todas las peticiones, debes configurar los siguientes parámetros:

- **Base URL**: `https://vcvlcoxbxjkmvdkwnbdo.supabase.co`
- **Headers Obligatorios**:
    - `apikey`: `sb_publishable_LrAk5c3leXpIAklL5GcHVA_3ICMCX_1`
    - `Content-Type`: `application/json`

---

## 2. Petición: Registro de Usuario (SignUp)
Este método crea un nuevo usuario en la base de datos.

- **Método**: `POST`
- **URL**: `{{BaseURL}}/auth/v1/signup`
- **Cuerpo (Body - JSON)**:
```json
{
  "email": "usuario_prueba@correo.com",
  "password": "PasswordSegura123",
  "data": {
    "full_name": "Usuario de Prueba"
  }
}
```
- **Resultado Esperado (200 OK)**: Recibirás un objeto JSON con los datos del usuario creado y un estado de "esperando confirmación de correo".

---

## 3. Petición: Inicio de Sesión (SignIn)
Este método valida las credenciales y genera un token de acceso.

- **Método**: `POST`
- **URL**: `{{BaseURL}}/auth/v1/token?grant_type=password`
- **Cuerpo (Body - JSON)**:
```json
{
  "email": "usuario_prueba@correo.com",
  "password": "PasswordSegura123"
}
```
- **Resultado Esperado (200 OK)**:
```json
{
  "access_token": "eyJhbG...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "...",
  "user": { ... }
}
```

---

## 4. Pruebas de Error (Escenarios Negativos)

### A. Contraseña Incorrecta
- **Acción**: Envía el SignIn con una clave errónea.
- **Respuesta**: `400 Bad Request`
- **Mensaje**: `{"error":"invalid_grant","error_description":"Invalid login credentials"}`

### B. Usuario No Existe
- **Acción**: Intenta loguearte con un correo que no esté registrado.
- **Respuesta**: `400 Bad Request`

---

> [!TIP]
> **Sustentación Técnica**: "Al usar Postman, validamos que el backend (Supabase) responde correctamente a estándares REST. Esto separa la lógica de negocio de la interfaz de usuario, permitiendo que nuestra aplicación sea escalable y segura mediante el uso de JWT (JSON Web Tokens) para el manejo de sesiones."
