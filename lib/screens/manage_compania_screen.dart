import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/compania.dart';
import '../services/firebase_service.dart';

class ManageCompaniaScreen extends StatefulWidget {
  final Compania? compania;

  const ManageCompaniaScreen({super.key, this.compania});

  @override
  State<ManageCompaniaScreen> createState() => _ManageCompaniaScreenState();
}

class _ManageCompaniaScreenState extends State<ManageCompaniaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _emailSiniestrosController;
  late TextEditingController _webController;
  late TextEditingController _notasController;
  late TextEditingController _agenteSeguroController;
  late TextEditingController _telefonoAgenteController;
  late TextEditingController _personaContactoController;

  final _uuid = const Uuid();

  bool get _isEditing => widget.compania != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.compania?.nombre ?? '');
    _telefonoController = TextEditingController(text: widget.compania?.telefono ?? '');
    _emailController = TextEditingController(text: widget.compania?.email ?? '');
    _emailSiniestrosController = TextEditingController(text: widget.compania?.emailSiniestros ?? '');
    _webController = TextEditingController(text: widget.compania?.web ?? '');
    _notasController = TextEditingController(text: widget.compania?.notas ?? '');
    _agenteSeguroController = TextEditingController(text: widget.compania?.agenteSeguro ?? '');
    _telefonoAgenteController = TextEditingController(text: widget.compania?.telefonoAgente ?? '');
    _personaContactoController = TextEditingController(text: widget.compania?.personaContacto ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _emailSiniestrosController.dispose();
    _webController.dispose();
    _notasController.dispose();
    _agenteSeguroController.dispose();
    _telefonoAgenteController.dispose();
    _personaContactoController.dispose();
    super.dispose();
  }

  Future<void> _saveCompania() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isEditing) {
      // Actualizar compañía existente
      widget.compania!.nombre = _nombreController.text;
      widget.compania!.telefono = _telefonoController.text.isEmpty ? null : _telefonoController.text;
      widget.compania!.email = _emailController.text.isEmpty ? null : _emailController.text;
      widget.compania!.emailSiniestros = _emailSiniestrosController.text.isEmpty ? null : _emailSiniestrosController.text;
      widget.compania!.web = _webController.text.isEmpty ? null : _webController.text;
      widget.compania!.notas = _notasController.text.isEmpty ? null : _notasController.text;
      widget.compania!.agenteSeguro = _agenteSeguroController.text.isEmpty ? null : _agenteSeguroController.text;
      widget.compania!.telefonoAgente = _telefonoAgenteController.text.isEmpty ? null : _telefonoAgenteController.text;
      widget.compania!.personaContacto = _personaContactoController.text.isEmpty ? null : _personaContactoController.text;

      await widget.compania!.save();
    } else {
      // Crear nueva compañía
      final compania = Compania(
        id: _uuid.v4(),
        nombre: _nombreController.text,
        telefono: _telefonoController.text.isEmpty ? null : _telefonoController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        emailSiniestros: _emailSiniestrosController.text.isEmpty ? null : _emailSiniestrosController.text,
        web: _webController.text.isEmpty ? null : _webController.text,
        notas: _notasController.text.isEmpty ? null : _notasController.text,
        agenteSeguro: _agenteSeguroController.text.isEmpty ? null : _agenteSeguroController.text,
        telefonoAgente: _telefonoAgenteController.text.isEmpty ? null : _telefonoAgenteController.text,
        personaContacto: _personaContactoController.text.isEmpty ? null : _personaContactoController.text,
      );

      await FirebaseService.addCompania(compania);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Compañía actualizada correctamente' : 'Compañía creada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteCompania() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Compañía'),
        content: const Text('¿Estás seguro de que deseas eliminar esta compañía aseguradora?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.compania!.delete();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compañía eliminada'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Aseguradora' : 'Nueva Aseguradora',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _deleteCompania,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información básica
              const Text(
                'Información Básica',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la Aseguradora *',
                  hintText: 'Ej: MAPFRE Seguros',
                  prefixIcon: const Icon(Icons.shield),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, introduce el nombre';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Datos de contacto
              const Text(
                'Datos de Contacto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  hintText: 'Ej: 900 123 456',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Email general
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email General',
                  hintText: 'info@aseguradora.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Email siniestros
              TextFormField(
                controller: _emailSiniestrosController,
                decoration: InputDecoration(
                  labelText: 'Email Siniestros',
                  hintText: 'siniestros@aseguradora.com',
                  prefixIcon: const Icon(Icons.mark_email_read),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: 'Email específico para comunicar siniestros',
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Web
              TextFormField(
                controller: _webController,
                decoration: InputDecoration(
                  labelText: 'Página Web',
                  hintText: 'www.aseguradora.com',
                  prefixIcon: const Icon(Icons.public),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 24),

              // Información del Agente
              const Text(
                'Información del Agente/Contacto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Agente de Seguro
              TextFormField(
                controller: _agenteSeguroController,
                decoration: InputDecoration(
                  labelText: 'Agente de Seguro',
                  hintText: 'Nombre del agente asignado',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 16),

              // Teléfono del Agente
              TextFormField(
                controller: _telefonoAgenteController,
                decoration: InputDecoration(
                  labelText: 'Teléfono del Agente',
                  hintText: 'Ej: 600 123 456',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Persona de Contacto
              TextFormField(
                controller: _personaContactoController,
                decoration: InputDecoration(
                  labelText: 'Persona de Contacto',
                  hintText: 'Otra persona de contacto',
                  prefixIcon: const Icon(Icons.contacts),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: 'Persona alternativa para gestiones',
                ),
              ),

              const SizedBox(height: 24),

              // Notas
              const Text(
                'Notas Adicionales (Opcional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notasController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Información adicional, horarios de atención, etc.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCompania,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isEditing ? 'Guardar Cambios' : 'Crear Aseguradora',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botón cancelar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
