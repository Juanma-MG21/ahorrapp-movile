# RF-19: plan de registro y consulta sin conexión

Fecha: 7 de octubre de 2026. Plataforma: AhorrApp móvil.

**Estado de la entrega: implementación móvil y backend disponible en las ramas `David-M`.** Este documento conserva el alcance acordado; los archivos, pruebas, exclusiones y pasos de activación están en `rf19-implementacion.md`. El despliegue y la aceptación en el servidor publicado deben comprobarse antes de cerrar la auditoría.

**Restricción confirmada el 7 de octubre:** no modificar el esquema de la base del servidor. La implementación final conserva los UUID y las confirmaciones en su tabla de historial existente; no utiliza una migración del backend. Los cambios de esquema local de SQLite pertenecen exclusivamente al teléfono.

## 1. Objetivo y fuente

Permitir consultar información previamente descargada y crear ingresos, gastos y ahorros sin internet. Cada creación se guardará primero en el teléfono y se enviará al servidor cuando sea posible, sin duplicarla por reintentos.

La auditoría `auditoriaRF-ArchivoGeneral.pdf`, páginas 47 y 48, mantiene RF-19 como pendiente: exige sesión previa con conexión, almacenamiento local, sincronización y ausencia de duplicados. También establece que los reportes no deben reflejar datos no sincronizados. El alcance de esta primera versión concreta esas condiciones.

## 2. Alcance de la primera versión

Incluye:

- Consulta local de ingresos, gastos y ahorros descargados para la cuenta activa.
- Copia local de categorías y dependientes necesarios para los formularios.
- Creación local de ingresos, gastos y ahorros, tanto con conexión como sin ella.
- Persistencia después de cerrar o reiniciar la app.
- Cola de operaciones, sincronización automática y botón Sincronizar.
- Aislamiento por usuario, estados visibles y protección contra duplicados en el servidor.

Quedan fuera **la edición, eliminación y los abonos sin conexión**. También quedan fuera la creación offline de categorías o dependientes, el primer inicio de sesión sin internet y el registro offline de otros módulos. La consulta cubre únicamente información descargada; no promete un historial completo si la descarga fue parcial.

Las acciones excluidas exigirán conexión y no se agregarán a la cola. Un registro pendiente no se podrá editar, eliminar ni abonar en esta versión. Los registros ya sincronizados conservarán sus acciones online existentes; sus resultados deberán actualizar la copia local.

## 3. Situación observada antes de implementar la primera etapa

Revisión estática del proyecto `C:\ahorrapp-movile`:

- `GastosService`, `IngresosService` y `AhorrosService` consultan directamente el servidor y devuelven una lista vacía cuando ocurre una excepción. Esto oculta la diferencia entre ausencia de datos y fallo de consulta.
- Sus métodos de creación envían directamente `POST /movimientos` y esperan un identificador del servidor.
- `AuthService.hasSession()` comprueba la presencia del token local; no demuestra que el servidor todavía lo acepte.
- `AuthService.getCurrentUser()` puede devolver null tras reiniciar cuando la identidad no se conservó. El modo offline requerirá una identidad persistida y verificable de la cuenta previamente autenticada.

Estos hallazgos no constituyen una prueba de funcionamiento en dispositivo ni una auditoría actual de idempotencia en el backend.

## 4. Etapas y entregables

| Etapa | Implementación propuesta | Condición de entrega |
| --- | --- | --- |
| 1. Almacenamiento y consulta | Base local transaccional, separación por usuario y lectura de copias persistidas. | Los registros descargados siguen consultables tras perder internet y reiniciar. |
| 2. Descarga inicial | Descargar movimientos, categorías y dependientes después del login; actualizar al abrir con conexión. | Se conoce qué recursos se descargaron y cuándo. |
| 3. Registro local | Validación y guardado atómico del movimiento junto con su operación pendiente. | El formulario confirma únicamente después de guardar en el teléfono. |
| 4. Sincronización | Procesar pendientes al recuperar conexión, abrir la app y pulsar Sincronizar. | Se conservan los fallos y se confirman los éxitos. |
| 5. Duplicados | Identificador estable de operación y deduplicación transaccional en el backend. | Repetir un envío conserva un solo movimiento. |
| 6. Estados y errores | Mostrar pendientes, errores, conexión y última sincronización. | El usuario distingue datos locales de datos confirmados. |
| 7. Evidencia | Pruebas en almacenamiento, API y dispositivo; actualizar la documentación. | RF-19 solo se marca terminado cuando existe evidencia reproducible. |

