> **Registro histórico de la primera etapa.** La entrega completa y su estado actual se describen en [rf19-implementacion.md](rf19-implementacion.md). Las funciones que este documento enumera como pendientes correspondían a la primera entrega.

# RF-19: primera entrega, almacenamiento y consulta offline

Fecha: 7 de octubre de 2026. Rama de trabajo: `David-M`.

## Alcance implementado

La aplicación móvil guarda copias de las respuestas de ingresos, gastos, ahorros, categorías y dependientes en una base SQLite del teléfono. Cada copia pertenece a un ID de usuario e incluye fecha de descarga. Las copias vacías también se conservan: una consulta válida sin registros es diferente de no haber descargado información.

Al abrir la pantalla principal después del login se intentan descargar los cinco recursos de manera independiente. Volver a la aplicación desde segundo plano vuelve a intentar la actualización. Las consultas de las listas financieras y los catálogos de los formularios utilizan la copia local si falla el transporte hacia el servidor. Los avisos muestran el origen de los datos y la fecha de la copia, con una acción Actualizar.

Un error de autenticación, permisos, servidor o formato se presenta como un fallo de consulta; no se disfraza como una lista vacía ni como pérdida de internet. Si no existe una copia, se explica que la información aún no se descargó.

La pantalla de dependientes también reutiliza la copia. La pantalla de administración de categorías calcula totales mediante otros endpoints: esos totales y esa pantalla completa no forman parte de la consulta offline de esta entrega. Se almacenan las categorías requeridas por los formularios financieros.

## Aislamiento y persistencia

- La clave de cada copia combina propietario y recurso. Ninguna consulta selecciona registros sin propietario.
- Se requiere token e identidad de la sesión actual. Para volver a entrar tras cerrar la app sin internet, la sesión debe haberse conservado mediante Recordar sesión. Sin sesión persistida se requiere login online; no se modifica esa preferencia del usuario.
- El cierre de sesión elimina credenciales y estado visible, pero conserva las copias por propietario. Otra cuenta no puede consultarlas.
- Las respuestas tardías de consultas comprueban la identidad y versión de sesión antes de devolver datos a las pantallas.
- Cada sustitución de copia es transaccional. Una respuesta que los modelos no puedan leer no sustituye la copia válida anterior.
- Los cambios online de los módulos afectados invalidan la copia anterior de su propietario. Hasta que termine otra descarga, ese recurso puede dejar de estar disponible offline; no se muestran registros anteriores a una edición o eliminación como si siguieran vigentes.
- Las descargas y escrituras concurrentes se identifican por revisión. Las pantallas descartan resultados de cargas anteriores cuando existe una carga posterior.

La base incluye una tabla reservada para operaciones pendientes, pero esta entrega no crea ni procesa operaciones en ella.

## Archivos principales

| Archivo | Responsabilidad |
| --- | --- |
| `lib/core/storage/offline_database.dart` | Apertura y versión de SQLite, copias por usuario, persistencia y eliminación de copias obsoletas. |
| `lib/services/offline_query_service.dart` | Consulta remota, fallback por fallo de transporte, estados, aislamiento y coordinación de consultas. |
| `lib/services/offline_download_service.dart` | Descarga independiente de los cinco recursos al entrar y volver a primer plano. |
| `lib/widgets/offline_query_banner.dart` | Mensajes de copia local, actualización, ausencia de copia y errores. |
| Servicios de gastos, ingresos y ahorros | Adaptación de consultas y confirmaciones de escrituras online. |
| `lib/services/auth_service.dart` | Versión de sesión y notificación de cambios para descartar respuestas anteriores. |
| Pantallas financieras y formularios | Avisos, tratamiento de errores, actualización y protección de cargas tardías. |
| `test/rf19_offline_test.dart` | Persistencia real en SQLite, aislamiento, fallos, concurrencia, integración con modelos y avisos de interfaz. |

## Verificación automatizada

- La suite completa terminó con **41 pruebas aprobadas**, incluidas **16 pruebas específicas de RF-19** y las regresiones de sesión y OCR/QR.
- Las pruebas de RF-19 utilizaron archivos SQLite reales en una carpeta temporal. Se cerró y reabrió la base para comprobar la persistencia; no se sustituyó esa comprobación por una lista en memoria.
- Se verificaron aislamiento entre usuarios, recuperación de la copia de la cuenta original, cierre de sesión, respuestas tardías, consultas simultáneas, invalidación tras escrituras online, conservación ante rechazos y descarte de respuestas antiguas sin borrar descargas nuevas.
- Se comprobó la integración de los modelos de ingresos, gastos y ahorros y el aviso de copia local o ausencia de copia en un entorno de pruebas de interfaz.
- El análisis de los archivos modificados no encontró errores ni advertencias de compilación. Permanecen avisos informativos de estilo y de APIs antiguas en código existente.
- La compilación Android debug terminó correctamente y generó `build/app/outputs/flutter-apk/app-debug.apk`. La herramienta reportó avisos de compatibilidad futura de Kotlin en `home_widget` y `mobile_scanner`; no impidieron generar el APK.
- No había un dispositivo ni emulador conectado. Estas pruebas no acreditan todavía la ejecución del flujo en modo avión en Android ni el comportamiento en iOS.

## Comprobación manual pendiente en Android

1. Instalar la versión generada e iniciar sesión con internet, conservando la sesión.
2. Esperar a ver Datos actualizados en ingresos, gastos y ahorros. Comprobar que los catálogos de los formularios están disponibles.
3. Activar modo avión y abrir o actualizar los tres módulos. Debe aparecer Copia local con su fecha; los datos deben corresponder a la última descarga.
4. Cerrar la app completamente, abrirla de nuevo y comprobar los mismos datos.
5. Probar con una cuenta sin descarga previa: debe aparecer la ausencia de copia, sin afirmar que no tiene movimientos.
6. Con internet, cerrar sesión y entrar con otra cuenta. Sus listas no deben incluir los registros de la primera. Volver a la cuenta original y repetir la consulta.
7. Recuperar internet y pulsar Actualizar o volver a primer plano. Comprobar que los datos remotos sustituyen las copias.

Las consultas remotas tienen un tiempo de espera de hasta 12 segundos antes del fallback, según el fallo de red. En esta fase la recuperación de internet no dispara una sincronización con la app cerrada ni una descarga por un detector de conectividad.

## Funciones que siguen pendientes

No se ha implementado creación offline de ingresos, gastos o ahorros, UUID de operaciones, envío de pendientes, deduplicación en backend, aviso de cierre con pendientes ni estados de sincronización de movimientos. La creación, edición, eliminación y los abonos todavía requieren servidor y no se encolan.

Los reportes mantienen su consulta al servidor; esta entrega no mezcla copias locales en sus cálculos ni añade reportes offline. La restricción de excluir pendientes tendrá que verificarse nuevamente cuando exista creación local.

SQLite nativo se utiliza para la plataforma móvil. La persistencia offline de Windows o Flutter web no está habilitada por esta entrega. Las pruebas de SQLite en Windows usan una fábrica de base de datos específica de pruebas.

RF-19 permanece **parcial y pendiente de cumplimiento completo**. La prueba principal del plan, que crea tres movimientos en modo avión y comprueba su unicidad en servidor, todavía no puede ejecutarse con esta primera etapa.
