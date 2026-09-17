# Datos de prueba (INSERTs) — Usuario ID 4

Este archivo contiene los `INSERT` necesarios para poblar con datos de ejemplo **todas las tablas** del esquema, asociados al usuario ya registrado con `id_usuario = 4`.

## Notas importantes antes de ejecutar

1. **No se incluyen** inserts para `usuarios`, `rol`, `usuarios_roles`, `notificaciones` ni `preferencias_notificacion`, tal como se pidió (el usuario ya existe, ya tiene rol asignado, y las notificaciones se excluyen).
2. Las tablas `movimientos → entrada/salida → (ahorros | ingresos | gastos | imprevistos | deudas)` están encadenadas con `WITH ... RETURNING` porque sus IDs se autogeneran (`SERIAL`) y las tablas hijas dependen de ese ID. Esto evita tener que adivinar o hardcodear IDs que podrían no coincidir con el estado real de tu base de datos.
3. Las referencias a categorías globales (`Alimentación`, `Transporte`, `Salario`, etc.) se resuelven por nombre con subconsultas, así no dependen de qué ID les haya tocado.
4. **`fondos_emergencia` tiene `id_usuario UNIQUE`**, por lo tanto un usuario solo puede tener **un** fondo de emergencia. Se inserta 1 fondo (no 5) y se compensa insertando 5 movimientos (`movimientos_fondo_emergencia`) asociados a ese fondo, que es donde realmente tiene sentido tener múltiples registros.
5. Se recomienda ejecutar los bloques en el orden en que aparecen (categorías y dependientes primero, ya que son referenciados después).

---

## 1. Categorías propias del usuario (`categorias`)

```sql
INSERT INTO categorias (id_usuario, nombre, descripcion, activa, sistema, es_global) VALUES
(4, 'Mascotas', 'Gastos relacionados con el cuidado de mascotas', TRUE, FALSE, FALSE),
(4, 'Suscripciones', 'Servicios de streaming, software y membresías', TRUE, FALSE, FALSE),
(4, 'Freelance', 'Ingresos por trabajos independientes', TRUE, FALSE, FALSE),
(4, 'Regalos', 'Gastos en regalos y celebraciones', TRUE, FALSE, FALSE),
(4, 'Inversiones', 'Rendimientos de inversiones personales', TRUE, FALSE, FALSE);
```

## 2. Dependientes (`dependientes`)

```sql
INSERT INTO dependientes (id_usuario, nombre, relacion, ocupacion, fecha_nacimiento, peso_economico) VALUES
(4, 'María Gómez', 'Hija', 'Estudiante', '2015-03-12', 5),
(4, 'Carlos Gómez', 'Hijo', 'Estudiante', '2018-07-22', 5),
(4, 'Rosa Pérez', 'Madre', 'Jubilada', '1958-11-05', 3),
(4, 'Luis Gómez', 'Padre', 'Jubilado', '1955-02-18', 3),
(4, 'Ana Torres', 'Cónyuge', 'Empleada', '1990-09-30', 4);
```

---

## 3. Ahorros (`movimientos` + `entrada` + `ahorros` + `abonos_ahorro`)

Cada bloque crea un movimiento tipo *Entrada/Ahorro*, su fila en `entrada`, el ahorro y, de una vez, un abono asociado a ese ahorro (así `abonos_ahorro` también queda con 5 registros).

```sql
WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ahorro') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
), ah AS (
    INSERT INTO ahorros (id_entrada, id_categoria, monto, monto_acumulado, descripcion, meta, fecha_registro, fecha_meta)
    SELECT id_entrada, NULL, 3000000, 900000, 'Ahorro para vacaciones familiares', 'Viaje a Cartagena', '2026-01-10', '2026-12-01'
    FROM ent RETURNING id_ahorros
)
INSERT INTO abonos_ahorro (id_ahorros, monto, fecha_registro)
SELECT id_ahorros, 300000, '2026-02-10' FROM ah;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ahorro') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
), ah AS (
    INSERT INTO ahorros (id_entrada, id_categoria, monto, monto_acumulado, descripcion, meta, fecha_registro, fecha_meta)
    SELECT id_entrada, NULL, 5000000, 1200000, 'Fondo para cuota inicial de vehículo', 'Carro nuevo', '2026-02-01', '2027-06-01'
    FROM ent RETURNING id_ahorros
)
INSERT INTO abonos_ahorro (id_ahorros, monto, fecha_registro)
SELECT id_ahorros, 500000, '2026-03-01' FROM ah;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ahorro') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
), ah AS (
    INSERT INTO ahorros (id_entrada, id_categoria, monto, monto_acumulado, descripcion, meta, fecha_registro, fecha_meta)
    SELECT id_entrada, (SELECT id_categoria FROM categorias WHERE nombre = 'Inversiones' AND id_usuario = 4), 2000000, 2000000, 'Ahorro completado para curso de especialización', 'Curso online', '2025-09-01', '2026-01-15'
    FROM ent RETURNING id_ahorros
)
INSERT INTO abonos_ahorro (id_ahorros, monto, fecha_registro)
SELECT id_ahorros, 2000000, '2026-01-15' FROM ah;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ahorro') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
), ah AS (
    INSERT INTO ahorros (id_entrada, id_categoria, monto, monto_acumulado, descripcion, meta, fecha_registro, fecha_meta)
    SELECT id_entrada, NULL, 1500000, 300000, 'Colchón financiero adicional', 'Reserva extra', '2026-03-05', NULL
    FROM ent RETURNING id_ahorros
)
INSERT INTO abonos_ahorro (id_ahorros, monto, fecha_registro)
SELECT id_ahorros, 150000, '2026-04-05' FROM ah;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ahorro') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
), ah AS (
    INSERT INTO ahorros (id_entrada, id_categoria, monto, monto_acumulado, descripcion, meta, fecha_registro, fecha_meta)
    SELECT id_entrada, NULL, 4000000, 500000, 'Ahorro navideño', 'Regalos y fin de año', '2026-01-20', '2026-12-15'
    FROM ent RETURNING id_ahorros
)
INSERT INTO abonos_ahorro (id_ahorros, monto, fecha_registro)
SELECT id_ahorros, 200000, '2026-02-20' FROM ah;
```

