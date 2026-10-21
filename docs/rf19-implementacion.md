# RF-19: registro y consulta sin conexión

Fecha de la entrega: 7 de octubre de 2026. Ramas: `David-M` en AhorrApp móvil y en el repositorio del backend.

**Estado:** almacenamiento, consulta offline, creación local, sincronización y deduplicación implementados. La verificación local y los límites se detallan abajo. La activación en el servidor publicado exige publicar el backend, sin modificar su esquema; la aplicación conserva los pendientes hasta comprobar que el servidor admite el protocolo seguro.

## Alcance acordado

Esta versión permite consultar ingresos, gastos y metas de ahorro previamente descargados y crear registros de esos tres módulos sin internet. También conserva las categorías y los dependientes descargados para los formularios. Cada creación se guarda primero en SQLite, aunque haya conexión.

La edición, eliminación y los abonos offline están fuera de alcance. Las modificaciones de registros sincronizados siguen utilizando el servidor; los pendientes no se pueden editar, eliminar ni abonar. Un registro rechazado puede **corregirse con conexión**, únicamente después de comprobar en el servidor que su operación original nunca se confirmó.

No hay primer inicio de sesión offline, reportes offline ni ejecución garantizada con la aplicación cerrada. El PDF `auditoriaRF-ArchivoGeneral.pdf`, páginas 47–48, es la fuente de RF-19; sus indicaciones se distinguen del alcance solicitado. No se modificó el PDF original.

## Flujo implementado

1. El usuario inicia sesión con internet. Se descargan los tres historiales, categorías y dependientes; cada recurso guarda su propietario y fecha. Un fallo en un recurso no elimina los demás.
2. Las consultas utilizan la copia descargada cuando falla el transporte o vence la sesión. Una lista vacía descargada es válida; falta de copia y fallo de consulta se muestran como errores. Un error de servidor, permisos o formato no se presenta como ausencia de registros.
3. Al guardar un formulario, una transacción SQLite crea el movimiento local y su operación pendiente con UUID. El formulario confirma el guardado en el teléfono y regresa a la lista sin esperar al servidor. Si falla la transacción, no anuncia éxito.
4. La lista combina la copia descargada con las creaciones locales. Cada registro muestra `Pendiente de sincronizar`, `Enviando`, `Sincronizado`, sesión requerida o error. El panel global presenta la conexión comprobada, pendientes, errores y última sincronización.
5. Al recuperar conectividad, iniciar la pantalla principal, volver al primer plano o pulsar **Sincronizar**, se procesa una sola cola para la cuenta actual. Se comprueba el protocolo del servidor antes de enviar. Wi-Fi disponible por sí solo no se interpreta como servidor accesible.
6. El envío conserva UUID y contenido originales en todos los reintentos. Una confirmación válida proporciona el mismo UUID y el ID del servidor. La app guarda esa confirmación y elimina la operación pendiente en una transacción local.
7. La descarga posterior incluye el UUID del servidor. La reconciliación elimina la representación local correspondiente y conserva un solo elemento, incluso si el servidor escribió el registro pero la app perdió la respuesta.

Las consultas locales actualizan las listas cuando cambia la cola. Los totales de las listas incluyen sus pendientes y el panel lo advierte. Los reportes continúan consultando exclusivamente sus endpoints del servidor; no suman datos de SQLite. El calendario y los resúmenes para widgets excluyen movimientos locales no confirmados.

## Persistencia y cuentas

La base `ahorrapp_offline.db`, versión 2, contiene:

| Tabla | Responsabilidad |
| --- | --- |
| `snapshots` | Copias por usuario y recurso, JSON validado y fecha de descarga. |
| `local_movements` | Creaciones locales, UUID, ID local negativo visible, ID remoto, estado y error. |
| `pending_operations` | Outbox por usuario y UUID con payload inmutable, intentos y siguiente reintento. |
| `sync_metadata` | Última sincronización completada por propietario. |

La migración desde la primera etapa conserva sus copias descargadas. El movimiento y su outbox se escriben juntos; una confirmación y la retirada de la cola también se escriben juntas. Una operación que quedó `sending` después de una interrupción se vuelve a intentar con el mismo UUID.

El usuario debe haber iniciado sesión antes de crear registros. Para entrar sin internet después de cerrar la app debe haber conservado la sesión mediante **Recordar sesión**. Un token vencido permite consultar y crear con la identidad local ya guardada, pero el envío se pausa hasta reautenticarse.

Todas las lecturas y escrituras locales reciben el ID del propietario. La versión de sesión impide que respuestas anteriores se muestren en una cuenta nueva. Una respuesta de envío que llega después de cambiar de cuenta puede confirmar la operación de su dueño, pero no cambia datos de la cuenta nueva ni continúa enviando su cola anterior.

