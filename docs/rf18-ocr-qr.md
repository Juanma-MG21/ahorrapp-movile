# RF-18: gastos mediante OCR y QR

Corrección realizada en la rama David-M.

Los parsers OCR y QR comparten reglas en ReceiptParserService: priorizan el total frente al subtotal, reconocen montos pequeños y separadores de miles/decimales, y no usan referencias o números de una URL como montos. Se admiten textos de comprobantes con etiquetas monetarias o símbolo de moneda; los enlaces de verificación se rechazan para solicitar entrada manual. No se consultan sitios externos ni se afirma soporte universal para QR de Nequi/Daviplata.

Ambos reconocen fechas dd/mm/yyyy, dd-mm-yyyy y yyyy-mm-dd (también con barras). Se descartan fechas inexistentes comparando los componentes tras construir DateTime. Cuando falta una fecha válida se propone hoy; el formulario muestra una indicación para revisar los datos antes de guardar. La categoría solo se sugiere cuando coincide una palabra clave, sin asignar General automáticamente.

El formulario permite corregir día, mes y año con el selector de fecha de Flutter. Conserva el límite de fechas hasta hoy. El monto y la descripción son editables; los escáneres abren el formulario y no crean movimientos automáticamente.

Validación: test/rf18_test.dart prueba extracción de total/fecha/comercio, decimales, montos pequeños, referencias, URLs, categorías y fechas imposibles. test/rf18_form_test.dart prueba que un gasto obtenido por QR no se envía antes de guardar y que las correcciones de monto, descripción, mes y año llegan a POST /movimientos con un cliente simulado.

Limitación: estas pruebas no verifican cámara, permisos, calidad del reconocimiento de una foto, QR reales de proveedores ni persistencia en una base de datos. Se requiere una prueba con dispositivo y sesión real para validar ese recorrido completo.
