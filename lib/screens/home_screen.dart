import 'package:flutter/material.dart';
import '../models/claim.dart';
import '../services/firebase_service.dart';
import 'claim_detail_screen.dart';
import 'new_claim_screen.dart';
import 'listados_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isKanbanView = true; // Vista por defecto: Kanban (columnas por estado)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Siniestros Manager',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'RPS Administración de Fincas',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        actions: [
          // Botón para cambiar vista
          IconButton(
            icon: Icon(_isKanbanView ? Icons.view_list : Icons.view_column),
            tooltip: _isKanbanView ? 'Vista Lista' : 'Vista Columnas',
            onPressed: () {
              setState(() {
                _isKanbanView = !_isKanbanView;
              });
            },
            color: Colors.white,
          ),
          // Botón de listados
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Listados y Filtros',
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListadosScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Claim>>(
        stream: FirebaseService.getClaimsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Recargar
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sincronizando con Firebase...'),
                ],
              ),
            );
          }

          final claims = snapshot.data ?? [];

          if (claims.isEmpty) {
            return _buildEmptyState();
          }

          return _isKanbanView
              ? _buildKanbanView(claims)
              : _buildListView(claims);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewClaimScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Siniestro'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildKanbanView(List<Claim> claims) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEstadoColumn(
            'PENDIENTE',
            ClaimStatus.pendiente,
            const Color(0xFFFFA726),
            claims,
          ),
          _buildEstadoColumn(
            'EN PROCESO',
            ClaimStatus.enProceso,
            const Color(0xFF42A5F5),
            claims,
          ),
          _buildEstadoColumn(
            'COMUNICADO',
            ClaimStatus.comunicado,
            const Color(0xFF66BB6A),
            claims,
          ),
          _buildEstadoColumn(
            'EN TRÁMITE',
            ClaimStatus.enTramite,
            const Color(0xFFAB47BC),
            claims,
          ),
          _buildEstadoColumn(
            'CERRADO',
            ClaimStatus.cerrado,
            const Color(0xFF78909C),
            claims,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoColumn(
    String titulo,
    ClaimStatus estado,
    Color color,
    List<Claim> todosLosClaims,
  ) {
    final claimsFiltrados = todosLosClaims
        .where((claim) => claim.estado == estado)
        .toList();

    return Container(
      width: 320,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la columna
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${claimsFiltrados.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenedor de tarjetas
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height - 200,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: claimsFiltrados.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Sin siniestros',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: claimsFiltrados.length,
                    itemBuilder: (context, index) {
                      return _buildKanbanCard(
                        claimsFiltrados[index],
                        color,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(Claim claim, Color estadoColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClaimDetailScreen(claim: claim),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: estadoColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de siniestro
              Text(
                claim.tipoSiniestro,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Comunidad
              Row(
                children: [
                  Icon(Icons.apartment, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      claim.comunidadNombre,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Fecha
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 11, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(claim.fechaAlta),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Número de siniestro (si existe)
              if (claim.numeroSiniestroCompania != null &&
                  claim.numeroSiniestroCompania!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.confirmation_number, size: 11, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Nº ${claim.numeroSiniestroCompania}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              // Compañía aseguradora (si existe)
              if (claim.companiaAseguradora != null &&
                  claim.companiaAseguradora!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.business, size: 11, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        claim.companiaAseguradora!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Claim> claims) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: claims.length,
      itemBuilder: (context, index) {
        final claim = claims[index];
        return _buildListCard(claim);
      },
    );
  }

  Widget _buildListCard(Claim claim) {
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: estadoColor,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      claim.getStatusText(),
                      style: TextStyle(
                        color: estadoColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.apartment, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      claim.comunidadNombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      claim.comunidadDireccion,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(claim.fechaAlta),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (claim.numeroSiniestroCompania != null &&
                  claim.numeroSiniestroCompania!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.confirmation_number,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Nº ${claim.numeroSiniestroCompania}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
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
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay siniestros registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pulsa el botón + para crear el primero',
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
