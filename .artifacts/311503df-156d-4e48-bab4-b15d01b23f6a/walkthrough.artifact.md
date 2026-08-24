# Walkthrough - Solución de Pantalla y Sustentación de API

Se ha solucionado el problema visual de la pantalla de PIN y se ha implementado un flujo completo de consumo de API para cumplir con los requisitos académicos.

## 1. Solución de Pantalla Negra (Flutter Web)
El error ocurría porque el componente `IntrinsicHeight` intentaba calcular la altura en un entorno de scroll sin límites fijos en la web, lo que resultaba en una altura de 0.
- **Cambio:** Se eliminó `IntrinsicHeight` de [auth_widgets.dart](file:///E:/Ahorrapp-MOVIL/lib/widgets/auth_widgets.dart).
- **Resultado:** El teclado y los indicadores del PIN ahora son visibles correctamente en el navegador y emuladores.

## 2. Implementación de API (Sustentación)
Para cumplir con el instructor, se ha creado un módulo de red profesional:

### Arquitectura de la API:
1.  **Dependencia:** Se añadió `dio` en `pubspec.yaml`, que es la librería líder para peticiones HTTP en Flutter.
2.  **Cliente ([api_client.dart](file:///E:/Ahorrapp-MOVIL/lib/core/network/api_client.dart)):** Centraliza la configuración (URL base, tiempos de espera, cabeceras). Usamos `jsonplaceholder.typicode.com` como servidor de prueba.
3.  **Modelo ([producto_model.dart](file:///E:/Ahorrapp-MOVIL/lib/models/producto_model.dart)):** Define cómo se estructura un producto. Incluye un `factory Producto.fromJson` para convertir la respuesta del servidor en objetos de Dart.
4.  **Servicio ([producto_service.dart](file:///E:/Ahorrapp-MOVIL/lib/services/producto_service.dart)):** Contiene la lógica para llamar a la API (método `getProductos`).
5.  **Pantalla ([productos_screen.dart](file:///E:/Ahorrapp-MOVIL/lib/screens/productos/productos_screen.dart)):** Utiliza un `FutureBuilder` para mostrar un cargador mientras los datos llegan y luego los presenta en una lista elegante.

## Guía para la Sustentación
Si el instructor te pregunta cómo funciona:
- **Pregunta:** "¿Cómo traes los datos?"
- **Respuesta:** "Usamos el patrón de servicios. La UI llama al `ProductoService`, este usa un cliente `Dio` configurado en el `core` para hacer una petición `GET`. Los datos recibidos se mapean a objetos mediante el modelo `Producto` y se muestran dinámicamente usando un `FutureBuilder`."

## Cómo Probar
1. Ejecuta `flutter run -d chrome`.
2. Ve a la pantalla de **PIN** e ingresa `1234`.
3. Al entrar al **Inicio**, verás un botón llamado **"Ver Catálogo (Consumo API)"**.
4. Haz clic y verás los productos cargados directamente desde internet.

> [!TIP]
> He subido los cambios a tu rama. Ya puedes hacer el commit final.
