import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/claim.dart';
import '../models/comunidad.dart';
import '../services/firebase_service.dart';

class NewClaimScreen extends StatefulWidget {
  const NewClaimScreen({super.key});

  @override
  State<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends State<NewClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tipoController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  // Controladores para datos del afectado
  final _afectadoNombreController = TextEditingController();
  final _afectadoTelefonoController = TextEditingController();
  final _afectadoEmailController = TextEditingController();
  final _afectadoPisoController = TextEditingController();
  
  // Controladores para datos del contacto
  final _contactoNombreController = TextEditingController();
  final _contactoTelefonoController = TextEditingController();
  final _contactoEmailController = TextEditingController();
  final _contactoRelacionController = TextEditingController();

  Comunidad? _selectedComunidad;
  final _uuid = const Uuid();

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
  void dispose() {
    _tipoController.dispose();
    _descripcionController.dispose();
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

    final now = DateTime.now();
    final claim = Claim(
      id: _uuid.v4(),
      comunidadNombre: _selectedComunidad!.nombre,
      comunidadDireccion:
          '${_selectedComunidad!.direccion}, ${_selectedComunidad!.ciudad}',
      tipoSiniestro: _tipoController.text,
      descripcion: _descripcionController.text,
      fechaAlta: now,
      estado: ClaimStatus.pendiente,
      companiaAseguradora: _selectedComunidad!.companiaAseguradora,
      numeroPoliza: _selectedComunidad!.numeroPoliza,
      actualizaciones: [
        '$now: Siniestro registrado',
      ],
      afectadoNombre: _afectadoNombreController.text.isEmpty ? null : _afectadoNombreController.text,
      afectadoTelefono: _afectadoTelefonoController.text.isEmpty ? null : _afectadoTelefonoController.text,
      afectadoEmail: _afectadoEmailController.text.isEmpty ? null : _afectadoEmailController.text,
      afectadoPiso: _afectadoPisoController.text.isEmpty ? null : _afectadoPisoController.text,
      contactoNombre: _contactoNombreController.text.isEmpty ? null : _contactoNombreController.text,
      contactoTelefono: _contactoTelefonoController.text.isEmpty ? null : _contactoTelefonoController.text,
      contactoEmail: _contactoEmailController.text.isEmpty ? null : _contactoEmailController.text,
      contactoRelacion: _contactoRelacionController.text.isEmpty ? null : _contactoRelacionController.text,
    );

    await FirebaseService.addClaim(claim);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Siniestro creado correctamente'),
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
        // Mostrar error si hay alguno
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Nuevo Siniestro'),
              backgroundColor: const Color(0xFF1976D2),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar comunidades:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        // Forzar recarga
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        // Mostrar indicador de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Nuevo Siniestro'),
              backgroundColor: const Color(0xFF1976D2),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando comunidades...'),
                ],
              ),
            ),
          );
        }

        // Si no hay datos pero tampoco hay error
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Nuevo Siniestro'),
              backgroundColor: const Color(0xFF1976D2),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay comunidades disponibles.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Por favor, crea comunidades en la app\nde Control de Tiempos primero.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }

        final comunidades = snapshot.data!;

        return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuevo Siniestro',
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
              // Información RPS
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
                          Icons.business,
                          color: const Color(0xFF1976D2),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'RPS Administración de Fincas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'C/ Juan XXIII, 13',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '30850 Totana, Murcia',
                      style: TextStyle(
                        fontSize: 14,
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

              const SizedBox(height: 32),

              // Datos del afectado
              const Text(
                'Datos del Afectado (Opcional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Nombre del afectado
              TextFormField(
                controller: _afectadoNombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  hintText: 'Nombre del propietario afectado',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 16),

              // Piso del afectado
              TextFormField(
                controller: _afectadoPisoController,
                decoration: InputDecoration(
                  labelText: 'Piso/Puerta',
                  hintText: 'Ej: 3º A',
                  prefixIcon: const Icon(Icons.home_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 16),

              // Teléfono y email del afectado
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _afectadoTelefonoController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        hintText: '600 123 456',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        hintText: 'email@ejemplo.com',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Datos del contacto para el perito
              const Text(
                'Contacto para el Perito (Opcional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Persona que coordinará con el perito',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // Nombre del contacto
              TextFormField(
                controller: _contactoNombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  hintText: 'Persona de contacto',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 16),

              // Relación con el afectado
              TextFormField(
                controller: _contactoRelacionController,
                decoration: InputDecoration(
                  labelText: 'Relación',
                  hintText: 'Ej: Propietario, Administrador, Familiar',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

              const SizedBox(height: 16),

              // Teléfono y email del contacto
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contactoTelefonoController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        hintText: '600 123 456',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        hintText: 'email@ejemplo.com',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                    'Crear Siniestro',
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
