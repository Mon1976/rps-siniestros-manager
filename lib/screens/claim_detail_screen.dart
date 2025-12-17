import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/claim.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import 'edit_claim_screen.dart';

class ClaimDetailScreen extends StatefulWidget {
  final Claim claim;

  const ClaimDetailScreen({super.key, required this.claim});

  @override
  State<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends State<ClaimDetailScreen> {
  late Claim _claim;

  @override
  void initState() {
    super.initState();
    _claim = widget.claim;
  }

  Color _getStatusColor() {
    switch (_claim.estado) {
      case ClaimStatus.pendiente:
        return const Color(0xFFFFA726);
      case ClaimStatus.enProceso:
        return const Color(0xFF42A5F5);
      case ClaimStatus.comunicado:
        return const Color(0xFF66BB6A);
      case ClaimStatus.enTramite:
        return const Color(0xFFAB47BC);
      case ClaimStatus.cerrado:
        return const Color(0xFF78909C);
    }
  }

  Future<void> _updateStatus(ClaimStatus newStatus) async {
    setState(() {
      _claim.estado = newStatus;
      final now = DateTime.now();
      _claim.actualizaciones.add(
        '${DateFormat('dd/MM/yyyy HH:mm').format(now)}: Estado cambiado a ${_claim.getStatusText()}',
      );

      if (newStatus == ClaimStatus.comunicado &&
          _claim.fechaComunicacion == null) {
        _claim.fechaComunicacion = now;
        _claim.actualizaciones.add(
          '${DateFormat('dd/MM/yyyy HH:mm').format(now)}: Comunicado a ${_claim.companiaAseguradora ?? "la aseguradora"}',
        );
      }

      if (newStatus == ClaimStatus.cerrado && _claim.fechaCierre == null) {
        _claim.fechaCierre = now;
        _claim.actualizaciones.add(
          '${DateFormat('dd/MM/yyyy HH:mm').format(now)}: Siniestro cerrado',
        );
      }
    });

    await FirebaseService.updateClaim(_claim);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a ${_claim.getStatusText()}'),
          backgroundColor: _getStatusColor(),
        ),
      );
    }
  }

  Future<void> _sendEmail() async {
    if (_claim.companiaAseguradora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay compañía aseguradora asignada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Buscar email de la compañía
    final companias = await FirebaseService.getCompaniasStream().first;
    final compania = companias.firstWhere(
      (c) => c.nombre == _claim.companiaAseguradora,
      orElse: () => companias.first,
    );

    final emailTo = compania.emailSiniestros ?? compania.email ?? '';
    final subject = Uri.encodeComponent(
      'Siniestro: ${_claim.tipoSiniestro} - ${_claim.comunidadNombre}',
    );
    // Construir sección de datos del afectado
    String datosAfectado = '';
    if (_claim.afectadoNombre != null && _claim.afectadoNombre!.isNotEmpty) {
      datosAfectado = '''

DATOS DEL AFECTADO:
- Nombre: ${_claim.afectadoNombre}''';
      if (_claim.afectadoPiso != null && _claim.afectadoPiso!.isNotEmpty) {
        datosAfectado += '\n- Piso/Puerta: ${_claim.afectadoPiso}';
      }
      if (_claim.afectadoTelefono != null && _claim.afectadoTelefono!.isNotEmpty) {
        datosAfectado += '\n- Teléfono: ${_claim.afectadoTelefono}';
      }
      if (_claim.afectadoEmail != null && _claim.afectadoEmail!.isNotEmpty) {
        datosAfectado += '\n- Email: ${_claim.afectadoEmail}';
      }
    }

    // Construir sección de contacto para el perito
    String datosContacto = '';
    if (_claim.contactoNombre != null && _claim.contactoNombre!.isNotEmpty) {
      datosContacto = '''

CONTACTO PARA EL PERITO:
- Nombre: ${_claim.contactoNombre}''';
      if (_claim.contactoRelacion != null && _claim.contactoRelacion!.isNotEmpty) {
        datosContacto += '\n- Relación: ${_claim.contactoRelacion}';
      }
      if (_claim.contactoTelefono != null && _claim.contactoTelefono!.isNotEmpty) {
        datosContacto += '\n- Teléfono: ${_claim.contactoTelefono}';
      }
      if (_claim.contactoEmail != null && _claim.contactoEmail!.isNotEmpty) {
        datosContacto += '\n- Email: ${_claim.contactoEmail}';
      }
    }

    final body = Uri.encodeComponent('''
Estimados señores,

Les comunicamos el siguiente siniestro:

DATOS DEL SINIESTRO:
- Tipo: ${_claim.tipoSiniestro}
- Fecha: ${DateFormat('dd/MM/yyyy').format(_claim.fechaAlta)}
- Comunidad: ${_claim.comunidadNombre}
- Dirección: ${_claim.comunidadDireccion}
${_claim.numeroPoliza != null ? '- Nº Póliza: ${_claim.numeroPoliza}' : ''}

DESCRIPCIÓN:
${_claim.descripcion}$datosAfectado$datosContacto

Les rogamos que una vez dispongan del número de siniestro asignado nos lo comuniquen para poder hacer el seguimiento correspondiente.

Quedamos a la espera de sus noticias.

Atentamente,
RPS Administración de Fincas
C/ Juan XXIII, 13
30850 Totana (Murcia)
Teléfono: [Añadir teléfono de contacto]
Email: [Añadir email de contacto]
''');

    final emailUri = Uri.parse('mailto:$emailTo?subject=$subject&body=$body');

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);

      // Actualizar estado automáticamente a "Comunicado"
      if (_claim.estado == ClaimStatus.pendiente ||
          _claim.estado == ClaimStatus.enProceso) {
        await _updateStatus(ClaimStatus.comunicado);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el cliente de correo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addNote() async {
    final controller = TextEditingController(text: _claim.notas ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notas del Siniestro'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Añade notas o comentarios...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _claim.notas = result;
      });
      await FirebaseService.updateClaim(_claim);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notas guardadas')),
        );
      }
    }
  }

  Future<void> _editClaim() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditClaimScreen(claim: _claim),
      ),
    );

    if (result == true) {
      setState(() {
        // Recargar datos del siniestro
      });
    }
  }

  Future<void> _generatePDF() async {
    try {
      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Generando PDF...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await PdfService.generateClaimReport(_claim);

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Text('PDF generado y descargado con éxito'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Error al generar PDF: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalle del Siniestro',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editClaim,
            tooltip: 'Editar siniestro',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _generatePDF,
            tooltip: 'Generar informe PDF',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar siniestro'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _claim.tipoSiniestro,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estado: ${_claim.getStatusText()}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Información de la comunidad
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoSection(
                    title: 'Comunidad',
                    icon: Icons.business,
                    children: [
                      _InfoRow(
                        label: 'Nombre',
                        value: _claim.comunidadNombre,
                      ),
                      _InfoRow(
                        label: 'Dirección',
                        value: _claim.comunidadDireccion,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Información del siniestro
                  _InfoSection(
                    title: 'Información del Siniestro',
                    icon: Icons.description,
                    children: [
                      _InfoRow(
                        label: 'Fecha de Alta',
                        value: DateFormat('dd/MM/yyyy HH:mm')
                            .format(_claim.fechaAlta),
                      ),
                      _InfoRow(
                        label: 'Descripción',
                        value: _claim.descripcion,
                      ),
                      if (_claim.companiaAseguradora != null)
                        _InfoRow(
                          label: 'Compañía',
                          value: _claim.companiaAseguradora!,
                        ),
                      if (_claim.numeroPoliza != null)
                        _InfoRow(
                          label: 'Nº Póliza',
                          value: _claim.numeroPoliza!,
                        ),
                      if (_claim.numeroSiniestroCompania != null)
                        _InfoRow(
                          label: 'Nº Siniestro Compañía',
                          value: _claim.numeroSiniestroCompania!,
                        ),
                      if (_claim.fechaComunicacion != null)
                        _InfoRow(
                          label: 'Fecha Comunicación',
                          value: DateFormat('dd/MM/yyyy HH:mm')
                              .format(_claim.fechaComunicacion!),
                        ),
                      if (_claim.fechaCierre != null)
                        _InfoRow(
                          label: 'Fecha Cierre',
                          value: DateFormat('dd/MM/yyyy HH:mm')
                              .format(_claim.fechaCierre!),
                        ),
                      if (_claim.presupuesto != null)
                        _InfoRow(
                          label: 'Presupuesto',
                          value: _claim.presupuesto!,
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Notas
                  _InfoSection(
                    title: 'Notas',
                    icon: Icons.note,
                    children: [
                      Text(
                        _claim.notas?.isEmpty ?? true
                            ? 'Sin notas adicionales'
                            : _claim.notas!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addNote,
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar Notas'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Datos del afectado
                  if (_claim.afectadoNombre != null || _claim.afectadoTelefono != null || _claim.afectadoEmail != null || _claim.afectadoPiso != null)
                    _InfoSection(
                      title: 'Datos del Afectado',
                      icon: Icons.person,
                      children: [
                        if (_claim.afectadoNombre != null)
                          _InfoRow(label: 'Nombre', value: _claim.afectadoNombre!),
                        if (_claim.afectadoPiso != null)
                          _InfoRow(label: 'Piso/Puerta', value: _claim.afectadoPiso!),
                        if (_claim.afectadoTelefono != null)
                          _InfoRow(label: 'Teléfono', value: _claim.afectadoTelefono!),
                        if (_claim.afectadoEmail != null)
                          _InfoRow(label: 'Email', value: _claim.afectadoEmail!),
                      ],
                    ),

                  if (_claim.afectadoNombre != null || _claim.afectadoTelefono != null || _claim.afectadoEmail != null || _claim.afectadoPiso != null)
                    const SizedBox(height: 20),

                  // Contacto para el perito
                  if (_claim.contactoNombre != null || _claim.contactoTelefono != null || _claim.contactoEmail != null || _claim.contactoRelacion != null)
                    _InfoSection(
                      title: 'Contacto para el Perito',
                      icon: Icons.contact_phone,
                      children: [
                        if (_claim.contactoNombre != null)
                          _InfoRow(label: 'Nombre', value: _claim.contactoNombre!),
                        if (_claim.contactoRelacion != null)
                          _InfoRow(label: 'Relación', value: _claim.contactoRelacion!),
                        if (_claim.contactoTelefono != null)
                          _InfoRow(label: 'Teléfono', value: _claim.contactoTelefono!),
                        if (_claim.contactoEmail != null)
                          _InfoRow(label: 'Email', value: _claim.contactoEmail!),
                      ],
                    ),

                  if (_claim.contactoNombre != null || _claim.contactoTelefono != null || _claim.contactoEmail != null || _claim.contactoRelacion != null)
                    const SizedBox(height: 20),

                  // Historial de actualizaciones
                  _InfoSection(
                    title: 'Historial de Actualizaciones',
                    icon: Icons.history,
                    children: [
                      if (_claim.actualizaciones.isEmpty)
                        const Text('Sin actualizaciones')
                      else
                        ..._claim.actualizaciones.map((update) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Color(0xFF1976D2),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      update,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Acciones
                  const Text(
                    'Acciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botón comunicar a aseguradora
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendEmail,
                      icon: const Icon(Icons.email),
                      label: const Text('Comunicar a Aseguradora'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cambiar estado
                  const Text(
                    'Cambiar Estado:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        label: 'Pendiente',
                        status: ClaimStatus.pendiente,
                        currentStatus: _claim.estado,
                        onTap: () => _updateStatus(ClaimStatus.pendiente),
                      ),
                      _StatusChip(
                        label: 'En Proceso',
                        status: ClaimStatus.enProceso,
                        currentStatus: _claim.estado,
                        onTap: () => _updateStatus(ClaimStatus.enProceso),
                      ),
                      _StatusChip(
                        label: 'Comunicado',
                        status: ClaimStatus.comunicado,
                        currentStatus: _claim.estado,
                        onTap: () => _updateStatus(ClaimStatus.comunicado),
                      ),
                      _StatusChip(
                        label: 'En Trámite',
                        status: ClaimStatus.enTramite,
                        currentStatus: _claim.estado,
                        onTap: () => _updateStatus(ClaimStatus.enTramite),
                      ),
                      _StatusChip(
                        label: 'Cerrado',
                        status: ClaimStatus.cerrado,
                        currentStatus: _claim.estado,
                        onTap: () => _updateStatus(ClaimStatus.cerrado),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Siniestro'),
        content:
            const Text('¿Estás seguro de que deseas eliminar este siniestro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseService.deleteClaim(_claim.id);
              if (mounted) {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Volver a la lista
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Siniestro eliminado'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1976D2)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final ClaimStatus status;
  final ClaimStatus currentStatus;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.status,
    required this.currentStatus,
    required this.onTap,
  });

  Color _getColor() {
    switch (status) {
      case ClaimStatus.pendiente:
        return const Color(0xFFFFA726);
      case ClaimStatus.enProceso:
        return const Color(0xFF42A5F5);
      case ClaimStatus.comunicado:
        return const Color(0xFF66BB6A);
      case ClaimStatus.enTramite:
        return const Color(0xFFAB47BC);
      case ClaimStatus.cerrado:
        return const Color(0xFF78909C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = status == currentStatus;

    return InkWell(
      onTap: isSelected ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _getColor() : _getColor().withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getColor(),
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _getColor(),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
