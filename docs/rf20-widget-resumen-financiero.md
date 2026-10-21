# RF-20: cifras coherentes en el widget Android

Fecha: 7 de octubre de 2026. Rama: `David-M`.

## Alcance y fuente

Se corrigieron los cálculos y la actualización de los widgets pequeño y mediano de la pantalla de inicio de Android. La fuente documental es RF-20, página 30 de `auditoriaRF-ArchivoGeneral.pdf`: resumen del mes en curso, actualización al abrir la aplicación o registrar transacciones y presentación sin contraseñas ni detalles de cuentas. El PDF original no se modificó. Su estado «Finalizado» es histórico y no sustituye la verificación de esta corrección.

No se modificó el backend ni el esquema de la base de datos remota. Se conservan los cambios previos de RF-19.

## Problema corregido

Los tres módulos escribían las mismas claves con fórmulas distintas: gastos establecía ingresos y presupuesto en cero; ingresos no incluía imprevistos; imprevistos sí los incluía y podía sumar pendientes. El último módulo abierto cambiaba el balance aunque no hubiera nuevas transacciones. Las escrituras individuales también podían combinar cifras de consultas distintas.

Ahora cada módulo solicita `WidgetService.refresh()` sin enviar totales. Un único servicio consulta ingresos, gastos e imprevistos de la cuenta actual y calcula el resumen completo. Ambos proveedores Android leen una sola instantánea JSON, `financial_summary_v1`, en lugar de las antiguas claves individuales.

## Reglas del cálculo

| Dato | Regla |
| --- | --- |
| Período | Mes y año actuales del teléfono, independientemente del mes seleccionado en las listas. |
| Ingresos | Suma de ingresos sincronizados del período. |
| Gastos | Gastos sincronizados más imprevistos del período. Los imprevistos se crean online en esta versión. |
| Balance | Ingresos menos gastos, incluyendo imprevistos una sola vez. Puede ser negativo. |
| Porcentaje | Gastos / ingresos × 100. Sin ingresos muestra «—». Puede superar 100%; solo la barra visual se limita a 100. |
| Moneda | Dos decimales y la misma representación en ambos widgets; las sumas se realizan en centavos enteros. |

El texto de la barra cambió a **Gastos respecto a ingresos del mes**: no representa un límite presupuestario. No se sustituye el ingreso real por un presupuesto, ni se descuentan metas de ahorro, deudas o aportes a emergencia en este resumen.

Ejemplo: ingresos 1.000, gastos 200 e imprevistos 50 producen balance 750, gastos 250 y porcentaje 25%, tanto al abrir ingresos como gastos o imprevistos. Las creaciones pendientes, enviándose o rechazadas de RF-19 no se incluyen.

## Actualización, errores y cuentas

La aplicación solicita actualizar el widget al entrar a la pantalla principal, volver al primer plano, cargar un módulo financiero y recibir cambios de sincronización. Los módulos vuelven a cargar tras registrar, editar o eliminar sus movimientos. Las consultas RF-19 por recurso pueden compartir una descarga en curso.

Solo se publica cuando los tres recursos se consultaron correctamente o disponen de copias locales válidas. No se utiliza el método de imprevistos que convierte un fallo en una lista vacía. Una copia local se identifica en la fecha; una consulta incompleta conserva el último resumen de la misma cuenta y mes con **sin actualizar**. Sin resumen válido, o si cambia el mes, muestra «—» y **No se pudo actualizar**. Una lista realmente vacía sí produce ceros válidos.

Las respuestas de sesiones anteriores y actualizaciones que terminan fuera de orden se descartan. Las publicaciones se serializan. Cerrar sesión limpia inmediatamente las cifras, sin esperar a Google o al borrado de credenciales; cambiar de cuenta exige un resumen nuevo y no reutiliza los importes anteriores. Solo se guardan cifras agregadas y etiquetas, sin token ni datos de identidad en el widget.

Android conserva la instantánea en las preferencias de `home_widget`. Los proveedores dibujan esa copia cuando el sistema solicita actualizar; no consultan el servidor ni garantizan sincronización automática con la app cerrada. Antes de disponer de la primera instantánea muestran **Abre AhorrApp**. Los accesos rápidos existentes del widget pequeño no forman parte de esta corrección de cálculos.

## Archivos y orden del flujo

1. `lib/screens/main_screen.dart` y los módulos de ingresos, gastos e imprevistos solicitan actualizar.
2. `lib/services/widget_service.dart` consulta los tres recursos con la sesión vigente y las copias RF-19.
3. `lib/services/financial_widget_summary.dart` calcula cifras y controla sesiones, errores y publicaciones tardías.
4. `home_widget` guarda el resumen completo y solicita redibujar ambos tamaños.
5. `android/app/src/main/kotlin/com/example/ahorrapp_movil/FinancialWidgetSnapshot.kt` lee el JSON; los proveedores pequeño y mediano muestran esa misma información.

## Verificación y aceptación

Las pruebas `test/rf20_widget_test.dart` cubren período y año, imprevistos, exclusión de pendientes, centavos, balance negativo, ausencia de ingresos, porcentaje superior a 100%, copia local, montos inválidos, solicitudes repetidas, errores, cambio de mes, respuestas fuera de orden, logout y cambio de cuenta.

Resultados: 70 pruebas Flutter aprobadas, incluidas 10 específicas de RF-20; análisis de los servicios, módulos, pantalla principal y pruebas: `No issues found`. La compilación Android incluye ambos proveedores Kotlin y su lector de instantáneas. APK de entrega: `build/app/outputs/flutter-apk/app-rf20-debug.apk`. Las pruebas automatizadas del cálculo y la compilación no equivalen a observar un widget colocado en un launcher real.

Aceptación visual pendiente:

1. Instalar el APK actualizado, iniciar sesión y añadir ambos widgets.
2. Con el ejemplo 1.000 / 200 / 50 del mes actual, comprobar 750 / 1.000 / 250 y 25%.
3. Abrir cada módulo en distinto orden y verificar que no cambian las cifras.
4. Crear, editar y eliminar movimientos online; regresar al inicio y comprobar ambos tamaños.
5. Crear pendientes offline: deben quedar excluidos. Tras sincronizarlos, deben aparecer una sola vez en los totales.
6. Probar ingresos cero, gastos superiores a ingresos y movimientos de otros meses/años.
7. Interrumpir la consulta: conservar cifras con aviso o mostrar falta de información, sin inventar ceros.
8. Cerrar sesión y cambiar de cuenta: las cifras anteriores deben desaparecer.