## 4. Ingresos (`movimientos` + `entrada` + `ingresos`)

```sql
WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ingreso') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
)
INSERT INTO ingresos (id_entrada, id_categoria, monto, descripcion, fuente, fecha_registro)
SELECT id_entrada, (SELECT id_categoria FROM categorias WHERE nombre = 'Salario' AND es_global = TRUE), 4500000, 'Pago de nómina mensual', 'Empresa ABC S.A.S.', '2026-01-30'
FROM ent;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ingreso') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
)
INSERT INTO ingresos (id_entrada, id_categoria, monto, descripcion, fuente, fecha_registro)
SELECT id_entrada, (SELECT id_categoria FROM categorias WHERE nombre = 'Freelance' AND id_usuario = 4), 1200000, 'Proyecto de desarrollo web', 'Cliente independiente', '2026-02-15'
FROM ent;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ingreso') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
)
INSERT INTO ingresos (id_entrada, id_categoria, monto, descripcion, fuente, fecha_registro)
SELECT id_entrada, (SELECT id_categoria FROM categorias WHERE nombre = 'Negocio' AND es_global = TRUE), 2800000, 'Ganancias del negocio propio', 'Tienda online', '2026-02-28'
FROM ent;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ingreso') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
)
INSERT INTO ingresos (id_entrada, id_categoria, monto, descripcion, fuente, fecha_registro)
SELECT id_entrada, (SELECT id_categoria FROM categorias WHERE nombre = 'Salario' AND es_global = TRUE), 4500000, 'Pago de nómina mensual', 'Empresa ABC S.A.S.', '2026-02-28'
FROM ent;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ingreso') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
)
INSERT INTO ingresos (id_entrada, id_categoria, monto, descripcion, fuente, fecha_registro)
SELECT id_entrada, NULL, 600000, 'Venta de artículos usados', 'Marketplace', '2026-03-10'
FROM ent;
```

## 5. Gastos (`movimientos` + `salida` + `gastos`)

```sql
WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Gasto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO gastos (id_salida, id_categoria, id_dependientes, monto, descripcion, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Alimentación' AND es_global = TRUE),
       NULL, 450000, 'Mercado del mes', '2026-01-05'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Gasto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO gastos (id_salida, id_categoria, id_dependientes, monto, descripcion, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Transporte' AND es_global = TRUE),
       NULL, 180000, 'Gasolina y peajes', '2026-01-12'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Gasto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO gastos (id_salida, id_categoria, id_dependientes, monto, descripcion, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Educación' AND es_global = TRUE),
       (SELECT id_dependientes FROM dependientes WHERE id_usuario = 4 AND nombre = 'María Gómez'),
       320000, 'Matrícula escolar', '2026-01-20'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Gasto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO gastos (id_salida, id_categoria, id_dependientes, monto, descripcion, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Mascotas' AND id_usuario = 4),
       NULL, 95000, 'Alimento y vacunas para la mascota', '2026-02-03'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Gasto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO gastos (id_salida, id_categoria, id_dependientes, monto, descripcion, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Vivienda' AND es_global = TRUE),
       (SELECT id_dependientes FROM dependientes WHERE id_usuario = 4 AND nombre = 'Rosa Pérez'),
       1100000, 'Arriendo mensual', '2026-02-05'
FROM sal;
```

## 6. Imprevistos (`movimientos` + `salida` + `imprevistos`)

```sql
WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Imprevisto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO imprevistos (id_salida, id_categoria, id_dependientes, monto, causa, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Salud' AND es_global = TRUE),
       (SELECT id_dependientes FROM dependientes WHERE id_usuario = 4 AND nombre = 'Carlos Gómez'),
       250000, 'Consulta médica de urgencia', '2026-01-08'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Imprevisto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO imprevistos (id_salida, id_categoria, id_dependientes, monto, causa, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Transporte' AND es_global = TRUE),
       NULL, 180000, 'Reparación mecánica del vehículo', '2026-01-25'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Imprevisto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO imprevistos (id_salida, id_categoria, id_dependientes, monto, causa, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Vivienda' AND es_global = TRUE),
       NULL, 400000, 'Daño en tubería del apartamento', '2026-02-10'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Imprevisto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO imprevistos (id_salida, id_categoria, id_dependientes, monto, causa, fecha_registro)
SELECT id_salida,
       NULL,
       (SELECT id_dependientes FROM dependientes WHERE id_usuario = 4 AND nombre = 'Luis Gómez'),
       150000, 'Medicamentos no cubiertos por seguro', '2026-02-18'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Imprevisto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO imprevistos (id_salida, id_categoria, id_dependientes, monto, causa, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Mascotas' AND id_usuario = 4),
       NULL, 90000, 'Emergencia veterinaria', '2026-03-02'
FROM sal;
```

## 7. Deudas (`movimientos` + `salida` + `deudas` + `abonos_deuda`)

