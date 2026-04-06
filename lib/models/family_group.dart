/// 가족 그룹 모델 (Firestore 전용 — Hive 저장 안 함)
class FamilyGroup {
  final String id; // Firestore document ID
  final String inviteCode; // 6자리 초대 코드
  final String ownerId; // 그룹 생성자 UID
  final DateTime createdAt;
  final List<FamilyMember> members;

  FamilyGroup({
    required this.id,
    required this.inviteCode,
    required this.ownerId,
    required this.createdAt,
    required this.members,
  });

  factory FamilyGroup.fromFirestore(Map<String, dynamic> data, String docId) {
    final membersList = (data['members'] as List<dynamic>? ?? [])
        .map((m) => FamilyMember.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    return FamilyGroup(
      id: docId,
      inviteCode: data['inviteCode'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] as int? ?? 0,
      ),
      members: membersList,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inviteCode': inviteCode,
      'ownerId': ownerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'members': members.map((m) => m.toMap()).toList(),
    };
  }

  /// 내 닉네임 찾기
  String? memberName(String uid) {
    try {
      return members.firstWhere((m) => m.uid == uid).nickname;
    } catch (_) {
      return null;
    }
  }
}

/// 가족 구성원
class FamilyMember {
  final String uid;
  final String nickname; // "엄마", "아빠", "할머니" 등
  final String role; // owner | member
  final DateTime joinedAt;

  FamilyMember({
    required this.uid,
    required this.nickname,
    required this.role,
    required this.joinedAt,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      uid: map['uid'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '가족',
      role: map['role'] as String? ?? 'member',
      joinedAt: DateTime.fromMillisecondsSinceEpoch(
        map['joinedAt'] as int? ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'role': role,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
    };
  }
}
