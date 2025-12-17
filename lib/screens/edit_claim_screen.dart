import 'package:flutter/material.dart';
import '../models/claim.dart';
import '../models/comunidad.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';

class EditClaimScreen extends StatefulWidget {
  final Claim claim;

  const EditClaimScreen({super.key, required this.claim});

  @override
  State<EditClaimScreen> createState() => _EditClaimScreenState();
}

class _EditClaimScreenState extends State<EditClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tipoController;
  late TextEditingController _descripcionController;
  late TextEditingController _numeroSiniestroController;
  late TextEditingController _presupuestoController;
  
  // Controladores para datos del afectado
  late TextEditingController _afectadoNombreController;
  late TextEditingController _afectadoTelefonoController;
  late TextEditingController _afectadoEmailController;
  late TextEditingController _afectadoPisoController;
  
  // Controladores para datos del contacto
  late TextEditingController _contactoNombreController;
  late TextEditingController _contactoTelefonoController;
  late TextEditingController _contactoEmailController;
  late TextEditingController _contactoRelacionController;

  Comunidad? _selectedComunidad;

  final List<String> _tiposSiniestro = [
    'Fuga de agua',
    'Cristales rotos',
    'Avería ascensor',
    'Daños estructurales',
    'Incendio',
    'Daños eléctricos',
    'Robo',
    'Vandalismo',
    'Filtraciones',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _tipoController = TextEditingController(text: widget.claim.tipoSiniestro);
    _descripcionController =
        TextEditingController(text: widget.claim.descripcion);
    _numeroSiniestroController =
        TextEditingController(text: widget.claim.numeroSiniestroCompania ?? '');
    _presupuestoController =
        TextEditingController(text: widget.claim.presupuesto ?? '');
    
    // Inicializar controladores del afectado
    _afectadoNombreController = TextEditingController(text: widget.claim.afectadoNombre ?? '');
    _afectadoTelefonoController = TextEditingController(text: widget.claim.afectadoTelefono ?? '');
    _afectadoEmailController = TextEditingController(text: widget.claim.afectadoEmail ?? '');
    _afectadoPisoController = TextEditingController(text: widget.claim.afectadoPiso ?? '');
    
    // Inicializar controladores del contacto
    _contactoNombreController = TextEditingController(text: widget.claim.contactoNombre ?? '');
    _contactoTelefonoController = TextEditingController(text: widget.claim.contactoTelefono ?? '');
    _contactoEmailController = TextEditingController(text: widget.claim.contactoEmail ?? '');
    _contactoRelacionController = TextEditingController(text: widget.claim.contactoRelacion ?? '');

    // Cargar la comunidad seleccionada de forma asíncrona
    FirebaseService.getComunidadesStream().first.then((comunidades) {
      if (comunidades.isNotEmpty) {
        setState(() {
          _selectedComunidad = comunidades.firstWhere(
            (c) => c.nombre == widget.claim.comunidadNombre,
            orElse: () => comunidades.first,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _descripcionController.dispose();
    _numeroSiniestroController.dispose();
    _presupuestoController.dispose();
    _afectadoNombreController.dispose();
    _afectadoTelefonoController.dispose();
    _afectadoEmailController.dispose();
    _afectadoPisoController.dispose();
    _contactoNombreController.dispose();
    _contactoTelefonoController.dispose();
    _contactoEmailController.dispose();
    _contactoRelacionController.dispose();
    super.dispose();
  }

  Future<void> _saveClaim() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedComunidad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una comunidad'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Actualizar datos del siniestro
    widget.claim.comunidadNombre = _selectedComunidad!.nombre;
    widget.claim.comunidadDireccion =
        '${_selectedComunidad!.direccion}, ${_selectedComunidad!.ciudad}';
    widget.claim.tipoSiniestro = _tipoController.text;
    widget.claim.descripcion = _descripcionController.text;
    widget.claim.companiaAseguradora = _selectedComunidad!.companiaAseguradora;
    widget.claim.numeroPoliza = _selectedComunidad!.numeroPoliza;
    widget.claim.numeroSiniestroCompania = _numeroSiniestroController.text.isEmpty
        ? null
        : _numeroSiniestroController.text;
    widget.claim.presupuesto = _presupuestoController.text.isEmpty
        ? null
        : _presupuestoController.text;
    
    // Actualizar datos del afectado
    widget.claim.afectadoNombre = _afectadoNombreController.text.isEmpty ? null : _afectadoNombreController.text;
    widget.claim.afectadoTelefono = _afectadoTelefonoController.text.isEmpty ? null : _afectadoTelefonoController.text;
    widget.claim.afectadoEmail = _afectadoEmailController.text.isEmpty ? null : _afectadoEmailController.text;
    widget.claim.afectadoPiso = _afectadoPisoController.text.isEmpty ? null : _afectadoPisoController.text;
    
    // Actualizar datos del contacto
    widget.claim.contactoNombre = _contactoNombreController.text.isEmpty ? null : _contactoNombreController.text;
    widget.claim.contactoTelefono = _contactoTelefonoController.text.isEmpty ? null : _contactoTelefonoController.text;
    widget.claim.contactoEmail = _contactoEmailController.text.isEmpty ? null : _contactoEmailController.text;
    widget.claim.contactoRelacion = _contactoRelacionController.text.isEmpty ? null : _contactoRelacionController.text;

    // Añadir actualización al historial
    widget.claim.actualizaciones.add(
      '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}: Siniestro modificado',
    );

    await FirebaseService.updateClaim(widget.claim);

    if (mounted) {
      Navigator.pop(context, true); // Devolver true para indicar que se guardó
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Siniestro actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Comunidad>>(
      stream: FirebaseService.getComunidadesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final comunidades = snapshot.data!;

        return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Siniestro',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del siniestro
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_document,
                          color: const Color(0xFF1976D2),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Editando Siniestro',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${widget.claim.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Fecha Alta: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.claim.fechaAlta)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seleccionar comunidad
              const Text(
                'Comunidad *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Comunidad>(
                value: _selectedComunidad,
                decoration: InputDecoration(
                  hintText: 'Selecciona una comunidad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: comunidades.map((comunidad) {
                  return DropdownMenuItem(
                    value: comunidad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          comunidad.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${comunidad.direccion}, ${comunidad.ciudad}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedComunidad = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor, selecciona una comunidad';
                  }
                  return null;
                },
              ),

              if (_selectedComunidad != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedComunidad!.companiaAseguradora != null) ...[
                        Row(
                          children: [
                            Icon(Icons.shield,
                                size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 6),
                            Text(
                              'Aseguradora: ${_selectedComunidad!.companiaAseguradora}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_selectedComunidad!.numeroPoliza != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.assignment,
                                size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 6),
                            Text(
                              'Póliza: ${_selectedComunidad!.numeroPoliza}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Tipo de siniestro
              const Text(
                'Tipo de Siniestro *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tiposSiniestro.contains(_tipoController.text)
                    ? _tipoController.text
                    : null,
                decoration: InputDecoration(
                  hintText: 'Selecciona el tipo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _tiposSiniestro.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (value) {
                  _tipoController.text = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecciona el tipo de siniestro';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Descripción
              const Text(
                'Descripción *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe el siniestro con el mayor detalle posible',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, describe el siniestro';
                  }
                  if (value.length < 20) {
                    return 'La descripción debe tener al menos 20 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Número de siniestro de la compañía
              const Text(
                'Nº Siniestro de la Compañía',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _numeroSiniestroController,
                decoration: InputDecoration(
                  hintText: 'Ej: SIN-2024-12345',
                  prefixIcon: const Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  helperText:
                      'Número de referencia asignado por la aseguradora',
                ),
              ),

              const SizedBox(height: 24),

              // Presupuesto
              const Text(
                'Presupuesto Estimado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _presupuestoController,
                decoration: InputDecoration(
                  hintText: 'Ej: 1.500 €',
                  prefixIcon: const Icon(Icons.euro),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 32),

              // Datos del afectado
              const Text(
                'Datos del Afectado (Opcional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _afectadoNombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _afectadoPisoController,
                decoration: InputDecoration(
                  labelText: 'Piso/Puerta',
                  hintText: 'Ej: 3º A',
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _afectadoTelefonoController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _afectadoEmailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Contacto para el perito
              const Text(
                'Contacto para el Perito (Opcional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Persona que coordinará con el perito', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactoNombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactoRelacionController,
                decoration: InputDecoration(
                  labelText: 'Relación',
                  hintText: 'Ej: Propietario, Administrador, Familiar',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contactoTelefonoController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _contactoEmailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar Cambios',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
