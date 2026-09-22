import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../models/categorias_model.dart';
import '../../services/categorias_service.dart';
import '../../core/theme/app_theme.dart'; // ajusta la ruta si la carpeta es distinta
import '../../core/theme/design_tokens.dart';
class AgregarCategoriaScreen extends StatefulWidget {
  // Igual que en dependientes: si viene null, el formulario está en
  // modo "crear"; si trae una categoría, está en modo "editar".
  final CategoriaModel? categoriaParaEditar;

  const AgregarCategoriaScreen({
    super.key,
    this.categoriaParaEditar,
  });

  @override
  State<AgregarCategoriaScreen> createState() =>
      _AgregarCategoriaScreenState();
}

class _AgregarCategoriaScreenState extends State<AgregarCategoriaScreen> {
  // `CategoriasService` no es estático, así que aquí SÍ necesitamos
  // crear una instancia (a diferencia de `DependientesService`, que
  // llamábamos directo sobre la clase). Se crea una sola vez, cuando
  // se construye el estado del widget.
  final _service = CategoriasService();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final categoria = widget.categoriaParaEditar;

    // Si estamos editando, precargamos los campos con los datos
    // actuales — igual que hacía `agregar_dependientes_screen.dart`.
    if (categoria != null) {
      _nombreController.text = categoria.nombre;
      // `descripcion` es `String?` en el modelo; `?? ''` evita poner
      // el texto "null" dentro del campo si viene vacío.
      _descripcionController.text = categoria.descripcion ?? '';
    }
  }

  @override
  void dispose() {
    // Siempre hay que liberar los controllers cuando el widget se
    // destruye — si no, quedan "vivos" en memoria innecesariamente
    // (el equivalente a no limpiar un listener en JS).
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // GUARDAR
  // ─────────────────────────────────────────────

  Future<void> _guardarCategoria() async {
    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();

    // Validación mínima: el backend también la exige
    // (`if (!nombre?.trim())` en el controller), pero validar aquí
    // primero evita una llamada HTTP innecesaria si el campo está
    // vacío.
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el nombre de la categoría'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final idExistente = widget.categoriaParaEditar?.id;

      if (idExistente == null) {
        // Modo crear. El service espera `descripcion` como
        // `required String` (no nullable) en `crearCategoria`, así
        // que mandamos el string vacío si el usuario no escribió
        // nada — el backend igual lo convierte a `null` con su
        // propio `descripcion?.trim() || null`.
        await _service.crearCategoria(
          nombre: nombre,
          descripcion: descripcion,
        );
      } else {
        // Modo editar. Aquí sí el parámetro es `String?`, así que
        // mandamos `null` explícito si quedó vacío, para que quede
        // claro que se está borrando la descripción y no guardando
        // un string vacío por accidente.
        await _service.editarCategoria(
          idExistente,
          nombre: nombre,
          descripcion: descripcion.isEmpty ? null : descripcion,
        );
      }

      // `!mounted` chequea que el widget siga en pantalla antes de
      // tocar `context` o `setState` — importante en operaciones
      // async, porque el usuario pudo haber cerrado la pantalla
      // mientras esperábamos la respuesta del servidor.
      if (!mounted) return;

      setState(() => _isSaving = false);

      // A diferencia de dependientes (donde reconstruíamos el modelo
      // completo con el id nuevo), aquí simplemente le avisamos a
      // quien nos abrió que "algo cambió" pasando `true`. La pantalla
      // de lista puede usar eso como señal para recargar, sin
      // necesitar el objeto completo.
      Navigator.pop(context, true);
    } catch (e) {
      // `CategoriasService` lanza `Exception` genérica (no
      // `ApiException`), así que aquí basta un solo `catch`. `e` en
      // este punto es un objeto `Exception`; `e.toString()` incluye
      // el prefijo "Exception: " — por eso lo quito con `replaceFirst`
      // para mostrar solo el mensaje real que viene del backend.
      if (!mounted) return;

      setState(() => _isSaving = false);

      final mensaje = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final editando = widget.categoriaParaEditar != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(editando),
              const SizedBox(height: 26),
              _buildFormCard(),
              const SizedBox(height: 28),
              _buildGuardarButton(editando),
              const SizedBox(height: 12),
              _buildCancelarButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool editando) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(Icons.arrow_back,
                size: 20, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editando ? 'Editar categoría' : 'Nueva categoría',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              editando ? 'Modificar información' : 'Registrar nueva categoría',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: clayRaised(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Nombre', required: true),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nombreController,
            hint: 'Ej: Transporte',
          ),
          const SizedBox(height: 18),
          _buildLabel('Descripción'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _descripcionController,
            hint: 'Ej: Gastos de bus, taxi, gasolina...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: claySunken(),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGuardarButton(bool editando) {
    return GestureDetector(
      onTap: _isSaving ? null : _guardarCategoria,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: clayGlow(),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                editando ? 'Guardar cambios' : 'Guardar categoría',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildCancelarButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Text(
          'Cancelar',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}