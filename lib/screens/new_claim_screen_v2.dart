import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/claim.dart';
import '../models/comunidad.dart';
import '../services/firebase_service.dart';

class NewClaimScreenV2 extends StatefulWidget {
  const NewClaimScreenV2({super.key});

  @override
  State<NewClaimScreenV2> createState() => _NewClaimScreenV2State();
}

class _NewClaimScreenV2State extends State<NewClaimScreenV2> {
  final _formKey = GlobalKey<FormState>();
  final _tipoController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  final _afectadoNombreController = TextEditingController();
  final _afectadoTelefonoController = TextEditingController();
  final _afectadoEmailController = TextEditingController();
  final _afectadoPisoController = TextEditingController();
  
  final _contactoNombreController = TextEditingController();
  final _contactoTelefonoController = TextEditingController();
  final _contactoEmailController = TextEditingController();
  final _contactoRelacionController = TextEditingController();

  Comunidad? _selectedComunidad;
  final _uuid = const Uuid();
  
  List<Comunidad> _comunidades = [];
  bool _isLoading = true;
  String? _errorMessage;

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
    _loadComunidades();
  }

  Future<void> _loadComunidades() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Cargar directamente desde Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('comunidades')
          .orderBy('nombre')
          .get();

      final comunidades = snapshot.docs.map((doc) {
        return Comunidad.fromFirestore(doc.data(), doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _comunidades = comunidades;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar comunidades: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuevo Siniestro',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando comunidades...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadComunidades,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _comunidades.isEmpty
                  ? Center(
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
                            'Por favor, crea comunidades primero.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
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
                              items: _comunidades.map((comunidad) {
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

                            const SizedBox(height: 24),

                            // Botón de guardar
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _saveClaim,
                                icon: const Icon(Icons.save),
                                label: const Text(
                                  'Crear Siniestro',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
