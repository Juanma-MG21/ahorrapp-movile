# Plan de Implementación: Navegación desde el Widget

Este plan describe cómo configurar los botones del widget de la pantalla de inicio para que abran la aplicación directamente en la vista de Ingresos o Gastos correspondiente.

## User Review Required

> [!IMPORTANT]
> Los botones en el widget ("- Gasto", "+ Ingreso") serán configurados para abrir la app directamente en el índice correspondiente de la `MainScreen` (Índice 1 para Ingresos, Índice 2 para Gastos).

## Proposed Changes

### 1. Android (Configuración del Widget)

#### [MODIFY] [AhorrAppMediumWidgetProvider.kt](file:///C:/ahorrappmovil/ahorrapp-movile/android/app/src/main/kotlin/com/example/ahorrapp/AhorrAppMediumWidgetProvider.kt)
*   Configurar `PendingIntents` para las secciones de ingresos y gastos en el widget mediano, similar a como está en el widget pequeño.

### 2. Flutter (Manejo de Navegación)

#### [MODIFY] [main_screen.dart](file:///C:/ahorrappmovil/ahorrapp-movile/lib/screens/main_screen.dart)
*   Importar `package:home_widget/home_widget.dart`.
*   Implementar `initState` para:
    1.  Verificar si la app fue lanzada desde el widget usando `HomeWidget.initiallyLaunchedFromHomeWidget()`.
    2.  Escuchar clics mientras la app está abierta usando `HomeWidget.widgetClicked.listen()`.
*   Crear una función `_handleWidgetClick(Uri? uri)` que actualice `_selectedIndex` según el esquema de URL (`ahorrapp://ingreso` -> 1, `ahorrapp://gasto` -> 2).

### 3. Servicios (Opcional pero recomendado)

#### [MODIFY] [widget_service.dart](file:///C:/ahorrappmovil/ahorrapp-movile/lib/services/widget_service.dart)
*   Asegurar que los datos del widget se actualicen correctamente incluyendo los campos necesarios para el widget mediano si se han añadido nuevos.

## Verification Plan

### Manual Verification
1.  Añadir el widget pequeño y mediano a la pantalla de inicio.
2.  Tocar el botón "- Gasto" en el widget pequeño y verificar que la app abra en la pestaña de Gastos.
3.  Tocar el botón "+ Ingreso" en el widget pequeño y verificar que la app abra en la pestaña de Ingresos.
4.  Repetir la prueba con el widget mediano (si se implementan los clics ahí).
5.  Probar con la aplicación cerrada y con la aplicación en segundo plano.
