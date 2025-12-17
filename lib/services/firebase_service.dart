import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/claim.dart';
import '../models/comunidad.dart';
import '../models/compania.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== CLAIMS (SINIESTROS) ====================

  /// Obtener todos los siniestros en tiempo real
  static Stream<List<Claim>> getClaimsStream() {
    return _firestore
        .collection('claims')
        .orderBy('fechaAlta', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Claim.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  /// Obtener un siniestro específico
  static Future<Claim?> getClaim(String id) async {
    final doc = await _firestore.collection('claims').doc(id).get();
    if (doc.exists) {
      return Claim.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// Agregar un nuevo siniestro
  static Future<String> addClaim(Claim claim) async {
    final docRef = await _firestore.collection('claims').add(claim.toFirestore());
    return docRef.id;
  }

  /// Actualizar un siniestro existente
  static Future<void> updateClaim(Claim claim) async {
    await _firestore
        .collection('claims')
        .doc(claim.id)
        .update(claim.toFirestore());
  }

  /// Eliminar un siniestro
  static Future<void> deleteClaim(String id) async {
    await _firestore.collection('claims').doc(id).delete();
  }

  // ==================== COMUNIDADES ====================

  /// Obtener todas las comunidades en tiempo real
  static Stream<List<Comunidad>> getComunidadesStream() {
    return _firestore
        .collection('comunidades')
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Comunidad.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  /// Obtener una comunidad específica
  static Future<Comunidad?> getComunidad(String id) async {
    final doc = await _firestore.collection('comunidades').doc(id).get();
    if (doc.exists) {
      return Comunidad.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// Agregar una nueva comunidad
  static Future<String> addComunidad(Comunidad comunidad) async {
    final docRef = await _firestore
        .collection('comunidades')
        .add(comunidad.toFirestore());
    return docRef.id;
  }

  /// Actualizar una comunidad existente
  static Future<void> updateComunidad(Comunidad comunidad) async {
    await _firestore
        .collection('comunidades')
        .doc(comunidad.id)
        .update(comunidad.toFirestore());
  }

  /// Eliminar una comunidad
  static Future<void> deleteComunidad(String id) async {
    await _firestore.collection('comunidades').doc(id).delete();
  }

  // ==================== COMPAÑÍAS ASEGURADORAS ====================

  /// Obtener todas las compañías en tiempo real
  static Stream<List<Compania>> getCompaniasStream() {
    return _firestore
        .collection('companias')
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Compania.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  /// Obtener una compañía específica
  static Future<Compania?> getCompania(String id) async {
    final doc = await _firestore.collection('companias').doc(id).get();
    if (doc.exists) {
      return Compania.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// Agregar una nueva compañía
  static Future<String> addCompania(Compania compania) async {
    final docRef = await _firestore
        .collection('companias')
        .add(compania.toFirestore());
    return docRef.id;
  }

  /// Actualizar una compañía existente
  static Future<void> updateCompania(Compania compania) async {
    await _firestore
        .collection('companias')
        .doc(compania.id)
        .update(compania.toFirestore());
  }

  /// Eliminar una compañía
  static Future<void> deleteCompania(String id) async {
    await _firestore.collection('companias').doc(id).delete();
  }

  // ==================== UTILIDADES ====================

  /// Verificar conexión con Firestore
  static Future<bool> checkConnection() async {
    try {
      await _firestore.collection('_health_check').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Inicializar datos de ejemplo (solo si las colecciones están vacías)
  static Future<void> initializeExampleData() async {
    // Verificar si ya hay datos
    final companiesSnapshot = await _firestore.collection('companias').limit(1).get();
    if (companiesSnapshot.docs.isNotEmpty) {
      return; // Ya hay datos, no inicializar
    }

    // Crear compañías de ejemplo
    final companias = [
      Compania(
        id: '',
        nombre: 'MAPFRE Seguros',
        telefono: '902 10 10 11',
        email: 'info@mapfre.es',
        emailSiniestros: 'siniestros@mapfre.es',
        web: 'https://www.mapfre.es',
        notas: 'Carretera de Pozuelo, 52, 28222 Majadahonda, Madrid',
      ),
      Compania(
        id: '',
        nombre: 'AXA Seguros',
        telefono: '900 123 183',
        email: 'info@axa.es',
        emailSiniestros: 'siniestros@axa.es',
        web: 'https://www.axa.es',
        notas: 'Av. de Bruselas, 34, 28108 Alcobendas, Madrid',
      ),
      Compania(
        id: '',
        nombre: 'Allianz Seguros',
        telefono: '902 30 90 90',
        email: 'info@allianz.es',
        emailSiniestros: 'siniestros@allianz.es',
        web: 'https://www.allianz.es',
        notas: 'C/ de los Madrazo, 15, 28014 Madrid',
      ),
    ];

    for (var compania in companias) {
      await addCompania(compania);
    }

    // Crear comunidades de ejemplo
    final comunidades = [
      Comunidad(
        id: '',
        nombre: 'Residencial Los Pinos',
        direccion: 'Calle Mayor, 45',
        ciudad: 'Totana',
        codigoPostal: '30850',
        telefono: '968 42 00 01',
        email: 'lospinos@rps.es',
        companiaAseguradora: 'MAPFRE Seguros',
        numeroPoliza: 'MP-2024-001234',
      ),
      Comunidad(
        id: '',
        nombre: 'Edificio Santa Ana',
        direccion: 'Avenida Rambla, 23',
        ciudad: 'Totana',
        codigoPostal: '30850',
        telefono: '968 42 00 02',
        email: 'santaana@rps.es',
        companiaAseguradora: 'AXA Seguros',
        numeroPoliza: 'AXA-2024-005678',
      ),
    ];

    for (var comunidad in comunidades) {
      await addComunidad(comunidad);
    }
  }
}
