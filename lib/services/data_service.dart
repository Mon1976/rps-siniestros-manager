import 'package:hive_flutter/hive_flutter.dart';
import '../models/claim.dart';
import '../models/comunidad.dart';
import '../models/compania.dart';

class DataService {
  static const String claimsBoxName = 'claims';
  static const String comunidadesBoxName = 'comunidades';
  static const String companiasBoxName = 'companias';

  // Inicializar Hive y registrar adaptadores
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Registrar adaptadores
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ClaimAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ClaimStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ComunidadAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CompaniaAdapter());
    }

    // Abrir boxes
    await Hive.openBox<Claim>(claimsBoxName);
    await Hive.openBox<Comunidad>(comunidadesBoxName);
    await Hive.openBox<Compania>(companiasBoxName);

    // Inicializar datos de ejemplo si no existen
    await _initializeSampleData();
  }

  static Future<void> _initializeSampleData() async {
    final claimsBox = Hive.box<Claim>(claimsBoxName);
    final comunidadesBox = Hive.box<Comunidad>(comunidadesBoxName);
    final companiasBox = Hive.box<Compania>(companiasBoxName);

    // Inicializar compañías de ejemplo
    if (companiasBox.isEmpty) {
      final companias = [
        Compania(
          id: '1',
          nombre: 'MAPFRE Seguros',
          telefono: '902 100 800',
          email: 'atencion.cliente@mapfre.com',
          emailSiniestros: 'siniestros@mapfre.com',
          web: 'www.mapfre.es',
        ),
        Compania(
          id: '2',
          nombre: 'AXA Seguros',
          telefono: '934 924 924',
          email: 'info@axa.es',
          emailSiniestros: 'siniestros.hogar@axa.es',
          web: 'www.axa.es',
        ),
        Compania(
          id: '3',
          nombre: 'Allianz Seguros',
          telefono: '902 300 186',
          email: 'info@allianz.es',
          emailSiniestros: 'tramitacion.siniestros@allianz.es',
          web: 'www.allianz.es',
        ),
      ];

      for (var compania in companias) {
        await companiasBox.add(compania);
      }
    }

    // Inicializar comunidades de ejemplo
    if (comunidadesBox.isEmpty) {
      final comunidades = [
        Comunidad(
          id: '1',
          nombre: 'Residencial Los Pinos',
          direccion: 'Calle Mayor, 45',
          ciudad: 'Totana',
          codigoPostal: '30850',
          telefono: '968 123 456',
          email: 'lospinos@email.com',
          companiaAseguradora: 'MAPFRE Seguros',
          numeroPoliza: 'POL-2024-001',
        ),
        Comunidad(
          id: '2',
          nombre: 'Edificio Santa Ana',
          direccion: 'Avenida de Lorca, 12',
          ciudad: 'Totana',
          codigoPostal: '30850',
          telefono: '968 234 567',
          email: 'santaana@email.com',
          companiaAseguradora: 'AXA Seguros',
          numeroPoliza: 'POL-2024-002',
        ),
      ];

      for (var comunidad in comunidades) {
        await comunidadesBox.add(comunidad);
      }
    }

    // Inicializar siniestros de ejemplo
    if (claimsBox.isEmpty) {
      final now = DateTime.now();
      final claims = [
        Claim(
          id: '1',
          comunidadNombre: 'Residencial Los Pinos',
          comunidadDireccion: 'Calle Mayor, 45, Totana',
          tipoSiniestro: 'Fuga de agua',
          descripcion:
              'Fuga de agua detectada en la tubería del cuarto piso. Afecta al techo del tercer piso causando daños visibles.',
          fechaAlta: now.subtract(const Duration(days: 5)),
          estado: ClaimStatus.enProceso,
          companiaAseguradora: 'MAPFRE Seguros',
          numeroPoliza: 'POL-2024-001',
          fechaComunicacion: now.subtract(const Duration(days: 4)),
          actualizaciones: [
            '${now.subtract(const Duration(days: 5))}: Siniestro registrado',
            '${now.subtract(const Duration(days: 4))}: Comunicado a MAPFRE',
            '${now.subtract(const Duration(days: 2))}: Perito asignado',
          ],
        ),
        Claim(
          id: '2',
          comunidadNombre: 'Edificio Santa Ana',
          comunidadDireccion: 'Avenida de Lorca, 12, Totana',
          tipoSiniestro: 'Cristales rotos',
          descripcion:
              'Rotura de cristales en la puerta principal por vandalismo durante la madrugada.',
          fechaAlta: now.subtract(const Duration(days: 2)),
          estado: ClaimStatus.comunicado,
          companiaAseguradora: 'AXA Seguros',
          numeroPoliza: 'POL-2024-002',
          fechaComunicacion: now.subtract(const Duration(days: 1)),
          actualizaciones: [
            '${now.subtract(const Duration(days: 2))}: Siniestro registrado',
            '${now.subtract(const Duration(days: 1))}: Comunicado a AXA Seguros',
          ],
        ),
        Claim(
          id: '3',
          comunidadNombre: 'Residencial Los Pinos',
          comunidadDireccion: 'Calle Mayor, 45, Totana',
          tipoSiniestro: 'Avería ascensor',
          descripcion:
              'Ascensor bloqueado en segunda planta. Requiere revisión técnica urgente.',
          fechaAlta: now.subtract(const Duration(hours: 12)),
          estado: ClaimStatus.pendiente,
          companiaAseguradora: 'MAPFRE Seguros',
          numeroPoliza: 'POL-2024-001',
          actualizaciones: [
            '${now.subtract(const Duration(hours: 12))}: Siniestro registrado',
          ],
        ),
      ];

      for (var claim in claims) {
        await claimsBox.add(claim);
      }
    }
  }

  // Claims
  static Box<Claim> get claimsBox => Hive.box<Claim>(claimsBoxName);

  static Future<void> addClaim(Claim claim) async {
    await claimsBox.add(claim);
  }

  static Future<void> updateClaim(Claim claim) async {
    await claim.save();
  }

  static Future<void> deleteClaim(Claim claim) async {
    await claim.delete();
  }

  static List<Claim> getAllClaims() {
    return claimsBox.values.toList()
      ..sort((a, b) => b.fechaAlta.compareTo(a.fechaAlta));
  }

  static List<Claim> getClaimsByStatus(ClaimStatus status) {
    return claimsBox.values.where((claim) => claim.estado == status).toList()
      ..sort((a, b) => b.fechaAlta.compareTo(a.fechaAlta));
  }

  // Comunidades
  static Box<Comunidad> get comunidadesBox =>
      Hive.box<Comunidad>(comunidadesBoxName);

  static Future<void> addComunidad(Comunidad comunidad) async {
    await comunidadesBox.add(comunidad);
  }

  static List<Comunidad> getAllComunidades() {
    return comunidadesBox.values.toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  // Compañías
  static Box<Compania> get companiasBox =>
      Hive.box<Compania>(companiasBoxName);

  static Future<void> addCompania(Compania compania) async {
    await companiasBox.add(compania);
  }

  static List<Compania> getAllCompanias() {
    return companiasBox.values.toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }
}
