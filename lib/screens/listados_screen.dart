import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/claim.dart';
import '../services/firebase_service.dart';
import 'claim_detail_screen.dart';
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ListadosScreen extends StatefulWidget {
  const ListadosScreen({super.key});

  @override
  State<ListadosScreen> createState() => _ListadosScreenState();
}

class _ListadosScreenState extends State<ListadosScreen> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  ClaimStatus? _estadoFiltro;
  String? _comunidadFiltro;
  String? _aseguradoraFiltro;
  
  List<Claim> _claimsFiltrados = [];
  List<String> _comunidadesDisponibles = [];
  List<String> _aseguradorasDisponibles = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final claims = await FirebaseService.getClaimsStream().first;
    
    final comunidades = claims
        .map((c) => c.comunidadNombre)
        .toSet()
        .toList()
      ..sort();
    
    final aseguradoras = claims
        .where((c) => c.companiaAseguradora != null && c.companiaAseguradora!.isNotEmpty)
        .map((c) => c.companiaAseguradora!)
        .toSet()
        .toList()
      ..sort();

    setState(() {
      _claimsFiltrados = claims;
      _comunidadesDisponibles = comunidades;
      _aseguradorasDisponibles = aseguradoras;
    });
  }

  void _aplicarFiltros(List<Claim> todosClaims) {
    var filtrados = todosClaims;

    // Filtro por fecha desde
    if (_fechaDesde != null) {
      filtrados = filtrados.where((claim) => 
        claim.fechaAlta.isAfter(_fechaDesde!) || 
        claim.fechaAlta.isAtSameMomentAs(_fechaDesde!)
      ).toList();
    }

    // Filtro por fecha hasta
    if (_fechaHasta != null) {
      final fechaHastaFin = DateTime(
        _fechaHasta!.year,
        _fechaHasta!.month,
        _fechaHasta!.day,
        23,
        59,
        59,
      );
      filtrados = filtrados.where((claim) => 
        claim.fechaAlta.isBefore(fechaHastaFin) || 
        claim.fechaAlta.isAtSameMomentAs(fechaHastaFin)
      ).toList();
    }

    // Filtro por estado
    if (_estadoFiltro != null) {
      filtrados = filtrados.where((claim) => claim.estado == _estadoFiltro).toList();
    }

    // Filtro por comunidad
    if (_comunidadFiltro != null) {
      filtrados = filtrados.where((claim) => claim.comunidadNombre == _comunidadFiltro).toList();
    }

    // Filtro por aseguradora
    if (_aseguradoraFiltro != null) {
      filtrados = filtrados.where((claim) => claim.companiaAseguradora == _aseguradoraFiltro).toList();
    }

    // Ordenar por fecha descendente
    filtrados.sort((a, b) => b.fechaAlta.compareTo(a.fechaAlta));

    setState(() {
      _claimsFiltrados = filtrados;
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _estadoFiltro = null;
      _comunidadFiltro = null;
      _aseguradoraFiltro = null;
    });
    _cargarDatos();
  }

  Future<void> _exportarPDF() async {
    if (_claimsFiltrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay siniestros para exportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      // Agrupar siniestros en páginas de 12
      final pageSize = 12;
      for (var i = 0; i < _claimsFiltrados.length; i += pageSize) {
        final pageClaims = _claimsFiltrados.skip(i).take(pageSize).toList();
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildPDFHeader(),
                  pw.SizedBox(height: 20),
                  
                  // Información de filtros
                  _buildFiltrosInfo(),
                  pw.SizedBox(height: 20),
                  
                  // Tabla de siniestros
                  _buildClaimsTable(pageClaims),
                  
                  pw.Spacer(),
                  
                  // Footer
                  pw.Center(
                    child: pw.Text(
                      'Página ${(i ~/ pageSize) + 1} de ${(_claimsFiltrados.length / pageSize).ceil()} - Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Descargar PDF
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'Listado_Siniestros_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Listado PDF exportado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPDFHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue700, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RPS',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'Listado de Siniestros',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.blue800,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Total: ${_claimsFiltrados.length} siniestros',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFiltrosInfo() {
    final filtrosActivos = <String>[];
    
    if (_fechaDesde != null) {
      filtrosActivos.add('Desde: ${DateFormat('dd/MM/yyyy').format(_fechaDesde!)}');
    }
    if (_fechaHasta != null) {
      filtrosActivos.add('Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaHasta!)}');
    }
    if (_estadoFiltro != null) {
      filtrosActivos.add('Estado: ${_getEstadoText(_estadoFiltro!)}');
    }
    if (_comunidadFiltro != null) {
      filtrosActivos.add('Comunidad: $_comunidadFiltro');
    }
    if (_aseguradoraFiltro != null) {
      filtrosActivos.add('Aseguradora: $_aseguradoraFiltro');
    }

    if (filtrosActivos.isEmpty) {
      return pw.Text(
        'Filtros: Ninguno (mostrando todos los siniestros)',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Filtros aplicados:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            filtrosActivos.join(' • '),
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClaimsTable(List<Claim> claims) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue700),
          children: [
            _buildTableCell('Tipo', true),
            _buildTableCell('Comunidad', true),
            _buildTableCell('Aseguradora', true),
            _buildTableCell('Fecha', true),
            _buildTableCell('Estado', true),
          ],
        ),
        // Rows
        ...claims.map((claim) => pw.TableRow(
          children: [
            _buildTableCell(claim.tipoSiniestro, false),
            _buildTableCell(claim.comunidadNombre, false),
            _buildTableCell(claim.companiaAseguradora ?? 'N/A', false),
            _buildTableCell(DateFormat('dd/MM/yy').format(claim.fechaAlta), false),
            _buildTableCell(_getEstadoText(claim.estado), false),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, bool isHeader) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  String _getEstadoText(ClaimStatus estado) {
    switch (estado) {
      case ClaimStatus.pendiente:
        return 'Pendiente';
      case ClaimStatus.enProceso:
        return 'En Proceso';
      case ClaimStatus.comunicado:
        return 'Comunicado';
      case ClaimStatus.enTramite:
        return 'En Trámite';
      case ClaimStatus.cerrado:
        return 'Cerrado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listados y Filtros'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar a PDF',
            onPressed: _exportarPDF,
          ),
        ],
      ),
      body: StreamBuilder<List<Claim>>(
        stream: FirebaseService.getClaimsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final todosClaims = snapshot.data ?? [];

          return Column(
            children: [
              // Panel de filtros
              _buildFiltrosPanel(todosClaims),
              
              // Resultados
              Expanded(
                child: _claimsFiltrados.isEmpty
                    ? _buildEmptyState()
                    : _buildResultados(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltrosPanel(List<Claim> todosClaims) {
    return Container(
      color: Colors.blue[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 16),
          
          // Fila 1: Fechas
          Row(
            children: [
              Expanded(
                child: _buildFechaSelector(
                  'Desde',
                  _fechaDesde,
                  (fecha) {
                    setState(() {
                      _fechaDesde = fecha;
                    });
                    _aplicarFiltros(todosClaims);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFechaSelector(
                  'Hasta',
                  _fechaHasta,
                  (fecha) {
                    setState(() {
                      _fechaHasta = fecha;
                    });
                    _aplicarFiltros(todosClaims);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Fila 2: Estado y Comunidad
          Row(
            children: [
              Expanded(
                child: _buildEstadoDropdown(todosClaims),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildComunidadDropdown(todosClaims),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Fila 3: Aseguradora
          Row(
            children: [
              Expanded(
                child: _buildAseguradoraDropdown(todosClaims),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar Filtros'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _aplicarFiltros(todosClaims),
                icon: const Icon(Icons.search),
                label: const Text('Aplicar Filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFechaSelector(String label, DateTime? fecha, Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: fecha ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onChanged(selectedDate);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: fecha != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : 'Seleccionar',
          style: TextStyle(
            fontSize: 14,
            color: fecha != null ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoDropdown(List<Claim> todosClaims) {
    return DropdownButtonFormField<ClaimStatus?>(
      initialValue: _estadoFiltro,
      decoration: const InputDecoration(
        labelText: 'Estado',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todos')),
        ...ClaimStatus.values.map((estado) => DropdownMenuItem(
          value: estado,
          child: Text(_getEstadoText(estado)),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _estadoFiltro = value;
        });
        _aplicarFiltros(todosClaims);
      },
    );
  }

  Widget _buildComunidadDropdown(List<Claim> todosClaims) {
    return DropdownButtonFormField<String?>(
      initialValue: _comunidadFiltro,
      decoration: const InputDecoration(
        labelText: 'Comunidad',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todas')),
        ..._comunidadesDisponibles.map((comunidad) => DropdownMenuItem(
          value: comunidad,
          child: Text(
            comunidad,
            overflow: TextOverflow.ellipsis,
          ),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _comunidadFiltro = value;
        });
        _aplicarFiltros(todosClaims);
      },
    );
  }

  Widget _buildAseguradoraDropdown(List<Claim> todosClaims) {
    return DropdownButtonFormField<String?>(
      initialValue: _aseguradoraFiltro,
      decoration: const InputDecoration(
        labelText: 'Aseguradora',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todas')),
        ..._aseguradorasDisponibles.map((aseguradora) => DropdownMenuItem(
          value: aseguradora,
          child: Text(
            aseguradora,
            overflow: TextOverflow.ellipsis,
          ),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _aseguradoraFiltro = value;
        });
        _aplicarFiltros(todosClaims);
      },
    );
  }

  Widget _buildResultados() {
    return Column(
      children: [
        // Header con contador
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[200],
          child: Row(
            children: [
              const Icon(Icons.list_alt, color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text(
                'Resultados: ${_claimsFiltrados.length} siniestros',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de resultados
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _claimsFiltrados.length,
            itemBuilder: (context, index) {
              final claim = _claimsFiltrados[index];
              return _buildClaimCard(claim);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClaimCard(Claim claim) {
    final estadoColor = _getStatusColor(claim.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: estadoColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClaimDetailScreen(claim: claim),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      claim.tipoSiniestro,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getEstadoText(claim.estado),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.apartment, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      claim.comunidadNombre,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM/yyyy').format(claim.fechaAlta),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (claim.companiaAseguradora != null &&
                      claim.companiaAseguradora!.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.business, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        claim.companiaAseguradora!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron siniestros',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba ajustando los filtros',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ClaimStatus estado) {
    switch (estado) {
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
}
