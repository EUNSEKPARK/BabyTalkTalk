import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat_baby_time/models/family_group.dart';
import 'package:chat_baby_time/models/baby_record.dart';

/// 가족 공유 서비스
///
/// - Firebase 익명 인증으로 기기별 사용자 식별 (백엔드용)
/// - 6자리 초대 코드로 가족 그룹 생성/참여
/// - Firestore로 기록 실시간 동기화
class FamilyService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _prefFamilyId = 'family_group_id';
  static const String _prefNickname = 'family_nickname';

  User? _user;
  FamilyGroup? _familyGroup;
  bool _initialized = false;
  bool _syncing = false;
  String? _error;

  StreamSubscription? _familySub;
  StreamSubscription? _recordsSub;

  // ===== Getters =====
  User? get user => _user;
  String? get uid => _user?.uid;
  FamilyGroup? get familyGroup => _familyGroup;
  bool get initialized => _initialized;
  bool get syncing => _syncing;
  String? get error => _error;
  bool get isInFamily => _familyGroup != null;
  String get myNickname => _familyGroup?.memberName(uid ?? '') ?? '나';

  /// 기록 동기화 콜백 (RecordService에서 등록)
  void Function(List<Map<String, dynamic>> records)? onRecordsSync;

  // ===== 초기화 =====

  Future<void> init() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      _user = _auth.currentUser;
      debugPrint('[FamilyService] UID: ${_user?.uid}');

      final prefs = await SharedPreferences.getInstance();
      final savedFamilyId = prefs.getString(_prefFamilyId);
      if (savedFamilyId != null) {
        await _loadFamilyGroup(savedFamilyId);
      }

      _initialized = true;
    } catch (e) {
      debugPrint('[FamilyService] init error: $e');
      _error = '가족 공유 초기화에 실패했습니다.';
      _initialized = true;
    }
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // ===== 가족 그룹 생성 =====

  /// 새 가족 그룹 생성. [nickname]은 "엄마", "아빠" 등.
  Future<String?> createFamily(String nickname) async {
    if (_user == null) {
      // 익명 인증 재시도
      try {
        await _auth.signInAnonymously();
        _user = _auth.currentUser;
      } catch (_) {}
      if (_user == null) return '인터넷 연결을 확인해주세요. (서버 연결 실패)';
    }
    _syncing = true;
    _error = null;
    notifyListeners();

    try {
      final code = await _generateUniqueCode();
      final now = DateTime.now();

      final member = FamilyMember(
        uid: _user!.uid,
        nickname: nickname,
        role: 'owner',
        joinedAt: now,
      );

      final group = FamilyGroup(
        id: '', // Firestore에서 자동 생성
        inviteCode: code,
        ownerId: _user!.uid,
        createdAt: now,
        members: [member],
      );

      final docRef = await _db.collection('families').add(group.toFirestore());

      // invites 컬렉션에 초대 코드 → familyId 매핑 저장
      await _db.collection('invites').doc(code).set({
        'familyId': docRef.id,
        'createdAt': now.millisecondsSinceEpoch,
      });

      // 로컬 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefFamilyId, docRef.id);
      await prefs.setString(_prefNickname, nickname);

      await _loadFamilyGroup(docRef.id);

      _syncing = false;
      notifyListeners();
      return null; // 성공
    } catch (e) {
      debugPrint('[FamilyService] createFamily error: $e');
      _error = '가족 그룹 생성에 실패했습니다.';
      _syncing = false;
      notifyListeners();
      return _error;
    }
  }

  // ===== 초대 코드로 참여 =====

  Future<String?> joinFamily(String code, String nickname) async {
    if (_user == null) {
      try {
        await _auth.signInAnonymously();
        _user = _auth.currentUser;
      } catch (_) {}
      if (_user == null) return '인터넷 연결을 확인해주세요. (서버 연결 실패)';
    }
    _syncing = true;
    _error = null;
    notifyListeners();

    try {
      // invites 컬렉션에서 초대 코드로 familyId 조회
      final inviteDoc = await _db
          .collection('invites')
          .doc(code.toUpperCase())
          .get();

      if (!inviteDoc.exists) {
        _syncing = false;
        _error = '초대 코드를 찾을 수 없습니다.';
        notifyListeners();
        return _error;
      }

      final familyId = inviteDoc.data()!['familyId'] as String;
      final doc = await _db.collection('families').doc(familyId).get();

      if (!doc.exists) {
        _syncing = false;
        _error = '가족 그룹을 찾을 수 없습니다.';
        notifyListeners();
        return _error;
      }

      final data = doc.data()!;
      final members = (data['members'] as List<dynamic>? ?? [])
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      // 이미 참여했는지 확인
      final alreadyJoined = members.any((m) => m['uid'] == _user!.uid);
      if (alreadyJoined) {
        // 이미 참여한 경우 그냥 로드
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefFamilyId, doc.id);
        await _loadFamilyGroup(doc.id);
        _syncing = false;
        notifyListeners();
        return null;
      }

      // 최대 인원 제한 (4명)
      if (members.length >= 4) {
        _syncing = false;
        _error = '가족 그룹 최대 인원(4명)을 초과했습니다.';
        notifyListeners();
        return _error;
      }

      // 멤버 추가
      final newMember = FamilyMember(
        uid: _user!.uid,
        nickname: nickname,
        role: 'member',
        joinedAt: DateTime.now(),
      );

      await doc.reference.update({
        'members': FieldValue.arrayUnion([newMember.toMap()]),
        'memberUids': FieldValue.arrayUnion([_user!.uid]),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefFamilyId, doc.id);
      await prefs.setString(_prefNickname, nickname);

      await _loadFamilyGroup(doc.id);

      _syncing = false;
      notifyListeners();
      return null; // 성공
    } catch (e) {
      debugPrint('[FamilyService] joinFamily error: $e');
      _error = '가족 참여에 실패했습니다.';
      _syncing = false;
      notifyListeners();
      return _error;
    }
  }

  // ===== 가족 탈퇴 =====

  Future<String?> leaveFamily() async {
    if (_user == null || _familyGroup == null) return null;
    _syncing = true;
    notifyListeners();

    try {
      final docRef = _db.collection('families').doc(_familyGroup!.id);

      if (_familyGroup!.ownerId == _user!.uid &&
          _familyGroup!.members.length <= 1) {
        // 마지막 멤버이자 소유자 → 그룹 삭제
        // 먼저 records 하위 컬렉션 삭제
        final records = await docRef.collection('records').get();
        for (final r in records.docs) {
          await r.reference.delete();
        }
        // invites 컬렉션에서도 삭제
        try {
          await _db.collection('invites').doc(_familyGroup!.inviteCode).delete();
        } catch (_) {}
        await docRef.delete();
      } else {
        // 본인만 제거
        final myData = _familyGroup!.members
            .where((m) => m.uid == _user!.uid)
            .map((m) => m.toMap())
            .toList();
        if (myData.isNotEmpty) {
          await docRef.update({
            'members': FieldValue.arrayRemove(myData),
            'memberUids': FieldValue.arrayRemove([_user!.uid]),
          });
        }
      }

      // 로컬 정리
      _familySub?.cancel();
      _recordsSub?.cancel();
      _familyGroup = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefFamilyId);
      await prefs.remove(_prefNickname);

      _syncing = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('[FamilyService] leaveFamily error: $e');
      _error = '가족 탈퇴에 실패했습니다.';
      _syncing = false;
      notifyListeners();
      return _error;
    }
  }

  // ===== 기록 동기화 (Firestore ↔ 로컬) =====

  /// 기록을 Firestore에 업로드
  Future<void> uploadRecord(BabyRecord record) async {
    if (_familyGroup == null || _user == null) return;
    try {
      final data = _recordToFirestore(record);
      await _db
          .collection('families')
          .doc(_familyGroup!.id)
          .collection('records')
          .doc(record.id)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FamilyService] uploadRecord error: $e');
    }
  }

  /// 기록 삭제를 Firestore에 반영
  Future<void> deleteRemoteRecord(String recordId) async {
    if (_familyGroup == null) return;
    try {
      await _db
          .collection('families')
          .doc(_familyGroup!.id)
          .collection('records')
          .doc(recordId)
          .delete();
    } catch (e) {
      debugPrint('[FamilyService] deleteRemoteRecord error: $e');
    }
  }

  // ===== 내부 헬퍼 =====

  Future<void> _loadFamilyGroup(String familyId) async {
    _familySub?.cancel();
    _recordsSub?.cancel();

    // 가족 그룹 실시간 리스닝
    _familySub = _db
        .collection('families')
        .doc(familyId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        _familyGroup = FamilyGroup.fromFirestore(snap.data()!, snap.id);
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('[FamilyService] family listen error: $e');
    });

    // 기록 실시간 리스닝 (최근 7일)
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    _recordsSub = _db
        .collection('families')
        .doc(familyId)
        .collection('records')
        .where('timestamp',
            isGreaterThanOrEqualTo: sevenDaysAgo.millisecondsSinceEpoch)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      final records = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      onRecordsSync?.call(records);
    }, onError: (e) {
      debugPrint('[FamilyService] records listen error: $e');
    });

    // 초기 데이터 한 번 로드
    try {
      final snap = await _db.collection('families').doc(familyId).get();
      if (snap.exists) {
        _familyGroup = FamilyGroup.fromFirestore(snap.data()!, snap.id);
      }
    } catch (e) {
      debugPrint('[FamilyService] initial load error: $e');
    }
  }

  /// 중복 없는 6자리 초대 코드 생성
  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동 문자 제외
    final rng = Random.secure();
    for (int attempt = 0; attempt < 10; attempt++) {
      final code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
      // invites 컬렉션에서 중복 확인 (보안 규칙 통과 가능)
      final existing = await _db.collection('invites').doc(code).get();
      if (!existing.exists) return code;
    }
    // 충돌 시 타임스탬프 기반 폴백
    return DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase().substring(0, 6);
  }

  /// BabyRecord → Firestore Map
  Map<String, dynamic> _recordToFirestore(BabyRecord r) {
    return {
      'category': r.category.index,
      'timestamp': r.timestamp.millisecondsSinceEpoch,
      'rawInput': r.rawInput,
      'feedingType': r.feedingType?.index,
      'amountMl': r.amountMl,
      'durationMinutes': r.durationMinutes,
      'sleepStatus': r.sleepStatus?.index,
      'diaperType': r.diaperType?.index,
      'temperature': r.temperature,
      'medicine': r.medicine,
      'memo': r.memo,
      'createdAt': r.createdAt.millisecondsSinceEpoch,
      'inputSource': r.inputSource,
      'authorId': r.authorId ?? _user?.uid,
      'authorName': r.authorName ?? myNickname,
      'profileId': r.profileId,
    };
  }

  @override
  void dispose() {
    _familySub?.cancel();
    _recordsSub?.cancel();
    super.dispose();
  }
}
