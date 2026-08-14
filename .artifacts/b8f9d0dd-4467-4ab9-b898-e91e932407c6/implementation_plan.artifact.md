# Implementation Plan - Home Screen Widgets for AhorrApp

This plan outlines the steps to implement Android Home Screen Widgets (Small 2x2 and Medium 4x2) as requested, based on the provided design.

## User Review Required

> [!IMPORTANT]
> To implement widgets that update automatically, we need to add the `home_widget` plugin. This plugin facilitates communication between Flutter and Native Android AppWidgets.
> The buttons on the widget ("- Gasto", "+ Ingreso") will be configured to open the app directly to the expense/income addition screen.

## Proposed Changes

### Dependencies

#### [MODIFY] [pubspec.yaml](file:///C:/ahorrappmovil/ahorrapp-movile/pubspec.yaml)
- Add `home_widget: ^0.7.1` (or latest stable).
- Add `path_provider` to help with shared storage if needed, though `home_widget` handles most of it.

### Android Native Implementation

#### [NEW] [small_widget.xml](file:///C:/ahorrappmovil/ahorrapp-movile/android/app/src/main/res/layout/small_widget.xml)
- Layout for the 2x2 widget.
- Dark background (`#0E1124`), rounded corners.
- Displays "Balance Actual" and two buttons.

#### [NEW] [medium_widget.xml](file:///C:/ahorrappmovil/ahorrapp-movile/android/app/src/main/res/layout/medium_widget.xml)
- Layout for the 4x2 widget.
- Displays "Balance Actual", "INGRESOS", "GASTOS", and the budget progress bar.

#### [NEW] [Widget Info Files](file:///C:/ahorrappmovil/ahorrapp-movile/android/app/src/main/res/xml/)
- `small_widget_info.xml` and `medium_widget_info.xml` to define widget properties (min width/height, update period).

#### [NEW] [AhorrAppWidgetProvider.kt](file:///C:/ahorrappmovil/ahorrapp-movile/android/app/src/main/kotlin/com/example/ahorrapp/AhorrAppWidgetProvider.kt)
- Kotlin class extending `AppWidgetProvider`.
- Handles `onUpdate` to read data from `SharedPreferences` and populate `RemoteViews`.
- Handles button clicks to launch the app with specific arguments.

#### [MODIFY] [AndroidManifest.xml](file:///C:/ahorrappmovil/ahorrapp-movile/android/app/src/main/AndroidManifest.xml)
- Register the two widgets as `receiver`s.

### Flutter Implementation

#### [NEW] [widget_service.dart](file:///C:/ahorrappmovil/ahorrapp-movile/lib/services/widget_service.dart)
- A utility service to update the widget data from Flutter.
- Methods like `updateWidgetData(balance, ingresos, gastos, budgetLimit)`.

#### [MODIFY] [modulo_gastos.dart](file:///C:/ahorrappmovil/ahorrapp-movile/lib/screens/gastos/modulo_gastos.dart)
- Call `WidgetService` whenever the expenses or balance changes to ensure the home screen stays in sync.

#### [MODIFY] [main.dart](file:///C:/ahorrappmovil/ahorrapp-movile/lib/main.dart)
- Initialize `home_widget` and handle deep links if the widget buttons are pressed.

## Verification Plan

### Automated Tests
- Since this involves Native-Flutter interaction, verification will be primarily manual on a device/emulator.

### Manual Verification
1. Add the "AhorrApp Small" widget to the home screen.
2. Add the "AhorrApp Medium" widget to the home screen.
3. Open the app and add a gasto.
4. Verify the balance updates on both widgets.
5. Tap the "+ Ingreso" or "- Gasto" button on the small widget and verify it opens the app.