La primera entrega será almacenamiento y consulta offline, con la descarga necesaria para poblar la copia local. Después se incorporará creación local. El envío se habilitará cuando esté disponible la protección contra duplicados del backend.

## 5. Diseño del almacenamiento

Se propone una base de datos local con transacciones y migraciones de esquema. La selección concreta del motor y la librería se hará durante la implementación según las plataformas soportadas.

| Entidad | Datos mínimos |
| --- | --- |
| Movimientos | Usuario propietario, ID local, ID del servidor si existe, módulo, contenido, fecha y estado de sincronización. |
| Categorías y dependientes | Usuario propietario, ID del servidor, contenido y fecha de descarga. |
| Operaciones pendientes | Usuario propietario, UUID de operación, tipo de creación, contenido inmutable, estado, intentos y error. |
| Metadatos | Usuario propietario, recurso, fecha de descarga exitosa y última sincronización exitosa. |

Todas las lecturas y escrituras exigirán el ID de la cuenta activa. No se usará el correo como identificador estable. Las categorías globales podrán copiarse dentro de cada cuenta para mantener el mismo aislamiento.

Guardar el movimiento y encolar su creación será una sola transacción: si falla, no se mostrará éxito ni quedará una operación incompleta. Si falta espacio o falla la base local, se informará que el registro no se guardó.

La descarga actualizará los registros sincronizados por ID del servidor y preservará los pendientes. Una respuesta vacía exitosa podrá actualizar la copia; un error no la borrará. Solo una descarga completa permitirá eliminar de la copia registros ausentes del servidor. Si hay paginación, no se tratará una página como una copia completa.

## 6. Consulta y descarga inicial

1. Iniciar sesión con internet y obtener una identidad válida del usuario.
2. Descargar los recursos necesarios y guardarlos por cuenta, registrando resultados por recurso.
3. Presentar la copia local; si hay conexión, intentar actualizarla.
4. Ante un fallo de red, conservar la copia e indicar su fecha de actualización.
5. Si no existe copia descargada, mostrar que no hay información disponible sin conexión.

La interfaz distinguirá: consulta exitosa sin registros, consulta desde copia local y consulta fallida sin copia. Un fallo de autenticación solicitará iniciar sesión; un fallo del servidor se identificará como tal, sin presentarlo automáticamente como falta de internet.

Si la descarga inicial queda incompleta, se indicará qué información no está disponible. Los formularios solo ofrecerán categorías y dependientes descargados; se respetarán los campos obligatorios y las reglas reales del servidor.

## 7. Registro local y estados

El formulario valida los datos, asigna un UUID y guarda movimiento y operación en una transacción. Después confirma el guardado y muestra **Pendiente de sincronizar**. Tener conexión no omite este paso: la creación pasa por la misma cola.

| Estado | Significado y comportamiento |
| --- | --- |
| Pendiente | Guardado en el teléfono; aún no confirmado por el servidor. |
| Enviando | Hay un envío en curso; no se inicia otro envío simultáneo de la misma operación. |
| Sincronizado | El servidor confirmó el movimiento y se guardó su identificador localmente. |
| Error que requiere corrección | El servidor rechazó datos o referencias; la operación se conserva y deja de reintentarse automáticamente. |
| Sesión requerida | Los pendientes permanecen guardados; el envío espera autenticación de su propietario. |

Los estados transitorios se recuperarán al reiniciar: una operación que quedó Enviando vuelve a ser reintentable con el mismo UUID. La confirmación del servidor y el cambio de estado local se guardarán juntos.

En esta versión, corregir un rechazo requerirá conexión. El flujo deberá comprobar el resultado definitivo de la operación original antes de permitir un registro corregido, para no duplicar una creación cuyo resultado todavía sea incierto. No se ofrecerá edición offline del contenido pendiente.

