// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comunidad.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ComunidadAdapter extends TypeAdapter<Comunidad> {
  @override
  final int typeId = 2;

  @override
  Comunidad read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Comunidad(
      id: fields[0] as String,
      nombre: fields[1] as String,
      direccion: fields[2] as String,
      ciudad: fields[3] as String,
      codigoPostal: fields[4] as String,
      telefono: fields[5] as String?,
      email: fields[6] as String?,
      companiaAseguradora: fields[8] as String?,
      numeroPoliza: fields[9] as String?,
      fechaVencimientoSeguro: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Comunidad obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.direccion)
      ..writeByte(3)
      ..write(obj.ciudad)
      ..writeByte(4)
      ..write(obj.codigoPostal)
      ..writeByte(5)
      ..write(obj.telefono)
      ..writeByte(6)
      ..write(obj.email)
      ..writeByte(8)
      ..write(obj.companiaAseguradora)
      ..writeByte(9)
      ..write(obj.numeroPoliza)
      ..writeByte(10)
      ..write(obj.fechaVencimientoSeguro);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComunidadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
