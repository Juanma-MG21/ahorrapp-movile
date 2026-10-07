# RF-16 — Cerrar sesión en móvil

Fecha: 2026-10-07. Rama de publicación: `codex/rf16-cerrar-sesion`.

## Requisito

Cerrar la sesión debe borrar las credenciales locales y volver a login. Volver atrás, reabrir la app o acceder a una ruta protegida requiere un nuevo inicio de sesión. Se conserva el alcance del PDF de auditoría: el cierre es del cliente y no revoca el JWT en el servidor.

## Fallos y correcciones

1. **Rutas directas sin guard:** `/home`, `/gastos` y `/reportes` construían directamente las pantallas, mientras que el inicio normal tenía `AuthGate`. Ahora esas rutas usan `AuthGate` con una pantalla hija opcional; sin sesión muestran `LoginScreen`.
2. **Lecturas pendientes:** una lectura de almacenamiento iniciada antes del cierre podía devolver después el token o usuario anterior y volver a guardarlo en memoria. Ahora se comprueba la versión de sesión y se descartan resultados anteriores al logout.
3. **Espera de Google antes de eliminar credenciales:** se limpiaban las claves persistidas después de esperar al proveedor. Ahora se eliminan conjuntamente token, usuario, PIN y configuración biométrica antes de intentar cerrar Google. Un fallo de Google no restaura las credenciales locales.
4. **Cierres simultáneos:** comparten la misma operación de limpieza y las lecturas esperan su finalización.

La memoria se limpia al iniciar logout. Los errores al borrar almacenamiento se propagan, evitando declarar éxito si no pudo completarse. Los botones existentes ya usan `pushNamedAndRemoveUntil('/login', (route) => false)`; se conserva ese comportamiento para vaciar el historial.

## Archivos

- `lib/services/auth_service.dart`: coordinación del cierre, protección de lecturas y función de Google inyectable en pruebas.
- `lib/screens/auth/auth_gate.dart`: pantalla hija opcional, protegida por sesión.
- `lib/app.dart`: protección de las rutas nombradas.
- `test/rf16_test.dart`: nueve pruebas del servicio y cuatro pruebas de widgets.

La rama incluye además la configuración solicitada previamente para apuntar `ApiClient` y `CategoriasService` a `https://david-ekcn.onrender.com/api`. Esto corresponde a `IMPORTANTE.md` del proyecto web, no a la lógica de RF-16.

## Pruebas

```powershell
flutter pub get
flutter test --no-pub test/rf16_test.dart
dart analyze lib/services/auth_service.dart lib/screens/auth/auth_gate.dart lib/app.dart test/rf16_test.dart
```

Resultado: **13 pruebas pasan, 0 fallan**. El análisis no tiene errores y conserva una sugerencia preexistente de usar `const`.

Se comprueba limpieza de token, usuario, PIN y biometría; reapertura del servicio; sesión solo en memoria; fallo y espera de Google; lecturas pendientes; dos cierres simultáneos; recuperación válida antes del cierre; acceso directo a las tres rutas reales de `AhorrApp`; borrado del historial y nuevo intento de acceder a una pantalla protegida.

## Límites y comprobación pendiente

El almacenamiento seguro, API y Google se simulan. No se prueba Android Keystore, iOS Keychain ni Google real. El caso de logout reproduce la secuencia de navegación usada por los botones, no un toque real en el menú de un dispositivo. No hay teléfono ni emulador conectado. La preferencia de correo recordado se conserva y no representa una sesión autenticada. No se auditó la limpieza de widgets externos.

En un dispositivo se debe iniciar sesión, cerrar desde el menú, pulsar Atrás, reiniciar la app e intentar abrir gastos/reportes desde accesos rápidos. Repetir con sesión recordada, sin recordar y con Google. En todos los casos posteriores al cierre debe solicitar autenticación.

La rama se publica para revisión; `master` y las aplicaciones distribuidas no se actualizan por publicar esta rama.

El registro general con RF-15 y el detalle de ambas plataformas se conserva en [arreglo de errores requerimientos funcionales.md](https://github.com/SENA-proyect/Ahorrapp-REACT/blob/David/arreglo%20de%20errores%20requerimientos%20funcionales.md).