## 8. Sincronización y protección contra duplicados

La conectividad del teléfono dispara intentos, pero no prueba que el servidor sea accesible. Se intentará sincronizar al abrir o volver a primer plano, recuperar conexión y pulsar Sincronizar. No se promete ejecución con la app cerrada; eso requeriría trabajo adicional específico de Android/iOS.

Un único coordinador procesará la cola de la cuenta activa. Capturará su identidad antes de enviar y verificará que siga siendo la misma antes de aplicar una respuesta. El cambio de cuenta o cierre de sesión detendrá nuevos envíos; una respuesta tardía solo podrá actualizar los datos de su propietario original.

Contrato propuesto para `POST /movimientos`:

- Cada creación incluirá un UUID de operación estable, conservado durante todos los reintentos.
- El backend obtendrá el propietario del token autenticado y aplicará unicidad por propietario y UUID.
- El movimiento y la evidencia de deduplicación se guardarán en una misma transacción del servidor.
- Repetir el UUID y el mismo contenido devolverá la confirmación y el ID originales.
- Repetir el UUID con contenido distinto se rechazará como conflicto.
- La deduplicación se conservará sin un vencimiento que permita duplicar pendientes antiguos.

Si el servidor guardó el movimiento pero la respuesta se perdió, el teléfono conservará el pendiente. El siguiente intento, con el mismo UUID, recuperará el resultado original. El cliente reconciliará ID local e ID del servidor para mostrar un solo elemento, incluso si una descarga ocurre antes de recibir la confirmación.

No basta con impedir un segundo toque en Guardar ni con comparar monto y fecha: dos movimientos iguales pueden ser legítimos. La garantía de reintentos exige cambios en el backend y su base de datos.

Los fallos transitorios tendrán reintentos con espera progresiva y un límite por ejecución. Un 401 pausará el envío hasta reautenticación; los rechazos de validación y permisos se mostrarán para intervención. Una referencia a categoría o dependiente deshabilitado será un rechazo explícito, sin sustituirla silenciosamente.

## 9. Sesiones y separación de cuentas

- El modo offline requiere un login previo exitoso y una identidad local persistida. Nunca se accederá a datos por la sola existencia de una base local.
- El vencimiento del token no eliminará pendientes. Se podrá conservar la consulta local de la sesión previamente identificada, pero el envío requerirá autenticación válida.
- Al cerrar sesión se mostrará cuántas operaciones quedan únicamente en el teléfono y se permitirá cancelar o continuar. Continuar conserva los pendientes asociados a su propietario y bloquea su acceso desde otras cuentas.
- Una cuenta diferente no consultará ni sincronizará esos registros. Al volver a autenticarse con la cuenta original, se recuperarán.
- Si no hay identidad local suficiente después de reiniciar, se solicitará login; no se elegirá automáticamente una cuenta por sus datos guardados.
- Desinstalar la app, borrar sus datos o perder el teléfono puede eliminar registros no enviados. La advertencia de pendientes debe dejar claro que aún no hay copia en el servidor.

## 10. Listas, reportes y mensajes

Las listas incluirán pendientes identificados. Se mostrarán conexión, cantidad de pendientes de la cuenta activa, fecha de la copia local, última sincronización exitosa y errores accionables. Una descarga exitosa no se confundirá con el envío exitoso de toda la cola.

**Los reportes excluirán los movimientos pendientes, en envío y rechazados.** Recuperar internet por sí solo no permite incluirlos: primero debe existir confirmación del servidor. Si se conserva un reporte previo, se mostrará su fecha; esta versión no añade generación offline de reportes.

Los resúmenes locales que incluyan pendientes deberán explicar ese alcance y no presentarse como reportes oficiales. La última sincronización completa solo se actualizará cuando termine la ejecución sin operaciones fallidas o pendientes de ese lote.

## 11. Pruebas y criterios de aceptación