Cada bloque crea la deuda y un abono asociado en el mismo `WITH`, para dejar `abonos_deuda` también con 5 registros.

```sql
WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Deuda') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
), deu AS (
    INSERT INTO deudas (id_salida, id_categoria, monto, fuente, descripcion, cuotas_total, cuotas_pagadas, fecha_inicio, fecha_fin, estado)
    SELECT id_salida, (SELECT id_categoria FROM categorias WHERE nombre = 'Vivienda' AND es_global = TRUE),
           15000000, 'Banco Nacional', 'Crédito hipotecario', 120, 12, '2025-01-01', '2035-01-01', 'pendiente'
    FROM sal RETURNING id_deudas
)
INSERT INTO abonos_deuda (id_deudas, cuotas, monto, fecha_registro, descripcion)
SELECT id_deudas, 1, 180000, '2026-01-01', 'Cuota mensual crédito hipotecario' FROM deu;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Deuda') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
), deu AS (
    INSERT INTO deudas (id_salida, id_categoria, monto, fuente, descripcion, cuotas_total, cuotas_pagadas, fecha_inicio, fecha_fin, estado)
    SELECT id_salida, (SELECT id_categoria FROM categorias WHERE nombre = 'Educación' AND es_global = TRUE),
           3000000, 'Universidad XYZ', 'Crédito educativo', 24, 6, '2025-06-01', '2027-06-01', 'pendiente'
    FROM sal RETURNING id_deudas
)
INSERT INTO abonos_deuda (id_deudas, cuotas, monto, fecha_registro, descripcion)
SELECT id_deudas, 1, 125000, '2026-01-15', 'Cuota crédito educativo' FROM deu;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Deuda') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
), deu AS (
    INSERT INTO deudas (id_salida, id_categoria, monto, fuente, descripcion, cuotas_total, cuotas_pagadas, fecha_inicio, fecha_fin, estado)
    SELECT id_salida, NULL,
           800000, 'Tarjeta de crédito Visa', 'Saldo pendiente tarjeta de crédito', NULL, 0, '2026-02-01', NULL, 'pendiente'
    FROM sal RETURNING id_deudas
)
INSERT INTO abonos_deuda (id_deudas, cuotas, monto, fecha_registro, descripcion)
SELECT id_deudas, 1, 200000, '2026-03-01', 'Pago parcial tarjeta de crédito' FROM deu;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Deuda') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
), deu AS (
    INSERT INTO deudas (id_salida, id_categoria, monto, fuente, descripcion, cuotas_total, cuotas_pagadas, fecha_inicio, fecha_fin, estado)
    SELECT id_salida, (SELECT id_categoria FROM categorias WHERE nombre = 'Salud' AND es_global = TRUE),
           1200000, 'Clínica particular', 'Préstamo por procedimiento médico', 12, 12, '2024-06-01', '2025-06-01', 'pagada'
    FROM sal RETURNING id_deudas
)
INSERT INTO abonos_deuda (id_deudas, cuotas, monto, fecha_registro, descripcion)
SELECT id_deudas, 1, 100000, '2025-06-01', 'Última cuota préstamo médico' FROM deu;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Deuda') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
), deu AS (
    INSERT INTO deudas (id_salida, id_categoria, monto, fuente, descripcion, cuotas_total, cuotas_pagadas, fecha_inicio, fecha_fin, estado)
    SELECT id_salida, NULL,
           2500000, 'Cooperativa de ahorro', 'Préstamo personal', 18, 3, '2026-01-01', '2027-07-01', 'pendiente'
    FROM sal RETURNING id_deudas
)
INSERT INTO abonos_deuda (id_deudas, cuotas, monto, fecha_registro, descripcion)
SELECT id_deudas, 1, 150000, '2026-02-01', 'Cuota préstamo personal' FROM deu;
```

## 8. Presupuestos (`presupuestos`)

> Nota: solo puede existir **un** presupuesto `activo = TRUE` por usuario (índice único parcial), por eso únicamente el primero queda activo. Todos los porcentajes suman exactamente 100, como exige la restricción `chk_porcentajes_total`.

```sql
INSERT INTO presupuestos (id_usuario, nombre, descripcion, activo, dia_corte, porcentaje_gastos, porcentaje_deudas, porcentaje_imprevistos, porcentaje_ahorros, porcentaje_emergencia) VALUES
(4, 'Presupuesto Principal', 'Presupuesto base mensual', TRUE, 5, 40.00, 20.00, 15.00, 10.00, 15.00),
(4, 'Presupuesto Ahorro Agresivo', 'Enfocado en maximizar ahorro', FALSE, 1, 35.00, 25.00, 10.00, 20.00, 10.00),
(4, 'Presupuesto Balanceado', 'Distribución equilibrada de gastos', FALSE, 15, 50.00, 10.00, 10.00, 15.00, 15.00),
(4, 'Presupuesto Familiar', 'Pensado para gastos con dependientes', FALSE, 28, 30.00, 30.00, 10.00, 20.00, 10.00),
(4, 'Presupuesto Conservador', 'Prioriza el fondo de emergencia', FALSE, 10, 45.00, 15.00, 15.00, 10.00, 15.00);
```

## 9. Periodos de presupuesto (`periodos_presupuesto`)