Cerrar sesión advierte si existen pendientes y permite cancelar. Al confirmar, se borra la sesión, se limpia el estado visible y se conservan los datos locales de su propietario. La desactivación de cuenta también advierte que no se pueden sincronizar pendientes mientras la cuenta esté inactiva. Desinstalar la app o borrar sus datos puede eliminar registros que aún solo estén en el teléfono.

## Contrato del servidor y duplicados

**Restricción incorporada:** no añadir ni modificar tablas, columnas o índices del servidor. La migración propuesta se retiró. Se utiliza la tabla `historial` que ya existe en `SQL/supabase.sql`.

Cada confirmación guarda una acción técnica `RF19:<uuid>` y detalles JSON con la huella del contenido y respuesta original. La identidad del propietario siempre procede del token. Un bloqueo PostgreSQL transaccional por usuario y hash del UUID serializa los reintentos entre todas las instancias del backend. El UUID completo se compara al consultar el historial; una colisión del hash solo produce espera, nunca mezcla operaciones. El nivel READ COMMITTED garantiza que el siguiente intento vea la confirmación del anterior después de esperar.

La creación financiera y su confirmación en historial se confirman en **la misma transacción PostgreSQL**. No hay DDL ni nuevos índices; se aprovecha el índice de historial por usuario ya previsto en el esquema. Estos registros se conservan, pero se excluyen de las vistas de historial y exportaciones, y la eliminación de exportaciones no puede borrarlos.

| Operación | Resultado |
| --- | --- |
| `GET /api/movimientos/sincronizacion` | Sesión válida e historial disponible: protocolo 1, idempotencia habilitada. Si no se puede comprobar: 503. |
| `POST /api/movimientos` con `operation_id` | Primera creación: 201, UUID y los IDs del movimiento/detalle. |
| Repetir el mismo propietario, UUID y contenido | 200 y la respuesta original; no inserta otro movimiento. |
| Reutilizar UUID con contenido diferente | 409; no modifica el registro original. |
| `GET /api/movimientos/sincronizacion/operaciones/:operationId` | Comprueba si la operación del usuario autenticado existe antes de corregirla. |
| GET de ingresos, gastos y ahorros | Incluye `operation_id` para reconciliar la descarga con la cola local. |

La cuenta procede del token autenticado, no del cuerpo enviado. El mismo UUID puede utilizarse por cuentas distintas sin compartir respuestas. El bloqueo transaccional y la consulta del historial resuelven también peticiones simultáneas. La huella utiliza JSON con claves ordenadas; cambiar el orden de las claves no transforma un reintento en un conflicto.

Se mantienen la validación de categorías activas y visibles y la pertenencia del dependiente al propietario. Los rechazos revierten también la reserva. Un fallo SQL no deja una operación parcialmente confirmada. Si falla un resumen o notificación después del COMMIT, la respuesta conserva el éxito financiero y evita inducir nuevas creaciones. Estas tareas auxiliares siguen registrando su propio error.

Las solicitudes existentes de la web sin UUID mantienen su contrato. El historial técnico conserva sus entradas incluso si después se elimina un movimiento, para evitar que un reintento antiguo lo vuelva a crear. No se ha programado eliminación automática de este historial.

## Estados, reintentos y corrección

Las interrupciones de transporte, HTTP 408/429 y errores 5xx conservan el registro y programan reintentos de hasta 60 segundos; la comprobación fallida del protocolo se reintenta a los 30 segundos. El botón manual permite solicitar un reintento inmediato. El usuario no tiene que volver a introducir el registro.

HTTP 401/403 pausa el envío y solicita iniciar sesión de nuevo. Los demás rechazos 4xx quedan como errores persistentes que requieren intervención; no se envían repetidamente sin cambios. Las listas presentan el mensaje del servidor.

**Corregir** abre el formulario del registro rechazado. Guardar exige conexión, protocolo verificado y una consulta que confirme ausencia del UUID original en servidor. Solo entonces se sustituye la operación rechazada por un nuevo UUID manteniendo un único registro local. Un resultado incierto o una operación ya existente bloquea la corrección; se debe actualizar/sincronizar para reconciliar el registro.

## Archivos principales

En móvil: `lib/core/storage/offline_database.dart`; `lib/services/offline_query_service.dart`, `offline_download_service.dart`, `offline_sync_service.dart`, `session_logout.dart`; modelos y servicios de ingresos, gastos y ahorros; los tres módulos y formularios; `MainScreen`; indicadores de consulta, sincronización y estado.

En backend: `Backend/src/service/OperacionesMovilesService.js`; `sincronizacionController.js`; controlador y rutas de movimientos. Las pruebas de PostgreSQL local están en `Backend/tests/rf19.cjs` y `rf19-fixture.cjs`.

