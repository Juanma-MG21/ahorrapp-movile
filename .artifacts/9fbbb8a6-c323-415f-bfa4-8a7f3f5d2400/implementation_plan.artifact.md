# Plan de Implementación - Edición y Confirmación de Eliminación

Se añadirá la funcionalidad para editar gastos existentes y se implementará un diálogo de confirmación antes de eliminar un registro, manteniendo la consistencia visual del proyecto.

## Proposed Changes

### [Gastos Feature]

#### [MODIFY] [agregar_gasto_screen.dart](file:///C:/ahorrappmovil/ahorrapp-movile/lib/screens/gastos/agregar_gasto_screen.dart)
- **Constructor**: Recibir un parámetro opcional `GastoModel? gastoParaEditar`.
- **Estado Inicial**: En `initState`, si `gastoParaEditar` no es nulo, pre-cargar los controladores de texto (`monto`, `descripcion`) y las variables de estado (`fecha`, `categoria`, `dependiente`).
- **Interfaz**:
    - Cambiar el título del encabezado a "Editar gasto" si se está editando.
    - Cambiar el texto del botón principal de "Crear gasto" a "Guardar cambios".
- **Lógica**: Asegurar que al presionar el botón se devuelva el modelo actualizado.

#### [MODIFY] [modulo_gastos.dart](file:///C:/ahorrappmovil/ahorrapp-movile/lib/screens/gastos/modulo_gastos.dart)
- **Eliminación**:
    - Crear un método `_mostrarDialogoConfirmacion` que despliegue una alerta neumórfica con la pregunta "¿Seguro de que quieres eliminar este gasto?".
    - Actualizar la acción del botón "Eliminar" para llamar a este método.
- **Edición**:
    - Actualizar la acción del botón "Editar" para navegar a `AgregarGastoScreen` pasando el gasto seleccionado.
    - Manejar el resultado devuelto para actualizar el gasto en la lista original mediante `setState`.

## Verification Plan

### Manual Verification
1.  **Eliminar**: Tocar "Eliminar" en un gasto y verificar que aparezca la alerta. Cancelar y verificar que no se borre. Confirmar y verificar que desaparezca de la lista.
2.  **Editar**: Tocar "Editar", verificar que la pantalla de agregar tenga los datos correctos y el botón diga "Guardar cambios". Cambiar un valor, guardar y verificar que se actualice en la lista principal sin crear un duplicado.