```sql
INSERT INTO periodos_presupuesto (id_presupuesto, id_usuario, fecha_inicio, fecha_fin, ingreso_estimado, ingreso_real, saldo_anterior, estado, monto_gastos, monto_deudas, monto_imprevistos, monto_ahorros, monto_emergencia)
SELECT id_presupuesto, 4, '2026-01-01', '2026-01-31', 4500000, 4500000, 0, 'cerrado', 1800000, 900000, 675000, 450000, 675000
FROM presupuestos WHERE id_usuario = 4 AND nombre = 'Presupuesto Principal';

INSERT INTO periodos_presupuesto (id_presupuesto, id_usuario, fecha_inicio, fecha_fin, ingreso_estimado, ingreso_real, saldo_anterior, estado, monto_gastos, monto_deudas, monto_imprevistos, monto_ahorros, monto_emergencia)
SELECT id_presupuesto, 4, '2026-02-01', '2026-02-28', 4500000, 4700000, 320000, 'cerrado', 1650000, 1175000, 470000, 940000, 470000
FROM presupuestos WHERE id_usuario = 4 AND nombre = 'Presupuesto Principal';

INSERT INTO periodos_presupuesto (id_presupuesto, id_usuario, fecha_inicio, fecha_fin, ingreso_estimado, ingreso_real, saldo_anterior, estado, monto_gastos, monto_deudas, monto_imprevistos, monto_ahorros, monto_emergencia)
SELECT id_presupuesto, 4, '2026-03-01', '2026-03-31', 4700000, 0, 150000, 'abierto', 2350000, 470000, 470000, 940000, 470000
FROM presupuestos WHERE id_usuario = 4 AND nombre = 'Presupuesto Principal';

INSERT INTO periodos_presupuesto (id_presupuesto, id_usuario, fecha_inicio, fecha_fin, ingreso_estimado, ingreso_real, saldo_anterior, estado, monto_gastos, monto_deudas, monto_imprevistos, monto_ahorros, monto_emergencia)
SELECT id_presupuesto, 4, '2026-01-01', '2026-01-31', 4500000, 4500000, 0, 'cerrado', 1575000, 1125000, 450000, 900000, 450000
FROM presupuestos WHERE id_usuario = 4 AND nombre = 'Presupuesto Ahorro Agresivo';

INSERT INTO periodos_presupuesto (id_presupuesto, id_usuario, fecha_inicio, fecha_fin, ingreso_estimado, ingreso_real, saldo_anterior, estado, monto_gastos, monto_deudas, monto_imprevistos, monto_ahorros, monto_emergencia)
SELECT id_presupuesto, 4, '2026-02-01', '2026-02-28', 4500000, 4450000, 0, 'cerrado', 1557500, 1112500, 445000, 890000, 445000
FROM presupuestos WHERE id_usuario = 4 AND nombre = 'Presupuesto Ahorro Agresivo';
```

## 10. Historial (`historial`)

```sql
INSERT INTO historial (id_usuario, accion, detalles, fecha) VALUES
(4, 'Inicio de sesión', 'El usuario inició sesión desde un nuevo dispositivo', '2026-01-01 08:15:00'),
(4, 'Creación de categoría', 'Se creó la categoría personalizada Mascotas', '2026-01-02 09:30:00'),
(4, 'Registro de gasto', 'Se registró un gasto en Alimentación por $450.000', '2026-01-05 12:00:00'),
(4, 'Actualización de presupuesto', 'Se activó el Presupuesto Principal', '2026-01-10 18:45:00'),
(4, 'Registro de ingreso', 'Se registró el ingreso de nómina mensual', '2026-01-30 10:00:00');
```

## 11. Fondo de emergencia (`fondos_emergencia` + `movimientos_fondo_emergencia`)

> Nota: `id_usuario` es `UNIQUE` en `fondos_emergencia`, así que un usuario solo puede tener **un** fondo. Se crea 1 fondo y 5 movimientos asociados a él.

```sql
INSERT INTO fondos_emergencia (id_usuario, meta, fecha_creacion) VALUES
(4, 6000000, '2026-01-01');

INSERT INTO movimientos_fondo_emergencia (id_fondo, tipo, monto, fecha_registro, descripcion)
SELECT id_fondo, 'aporte', 500000, '2026-01-05', 'Aporte inicial al fondo de emergencia'
FROM fondos_emergencia WHERE id_usuario = 4;

INSERT INTO movimientos_fondo_emergencia (id_fondo, tipo, monto, fecha_registro, descripcion)
SELECT id_fondo, 'aporte', 300000, '2026-02-05', 'Aporte mensual programado'
FROM fondos_emergencia WHERE id_usuario = 4;

INSERT INTO movimientos_fondo_emergencia (id_fondo, tipo, monto, fecha_registro, descripcion)
SELECT id_fondo, 'aporte', 300000, '2026-03-05', 'Aporte mensual programado'
FROM fondos_emergencia WHERE id_usuario = 4;

INSERT INTO movimientos_fondo_emergencia (id_fondo, tipo, monto, fecha_registro, descripcion)
SELECT id_fondo, 'retiro', 200000, '2026-02-20', 'Retiro por emergencia médica de un dependiente'
FROM fondos_emergencia WHERE id_usuario = 4;

INSERT INTO movimientos_fondo_emergencia (id_fondo, tipo, monto, fecha_registro, descripcion)
SELECT id_fondo, 'aporte', 400000, '2026-04-05', 'Aporte mensual programado'
FROM fondos_emergencia WHERE id_usuario = 4;
```

---

## Resumen de tablas cubiertas