`sqflite` proporciona persistencia móvil, `uuid` los identificadores y `connectivity_plus` las señales de conectividad. Las pruebas de escritorio utilizan SQLite FFI; esta entrega no habilita almacenamiento offline para Flutter web o Windows.

## Evidencia y verificación

**Resultados ejecutados:** APK normal de la app compilado con `flutter build apk --debug`, disponible en `build/app/outputs/flutter-apk/app-rf19-debug.apk`; 60 pruebas Flutter aprobadas; 17 pruebas RF-19 del backend con HTTP/JWT y PostgreSQL reales aprobadas; 50 regresiones RF-15 aprobadas. El análisis final de almacenamiento, consulta, sincronización, logout, indicadores, pantalla principal, cuenta y prueba Android terminó con `No issues found`; el análisis previo de los módulos principales no presentó errores ni advertencias. Las pruebas cubren:

- SQLite real: persistencia, transacciones, migración desde versión 1, tres creaciones, estados, respuestas perdidas, recuperación de `sending`, fallos de almacenamiento y aislamiento por cuenta.
- Cliente: prohibición de enviar a un backend antiguo, token vencido, reintentos simultáneos, cambios de cuenta durante envío, corrección segura, reportes sin pendientes y advertencia de logout.
- Backend por HTTP y JWT reales con PostgreSQL aislado: 17 casos, incluidos los tres módulos, 12 reintentos simultáneos y 20 operaciones diferentes concurrentes, UUID normalizado, esquema e índices sin cambios, historial técnico protegido, contenido conflictivo, cuentas distintas, rollback SQL, token vencido y borrado seguido de reintento.
- Regresión RF-15: 50 casos aprobados con controladores reales y consultas/servicios simulados; esta regresión no prueba persistencia real.
- Android: `integration_test/rf19_device_test.dart` **aprobada** en el emulador Pixel 5, Android API 37, x86_64. Verificó SQLite y almacenamiento seguro nativos, persistencia al reabrir la base y los servicios, creación en los tres módulos, sincronización HTTP/JWT con PostgreSQL real aislado, respuesta perdida, aislamiento por cuenta y ausencia de duplicados. Resultado: `All tests passed!`, una prueba de integración, 21 segundos después de instalar el APK de prueba.

La prueba Android interrumpe el transporte de manera controlada y vuelve a abrir la base y los servicios. Eso no equivale a haber probado físicamente modo avión, matar todo el proceso o reiniciar un teléfono. La aceptación final debe repetir los seis pasos principales del plan en el dispositivo y servidor que se publicarán.

## Activación del entorno publicado

1. Publicar el backend de `David-M` con el contrato RF-19. No ejecutar migraciones ni alterar tablas, columnas o índices.
2. Con una sesión válida, comprobar `GET /api/movimientos/sincronizacion`: protocolo 1 e idempotencia habilitada. La tabla existente `historial` debe estar disponible para el backend; no se crea automáticamente si falta.
3. Mantener los registros técnicos `RF19:` mientras puedan existir reintentos. La garantía requiere que todas las instancias que crean operaciones móviles utilicen el bloqueo y que nadie purgue ese historial fuera de la aplicación.
4. Distribuir la compilación móvil de esta rama. La URL publicada se mantiene por defecto; `AHORRAPP_API_URL` permite configurar otro entorno al compilar.
5. Ejecutar login/descarga, modo avión, tres creaciones, cierre/reapertura, reconexión, sincronización y repetición. Comprobar unicidad en servidor y exclusión de pendientes en reportes. Registrar evidencia antes de cerrar RF-19 en la auditoría.

No se ha modificado la base remota ni se ha publicado el backend desde esta entrega. Render mostró una pantalla de inicio de sesión y no se dispone de acceso autenticado al servicio. Mientras el servidor actual no anuncie el protocolo, la app conserva las creaciones en el teléfono y explica el impedimento.

## Reproducción de las comprobaciones

Desde móvil: `flutter test`, análisis de los archivos modificados y `flutter build apk --debug`. Desde `Backend`: `npm ci`, `npm run test:rf19` y `npm run test:rf15`. RF-19 inicializa una instancia PostgreSQL temporal y la retira al terminar; no utiliza la base remota configurada.

Para integración Android, iniciar `node tests/rf19-fixture.cjs`, arrancar un emulador de 64 bits, ejecutar `adb reverse tcp:18719 tcp:18719` y `flutter test integration_test/rf19_device_test.dart -d <dispositivo>`. Utilizar una instancia nueva del fixture para cada ejecución. Las cuentas y la ruta de login del fixture solo existen en pruebas. HTTP sin cifrar se permite únicamente en la configuración Android de debug para ese servidor local; la configuración de producción no se modifica.
