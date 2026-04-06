// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BabyProfileAdapter extends TypeAdapter<BabyProfile> {
  @override
  final int typeId = 5;

  @override
  BabyProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BabyProfile(
      name: (fields[0] as String?) ?? '우리 아기',
      birthDate: (fields[1] as DateTime?) ?? DateTime.now(),
      gender: fields[2] as String?,
      birthWeight: fields[3] as double?,
      birthHeight: fields[4] as double?,
      growthStageIndex: (fields[5] as int?) ?? 0,
      profileId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BabyProfile obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.birthDate)
      ..writeByte(2)
      ..write(obj.gender)
      ..writeByte(3)
      ..write(obj.birthWeight)
      ..writeByte(4)
      ..write(obj.birthHeight)
      ..writeByte(5)
      ..write(obj.growthStageIndex)
      ..writeByte(6)
      ..write(obj.profileId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BabyProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
