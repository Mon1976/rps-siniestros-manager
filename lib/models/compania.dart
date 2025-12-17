import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'compania.g.dart';

@HiveType(typeId: 3)
class Compania extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String? telefono;

  @HiveField(3)
  String? email;

  @HiveField(4)
  String? emailSiniestros;

  @HiveField(5)
  String? web;

  @HiveField(6)
  String? notas;

  @HiveField(7)
  String? agenteSeguro;

  @HiveField(8)
  String? telefonoAgente;

  @HiveField(9)
  String? personaContacto;

  Compania({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.emailSiniestros,
    this.web,
    this.notas,
    this.agenteSeguro,
    this.telefonoAgente,
    this.personaContacto,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'emailSiniestros': emailSiniestros,
      'web': web,
      'notas': notas,
      'agenteSeguro': agenteSeguro,
      'telefonoAgente': telefonoAgente,
      'personaContacto': personaContacto,
    };
  }

  factory Compania.fromJson(Map<String, dynamic> json) {
    return Compania(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      emailSiniestros: json['emailSiniestros'] as String?,
      web: json['web'] as String?,
      notas: json['notas'] as String?,
      agenteSeguro: json['agenteSeguro'] as String?,
      telefonoAgente: json['telefonoAgente'] as String?,
      personaContacto: json['personaContacto'] as String?,
    );
  }

  // Métodos para Firebase Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'emailSiniestros': emailSiniestros,
      'web': web,
      'notas': notas,
      'agenteSeguro': agenteSeguro,
      'telefonoAgente': telefonoAgente,
      'personaContacto': personaContacto,
    };
  }

  factory Compania.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Compania(
      id: documentId,
      nombre: data['nombre'] as String,
      telefono: data['telefono'] as String?,
      email: data['email'] as String?,
      emailSiniestros: data['emailSiniestros'] as String?,
      web: data['web'] as String?,
      notas: data['notas'] as String?,
      agenteSeguro: data['agenteSeguro'] as String?,
      telefonoAgente: data['telefonoAgente'] as String?,
      personaContacto: data['personaContacto'] as String?,
    );
  }
}