| Tabla | Registros | Nota |
|---|---|---|
| categorias | 5 | propias del usuario 4 |
| dependientes | 5 | |
| movimientos | 25 | 5 por cada subtipo (Ahorro, Ingreso, Gasto, Imprevisto, Deuda) |
| entrada | 10 | 5 Ahorro + 5 Ingreso |
| salida | 15 | 5 Gasto + 5 Imprevisto + 5 Deuda |
| ahorros | 5 | |
| abonos_ahorro | 5 | 1 por ahorro |
| ingresos | 5 | |
| gastos | 5 | |
| imprevistos | 5 | |
| deudas | 5 | |
| abonos_deuda | 5 | 1 por deuda |
| presupuestos | 5 | solo 1 activo |
| periodos_presupuesto | 5 | |
| historial | 5 | |
| fondos_emergencia | 1 | limitado por UNIQUE(id_usuario) |
| movimientos_fondo_emergencia | 5 | |

Tablas excluidas a propósito: `usuarios`, `rol`, `usuarios_roles`, `notificaciones`, `preferencias_notificacion`.

# VALORES ACTUALES AL MISMO MES
Este script proporcionara los datos para realizar pruebas de un mismo periodo dentro del mismo mes:

```body
-- ========================================================================
-- DATOS DE PRUEBA (INSERTs) - USUARIO ID 4 - SET 2 (valores distintos al set anterior)
-- Fechas entre el 01 y el 16 de septiembre de 2026
-- No incluye: usuarios, rol, usuarios_roles, notificaciones, preferencias_notificacion,
--             presupuestos, periodos_presupuesto
-- ========================================================================

-- ========================================================================
-- 1. CATEGORÍAS PROPIAS DEL USUARIO (nombres distintos al set anterior)
-- ========================================================================
INSERT INTO categorias (id_usuario, nombre, descripcion, activa, sistema, es_global) VALUES
(4, 'Tecnología', 'Compra de dispositivos y accesorios electrónicos', TRUE, FALSE, FALSE),
(4, 'Viajes', 'Tiquetes, hospedaje y gastos de viaje', TRUE, FALSE, FALSE),
(4, 'Deportes', 'Membresías de gimnasio e implementos deportivos', TRUE, FALSE, FALSE),
(4, 'Belleza', 'Cuidado personal y estética', TRUE, FALSE, FALSE),
(4, 'Hogar', 'Muebles, decoración y mantenimiento del hogar', TRUE, FALSE, FALSE);

-- ========================================================================
-- 2. DEPENDIENTES (nombres distintos al set anterior)
-- ========================================================================
INSERT INTO dependientes (id_usuario, nombre, relacion, ocupacion, fecha_nacimiento, peso_economico) VALUES
(4, 'Sofía Ramírez', 'Hija', 'Estudiante', '2016-05-20', 5),
(4, 'Pedro Ramírez', 'Hijo', 'Estudiante', '2019-11-08', 5),
(4, 'Elena Torres', 'Madre', 'Jubilada', '1960-04-14', 3),
(4, 'Jorge Torres', 'Padre', 'Jubilado', '1957-08-27', 3),
(4, 'Laura Méndez', 'Pareja', 'Empleada', '1992-06-15', 4);

-- ========================================================================
-- 3. AHORROS (movimientos + entrada + ahorros + abonos_ahorro)
-- ========================================================================
WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ahorro') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
), ah AS (
    INSERT INTO ahorros (id_entrada, id_categoria, monto, monto_acumulado, descripcion, meta, fecha_registro, fecha_meta)
    SELECT id_entrada, NULL, 2200000, 600000, 'Ahorro para renovar el computador', 'Nuevo portátil', '2026-09-02', '2026-11-01'
    FROM ent RETURNING id_ahorros
)
INSERT INTO abonos_ahorro (id_ahorros, monto, fecha_registro)
SELECT id_ahorros, 220000, '2026-09-06' FROM ah;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ahorro') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
), ah AS (
    INSERT INTO ahorros (id_entrada, id_categoria, monto, monto_acumulado, descripcion, meta, fecha_registro, fecha_meta)
    SELECT id_entrada, (SELECT id_categoria FROM categorias WHERE nombre = 'Viajes' AND id_usuario = 4), 6000000, 1500000, 'Ahorro para viaje internacional', 'Viaje a Europa', '2026-09-03', '2027-07-01'
    FROM ent RETURNING id_ahorros
)
INSERT INTO abonos_ahorro (id_ahorros, monto, fecha_registro)
SELECT id_ahorros, 600000, '2026-09-09' FROM ah;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ahorro') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
), ah AS (
    INSERT INTO ahorros (id_entrada, id_categoria, monto, monto_acumulado, descripcion, meta, fecha_registro, fecha_meta)
    SELECT id_entrada, NULL, 900000, 900000, 'Ahorro completado para bicicleta', 'Bicicleta de montaña', '2026-09-01', '2026-09-14'
    FROM ent RETURNING id_ahorros
)
INSERT INTO abonos_ahorro (id_ahorros, monto, fecha_registro)
SELECT id_ahorros, 900000, '2026-09-14' FROM ah;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ahorro') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
), ah AS (
    INSERT INTO ahorros (id_entrada, id_categoria, monto, monto_acumulado, descripcion, meta, fecha_registro, fecha_meta)
    SELECT id_entrada, NULL, 3500000, 400000, 'Ahorro para remodelar la sala', 'Remodelación hogar', '2026-09-05', '2027-01-15'
    FROM ent RETURNING id_ahorros
)
INSERT INTO abonos_ahorro (id_ahorros, monto, fecha_registro)
SELECT id_ahorros, 350000, '2026-09-11' FROM ah;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ahorro') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
), ah AS (
    INSERT INTO ahorros (id_entrada, id_categoria, monto, monto_acumulado, descripcion, meta, fecha_registro, fecha_meta)
    SELECT id_entrada, NULL, 1800000, 200000, 'Fondo para gastos de matrícula del próximo semestre', 'Matrícula universitaria', '2026-09-08', '2027-01-20'
    FROM ent RETURNING id_ahorros
)
INSERT INTO abonos_ahorro (id_ahorros, monto, fecha_registro)
SELECT id_ahorros, 180000, '2026-09-15' FROM ah;

-- ========================================================================
-- 4. INGRESOS (movimientos + entrada + ingresos)
-- ========================================================================
WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ingreso') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
)
INSERT INTO ingresos (id_entrada, id_categoria, monto, descripcion, fuente, fecha_registro)
SELECT id_entrada, (SELECT id_categoria FROM categorias WHERE nombre = 'Negocio' AND es_global = TRUE), 3200000, 'Ganancias por venta de productos artesanales', 'Emprendimiento propio', '2026-09-02'
FROM ent;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ingreso') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
)
INSERT INTO ingresos (id_entrada, id_categoria, monto, descripcion, fuente, fecha_registro)
SELECT id_entrada, NULL, 850000, 'Comisión por referido de un servicio', 'Programa de referidos', '2026-09-04'
FROM ent;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ingreso') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
)
INSERT INTO ingresos (id_entrada, id_categoria, monto, descripcion, fuente, fecha_registro)
SELECT id_entrada, (SELECT id_categoria FROM categorias WHERE nombre = 'Salario' AND es_global = TRUE), 3900000, 'Pago quincenal de nómina', 'Empresa Tech Solutions', '2026-09-07'
FROM ent;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ingreso') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
)
INSERT INTO ingresos (id_entrada, id_categoria, monto, descripcion, fuente, fecha_registro)
SELECT id_entrada, NULL, 1500000, 'Reembolso de gastos médicos por parte de la EPS', 'EPS Sanitas', '2026-09-10'
FROM ent;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Entrada', 'Ingreso') RETURNING id_movimiento
), ent AS (
    INSERT INTO entrada (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_entrada
)
INSERT INTO ingresos (id_entrada, id_categoria, monto, descripcion, fuente, fecha_registro)
SELECT id_entrada, (SELECT id_categoria FROM categorias WHERE nombre = 'Negocio' AND es_global = TRUE), 2100000, 'Pago por asesoría profesional', 'Consultoría independiente', '2026-09-13'
FROM ent;

-- ========================================================================
-- 5. GASTOS (movimientos + salida + gastos)
-- ========================================================================
WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Gasto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO gastos (id_salida, id_categoria, id_dependientes, monto, descripcion, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Servicios' AND es_global = TRUE),
       NULL, 220000, 'Pago de servicios públicos (agua, luz, gas)', '2026-09-03'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Gasto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO gastos (id_salida, id_categoria, id_dependientes, monto, descripcion, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Entretenimiento' AND es_global = TRUE),
       NULL, 130000, 'Salida al cine y cena en familia', '2026-09-06'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Gasto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO gastos (id_salida, id_categoria, id_dependientes, monto, descripcion, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Tecnología' AND id_usuario = 4),
       NULL, 780000, 'Compra de audífonos inalámbricos', '2026-09-08'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Gasto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO gastos (id_salida, id_categoria, id_dependientes, monto, descripcion, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Hogar' AND id_usuario = 4),
       (SELECT id_dependientes FROM dependientes WHERE id_usuario = 4 AND nombre = 'Elena Torres'),
       540000, 'Compra de electrodoméstico para el hogar', '2026-09-11'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Gasto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO gastos (id_salida, id_categoria, id_dependientes, monto, descripcion, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Deportes' AND id_usuario = 4),
       (SELECT id_dependientes FROM dependientes WHERE id_usuario = 4 AND nombre = 'Pedro Ramírez'),
       160000, 'Inscripción a escuela de fútbol', '2026-09-14'
FROM sal;

-- ========================================================================
-- 6. IMPREVISTOS (movimientos + salida + imprevistos)
-- ========================================================================
WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Imprevisto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO imprevistos (id_salida, id_categoria, id_dependientes, monto, causa, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Hogar' AND id_usuario = 4),
       NULL, 320000, 'Daño en el sistema eléctrico de la casa', '2026-09-01'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Imprevisto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO imprevistos (id_salida, id_categoria, id_dependientes, monto, causa, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Salud' AND es_global = TRUE),
       (SELECT id_dependientes FROM dependientes WHERE id_usuario = 4 AND nombre = 'Jorge Torres'),
       410000, 'Hospitalización de emergencia', '2026-09-05'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Imprevisto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO imprevistos (id_salida, id_categoria, id_dependientes, monto, causa, fecha_registro)
SELECT id_salida,
       NULL,
       NULL, 95000, 'Multa de tránsito inesperada', '2026-09-08'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Imprevisto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO imprevistos (id_salida, id_categoria, id_dependientes, monto, causa, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Tecnología' AND id_usuario = 4),
       NULL, 260000, 'Reparación urgente del portátil de trabajo', '2026-09-12'
FROM sal;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Imprevisto') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
)
INSERT INTO imprevistos (id_salida, id_categoria, id_dependientes, monto, causa, fecha_registro)
SELECT id_salida,
       (SELECT id_categoria FROM categorias WHERE nombre = 'Vivienda' AND es_global = TRUE),
       (SELECT id_dependientes FROM dependientes WHERE id_usuario = 4 AND nombre = 'Sofía Ramírez'),
       175000, 'Pérdida de llaves y cambio de cerradura', '2026-09-15'
FROM sal;

-- ========================================================================
-- 7. DEUDAS (movimientos + salida + deudas + abonos_deuda)
-- ========================================================================
WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Deuda') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
), deu AS (
    INSERT INTO deudas (id_salida, id_categoria, monto, fuente, descripcion, cuotas_total, cuotas_pagadas, fecha_inicio, fecha_fin, estado)
    SELECT id_salida, (SELECT id_categoria FROM categorias WHERE nombre = 'Tecnología' AND id_usuario = 4),
           2400000, 'Financiera Sistecrédito', 'Crédito para compra de computador', 12, 4, '2026-06-01', '2027-06-01', 'pendiente'
    FROM sal RETURNING id_deudas
)
INSERT INTO abonos_deuda (id_deudas, cuotas, monto, fecha_registro, descripcion)
SELECT id_deudas, 1, 200000, '2026-09-01', 'Cuota mensual crédito computador' FROM deu;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Deuda') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
), deu AS (
    INSERT INTO deudas (id_salida, id_categoria, monto, fuente, descripcion, cuotas_total, cuotas_pagadas, fecha_inicio, fecha_fin, estado)
    SELECT id_salida, NULL,
           1600000, 'Tarjeta de crédito Mastercard', 'Saldo pendiente por compras a cuotas', NULL, 0, '2026-09-03', NULL, 'pendiente'
    FROM sal RETURNING id_deudas
)
INSERT INTO abonos_deuda (id_deudas, cuotas, monto, fecha_registro, descripcion)
SELECT id_deudas, 1, 300000, '2026-09-04', 'Abono a tarjeta de crédito' FROM deu;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Deuda') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
), deu AS (
    INSERT INTO deudas (id_salida, id_categoria, monto, fuente, descripcion, cuotas_total, cuotas_pagadas, fecha_inicio, fecha_fin, estado)
    SELECT id_salida, (SELECT id_categoria FROM categorias WHERE nombre = 'Hogar' AND id_usuario = 4),
           4500000, 'Almacén Éxito', 'Crédito para compra de muebles', 10, 10, '2025-11-01', '2026-09-01', 'pagada'
    FROM sal RETURNING id_deudas
)
INSERT INTO abonos_deuda (id_deudas, cuotas, monto, fecha_registro, descripcion)
SELECT id_deudas, 1, 450000, '2026-09-01', 'Última cuota crédito de muebles' FROM deu;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Deuda') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
), deu AS (
    INSERT INTO deudas (id_salida, id_categoria, monto, fuente, descripcion, cuotas_total, cuotas_pagadas, fecha_inicio, fecha_fin, estado)
    SELECT id_salida, (SELECT id_categoria FROM categorias WHERE nombre = 'Educación' AND es_global = TRUE),
           1800000, 'Instituto Técnico', 'Crédito por curso de certificación', 6, 2, '2026-07-01', '2027-01-01', 'pendiente'
    FROM sal RETURNING id_deudas
)
INSERT INTO abonos_deuda (id_deudas, cuotas, monto, fecha_registro, descripcion)
SELECT id_deudas, 1, 300000, '2026-09-07', 'Cuota curso de certificación' FROM deu;

WITH mov AS (
    INSERT INTO movimientos (id_usuario, tipo_flujo, subtipo_modulo)
    VALUES (4, 'Salida', 'Deuda') RETURNING id_movimiento
), sal AS (
    INSERT INTO salida (id_movimiento)
    SELECT id_movimiento FROM mov RETURNING id_salida
), deu AS (
    INSERT INTO deudas (id_salida, id_categoria, monto, fuente, descripcion, cuotas_total, cuotas_pagadas, fecha_inicio, fecha_fin, estado)
    SELECT id_salida, NULL,
           950000, 'Préstamo entre amigos', 'Préstamo informal para gastos personales', 4, 1, '2026-09-10', '2027-01-10', 'pendiente'
    FROM sal RETURNING id_deudas
)
INSERT INTO abonos_deuda (id_deudas, cuotas, monto, fecha_registro, descripcion)
SELECT id_deudas, 1, 237500, '2026-09-13', 'Primera cuota del préstamo informal' FROM deu;

-- ========================================================================
-- 8. HISTORIAL (acciones distintas al set anterior)
-- ========================================================================
INSERT INTO historial (id_usuario, accion, detalles, fecha) VALUES
(4, 'Creación de dependiente', 'Se agregó a Sofía Ramírez como dependiente', '2026-09-02 09:00:00'),
(4, 'Registro de deuda', 'Se registró una deuda por compra de computador a crédito', '2026-09-04 14:20:00'),
(4, 'Registro de imprevisto', 'Se registró un imprevisto por daño eléctrico en el hogar', '2026-09-05 19:10:00'),
(4, 'Actualización de perfil', 'El usuario actualizó su información de contacto', '2026-09-09 11:05:00'),
(4, 'Cierre de sesión', 'El usuario cerró sesión manualmente', '2026-09-15 21:40:00');

-- ========================================================================
-- 9. FONDO DE EMERGENCIA
-- NOTA: id_usuario es UNIQUE en fondos_emergencia, por lo que el usuario 4
-- ya cuenta con un único fondo creado en el set anterior. No se vuelve a
-- insertar en fondos_emergencia; solo se agregan nuevos movimientos
-- (aportes/retiros) distintos sobre ese mismo fondo existente.
-- ========================================================================
INSERT INTO movimientos_fondo_emergencia (id_fondo, tipo, monto, fecha_registro, descripcion)
SELECT id_fondo, 'aporte', 250000, '2026-09-02', 'Aporte extra por bono laboral'
FROM fondos_emergencia WHERE id_usuario = 4;

INSERT INTO movimientos_fondo_emergencia (id_fondo, tipo, monto, fecha_registro, descripcion)
SELECT id_fondo, 'retiro', 150000, '2026-09-06', 'Retiro para cubrir imprevisto eléctrico'
FROM fondos_emergencia WHERE id_usuario = 4;

INSERT INTO movimientos_fondo_emergencia (id_fondo, tipo, monto, fecha_registro, descripcion)
SELECT id_fondo, 'aporte', 350000, '2026-09-09', 'Aporte quincenal programado'
FROM fondos_emergencia WHERE id_usuario = 4;

INSERT INTO movimientos_fondo_emergencia (id_fondo, tipo, monto, fecha_registro, descripcion)
SELECT id_fondo, 'retiro', 100000, '2026-09-12', 'Retiro para gastos médicos menores'
FROM fondos_emergencia WHERE id_usuario = 4;

INSERT INTO movimientos_fondo_emergencia (id_fondo, tipo, monto, fecha_registro, descripcion)
SELECT id_fondo, 'aporte', 300000, '2026-09-16', 'Aporte de cierre de quincena'
FROM fondos_emergencia WHERE id_usuario = 4;
```


