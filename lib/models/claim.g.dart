// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClaimAdapter extends TypeAdapter<Claim> {
  @override
  final int typeId = 0;

  @override
  Claim read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Claim(
      id: fields[0] as String,
      comunidadNombre: fields[1] as String,
      comunidadDireccion: fields[2] as String,
      tipoSiniestro: fields[3] as String,
      descripcion: fields[4] as String,
      fechaAlta: fields[5] as DateTime,
      estado: fields[6] as ClaimStatus,
      companiaAseguradora: fields[7] as String?,
      numeroPoliza: fields[8] as String?,
      fotosUrls: (fields[9] as List?)?.cast<String>(),
      presupuesto: fields[10] as String?,
      notas: fields[11] as String?,
      fechaComunicacion: fields[12] as DateTime?,
      fechaCierre: fields[13] as DateTime?,
      actualizaciones: (fields[14] as List?)?.cast<String>(),
      numeroSiniestroCompania: fields[15] as String?,
      afectadoNombre: fields[16] as String?,
      afectadoTelefono: fields[17] as String?,
      afectadoEmail: fields[18] as String?,
      afectadoPiso: fields[19] as String?,
      contactoNombre: fields[20] as String?,
      contactoTelefono: fields[21] as String?,
      contactoEmail: fields[22] as String?,
      contactoRelacion: fields[23] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Claim obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.comunidadNombre)
      ..writeByte(2)
      ..write(obj.comunidadDireccion)
      ..writeByte(3)
      ..write(obj.tipoSiniestro)
      ..writeByte(4)
      ..write(obj.descripcion)
      ..writeByte(5)
      ..write(obj.fechaAlta)
      ..writeByte(6)
      ..write(obj.estado)
      ..writeByte(7)
      ..write(obj.companiaAseguradora)
      ..writeByte(8)
      ..write(obj.numeroPoliza)
      ..writeByte(9)
      ..write(obj.fotosUrls)
      ..writeByte(10)
      ..write(obj.presupuesto)
      ..writeByte(11)
      ..write(obj.notas)
      ..writeByte(12)
      ..write(obj.fechaComunicacion)
      ..writeByte(13)
      ..write(obj.fechaCierre)
      ..writeByte(14)
      ..write(obj.actualizaciones)
      ..writeByte(15)
      ..write(obj.numeroSiniestroCompania)
      ..writeByte(16)
      ..write(obj.afectadoNombre)
      ..writeByte(17)
      ..write(obj.afectadoTelefono)
      ..writeByte(18)
      ..write(obj.afectadoEmail)
      ..writeByte(19)
      ..write(obj.afectadoPiso)
      ..writeByte(20)
      ..write(obj.contactoNombre)
      ..writeByte(21)
      ..write(obj.contactoTelefono)
      ..writeByte(22)
      ..write(obj.contactoEmail)
      ..writeByte(23)
      ..write(obj.contactoRelacion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ClaimStatusAdapter extends TypeAdapter<ClaimStatus> {
  @override
  final int typeId = 1;

  @override
  ClaimStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ClaimStatus.pendiente;
      case 1:
        return ClaimStatus.enProceso;
      case 2:
        return ClaimStatus.comunicado;
      case 3:
        return ClaimStatus.enTramite;
      case 4:
        return ClaimStatus.cerrado;
      default:
        return ClaimStatus.pendiente;
    }
  }

  @override
  void write(BinaryWriter writer, ClaimStatus obj) {
    switch (obj) {
      case ClaimStatus.pendiente:
        writer.writeByte(0);
        break;
      case ClaimStatus.enProceso:
        writer.writeByte(1);
        break;
      case ClaimStatus.comunicado:
        writer.writeByte(2);
        break;
      case ClaimStatus.enTramite:
        writer.writeByte(3);
        break;
      case ClaimStatus.cerrado:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
