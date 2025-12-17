import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'claim.g.dart';

@HiveType(typeId: 0)
class Claim extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String comunidadNombre;

  @HiveField(2)
  String comunidadDireccion;

  @HiveField(3)
  String tipoSiniestro;

  @HiveField(4)
  String descripcion;

  @HiveField(5)
  DateTime fechaAlta;

  @HiveField(6)
  ClaimStatus estado;

  @HiveField(7)
  String? companiaAseguradora;

  @HiveField(8)
  String? numeroPoliza;

  @HiveField(9)
  List<String> fotosUrls;

  @HiveField(10)
  String? presupuesto;

  @HiveField(11)
  String? notas;

  @HiveField(12)
  DateTime? fechaComunicacion;

  @HiveField(13)
  DateTime? fechaCierre;

  @HiveField(14)
  List<String> actualizaciones;

  @HiveField(15)
  String? numeroSiniestroCompania;

  // Datos del afectado
  @HiveField(16)
  String? afectadoNombre;

  @HiveField(17)
  String? afectadoTelefono;

  @HiveField(18)
  String? afectadoEmail;

  @HiveField(19)
  String? afectadoPiso;

  // Datos de la persona de contacto para el perito
  @HiveField(20)
  String? contactoNombre;

  @HiveField(21)
  String? contactoTelefono;

  @HiveField(22)
  String? contactoEmail;

  @HiveField(23)
  String? contactoRelacion;

  Claim({
    required this.id,
    required this.comunidadNombre,
    required this.comunidadDireccion,
    required this.tipoSiniestro,
    required this.descripcion,
    required this.fechaAlta,
    required this.estado,
    this.companiaAseguradora,
    this.numeroPoliza,
    List<String>? fotosUrls,
    this.presupuesto,
    this.notas,
    this.fechaComunicacion,
    this.fechaCierre,
    List<String>? actualizaciones,
    this.numeroSiniestroCompania,
    this.afectadoNombre,
    this.afectadoTelefono,
    this.afectadoEmail,
    this.afectadoPiso,
    this.contactoNombre,
    this.contactoTelefono,
    this.contactoEmail,
    this.contactoRelacion,
  })  : fotosUrls = fotosUrls ?? [],
        actualizaciones = actualizaciones ?? [];

  // Método para obtener el color del estado
  String getStatusColor() {
    switch (estado) {
      case ClaimStatus.pendiente:
        return '#FFA726'; // Naranja
      case ClaimStatus.enProceso:
        return '#42A5F5'; // Azul
      case ClaimStatus.comunicado:
        return '#66BB6A'; // Verde claro
      case ClaimStatus.enTramite:
        return '#AB47BC'; // Morado
      case ClaimStatus.cerrado:
        return '#78909C'; // Gris
    }
  }

  // Método para obtener el texto del estado
  String getStatusText() {
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comunidadNombre': comunidadNombre,
      'comunidadDireccion': comunidadDireccion,
      'tipoSiniestro': tipoSiniestro,
      'descripcion': descripcion,
      'fechaAlta': fechaAlta.toIso8601String(),
      'estado': estado.index,
      'companiaAseguradora': companiaAseguradora,
      'numeroPoliza': numeroPoliza,
      'fotosUrls': fotosUrls,
      'presupuesto': presupuesto,
      'notas': notas,
      'fechaComunicacion': fechaComunicacion?.toIso8601String(),
      'fechaCierre': fechaCierre?.toIso8601String(),
      'actualizaciones': actualizaciones,
      'numeroSiniestroCompania': numeroSiniestroCompania,
      'afectadoNombre': afectadoNombre,
      'afectadoTelefono': afectadoTelefono,
      'afectadoEmail': afectadoEmail,
      'afectadoPiso': afectadoPiso,
      'contactoNombre': contactoNombre,
      'contactoTelefono': contactoTelefono,
      'contactoEmail': contactoEmail,
      'contactoRelacion': contactoRelacion,
    };
  }

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'] as String,
      comunidadNombre: json['comunidadNombre'] as String,
      comunidadDireccion: json['comunidadDireccion'] as String,
      tipoSiniestro: json['tipoSiniestro'] as String,
      descripcion: json['descripcion'] as String,
      fechaAlta: DateTime.parse(json['fechaAlta'] as String),
      estado: ClaimStatus.values[json['estado'] as int],
      companiaAseguradora: json['companiaAseguradora'] as String?,
      numeroPoliza: json['numeroPoliza'] as String?,
      fotosUrls: (json['fotosUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      presupuesto: json['presupuesto'] as String?,
      notas: json['notas'] as String?,
      fechaComunicacion: json['fechaComunicacion'] != null
          ? DateTime.parse(json['fechaComunicacion'] as String)
          : null,
      fechaCierre: json['fechaCierre'] != null
          ? DateTime.parse(json['fechaCierre'] as String)
          : null,
      actualizaciones:
          (json['actualizaciones'] as List<dynamic>?)?.cast<String>() ?? [],
      numeroSiniestroCompania: json['numeroSiniestroCompania'] as String?,
      afectadoNombre: json['afectadoNombre'] as String?,
      afectadoTelefono: json['afectadoTelefono'] as String?,
      afectadoEmail: json['afectadoEmail'] as String?,
      afectadoPiso: json['afectadoPiso'] as String?,
      contactoNombre: json['contactoNombre'] as String?,
      contactoTelefono: json['contactoTelefono'] as String?,
      contactoEmail: json['contactoEmail'] as String?,
      contactoRelacion: json['contactoRelacion'] as String?,
    );
  }

  // Métodos para Firebase Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'comunidadNombre': comunidadNombre,
      'comunidadDireccion': comunidadDireccion,
      'tipoSiniestro': tipoSiniestro,
      'descripcion': descripcion,
      'fechaAlta': Timestamp.fromDate(fechaAlta),
      'estado': estado.name, // Usamos el nombre del enum para Firebase
      'companiaAseguradora': companiaAseguradora,
      'numeroPoliza': numeroPoliza,
      'fotosUrls': fotosUrls,
      'presupuesto': presupuesto,
      'notas': notas,
      'fechaComunicacion': fechaComunicacion != null 
          ? Timestamp.fromDate(fechaComunicacion!) 
          : null,
      'fechaCierre': fechaCierre != null 
          ? Timestamp.fromDate(fechaCierre!) 
          : null,
      'actualizaciones': actualizaciones,
      'numeroSiniestroCompania': numeroSiniestroCompania,
      'afectadoNombre': afectadoNombre,
      'afectadoTelefono': afectadoTelefono,
      'afectadoEmail': afectadoEmail,
      'afectadoPiso': afectadoPiso,
      'contactoNombre': contactoNombre,
      'contactoTelefono': contactoTelefono,
      'contactoEmail': contactoEmail,
      'contactoRelacion': contactoRelacion,
    };
  }

  factory Claim.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Claim(
      id: documentId,
      comunidadNombre: data['comunidadNombre'] as String,
      comunidadDireccion: data['comunidadDireccion'] as String,
      tipoSiniestro: data['tipoSiniestro'] as String,
      descripcion: data['descripcion'] as String,
      fechaAlta: (data['fechaAlta'] as Timestamp).toDate(),
      estado: ClaimStatus.values.firstWhere(
        (e) => e.name == data['estado'],
        orElse: () => ClaimStatus.pendiente,
      ),
      companiaAseguradora: data['companiaAseguradora'] as String?,
      numeroPoliza: data['numeroPoliza'] as String?,
      fotosUrls: (data['fotosUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      presupuesto: data['presupuesto'] as String?,
      notas: data['notas'] as String?,
      fechaComunicacion: data['fechaComunicacion'] != null
          ? (data['fechaComunicacion'] as Timestamp).toDate()
          : null,
      fechaCierre: data['fechaCierre'] != null
          ? (data['fechaCierre'] as Timestamp).toDate()
          : null,
      actualizaciones:
          (data['actualizaciones'] as List<dynamic>?)?.cast<String>() ?? [],
      numeroSiniestroCompania: data['numeroSiniestroCompania'] as String?,
      afectadoNombre: data['afectadoNombre'] as String?,
      afectadoTelefono: data['afectadoTelefono'] as String?,
      afectadoEmail: data['afectadoEmail'] as String?,
      afectadoPiso: data['afectadoPiso'] as String?,
      contactoNombre: data['contactoNombre'] as String?,
      contactoTelefono: data['contactoTelefono'] as String?,
      contactoEmail: data['contactoEmail'] as String?,
      contactoRelacion: data['contactoRelacion'] as String?,
    );
  }
}

@HiveType(typeId: 1)
enum ClaimStatus {
  @HiveField(0)
  pendiente,

  @HiveField(1)
  enProceso,

  @HiveField(2)
  comunicado,

  @HiveField(3)
  enTramite,

  @HiveField(4)
  cerrado,
}
