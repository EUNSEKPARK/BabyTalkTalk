import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_baby_time/services/nlp_parser.dart';
import 'package:chat_baby_time/models/baby_record.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 🧪 베타 테스터 시뮬레이션 입력 로그 v2 (10명 페르소나 + 엣지 케이스)
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
///
/// 페르소나 10명:
///   👩 테스터A — 꼼꼼한 초보맘 (생후 2개월, 완분, 정자체 입력)
///   👩‍🦱 테스터B — 바쁜 워킹맘 (생후 7개월, 혼합+이유식, 초약어)
///   👨 테스터C — 아빠 유저 (생후 4개월, 완모, 구어체+이모지)
///   👧 테스터D — MZ세대 엄마 (생후 10개월, 이유식+간식, 반말+신조어)
///   👩‍🔬 테스터E — 꼼꼼 기록파 (생후 12개월, 다양한 카테고리, 상세)
///   👵 테스터F — 할머니 돌봄 (생후 5개월, 완분, 존댓말+옛표현)
///   👶 테스터G — 신생아맘 (생후 15일, 완모, 불안+빈번 기록)
///   👫 테스터H — 쌍둥이맘 (생후 8개월, 혼합, 둘 비교 표현)
///   📱 테스터I — 음성입력파 (생후 6개월, STT 스타일, 띄어쓰기 무시)
///   🧑‍⚕️ 테스터J — 의료진 추천 사용자 (생후 3개월, 정확한 의학 용어)
///
/// 실행: flutter test test/beta_tester_simulation_test.dart
///
void main() {
  final catMap = <String, RecordCategory>{
    'feeding': RecordCategory.feeding,
    'sleep': RecordCategory.sleep,
    'diaper': RecordCategory.diaper,
    'health': RecordCategory.health,
    'babyfood': RecordCategory.babyfood,
    'snack': RecordCategory.snack,
    'milestone': RecordCategory.milestone,
    'other': RecordCategory.other,
  };

  RecordCategory? extractCategory(ParseResult result) {
    if (result.record?.category != null) return result.record!.category;
    if (result.pendingRecord?.category != null) return result.pendingRecord!.category;
    if (result.needsFeedingTypeDisambiguation) return RecordCategory.feeding;
    if (result.needsMedicineTypeDisambiguation) return RecordCategory.health;
    if (result.needsStoolDetailInput) return RecordCategory.diaper;
    if (result.needsDisambiguation && result.disambiguationOptions!.isNotEmpty) {
      return result.disambiguationOptions!.first.category;
    }
    return null;
  }

  String resultLabel(ParseResult result) {
    if (result.record != null) return '확정';
    if (result.pendingRecord != null) {
      if (result.needsAmountInput) return '양/시간 질문';
      if (result.needsStoolDetailInput) return '대변상세 질문';
      return 'pending';
    }
    if (result.needsFeedingTypeDisambiguation) return '수유타입 질문';
    if (result.needsMedicineTypeDisambiguation) return '약종류 질문';
    if (result.needsDisambiguation) return '객관식';
    return 'unknown';
  }

  // ═══════════════════════════════════════════════════════════
  //  👩 테스터A — 꼼꼼한 초보맘 (생후 2개월, 완분)
  //  특징: 정자체, 정확한 수치, 문장형, 시간 꼭 기재
  // ═══════════════════════════════════════════════════════════
  final testerA = <Map<String, String>>[
    {'input': '새벽 2시에 분유 80ml 먹였어요', 'expected': 'feeding'},
    {'input': '새벽 5시 분유 100ml 먹었어요', 'expected': 'feeding'},
    {'input': '아침에 기저귀 갈아줬어요 소변만', 'expected': 'diaper'},
    {'input': '9시쯤 기저귀 교체했어요 노란변이었어요', 'expected': 'diaper'},
    {'input': '오전 8시 분유 120ml 다 먹었어요', 'expected': 'feeding'},
    {'input': '11시에 분유 100ml 줬는데 반밖에 안 먹었어요', 'expected': 'feeding'},
    {'input': '오후 2시 분유 120ml 완료', 'expected': 'feeding'},
    {'input': '낮잠 들었어요 오후 1시에', 'expected': 'sleep'},
    {'input': '40분 자고 깼어요', 'expected': 'sleep'},
    {'input': '저녁 6시에 쪽잠 잠깐 잤어요', 'expected': 'sleep'},
    {'input': '체온 재봤어요 36.8도', 'expected': 'health'},
    {'input': '비타민D 한 방울 먹였어요', 'expected': 'health'},
    {'input': '오후에 소아과 갔다 왔어요', 'expected': 'health'},
    {'input': '저녁 7시에 목욕했어요', 'expected': 'other'},
    {'input': '분유 100ml 먹이고 재웠어요', 'expected': 'feeding'},
    {'input': '밤 10시 분유 120ml 먹고 잠들었어요', 'expected': 'feeding'},
    {'input': '오후 4시 분유 90ml 먹었어요', 'expected': 'feeding'},
    {'input': '기저귀 갈았는데 대변이 좀 묽었어요', 'expected': 'diaper'},
    {'input': '3시간 넘게 잘 잤어요', 'expected': 'sleep'},
    {'input': '분유 어떤 브랜드가 좋을까요', 'expected': 'other'},
    {'input': '아기 왜 이렇게 먹는 양이 들쭉날쭉이지', 'expected': 'other'},
  ];

  // ═══════════════════════════════════════════════════════════
  //  👩‍🦱 테스터B — 바쁜 워킹맘 (생후 7개월, 혼합+이유식)
  //  특징: 초약어, 짧은 입력, 맞춤법 신경X, 숫자 위주
  // ═══════════════════════════════════════════════════════════
  final testerB = <Map<String, String>>[
    {'input': '새벽 모유', 'expected': 'feeding'},
    {'input': 'ㅂㄴ 100', 'expected': 'feeding'},
    {'input': '기갈', 'expected': 'diaper'},
    {'input': '응가 함', 'expected': 'diaper'},
    {'input': '이유식 50ml', 'expected': 'babyfood'},
    {'input': '소고기죽 3스푼', 'expected': 'babyfood'},
    {'input': '분유 140', 'expected': 'feeding'},
    {'input': 'ㅁㅇ 10분', 'expected': 'feeding'},
    {'input': '뻥튀기 줌', 'expected': 'snack'},
    {'input': '바나나 좀', 'expected': 'snack'},
    {'input': '낮잠', 'expected': 'sleep'},
    {'input': '깸', 'expected': 'sleep'},
    {'input': '잠듬', 'expected': 'sleep'},
    {'input': '또 응가', 'expected': 'diaper'},
    {'input': '기저귀 갈음', 'expected': 'diaper'},
    {'input': '유산균 줌', 'expected': 'health'},
    {'input': '목욕함', 'expected': 'other'},
    {'input': '분유 120 줌', 'expected': 'feeding'},
    {'input': '이유식 거부', 'expected': 'babyfood'},
    {'input': '완분으로 전환', 'expected': 'feeding'},
    {'input': '소변만', 'expected': 'diaper'},
    {'input': '퇴근함', 'expected': 'other'},
    {'input': '내일 이유식 뭐 해주지', 'expected': 'other'},
  ];

  // ═══════════════════════════════════════════════════════════
  //  👨 테스터C — 아빠 유저 (생후 4개월, 완모)
  //  특징: 구어체, 이모지 많이 사용, 감정 표현 풍부
  // ═══════════════════════════════════════════════════════════
  final testerC = <Map<String, String>>[
    {'input': '와이프가 모유 수유했대 15분 😊', 'expected': 'feeding'},
    {'input': '직수 20분 했어 잘 먹었다 👍', 'expected': 'feeding'},
    {'input': '젖병으로 유축 100ml 줬어', 'expected': 'feeding'},
    {'input': '똥 폭발ㅋㅋㅋ 옷까지 다 갈아입혔어', 'expected': 'diaper'},
    {'input': '기저귀 갈았는데 소변만 🧷', 'expected': 'diaper'},
    {'input': '또 쉬했어', 'expected': 'diaper'},
    {'input': '겨우 재웠다... 1시간 걸림 😓', 'expected': 'sleep'},
    {'input': '잤다!! 드디어!! 😴', 'expected': 'sleep'},
    {'input': '깼어 ㅠㅠ 30분만에', 'expected': 'sleep'},
    {'input': '아기 일어남 기상!! 🌅', 'expected': 'sleep'},
    {'input': '아기 열 있는것 같아서 재봤는데 37.2도', 'expected': 'health'},
    {'input': '콧물 좀 나와 🤧', 'expected': 'health'},
    {'input': '목 가누기 성공!! 👶💪', 'expected': 'milestone'},
    {'input': '옹알이 엄청 해 ㅋㅋ 귀여워 죽겠다', 'expected': 'milestone'},
    {'input': '목욕 완료 🛁', 'expected': 'other'},
    {'input': '산책 다녀옴 공원에서 30분 ☀️', 'expected': 'other'},
    {'input': '유축 80ml 냉동 보관했어', 'expected': 'feeding'},
    {'input': '오늘 처음으로 소리내서 웃었어 😍', 'expected': 'milestone'},
    {'input': '기저귀 3번째 교체ㅋㅋ', 'expected': 'diaper'},
    {'input': '아기 너무 귀엽다 ❤️', 'expected': 'other'},
    {'input': '육아 힘들다 ㅋㅋ', 'expected': 'other'},
  ];

  // ═══════════════════════════════════════════════════════════
  //  👧 테스터D — MZ세대 엄마 (생후 10개월, 이유식+간식)
  //  특징: 줄임말, 신조어, 반말, 자음만 사용, 오타 많음
  // ═══════════════════════════════════════════════════════════
  final testerD = <Map<String, String>>[
    {'input': '아침에 이유식 먹엇음', 'expected': 'babyfood'},
    {'input': '고구마죽 한그릇 클리어', 'expected': 'babyfood'},
    {'input': '점심 이유식 반만 먹음 ㅜ', 'expected': 'babyfood'},
    {'input': '딸기 세개 줌', 'expected': 'snack'},
    {'input': '요거트 맛나게 먹음', 'expected': 'snack'},
    {'input': '떡뻥 까먹는중', 'expected': 'snack'},
    {'input': '블루베리 좀 줬음', 'expected': 'snack'},
    {'input': '분유 160 먹임', 'expected': 'feeding'},
    {'input': '자기전 분유 한병', 'expected': 'feeding'},
    {'input': '응가 대박 많이함', 'expected': 'diaper'},
    {'input': '기저귀 교체함 쉬만', 'expected': 'diaper'},
    {'input': '방금 기저기 갈았음', 'expected': 'diaper'},
    {'input': '낮잠 1시간 잠', 'expected': 'sleep'},
    {'input': '깸 ㅠ', 'expected': 'sleep'},
    {'input': '잤음', 'expected': 'sleep'},
    {'input': '혼자 서기 성공!!', 'expected': 'milestone'},
    {'input': '박수 쳤어 처음으로!', 'expected': 'milestone'},
    {'input': '코딱지 많이 나옴', 'expected': 'health'},
    {'input': '목욕시킴', 'expected': 'other'},
    {'input': '키위 줬는데 잘먹음', 'expected': 'snack'},
    {'input': '쌀과자 쪼금', 'expected': 'snack'},
    {'input': '소고기 감자 이유식 완식', 'expected': 'babyfood'},
    {'input': '기저귀 쉬 많이 봄', 'expected': 'diaper'},
    {'input': '이유식 레시피 추천좀', 'expected': 'other'},
    {'input': '아 힘들다 진짜', 'expected': 'other'},
  ];

  // ═══════════════════════════════════════════════════════════
  //  👩‍🔬 테스터E — 꼼꼼 기록파 (생후 12개월, 다양한 카테고리)
  //  특징: 상세 설명, 복합 정보, 메모 스타일
  // ═══════════════════════════════════════════════════════════
  final testerE = <Map<String, String>>[
    {'input': '아침 7시 기상 기분 좋아보임', 'expected': 'sleep'},
    {'input': '기상 후 기저귀 갈아줌 소변 많았음', 'expected': 'diaper'},
    {'input': '아침 이유식 소고기 브로콜리죽 100ml 잘 먹음', 'expected': 'babyfood'},
    {'input': '식후 분유 100ml 추가로 줌', 'expected': 'feeding'},
    {'input': '10시 기저귀 교체 묽은변 소량', 'expected': 'diaper'},
    {'input': '간식으로 사과 반개 갈아서 줌', 'expected': 'snack'},
    {'input': '유산균 1포 복용', 'expected': 'health'},
    {'input': '11시반에 낮잠 시작 토닥여서 재움', 'expected': 'sleep'},
    {'input': '1시간 20분 자고 깸', 'expected': 'sleep'},
    {'input': '점심 이유식 닭고기야채죽 120ml', 'expected': 'babyfood'},
    {'input': '후식으로 바나나 3조각 줌', 'expected': 'snack'},
    {'input': '식후 기저귀 교체 대변 정상', 'expected': 'diaper'},
    {'input': '분유 140ml 먹임', 'expected': 'feeding'},
    {'input': '오후 3시 뻥튀기 2개 줌', 'expected': 'snack'},
    {'input': '공원 산책 40분 했음', 'expected': 'other'},
    {'input': '저녁 이유식 감자당근죽 80ml 좀 남김', 'expected': 'babyfood'},
    {'input': '목욕 후 로션 발라줌', 'expected': 'other'},
    {'input': '체온 36.7도 정상', 'expected': 'health'},
    {'input': '분유 160ml 먹고 8시반에 잠들었음', 'expected': 'feeding'},
    {'input': '오늘 처음 두 발짝 걸었음 감동', 'expected': 'milestone'},
    {'input': '오후에 귤 한쪽 줌', 'expected': 'snack'},
    {'input': '2시 기저귀 교체 소변 적당', 'expected': 'diaper'},
    {'input': '비타민D 먹임', 'expected': 'health'},
    {'input': '내일 소아과 검진 예약 확인해야함', 'expected': 'other'},
  ];

  // ═══════════════════════════════════════════════════════════
  //  👵 테스터F — 할머니 돌봄 (생후 5개월, 완분)
  //  특징: 존댓말, 옛표현, 느리게 입력, 한자어 선호
  // ═══════════════════════════════════════════════════════════
  final testerF = <Map<String, String>>[
    {'input': '아기 분유 먹였습니다 100ml', 'expected': 'feeding'},
    {'input': '분유 80밀리 먹였어요', 'expected': 'feeding'},
    {'input': '기저귀 갈아줬습니다', 'expected': 'diaper'},
    {'input': '소변 봤어요', 'expected': 'diaper'},
    {'input': '대변 봤는데 색이 노란색이에요', 'expected': 'diaper'},
    {'input': '아기 재웠습니다', 'expected': 'sleep'},
    {'input': '낮잠 잘 잤어요', 'expected': 'sleep'},
    {'input': '일어났어요', 'expected': 'sleep'},
    {'input': '체온이 37도입니다', 'expected': 'health'},
    {'input': '목욕 시켜줬습니다', 'expected': 'other'},
    {'input': '분유 120ml 먹이고 트림 시켰어요', 'expected': 'feeding'},
    {'input': '기저귀 갈아줬는데 대변이 묽어요', 'expected': 'diaper'},
    {'input': '오후에 30분 동안 잤어요', 'expected': 'sleep'},
    {'input': '분유 거부해서 조금만 먹었어요', 'expected': 'feeding'},
    {'input': '아기가 자꾸 울어요', 'expected': 'other'},
    {'input': '엄마한테 연락해야 하나요', 'expected': 'other'},
  ];

  // ═══════════════════════════════════════════════════════════
  //  👶 테스터G — 신생아맘 (생후 15일, 완모, 불안+빈번)
  //  특징: 걱정 많은 톤, 시간 빈번, 모유 위주, 신생아 키워드
  // ═══════════════════════════════════════════════════════════
  final testerG = <Map<String, String>>[
    {'input': '모유 수유 10분 했어', 'expected': 'feeding'},
    {'input': '직수 양쪽 15분씩 했어', 'expected': 'feeding'},
    {'input': '모유 먹이고 2시간만에 또 먹었어', 'expected': 'feeding'},
    {'input': '태변 나왔어', 'expected': 'diaper'},
    {'input': '기저귀 갈았는데 초록색 변이야', 'expected': 'diaper'},
    {'input': '소변 기저귀 무거워', 'expected': 'diaper'},
    {'input': '겨우 잠들었어', 'expected': 'sleep'},
    {'input': '1시간도 안 돼서 깼어', 'expected': 'sleep'},
    {'input': '새벽 3시에 깼어', 'expected': 'sleep'},
    {'input': '배꼽에서 진물 나와', 'expected': 'health'},
    {'input': '체온 37.3도 괜찮은건지', 'expected': 'health'},
    {'input': '황달 수치 재러 병원 갔다왔어', 'expected': 'health'},
    {'input': '신생아 목욕 시켰어', 'expected': 'other'},
    {'input': '직수 5분만에 잠들어버렸어', 'expected': 'feeding'},
    {'input': '모유 잘 나오는지 모르겠어', 'expected': 'other'},
    {'input': '아기가 계속 보채', 'expected': 'other'},
    {'input': '수유 후 게워냈어', 'expected': 'health'},
    {'input': '모유 수유 20분 완료', 'expected': 'feeding'},
    {'input': '밤새 3번 깼어', 'expected': 'sleep'},
    {'input': '젖몸살 올 것 같아', 'expected': 'other'},
  ];

  // ═══════════════════════════════════════════════════════════
  //  👫 테스터H — 쌍둥이맘 (생후 8개월, 혼합+이유식)
  //  특징: 둘 비교 표현, 빈번 기록, 혼합수유
  // ═══════════════════════════════════════════════════════════
  final testerH = <Map<String, String>>[
    {'input': '분유 120ml 먹었어', 'expected': 'feeding'},
    {'input': '모유 수유 15분', 'expected': 'feeding'},
    {'input': '이유식 80ml 잘 먹음', 'expected': 'babyfood'},
    {'input': '이유식 절반만 먹었어', 'expected': 'babyfood'},
    {'input': '기저귀 갈았어 대변', 'expected': 'diaper'},
    {'input': '소변 기저귀 교체', 'expected': 'diaper'},
    {'input': '기저귀 갈아줬어 소변만', 'expected': 'diaper'},
    {'input': '낮잠 들었어', 'expected': 'sleep'},
    {'input': '깼어 30분 잤어', 'expected': 'sleep'},
    {'input': '뻥튀기 하나 줌', 'expected': 'snack'},
    {'input': '바나나 반개 먹었어', 'expected': 'snack'},
    {'input': '해열제 먹였어', 'expected': 'health'},
    {'input': '혼합수유 중이에요', 'expected': 'feeding'},
    {'input': '분유 100 모유 10분', 'expected': 'feeding'},
    {'input': '기저귀 벌써 6번째', 'expected': 'diaper'},
    {'input': '잠투정 심해', 'expected': 'sleep'},
    {'input': '뒤집기 했어', 'expected': 'milestone'},
    {'input': '오이 스틱 줬어', 'expected': 'snack'},
    {'input': '이유식 당근죽 100ml', 'expected': 'babyfood'},
    {'input': '산책 갔다 왔어', 'expected': 'other'},
    {'input': '둘 다 너무 힘들다', 'expected': 'other'},
  ];

  // ═══════════════════════════════════════════════════════════
  //  📱 테스터I — 음성입력파 (생후 6개월, STT 스타일)
  //  특징: 띄어쓰기 없음, 문장이 길게 연결, 구어체
  // ═══════════════════════════════════════════════════════════
  final testerI = <Map<String, String>>[
    {'input': '분유백이십먹었어', 'expected': 'feeding'},
    {'input': '분유 100밀리 먹었어요', 'expected': 'feeding'},
    {'input': '아기잠들었어', 'expected': 'sleep'},
    {'input': '기저귀갈았어', 'expected': 'diaper'},
    {'input': '이유식먹었어', 'expected': 'babyfood'},
    {'input': '응가했어요', 'expected': 'diaper'},
    {'input': '모유수유했어요', 'expected': 'feeding'},
    {'input': '아기가 일어났어요', 'expected': 'sleep'},
    {'input': '분유 먹이고 재웠어요', 'expected': 'feeding'},
    {'input': '뻥튀기 줬어요', 'expected': 'snack'},
    {'input': '체온 삼십칠점오도', 'expected': 'health'},
    {'input': '목욕했어요', 'expected': 'other'},
    {'input': '사과 갈아서 줬어요', 'expected': 'snack'},
    {'input': '약먹였어요', 'expected': 'health'},
    {'input': '감기약줬어요', 'expected': 'health'},
    {'input': '낮잠잤어요', 'expected': 'sleep'},
    {'input': '기저귀교체했어요', 'expected': 'diaper'},
    {'input': '유축해서 80밀리 줬어요', 'expected': 'feeding'},
    {'input': '산책다녀왔어요', 'expected': 'other'},
    {'input': '아기가 뒤집기를 했어요', 'expected': 'milestone'},
  ];

  // ═══════════════════════════════════════════════════════════
  //  🧑‍⚕️ 테스터J — 의료진 추천 사용자 (생후 3개월, 정확한 용어)
  //  특징: 의학용어, 정확한 수치, 시간 기록, 관찰 일지 스타일
  // ═══════════════════════════════════════════════════════════
  final testerJ = <Map<String, String>>[
    {'input': '분유 수유 140ml 완료', 'expected': 'feeding'},
    {'input': '모유 직수 좌측 10분 우측 8분', 'expected': 'feeding'},
    {'input': '배변 1회 황색 정상변', 'expected': 'diaper'},
    {'input': '배뇨 확인 기저귀 교체', 'expected': 'diaper'},
    {'input': '수면 시작 13:00', 'expected': 'sleep'},
    {'input': '기상 14:30 수면시간 1시간30분', 'expected': 'sleep'},
    {'input': '체온 측정 36.5도', 'expected': 'health'},
    {'input': '예방접종 DPT 2차 완료', 'expected': 'health'},
    {'input': '비타민D 400IU 투여', 'expected': 'health'},
    {'input': '프로바이오틱스 1포 투여', 'expected': 'health'},
    {'input': '전신 목욕 실시', 'expected': 'other'},
    {'input': '복부 마사지 5분간 시행', 'expected': 'other'},
    {'input': '분유 120ml 수유 후 역류 소량 관찰', 'expected': 'feeding'},
    {'input': '두부 지탱 발달 확인', 'expected': 'milestone'},
    {'input': '사회적 미소 관찰됨', 'expected': 'milestone'},
    {'input': '수면 패턴 불규칙 관찰 중', 'expected': 'other'},
    {'input': '유축 모유 100ml 냉장 보관', 'expected': 'feeding'},
    {'input': '습진 발생 좌측 볼', 'expected': 'health'},
    {'input': '기저귀 발진 연고 도포', 'expected': 'health'},
    {'input': '모유 15분 수유 완료', 'expected': 'feeding'},
  ];

  // ═══════════════════════════════════════════════════════════
  //  🎯 엣지 케이스 — 까다로운 입력 패턴
  // ═══════════════════════════════════════════════════════════
  final edgeCases = <Map<String, String>>[
    // ── STT 스타일 (띄어쓰기 없음) ──
    {'input': '분유 80', 'expected': 'feeding'},
    {'input': '모유', 'expected': 'feeding'},
    {'input': '응가', 'expected': 'diaper'},
    {'input': '잤어', 'expected': 'sleep'},
    {'input': '깼어', 'expected': 'sleep'},
    {'input': '뻥튀기', 'expected': 'snack'},

    // ── 긴 수다 속 기록 ──
    {'input': '아 오늘 너무 힘든데 그래도 분유 120ml 잘 먹어서 다행이다', 'expected': 'feeding'},
    {'input': '엄마한테 전화하다가 보니까 아기 잠들었어', 'expected': 'sleep'},

    // ── 순서 뒤바뀜 ──
    {'input': '120ml 분유 줬어', 'expected': 'feeding'},
    {'input': '먹었어 이유식 80ml', 'expected': 'babyfood'},

    // ── 복합 기록 (먼저 나온 행위 우선) ──
    {'input': '분유 먹이고 기저귀 갈았어', 'expected': 'feeding'},
    {'input': '이유식 먹고 낮잠 잤어', 'expected': 'babyfood'},

    // ── 부정문 (기록 아님) ──
    {'input': '분유 안 먹어', 'expected': 'other'},
    {'input': '잠을 안 자', 'expected': 'other'},

    // ── 질문형 (기록 아님) ──
    {'input': '분유 얼마나 줘야 해?', 'expected': 'other'},
    {'input': '이유식 언제 시작해?', 'expected': 'other'},
    {'input': '기저귀 몇 개나 쓰는 게 정상이야?', 'expected': 'other'},

    // ── 예방접종 ──
    {'input': '오늘 BCG 접종 맞았어', 'expected': 'health'},
    {'input': '예방접종 2차 완료', 'expected': 'health'},

    // ── 약 투약 ──
    {'input': '타이레놀 시럽 2.5ml 먹임', 'expected': 'health'},
    {'input': '감기약 아침저녁으로 줬어', 'expected': 'health'},

    // ── 수유 중 이벤트 ──
    {'input': '분유 먹다가 토했어', 'expected': 'health'},
    {'input': '모유 수유 중 잠들었어', 'expected': 'feeding'},

    // ── 비표준 단위 ──
    {'input': '분유 4온스 줬어', 'expected': 'feeding'},
    {'input': '이유식 2큰술 먹었어', 'expected': 'babyfood'},

    // ── 오타/구어체 극단 ──
    {'input': '분유 먹엇어 100', 'expected': 'feeding'},
    {'input': '잣어', 'expected': 'sleep'},
    {'input': '기져귀 갈았어', 'expected': 'diaper'},
    {'input': '이윳식 줬어', 'expected': 'babyfood'},

    // ── 숫자만/숫자+동사 ──
    {'input': '120 먹었어', 'expected': 'feeding'},
    {'input': '80 줬어', 'expected': 'feeding'},
    {'input': '100ml', 'expected': 'feeding'},

    // ── 이모지만/이모지+텍스트 ──
    {'input': '분유 100ml 먹었어 👶', 'expected': 'feeding'},
    {'input': '잠들었어 😴', 'expected': 'sleep'},
    {'input': '응가!!! 💩', 'expected': 'diaper'},

    // ── 오탐 방지 ──
    {'input': '무서워했어', 'expected': 'other'},
    {'input': '약속 잡았어', 'expected': 'other'},
    {'input': '쉬는 날이야', 'expected': 'other'},
    {'input': '열심히 놀았어', 'expected': 'other'},
    {'input': '젖었어 옷이', 'expected': 'other'},

    // ── 잡담/감정/인사 ──
    {'input': '안녕하세요', 'expected': 'other'},
    {'input': '오늘 아기가 너무 귀엽다', 'expected': 'other'},
    {'input': '어떡해 안 먹어', 'expected': 'other'},
    {'input': '왜 이렇게 안 자지', 'expected': 'other'},

    // ── 시간 표현 ──
    {'input': '새벽 3시에 깼어', 'expected': 'sleep'},
    {'input': '점심때 이유식 먹었어', 'expected': 'babyfood'},
    {'input': '방금 기저귀 갈았어', 'expected': 'diaper'},
    {'input': '30분 전에 분유 100ml 먹었어', 'expected': 'feeding'},
  ];

  // ═══════════════════════════════════════════════════════════
  //  테스터별 그룹 테스트
  // ═══════════════════════════════════════════════════════════
  final testerGroups = <String, List<Map<String, String>>>{
    '👩 테스터A (초보맘, 완분, 정자체)': testerA,
    '👩‍🦱 테스터B (워킹맘, 혼합, 초약어)': testerB,
    '👨 테스터C (아빠, 완모, 이모지)': testerC,
    '👧 테스터D (MZ엄마, 이유식기, 신조어)': testerD,
    '👩‍🔬 테스터E (기록파, 12개월, 상세)': testerE,
    '👵 테스터F (할머니, 완분, 존댓말)': testerF,
    '👶 테스터G (신생아맘, 완모, 불안)': testerG,
    '👫 테스터H (쌍둥이맘, 혼합, 비교)': testerH,
    '📱 테스터I (음성입력파, STT)': testerI,
    '🧑‍⚕️ 테스터J (의료진추천, 정확용어)': testerJ,
    '🎯 엣지 케이스 (까다로운 입력)': edgeCases,
  };

  for (final entry in testerGroups.entries) {
    group(entry.key, () {
      for (final tc in entry.value) {
        test('"${tc['input']}" → ${tc['expected']}', () {
          final result = NlpParser.parse(tc['input']!);
          final expected = catMap[tc['expected']!];
          final actual = extractCategory(result);
          final label = resultLabel(result);

          expect(
            actual,
            expected,
            reason: '❌ "${tc['input']}" → 기대: ${tc['expected']}, '
                '실제: ${actual?.name ?? "null"} '
                '[$label] '
                '(${(result.confidence * 100).round()}%)',
          );
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  📊 전체 시뮬레이션 결과 요약 + 로그 저장
  // ═══════════════════════════════════════════════════════════
  test('📊 베타 테스터 시뮬레이션 전체 결과 + 로그 저장', () {
    final allTests = <Map<String, dynamic>>[];

    for (final entry in testerGroups.entries) {
      for (final tc in entry.value) {
        allTests.add({
          'tester': entry.key,
          'input': tc['input']!,
          'expected': tc['expected']!,
        });
      }
    }

    var total = 0;
    var passed = 0;
    final testerStats = <String, List<int>>{};
    final catStats = <String, List<int>>{};
    final failures = <String>[];
    final allResults = <String>[];
    final testerLogs = <String, StringBuffer>{};

    final catEmoji = {
      'feeding': '🍼', 'sleep': '😴', 'diaper': '🧷',
      'health': '🏥', 'babyfood': '🥣', 'snack': '🍎',
      'other': '📝', 'milestone': '⭐',
    };

    final catNames = {
      'feeding': '🍼 수유', 'sleep': '😴 수면', 'diaper': '🧷 기저귀',
      'health': '🏥 건강', 'babyfood': '🥣 이유식', 'snack': '🍎 간식',
      'other': '📝 기타', 'milestone': '⭐ 성장',
    };

    for (final t in allTests) {
      total++;
      final expected = catMap[t['expected']!];
      final result = NlpParser.parse(t['input']!);
      final actual = extractCategory(result);
      final label = resultLabel(result);
      final ok = actual == expected;
      final emoji = catEmoji[actual?.name] ?? '❓';
      final confPct = result.confidence > 0
          ? '${(result.confidence * 100).round()}%'
          : (result.pendingRecord != null ? '확정' : '0%');

      testerStats.putIfAbsent(t['tester']!, () => [0, 0]);
      testerStats[t['tester']!]![1]++;
      catStats.putIfAbsent(t['expected']!, () => [0, 0]);
      catStats[t['expected']!]![1]++;
      testerLogs.putIfAbsent(t['tester']!, () => StringBuffer());

      final mark = ok ? '✅' : '❌';
      final logLine = '$mark  "${t['input']}" → $emoji ${result.message} [$label] ($confPct)';

      if (ok) {
        passed++;
        testerStats[t['tester']!]![0]++;
        catStats[t['expected']!]![0]++;
      } else {
        failures.add(
          '  ❌ [${t['tester']!.substring(0, 2)}] "${t['input']}" → 기대: ${t['expected']}, '
          '실제: ${actual?.name ?? "null"} [$label] ($confPct)',
        );
      }

      allResults.add(
        '  $mark  ${t['input'].toString().padRight(40)} │ $emoji ${result.message} [$label] ($confPct)',
      );
      testerLogs[t['tester']!]!.writeln(logLine);
    }

    final pct = (passed / total * 100).toStringAsFixed(1);
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    // ─── 콘솔 출력 ───
    print('\n');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('  🧪 베타 테스터 시뮬레이션 결과 v2 (10명 페르소나)');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('  전체: $passed/$total ($pct%)');
    print('');

    print('  ── 테스터별 정확도 ──');
    for (final entry in testerStats.entries) {
      final p = entry.value[0];
      final t = entry.value[1];
      final tpct = (p / t * 100).round();
      final bar = '█' * (tpct ~/ 5) + '░' * (20 - tpct ~/ 5);
      print('  ${entry.key}: $p/$t ($tpct%) $bar');
    }
    print('');

    print('  ── 카테고리별 정확도 ──');
    for (final cat in catStats.keys) {
      final p = catStats[cat]![0];
      final t = catStats[cat]![1];
      final cpct = (p / t * 100).round();
      final eName = catNames[cat] ?? cat;
      final bar = '█' * (cpct ~/ 5) + '░' * (20 - cpct ~/ 5);
      print('  $eName: $p/$t ($cpct%) $bar');
    }

    print('');
    print('  ── 전체 입력 로그 (입력 → 기록) ──');
    print('  ${"─" * 95}');
    for (final row in allResults) {
      print(row);
    }
    print('  ${"─" * 95}');

    if (failures.isNotEmpty) {
      print('');
      print('  ── 실패 목록 (${failures.length}개) ──');
      for (final f in failures) {
        print(f);
      }
      print('');
      print('  💡 위 실패 항목을 기반으로 NLP 파서를 추가 개선할 수 있습니다.');
    } else {
      print('');
      print('  🎉 모든 베타 테스터 시뮬레이션 통과!');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // ─── 로그 파일 저장 ───
    final logDir = Directory('test/beta_logs');
    if (!logDir.existsSync()) {
      logDir.createSync(recursive: true);
    }

    // 1) 전체 요약 로그
    final summaryBuf = StringBuffer();
    summaryBuf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    summaryBuf.writeln('🧪 베타 테스터 시뮬레이션 결과 v2');
    summaryBuf.writeln('실행 시각: $now');
    summaryBuf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    summaryBuf.writeln('');
    summaryBuf.writeln('전체: $passed/$total ($pct%)');
    summaryBuf.writeln('');
    summaryBuf.writeln('── 테스터별 정확도 ──');
    for (final entry in testerStats.entries) {
      final p = entry.value[0];
      final t = entry.value[1];
      final tpct = (p / t * 100).round();
      summaryBuf.writeln('  ${entry.key}: $p/$t ($tpct%)');
    }
    summaryBuf.writeln('');
    summaryBuf.writeln('── 카테고리별 정확도 ──');
    for (final cat in catStats.keys) {
      final p = catStats[cat]![0];
      final t = catStats[cat]![1];
      final cpct = (p / t * 100).round();
      final eName = catNames[cat] ?? cat;
      summaryBuf.writeln('  $eName: $p/$t ($cpct%)');
    }
    if (failures.isNotEmpty) {
      summaryBuf.writeln('');
      summaryBuf.writeln('── 실패 목록 (${failures.length}개) ──');
      for (final f in failures) {
        summaryBuf.writeln(f);
      }
    }
    summaryBuf.writeln('');
    summaryBuf.writeln('── 전체 입력 로그 ──');
    for (final row in allResults) {
      summaryBuf.writeln(row);
    }

    File('test/beta_logs/summary_$timestamp.log')
        .writeAsStringSync(summaryBuf.toString());

    // 2) 테스터별 개별 로그
    final testerFileNames = {
      '👩 테스터A (초보맘, 완분, 정자체)': 'testerA_초보맘',
      '👩‍🦱 테스터B (워킹맘, 혼합, 초약어)': 'testerB_워킹맘',
      '👨 테스터C (아빠, 완모, 이모지)': 'testerC_아빠',
      '👧 테스터D (MZ엄마, 이유식기, 신조어)': 'testerD_MZ엄마',
      '👩‍🔬 테스터E (기록파, 12개월, 상세)': 'testerE_기록파',
      '👵 테스터F (할머니, 완분, 존댓말)': 'testerF_할머니',
      '👶 테스터G (신생아맘, 완모, 불안)': 'testerG_신생아맘',
      '👫 테스터H (쌍둥이맘, 혼합, 비교)': 'testerH_쌍둥이맘',
      '📱 테스터I (음성입력파, STT)': 'testerI_음성입력',
      '🧑‍⚕️ 테스터J (의료진추천, 정확용어)': 'testerJ_의료진',
      '🎯 엣지 케이스 (까다로운 입력)': 'edge_cases',
    };

    for (final entry in testerLogs.entries) {
      final fileName = testerFileNames[entry.key] ?? 'unknown';
      final testerBuf = StringBuffer();
      final stats = testerStats[entry.key]!;
      final tpct = (stats[0] / stats[1] * 100).round();

      testerBuf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      testerBuf.writeln('${entry.key}');
      testerBuf.writeln('실행 시각: $now');
      testerBuf.writeln('정확도: ${stats[0]}/${stats[1]} ($tpct%)');
      testerBuf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      testerBuf.writeln('');
      testerBuf.writeln('입력 텍스트 → 기록 결과');
      testerBuf.writeln('${"─" * 60}');
      testerBuf.write(entry.value.toString());

      File('test/beta_logs/${fileName}_$timestamp.log')
          .writeAsStringSync(testerBuf.toString());
    }

    // 3) 실패 전용 로그
    if (failures.isNotEmpty) {
      final failBuf = StringBuffer();
      failBuf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      failBuf.writeln('❌ 실패 항목 모음 (NLP 파서 개선용)');
      failBuf.writeln('실행 시각: $now');
      failBuf.writeln('총 실패: ${failures.length}/$total');
      failBuf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      failBuf.writeln('');
      for (final f in failures) {
        failBuf.writeln(f);
      }
      failBuf.writeln('');
      failBuf.writeln('💡 이 파일을 Claude에게 붙여넣기하면 자동 개선 가능');

      File('test/beta_logs/failures_$timestamp.log')
          .writeAsStringSync(failBuf.toString());
    }

    print('');
    print('  📁 로그 저장 완료 → test/beta_logs/');
    print('     summary_$timestamp.log     (전체 요약)');
    for (final name in testerFileNames.values) {
      print('     ${name}_$timestamp.log');
    }
    if (failures.isNotEmpty) {
      print('     failures_$timestamp.log    (실패 항목)');
    }
    print('');
  });
}