| Prueba | Resultado exigido |
| --- | --- |
| Login y descarga online | Copia persistida con identidad y fechas; recursos incompletos visibles. |
| Modo avión y consulta | Registros descargados accesibles; no aparece un falso historial vacío. |
| Crear un ingreso, un gasto y un ahorro offline | Tres registros locales y tres operaciones pendientes. |
| Cerrar y abrir; reiniciar dispositivo | Los tres registros y sus UUID permanecen. |
| Recuperar conexión y sincronizar | Tres confirmaciones con ID del servidor; ningún pendiente perdido. |
| Repetir sincronización | Un solo registro en servidor por cada UUID. |
| Cortar conexión después del guardado en servidor | Reintento devuelve el mismo registro, sin duplicación. |
| Reiniciar durante envío o confirmación local | Recuperación segura con el UUID original. |
| Disparar sincronización automática y manual juntas | Sin doble procesamiento; unicidad garantizada también por servidor. |
| Token vencido | Pendientes intactos y envío pausado hasta login del propietario. |
| Cerrar sesión y entrar con otra cuenta | Advertencia; ninguna lectura ni envío de la cuenta anterior. |
| Cambiar cuenta mientras llega una respuesta | La respuesta no modifica la cuenta nueva. |
| Servidor devuelve vacío válido | Se distingue de fallo de red; pendientes conservados. |
| Categoría deshabilitada o datos rechazados | Error visible y persistido; no hay reintento infinito. |
| Descargar después de un envío sin respuesta | Un solo elemento local tras reconciliación. |
| Generar reporte antes y después de confirmar | Pendientes excluidos; inclusión únicamente tras confirmación. |
| Fallo de almacenamiento | No se afirma que el registro quedó guardado. |
| Editar, eliminar o abonar offline | Acción exige conexión y no entra en la cola. |

La prueba principal sigue la secuencia: login y descarga, modo avión, creación de los tres módulos, cierre y reapertura, reconexión, sincronización y repetición. La unicidad se comprobará consultando el servidor o su base de datos; la lista móvil por sí sola no la demuestra.

Se combinarán pruebas de transacciones y aislamiento local, pruebas de integración del contrato de deduplicación y pruebas en dispositivo. Se registrarán versión de app y backend, dispositivo, pasos, resultados, capturas, UUID e identificadores del servidor, sin publicar tokens.

## 12. Actualización propuesta del requerimiento

**Identificador:** RF-19.

**Nombre:** Registro y consulta en modo sin conexión.

**Descripción:** La aplicación móvil permitirá consultar ingresos, gastos y ahorros previamente descargados y crear nuevos registros de esos módulos sin conexión. Las creaciones se almacenarán primero en el teléfono, asociadas a su propietario, y se sincronizarán al recuperar acceso al servidor, abrir la aplicación o solicitar sincronización manual, sin duplicarse por reintentos.

**Precondiciones:** Login previo exitoso con internet e identidad local persistida. La consulta requiere una descarga previa; los formularios requieren los catálogos necesarios disponibles localmente. El envío requiere una sesión válida del propietario.

**Postcondiciones:** Los registros confirmados quedan asociados a un ID del servidor y marcados como sincronizados. Los no confirmados se conservan localmente con estado y error visibles.

**Restricciones:** Primera versión sin edición, eliminación ni abonos offline; sin primer login offline; sin acceso entre cuentas. Los reportes excluyen registros no confirmados. No se garantiza sincronización con la aplicación cerrada ni recuperación de datos locales tras desinstalación.

**Dependencias y relaciones:** RF-02, RF-03 y RF-04; inicio y cierre de sesión, categorías y reportes. Requiere almacenamiento local y soporte de deduplicación en el backend.

**Prioridad:** Alta. **Estado:** Implementado en código; pendiente de activación y aceptación en el entorno publicado. **Versión documental:** 1.1. **Cumplimiento:** Evidencia local documentada en `rf19-implementacion.md`.

**Justificación:** Mantener registro y consulta con conectividad limitada, preservando los datos y evitando duplicados.

**RNF relacionados:** RNF-04 (Disponibilidad) y RNF-06 (Escalabilidad), según la auditoría.

**Evidencia:** `test/rf19_offline_test.dart`, `test/rf19_sync_test.dart`, `integration_test/rf19_device_test.dart` y `Backend/tests/rf19.cjs`. Consultar resultados ejecutados y límites en `rf19-implementacion.md`. La auditoría PDF se usa como fuente; no se ha modificado el archivo original.
