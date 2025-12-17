import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/claim.dart';
import 'dart:html' as html;

class PdfService {
  static Future<void> generateClaimReport(Claim claim) async {
    try {
      final pdf = pw.Document();

      // Construir lista de actualizaciones de forma segura
      final List<pw.Widget> actualizacionesWidgets = [];
      if (claim.actualizaciones.isNotEmpty) {
        for (var update in claim.actualizaciones) {
          actualizacionesWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                update,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          );
        }
      }

      // Agregar página con toda la información
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Encabezado RPS
              _buildHeader(),
              pw.SizedBox(height: 20),

              // Título del documento
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  'INFORME DE SINIESTRO',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Información de la Comunidad
              _buildSection('Datos de la Comunidad', [
                _buildInfoRow('Nombre:', claim.comunidadNombre),
                _buildInfoRow('Dirección:', claim.comunidadDireccion),
              ]),
              pw.SizedBox(height: 15),

              // Información del Siniestro
              _buildSection('Información del Siniestro', [
                _buildInfoRow('Tipo:', claim.tipoSiniestro),
                _buildInfoRow('Fecha de Alta:', DateFormat('dd/MM/yyyy').format(claim.fechaAlta)),
                _buildInfoRow('Estado:', claim.getStatusText()),
                if (claim.numeroSiniestroCompania != null && claim.numeroSiniestroCompania!.isNotEmpty)
                  _buildInfoRow('Nº Siniestro Compañía:', claim.numeroSiniestroCompania!),
              ]),
              pw.SizedBox(height: 15),

              // Información de la Aseguradora
              _buildSection('Datos de la Aseguradora', [
                _buildInfoRow('Compañía:', claim.companiaAseguradora ?? 'No especificada'),
                _buildInfoRow('Nº de Póliza:', claim.numeroPoliza ?? 'No especificado'),
              ]),
              pw.SizedBox(height: 15),

              // Datos del Afectado
              if (claim.afectadoNombre != null && claim.afectadoNombre!.isNotEmpty) ...[
                _buildSection('Datos del Afectado', [
                  _buildInfoRow('Nombre:', claim.afectadoNombre!),
                  if (claim.afectadoPiso != null && claim.afectadoPiso!.isNotEmpty)
                    _buildInfoRow('Piso/Puerta:', claim.afectadoPiso!),
                  if (claim.afectadoTelefono != null && claim.afectadoTelefono!.isNotEmpty)
                    _buildInfoRow('Teléfono:', claim.afectadoTelefono!),
                  if (claim.afectadoEmail != null && claim.afectadoEmail!.isNotEmpty)
                    _buildInfoRow('Email:', claim.afectadoEmail!),
                ]),
                pw.SizedBox(height: 15),
              ],

              // Contacto para el Perito
              if (claim.contactoNombre != null && claim.contactoNombre!.isNotEmpty) ...[
                _buildSection('Contacto para el Perito', [
                  _buildInfoRow('Nombre:', claim.contactoNombre!),
                  if (claim.contactoRelacion != null && claim.contactoRelacion!.isNotEmpty)
                    _buildInfoRow('Relación:', claim.contactoRelacion!),
                  if (claim.contactoTelefono != null && claim.contactoTelefono!.isNotEmpty)
                    _buildInfoRow('Teléfono:', claim.contactoTelefono!),
                  if (claim.contactoEmail != null && claim.contactoEmail!.isNotEmpty)
                    _buildInfoRow('Email:', claim.contactoEmail!),
                ]),
                pw.SizedBox(height: 15),
              ],

              // Descripción
              _buildSection('Descripción del Siniestro', [
                pw.Text(claim.descripcion, style: const pw.TextStyle(fontSize: 12)),
              ]),
              pw.SizedBox(height: 15),

              // Presupuesto
              if (claim.presupuesto != null && claim.presupuesto!.isNotEmpty) ...[
                _buildSection('Presupuesto Estimado', [
                  pw.Text(
                    '${claim.presupuesto!} €',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ]),
                pw.SizedBox(height: 15),
              ],

              // Notas adicionales
              if (claim.notas != null && claim.notas!.isNotEmpty) ...[
                _buildSection('Notas Adicionales', [
                  pw.Text(claim.notas!, style: const pw.TextStyle(fontSize: 12)),
                ]),
                pw.SizedBox(height: 15),
              ],

              // Historial de Actualizaciones
              if (actualizacionesWidgets.isNotEmpty) ...[
                _buildSection('Historial de Actualizaciones', actualizacionesWidgets),
                pw.SizedBox(height: 30),
              ],

              // Pie de documento
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Documento generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Firma y sello:',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 40),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      // Generar el PDF como bytes
      final bytes = await pdf.save();

      // Crear un Blob con los bytes del PDF
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Crear un elemento de enlace para descargar
      html.AnchorElement(href: url)
        ..setAttribute('download', 'Siniestro_${claim.tipoSiniestro}_${DateFormat('yyyyMMdd').format(claim.fechaAlta)}.pdf')
        ..click();

      // Limpiar la URL del objeto
      html.Url.revokeObjectUrl(url);

    } catch (e) {
      throw Exception('Error al generar PDF: $e');
    }
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RPS ADMINISTRACIÓN DE FINCAS',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'C/ Juan XXIII, 13',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Text(
          '30850 Totana (Murcia)',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue700),
      ],
    );
  }

  static pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
