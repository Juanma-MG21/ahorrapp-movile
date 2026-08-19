# Plan de Implementación - Corrección Crítica de Procesamiento de Voz

Se corregirá el error donde los montos con símbolos (ej: "$12.000") no son detectados como números y terminan apareciendo en la descripción. Se simplificará y robustecerá el motor de análisis.

## Proposed Changes

### [Services]

#### [MODIFY] [voice_parser_service.dart](file:///C:/ahorrappmovil/ahorrapp-movile/lib/services/voice_parser_service.dart)

1.  **Limpieza Previa de Símbolos**:
    *   Antes de cualquier procesamiento, eliminar el signo "$" y normalizar los puntos/comas de miles para que no interfieran con la detección numérica.

2.  **Detección de Montos Robusta**:
    *   Modificar `_extractAmount` para que limpie cada palabra de símbolos no numéricos antes de evaluarla.
    *   Asegurar que la detección de dígitos sea prioritaria y maneje formatos mixtos (ej: "$12 mil").

3.  **Lógica de Descripción Inteligente**:
    *   Mejorar el filtrado palabra por palabra para que cualquier cosa que parezca un número (incluso con símbolos) sea descartada de la descripción.
    *   Ajustar el fallback: si la descripción queda vacía tras quitar el monto, usar el nombre de la categoría en lugar del texto original sucio.

## Verification Plan

### Manual Verification
1.  **Caso Símbolo**: Decir "$12,000".
    *   *Resultado esperado*: Monto 12000, Descripción vacía o nombre de categoría.
2.  **Caso Frase con Símbolo**: Decir "Empanada de $3.500".
    *   *Resultado esperado*: Monto 3500, Descripción "Empanada".
3.  **Caso "Diez mil"**: Decir "diez mil pesos".
    *   *Resultado esperado*: Monto 10000, Descripción vacía o nombre de categoría.
