import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/models/family_group.dart';

void main() {
  final testTime = DateTime(2026, 4, 13, 10, 0);

  group('FamilyMember', () {
    test('toMap → fromMap 라운드트립', () {
      final member = FamilyMember(
        uid: 'uid-123',
        nickname: '엄마',
        role: 'owner',
        joinedAt: testTime,
      );
      final map = member.toMap();
      final restored = FamilyMember.fromMap(map);

      expect(restored.uid, 'uid-123');
      expect(restored.nickname, '엄마');
      expect(restored.role, 'owner');
      expect(restored.joinedAt, testTime);
    });

    test('fromMap 누락된 필드에 기본값 적용', () {
      final member = FamilyMember.fromMap({});

      expect(member.uid, '');
      expect(member.nickname, '가족');
      expect(member.role, 'member');
    });
  });

  group('FamilyGroup', () {
    late FamilyGroup group;

    setUp(() {
      group = FamilyGroup(
        id: 'family-1',
        inviteCode: 'ABC123',
        ownerId: 'uid-owner',
        createdAt: testTime,
        members: [
          FamilyMember(uid: 'uid-owner', nickname: '엄마', role: 'owner', joinedAt: testTime),
          FamilyMember(uid: 'uid-2', nickname: '아빠', role: 'member', joinedAt: testTime),
        ],
      );
    });

    test('memberUids 올바른 UID 목록 반환', () {
      expect(group.memberUids, ['uid-owner', 'uid-2']);
    });

    test('memberName 존재하는 UID 닉네임 반환', () {
      expect(group.memberName('uid-owner'), '엄마');
      expect(group.memberName('uid-2'), '아빠');
    });

    test('memberName 없는 UID는 null 반환', () {
      expect(group.memberName('uid-unknown'), null);
    });

    test('toFirestore 올바른 구조', () {
      final map = group.toFirestore();

      expect(map['inviteCode'], 'ABC123');
      expect(map['ownerId'], 'uid-owner');
      expect(map['createdAt'], testTime.millisecondsSinceEpoch);
      expect(map['memberUids'], ['uid-owner', 'uid-2']);
      expect((map['members'] as List).length, 2);
    });

    test('fromFirestore → toFirestore 라운드트립', () {
      final firestoreData = group.toFirestore();
      final restored = FamilyGroup.fromFirestore(firestoreData, 'family-1');

      expect(restored.id, 'family-1');
      expect(restored.inviteCode, 'ABC123');
      expect(restored.ownerId, 'uid-owner');
      expect(restored.members.length, 2);
      expect(restored.members[0].nickname, '엄마');
      expect(restored.members[1].nickname, '아빠');
    });

    test('fromFirestore 빈 데이터 안전 처리', () {
      final restored = FamilyGroup.fromFirestore({}, 'empty-doc');

      expect(restored.id, 'empty-doc');
      expect(restored.inviteCode, '');
      expect(restored.ownerId, '');
      expect(restored.members, isEmpty);
      expect(restored.memberUids, isEmpty);
    });

    test('toFirestore에 memberUids가 반드시 포함됨', () {
      final map = group.toFirestore();
      expect(map.containsKey('memberUids'), true);
      expect(map['memberUids'], isA<List>());
    });
  });
}