## SCRIPTS EXTRA
```body
-- ========================================================================
-- 9. PERIODOS DE PRESUPUESTO
-- ========================================================================
INSERT INTO periodos_presupuesto (id_presupuesto, id_usuario, fecha_inicio, fecha_fin, ingreso_estimado, ingreso_real, saldo_anterior, estado, monto_gastos, monto_deudas, monto_imprevistos, monto_ahorros, monto_emergencia)
SELECT id_presupuesto, 4, '2026-09-01', '2026-09-16', 4500000, 4500000, 0, 'abierto', 1800000, 900000, 675000, 450000, 675000
FROM presupuestos WHERE id_usuario = 4 AND nombre = 'Presupuesto Principal';

INSERT INTO periodos_presupuesto (id_presupuesto, id_usuario, fecha_inicio, fecha_fin, ingreso_estimado, ingreso_real, saldo_anterior, estado, monto_gastos, monto_deudas, monto_imprevistos, monto_ahorros, monto_emergencia)
SELECT id_presupuesto, 4, '2026-09-01', '2026-09-10', 4500000, 4700000, 320000, 'cerrado', 1650000, 1175000, 470000, 940000, 470000
FROM presupuestos WHERE id_usuario = 4 AND nombre = 'Presupuesto Principal';

INSERT INTO periodos_presupuesto (id_presupuesto, id_usuario, fecha_inicio, fecha_fin, ingreso_estimado, ingreso_real, saldo_anterior, estado, monto_gastos, monto_deudas, monto_imprevistos, monto_ahorros, monto_emergencia)
SELECT id_presupuesto, 4, '2026-09-05', '2026-09-15', 4700000, 0, 150000, 'abierto', 2350000, 470000, 470000, 940000, 470000
FROM presupuestos WHERE id_usuario = 4 AND nombre = 'Presupuesto Principal';

INSERT INTO periodos_presupuesto (id_presupuesto, id_usuario, fecha_inicio, fecha_fin, ingreso_estimado, ingreso_real, saldo_anterior, estado, monto_gastos, monto_deudas, monto_imprevistos, monto_ahorros, monto_emergencia)
SELECT id_presupuesto, 4, '2026-09-02', '2026-09-16', 4500000, 4500000, 0, 'abierto', 1575000, 1125000, 450000, 900000, 450000
FROM presupuestos WHERE id_usuario = 4 AND nombre = 'Presupuesto Ahorro Agresivo';

INSERT INTO periodos_presupuesto (id_presupuesto, id_usuario, fecha_inicio, fecha_fin, ingreso_estimado, ingreso_real, saldo_anterior, estado, monto_gastos, monto_deudas, monto_imprevistos, monto_ahorros, monto_emergencia)
SELECT id_presupuesto, 4, '2026-09-01', '2026-09-14', 4500000, 4450000, 0, 'abierto', 1557500, 1112500, 445000, 890000, 445000
FROM presupuestos WHERE id_usuario = 4 AND nombre = 'Presupuesto Ahorro Agresivo';

-- ========================================================================
-- 8. PRESUPUESTOS
-- Solo puede existir un presupuesto activo = TRUE por usuario (índice único parcial)
-- ========================================================================
INSERT INTO presupuestos (id_usuario, nombre, descripcion, activo, dia_corte, porcentaje_gastos, porcentaje_deudas, porcentaje_imprevistos, porcentaje_ahorros, porcentaje_emergencia) VALUES
(4, 'Presupuesto Principal', 'Presupuesto base mensual', TRUE, 5, 40.00, 20.00, 15.00, 10.00, 15.00),
(4, 'Presupuesto Ahorro Agresivo', 'Enfocado en maximizar ahorro', FALSE, 1, 35.00, 25.00, 10.00, 20.00, 10.00),
(4, 'Presupuesto Balanceado', 'Distribución equilibrada de gastos', FALSE, 15, 50.00, 10.00, 10.00, 15.00, 15.00),
(4, 'Presupuesto Familiar', 'Pensado para gastos con dependientes', FALSE, 28, 30.00, 30.00, 10.00, 20.00, 10.00),
(4, 'Presupuesto Conservador', 'Prioriza el fondo de emergencia', FALSE, 10, 45.00, 15.00, 15.00, 10.00, 15.00);



```