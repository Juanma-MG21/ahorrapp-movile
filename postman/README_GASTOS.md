# Pruebas de la API de gastos en Postman

Importa `AhorrApp_Gastos.postman_collection.json` en Postman. Incluye el registro e inicio de sesión necesarios para obtener un JWT, además del CRUD de gastos.

Antes de enviarla, abre la colección y asigna estas variables:

| Variable | Valor |
| --- | --- |
| `token` | JWT de una sesión válida, sin el prefijo `Bearer`; Login lo completa automáticamente |
| `test_email` | Correo de la cuenta de prueba; Registro crea uno único si se deja vacío |
| `test_password` | Contraseña de la cuenta de prueba |
| `id_categoria` | ID de una categoría existente de tu cuenta |
| `id_dependientes` | ID de un dependiente existente; déjalo como `null` si el gasto es propio |

El valor por defecto de `baseUrl` ya apunta a `https://ahorrapp-react-pkj9.onrender.com/api`.

Para una prueba desde cero, ejecuta en este orden: **Registrar usuario de prueba**, **Login**, GET, POST, PUT y DELETE. Login guarda automáticamente el JWT en `token`; el POST de gastos guarda `ID_detalle` en `gasto_id`, que después usan PUT y DELETE. Si vas a modificar o borrar un gasto ya existente, escribe su identificador manualmente en `gasto_id`.

Las rutas que cubre la colección son:

| Método | Ruta |
| --- | --- |
| GET | `/movimientos/gastos` |
| POST | `/movimientos` |
| PUT | `/movimientos/gastos/:id` |
| DELETE | `/movimientos/gastos/:id` |

Todas requieren las cabeceras `Authorization: Bearer <JWT>` y, para los cuerpos JSON, `Content-Type: application/json`.
