// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BabyRecordAdapter extends TypeAdapter<BabyRecord> {
  @override
  final int typeId = 4;

  @override
  BabyRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BabyRecord(
      id: (fields[0] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      category: (fields[1] as RecordCategory?) ?? RecordCategory.other,
      timestamp: (fields[2] as DateTime?) ?? DateTime.now(),
      rawInput: fields[3] as String?,
      feedingType: fields[4] as FeedingType?,
      amountMl: fields[5] as int?,
      durationMinutes: fields[6] as int?,
      sleepStatus: fields[7] as SleepStatus?,
      diaperType: fields[8] as DiaperType?,
      temperature: fields[9] as double?,
      medicine: fields[10] as String?,
      memo: fields[11] as String?,
      inputSource: fields[13] as String?,
      createdAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BabyRecord obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.rawInput)
      ..writeByte(4)
      ..write(obj.feedingType)
      ..writeByte(5)
      ..write(obj.amountMl)
      ..writeByte(6)
      ..write(obj.durationMinutes)
      ..writeByte(7)
      ..write(obj.sleepStatus)
      ..writeByte(8)
      ..write(obj.diaperType)
      ..writeByte(9)
      ..write(obj.temperature)
      ..writeByte(10)
      ..write(obj.medicine)
      ..writeByte(11)
      ..write(obj.memo)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.inputSource);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BabyRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecordCategoryAdapter extends TypeAdapter<RecordCategory> {
  @override
  final int typeId = 0;

  @override
  RecordCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecordCategory.feeding;
      case 1:
        return RecordCategory.sleep;
      case 2:
        return RecordCategory.diaper;
      case 3:
        return RecordCategory.milestone;
      case 4:
        return RecordCategory.health;
      case 5:
        return RecordCategory.other;
      case 6:
        return RecordCategory.babyfood;
      case 7:
        return RecordCategory.snack;
      default:
        return RecordCategory.feeding;
    }
  }

  @override
  void write(BinaryWriter writer, RecordCategory obj) {
    switch (obj) {
      case RecordCategory.feeding:
        writer.writeByte(0);
        break;
      case RecordCategory.sleep:
        writer.writeByte(1);
        break;
      case RecordCategory.diaper:
        writer.writeByte(2);
        break;
      case RecordCategory.milestone:
        writer.writeByte(3);
        break;
      case RecordCategory.health:
        writer.writeByte(4);
        break;
      case RecordCategory.other:
        writer.writeByte(5);
        break;
      case RecordCategory.babyfood:
        writer.writeByte(6);
        break;
      case RecordCategory.snack:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FeedingTypeAdapter extends TypeAdapter<FeedingType> {
  @override
  final int typeId = 1;

  @override
  FeedingType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FeedingType.breast;
      case 1:
        return FeedingType.formula;
      case 2:
        return FeedingType.babyfood;
      case 3:
        return FeedingType.snack;
      default:
        return FeedingType.breast;
    }
  }

  @override
  void write(BinaryWriter writer, FeedingType obj) {
    switch (obj) {
      case FeedingType.breast:
        writer.writeByte(0);
        break;
      case FeedingType.formula:
        writer.writeByte(1);
        break;
      case FeedingType.babyfood:
        writer.writeByte(2);
        break;
      case FeedingType.snack:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedingTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiaperTypeAdapter extends TypeAdapter<DiaperType> {
  @override
  final int typeId = 2;

  @override
  DiaperType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DiaperType.pee;
      case 1:
        return DiaperType.poop;
      case 2:
        return DiaperType.both;
      default:
        return DiaperType.pee;
    }
  }

  @override
  void write(BinaryWriter writer, DiaperType obj) {
    switch (obj) {
      case DiaperType.pee:
        writer.writeByte(0);
        break;
      case DiaperType.poop:
        writer.writeByte(1);
        break;
      case DiaperType.both:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaperTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SleepStatusAdapter extends TypeAdapter<SleepStatus> {
  @override
  final int typeId = 3;

  @override
  SleepStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SleepStatus.start;
      case 1:
        return SleepStatus.end;
      default:
        return SleepStatus.start;
    }
  }

  @override
  void write(BinaryWriter writer, SleepStatus obj) {
    switch (obj) {
      case SleepStatus.start:
        writer.writeByte(0);
        break;
      case SleepStatus.end:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
