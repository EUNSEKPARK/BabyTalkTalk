/// 100명 페르소나 정의 + 문장 템플릿 조합 엔진
///
/// 페르소나 속성:
///   - formality: 존댓말(3), 보통(2), 반말(1), 극반말(0)
///   - typoRate: 오타 빈도 0.0~1.0
///   - emojiRate: 이모지 사용 빈도 0.0~1.0
///   - abbrRate: 줄임말/약어 빈도 0.0~1.0
///   - verbosity: 장문(3), 보통(2), 단문(1), 극단문(0)
///   - babyMonths: 아기 월령 (0~24)
///   - feedingType: 'formula'|'breast'|'mixed'|'babyfood'
///   - style: 입력 스타일 태그

class Persona {
  final String id;
  final String name;
  final String desc;
  final int formality;     // 0~3
  final double typoRate;   // 0.0~1.0
  final double emojiRate;  // 0.0~1.0
  final double abbrRate;   // 0.0~1.0
  final int verbosity;     // 0~3
  final int babyMonths;    // 0~24
  final String feedingType;
  final String style;

  const Persona({
    required this.id,
    required this.name,
    required this.desc,
    this.formality = 2,
    this.typoRate = 0.0,
    this.emojiRate = 0.0,
    this.abbrRate = 0.0,
    this.verbosity = 2,
    this.babyMonths = 6,
    this.feedingType = 'formula',
    this.style = 'normal',
  });
}

/// 100명 페르소나 목록
final allPersonas = <Persona>[
  // ── 초보맘 그룹 (1~10) ──
  Persona(id: 'P01', name: '초보맘A', desc: '생후1개월 완분 꼼꼼', formality: 3, verbosity: 3, babyMonths: 1, feedingType: 'formula', style: 'polite'),
  Persona(id: 'P02', name: '초보맘B', desc: '생후2개월 완분 정자체', formality: 3, verbosity: 2, babyMonths: 2, feedingType: 'formula', style: 'polite'),
  Persona(id: 'P03', name: '초보맘C', desc: '생후1개월 완모 불안', formality: 2, verbosity: 3, babyMonths: 1, feedingType: 'breast', style: 'anxious'),
  Persona(id: 'P04', name: '초보맘D', desc: '생후3개월 혼합 질문많음', formality: 2, verbosity: 2, babyMonths: 3, feedingType: 'mixed', style: 'questioning'),
  Persona(id: 'P05', name: '초보맘E', desc: '신생아 완모 빈번기록', formality: 2, verbosity: 1, babyMonths: 0, feedingType: 'breast', style: 'frequent'),
  Persona(id: 'P06', name: '초보맘F', desc: '생후2개월 완분 이모지', formality: 2, emojiRate: 0.7, verbosity: 2, babyMonths: 2, feedingType: 'formula', style: 'emoji'),
  Persona(id: 'P07', name: '초보맘G', desc: '생후1개월 혼합 존댓말', formality: 3, verbosity: 2, babyMonths: 1, feedingType: 'mixed', style: 'polite'),
  Persona(id: 'P08', name: '초보맘H', desc: '생후3개월 완분 단문', formality: 1, verbosity: 0, babyMonths: 3, feedingType: 'formula', style: 'short'),
  Persona(id: 'P09', name: '초보맘I', desc: '생후2개월 완모 장문', formality: 2, verbosity: 3, babyMonths: 2, feedingType: 'breast', style: 'verbose'),
  Persona(id: 'P10', name: '초보맘J', desc: '생후1개월 완분 오타', formality: 1, typoRate: 0.5, verbosity: 1, babyMonths: 1, feedingType: 'formula', style: 'typo'),

  // ── 워킹맘 그룹 (11~20) ──
  Persona(id: 'P11', name: '워킹맘A', desc: '생후5개월 혼합 초약어', formality: 1, abbrRate: 0.8, verbosity: 0, babyMonths: 5, feedingType: 'mixed', style: 'abbr'),
  Persona(id: 'P12', name: '워킹맘B', desc: '생후7개월 이유식시작 바쁨', formality: 1, abbrRate: 0.5, verbosity: 1, babyMonths: 7, feedingType: 'babyfood', style: 'busy'),
  Persona(id: 'P13', name: '워킹맘C', desc: '생후6개월 완분 숫자위주', formality: 1, verbosity: 0, babyMonths: 6, feedingType: 'formula', style: 'numeric'),
  Persona(id: 'P14', name: '워킹맘D', desc: '생후8개월 혼합 빠른입력', formality: 1, typoRate: 0.3, verbosity: 1, babyMonths: 8, feedingType: 'mixed', style: 'fast'),
  Persona(id: 'P15', name: '워킹맘E', desc: '생후9개월 이유식 약어', formality: 1, abbrRate: 0.6, verbosity: 0, babyMonths: 9, feedingType: 'babyfood', style: 'abbr'),
  Persona(id: 'P16', name: '워킹맘F', desc: '생후4개월 완분 메모형', formality: 2, verbosity: 2, babyMonths: 4, feedingType: 'formula', style: 'memo'),
  Persona(id: 'P17', name: '워킹맘G', desc: '생후10개월 완분 단답', formality: 0, verbosity: 0, babyMonths: 10, feedingType: 'formula', style: 'ultra_short'),
  Persona(id: 'P18', name: '워킹맘H', desc: '생후6개월 혼합 시간기록', formality: 2, verbosity: 2, babyMonths: 6, feedingType: 'mixed', style: 'timed'),
  Persona(id: 'P19', name: '워킹맘I', desc: '생후11개월 이유식 구어체', formality: 1, verbosity: 1, babyMonths: 11, feedingType: 'babyfood', style: 'casual'),
  Persona(id: 'P20', name: '워킹맘J', desc: '생후5개월 완모 야간', formality: 1, verbosity: 1, babyMonths: 5, feedingType: 'breast', style: 'night'),

  // ── 아빠 그룹 (21~30) ──
  Persona(id: 'P21', name: '아빠A', desc: '생후3개월 완모 이모지', formality: 1, emojiRate: 0.8, verbosity: 2, babyMonths: 3, feedingType: 'breast', style: 'emoji_dad'),
  Persona(id: 'P22', name: '아빠B', desc: '생후6개월 혼합 구어체', formality: 1, verbosity: 2, babyMonths: 6, feedingType: 'mixed', style: 'casual_dad'),
  Persona(id: 'P23', name: '아빠C', desc: '생후4개월 완분 기술적', formality: 2, verbosity: 2, babyMonths: 4, feedingType: 'formula', style: 'tech'),
  Persona(id: 'P24', name: '아빠D', desc: '생후8개월 이유식 단문', formality: 1, verbosity: 0, babyMonths: 8, feedingType: 'babyfood', style: 'short_dad'),
  Persona(id: 'P25', name: '아빠E', desc: '생후2개월 완모 감정적', formality: 1, emojiRate: 0.5, verbosity: 3, babyMonths: 2, feedingType: 'breast', style: 'emotional'),
  Persona(id: 'P26', name: '아빠F', desc: '생후5개월 혼합 보고형', formality: 2, verbosity: 2, babyMonths: 5, feedingType: 'mixed', style: 'report'),
  Persona(id: 'P27', name: '아빠G', desc: '생후12개월 걸음마기 축하형', formality: 1, emojiRate: 0.6, verbosity: 2, babyMonths: 12, feedingType: 'babyfood', style: 'celebratory'),
  Persona(id: 'P28', name: '아빠H', desc: '생후7개월 완분 밤당번', formality: 1, verbosity: 1, babyMonths: 7, feedingType: 'formula', style: 'night_dad'),
  Persona(id: 'P29', name: '아빠I', desc: '생후1개월 완모 초보', formality: 2, verbosity: 2, babyMonths: 1, feedingType: 'breast', style: 'newbie_dad'),
  Persona(id: 'P30', name: '아빠J', desc: '생후9개월 이유식 사진형', formality: 1, emojiRate: 0.4, verbosity: 1, babyMonths: 9, feedingType: 'babyfood', style: 'photo'),

  // ── MZ세대 엄마 그룹 (31~40) ──
  Persona(id: 'P31', name: 'MZ맘A', desc: '생후10개월 이유식 신조어', formality: 0, typoRate: 0.3, verbosity: 1, babyMonths: 10, feedingType: 'babyfood', style: 'slang'),
  Persona(id: 'P32', name: 'MZ맘B', desc: '생후8개월 혼합 줄임말', formality: 0, abbrRate: 0.7, verbosity: 0, babyMonths: 8, feedingType: 'mixed', style: 'abbr_mz'),
  Persona(id: 'P33', name: 'MZ맘C', desc: '생후6개월 완분 이모지폭탄', formality: 1, emojiRate: 0.9, verbosity: 1, babyMonths: 6, feedingType: 'formula', style: 'emoji_bomb'),
  Persona(id: 'P34', name: 'MZ맘D', desc: '생후11개월 이유식 반말', formality: 0, verbosity: 1, babyMonths: 11, feedingType: 'babyfood', style: 'banmal'),
  Persona(id: 'P35', name: 'MZ맘E', desc: '생후9개월 완분 오타', formality: 0, typoRate: 0.6, verbosity: 1, babyMonths: 9, feedingType: 'formula', style: 'typo_mz'),
  Persona(id: 'P36', name: 'MZ맘F', desc: '생후7개월 혼합 감정', formality: 1, emojiRate: 0.5, verbosity: 2, babyMonths: 7, feedingType: 'mixed', style: 'emotional_mz'),
  Persona(id: 'P37', name: 'MZ맘G', desc: '생후12개월 이유식 기록마니아', formality: 1, verbosity: 2, babyMonths: 12, feedingType: 'babyfood', style: 'recorder'),
  Persona(id: 'P38', name: 'MZ맘H', desc: '생후5개월 완모 SNS체', formality: 0, emojiRate: 0.7, verbosity: 1, babyMonths: 5, feedingType: 'breast', style: 'sns'),
  Persona(id: 'P39', name: 'MZ맘I', desc: '생후4개월 혼합 늦밤', formality: 0, verbosity: 1, babyMonths: 4, feedingType: 'mixed', style: 'late_night'),
  Persona(id: 'P40', name: 'MZ맘J', desc: '생후3개월 완분 초성', formality: 0, abbrRate: 0.9, verbosity: 0, babyMonths: 3, feedingType: 'formula', style: 'consonant'),

  // ── 할머니/할아버지 그룹 (41~50) ──
  Persona(id: 'P41', name: '할머니A', desc: '생후5개월 완분 존댓말', formality: 3, verbosity: 2, babyMonths: 5, feedingType: 'formula', style: 'grandma'),
  Persona(id: 'P42', name: '할머니B', desc: '생후8개월 이유식 옛말', formality: 3, verbosity: 3, babyMonths: 8, feedingType: 'babyfood', style: 'old_style'),
  Persona(id: 'P43', name: '할아버지A', desc: '생후3개월 완분 간결', formality: 3, verbosity: 1, babyMonths: 3, feedingType: 'formula', style: 'grandpa'),
  Persona(id: 'P44', name: '할머니C', desc: '생후6개월 혼합 걱정', formality: 3, verbosity: 3, babyMonths: 6, feedingType: 'mixed', style: 'worried_gm'),
  Persona(id: 'P45', name: '할머니D', desc: '생후10개월 이유식 경험', formality: 3, verbosity: 2, babyMonths: 10, feedingType: 'babyfood', style: 'experienced_gm'),
  Persona(id: 'P46', name: '할아버지B', desc: '생후4개월 완분 기록', formality: 3, verbosity: 2, babyMonths: 4, feedingType: 'formula', style: 'record_gp'),
  Persona(id: 'P47', name: '할머니E', desc: '생후7개월 혼합 따뜻', formality: 3, verbosity: 2, babyMonths: 7, feedingType: 'mixed', style: 'warm_gm'),
  Persona(id: 'P48', name: '할머니F', desc: '생후2개월 완분 느린타이핑', formality: 3, typoRate: 0.4, verbosity: 1, babyMonths: 2, feedingType: 'formula', style: 'slow_type'),
  Persona(id: 'P49', name: '할머니G', desc: '생후9개월 이유식 전화체', formality: 3, verbosity: 2, babyMonths: 9, feedingType: 'babyfood', style: 'phone_style'),
  Persona(id: 'P50', name: '할머니H', desc: '생후1개월 완모 신생아돌봄', formality: 3, verbosity: 2, babyMonths: 1, feedingType: 'breast', style: 'newborn_gm'),

  // ── 신생아맘 그룹 (51~55) ──
  Persona(id: 'P51', name: '신생아맘A', desc: '생후0개월 완모 빈번', formality: 2, verbosity: 1, babyMonths: 0, feedingType: 'breast', style: 'newborn'),
  Persona(id: 'P52', name: '신생아맘B', desc: '생후0개월 혼합 불안', formality: 2, verbosity: 2, babyMonths: 0, feedingType: 'mixed', style: 'anxious_nb'),
  Persona(id: 'P53', name: '신생아맘C', desc: '생후1개월 완모 꼼꼼', formality: 2, verbosity: 3, babyMonths: 1, feedingType: 'breast', style: 'detailed_nb'),
  Persona(id: 'P54', name: '신생아맘D', desc: '생후0개월 완분 야간', formality: 1, verbosity: 1, babyMonths: 0, feedingType: 'formula', style: 'night_nb'),
  Persona(id: 'P55', name: '신생아맘E', desc: '생후1개월 혼합 STT', formality: 1, typoRate: 0.3, verbosity: 1, babyMonths: 1, feedingType: 'mixed', style: 'stt_nb'),

  // ── 쌍둥이/다둥이맘 그룹 (56~62) ──
  Persona(id: 'P56', name: '쌍둥이맘A', desc: '생후6개월 혼합 비교', formality: 1, verbosity: 2, babyMonths: 6, feedingType: 'mixed', style: 'twin'),
  Persona(id: 'P57', name: '쌍둥이맘B', desc: '생후4개월 완분 빈번', formality: 1, verbosity: 0, babyMonths: 4, feedingType: 'formula', style: 'twin_fast'),
  Persona(id: 'P58', name: '다둥이맘A', desc: '생후8개월 이유식 경험', formality: 1, verbosity: 1, babyMonths: 8, feedingType: 'babyfood', style: 'multi'),
  Persona(id: 'P59', name: '다둥이맘B', desc: '생후10개월 혼합 바쁨', formality: 0, verbosity: 0, babyMonths: 10, feedingType: 'mixed', style: 'multi_busy'),
  Persona(id: 'P60', name: '쌍둥이맘C', desc: '생후3개월 완분 야간', formality: 1, verbosity: 1, babyMonths: 3, feedingType: 'formula', style: 'twin_night'),
  Persona(id: 'P61', name: '다둥이맘C', desc: '생후12개월 이유식 효율', formality: 1, abbrRate: 0.5, verbosity: 0, babyMonths: 12, feedingType: 'babyfood', style: 'multi_eff'),
  Persona(id: 'P62', name: '쌍둥이맘D', desc: '생후7개월 혼합 감정', formality: 1, emojiRate: 0.4, verbosity: 2, babyMonths: 7, feedingType: 'mixed', style: 'twin_emo'),

  // ── 음성입력파 그룹 (63~70) ──
  Persona(id: 'P63', name: 'STT맘A', desc: '생후5개월 완분 띄어쓰기없음', formality: 1, typoRate: 0.2, verbosity: 2, babyMonths: 5, feedingType: 'formula', style: 'stt'),
  Persona(id: 'P64', name: 'STT맘B', desc: '생후7개월 이유식 구어체', formality: 1, verbosity: 2, babyMonths: 7, feedingType: 'babyfood', style: 'stt_casual'),
  Persona(id: 'P65', name: 'STT아빠A', desc: '생후4개월 완모 음성', formality: 1, verbosity: 2, babyMonths: 4, feedingType: 'breast', style: 'stt_dad'),
  Persona(id: 'P66', name: 'STT맘C', desc: '생후9개월 혼합 장문', formality: 1, verbosity: 3, babyMonths: 9, feedingType: 'mixed', style: 'stt_long'),
  Persona(id: 'P67', name: 'STT맘D', desc: '생후6개월 완분 빠른', formality: 0, verbosity: 1, babyMonths: 6, feedingType: 'formula', style: 'stt_fast'),
  Persona(id: 'P68', name: 'STT맘E', desc: '생후3개월 완모 밤', formality: 1, verbosity: 1, babyMonths: 3, feedingType: 'breast', style: 'stt_night'),
  Persona(id: 'P69', name: 'STT맘F', desc: '생후11개월 이유식 긴문장', formality: 2, verbosity: 3, babyMonths: 11, feedingType: 'babyfood', style: 'stt_verbose'),
  Persona(id: 'P70', name: 'STT아빠B', desc: '생후8개월 혼합 간결', formality: 1, verbosity: 0, babyMonths: 8, feedingType: 'mixed', style: 'stt_short'),

  // ── 의료/전문 그룹 (71~77) ──
  Persona(id: 'P71', name: '의료맘A', desc: '생후2개월 완분 의학용어', formality: 3, verbosity: 2, babyMonths: 2, feedingType: 'formula', style: 'medical'),
  Persona(id: 'P72', name: '의료맘B', desc: '생후6개월 혼합 관찰일지', formality: 3, verbosity: 3, babyMonths: 6, feedingType: 'mixed', style: 'journal'),
  Persona(id: 'P73', name: '간호사맘', desc: '생후4개월 완모 정확', formality: 2, verbosity: 2, babyMonths: 4, feedingType: 'breast', style: 'nurse'),
  Persona(id: 'P74', name: '약사맘', desc: '생후3개월 완분 약이름', formality: 2, verbosity: 2, babyMonths: 3, feedingType: 'formula', style: 'pharmacist'),
  Persona(id: 'P75', name: '의료아빠', desc: '생후5개월 혼합 차트식', formality: 2, verbosity: 2, babyMonths: 5, feedingType: 'mixed', style: 'chart'),
  Persona(id: 'P76', name: '소아과맘', desc: '생후8개월 이유식 검진', formality: 2, verbosity: 2, babyMonths: 8, feedingType: 'babyfood', style: 'checkup'),
  Persona(id: 'P77', name: '영양사맘', desc: '생후10개월 이유식 영양', formality: 2, verbosity: 2, babyMonths: 10, feedingType: 'babyfood', style: 'nutrition'),

  // ── 기록파 그룹 (78~85) ──
  Persona(id: 'P78', name: '기록파A', desc: '생후6개월 혼합 상세', formality: 2, verbosity: 3, babyMonths: 6, feedingType: 'mixed', style: 'detailed'),
  Persona(id: 'P79', name: '기록파B', desc: '생후12개월 이유식 시간표', formality: 2, verbosity: 2, babyMonths: 12, feedingType: 'babyfood', style: 'schedule'),
  Persona(id: 'P80', name: '기록파C', desc: '생후9개월 완분 숫자', formality: 2, verbosity: 1, babyMonths: 9, feedingType: 'formula', style: 'numbers'),
  Persona(id: 'P81', name: '기록파D', desc: '생후3개월 완모 일기체', formality: 2, verbosity: 3, babyMonths: 3, feedingType: 'breast', style: 'diary'),
  Persona(id: 'P82', name: '기록파E', desc: '생후7개월 혼합 메모', formality: 2, verbosity: 2, babyMonths: 7, feedingType: 'mixed', style: 'memo_rec'),
  Persona(id: 'P83', name: '기록파F', desc: '생후11개월 이유식 정리', formality: 2, verbosity: 2, babyMonths: 11, feedingType: 'babyfood', style: 'organized'),
  Persona(id: 'P84', name: '기록파G', desc: '생후4개월 완분 앱익숙', formality: 1, verbosity: 1, babyMonths: 4, feedingType: 'formula', style: 'app_savvy'),
  Persona(id: 'P85', name: '기록파H', desc: '생후2개월 완모 첫앱', formality: 2, verbosity: 2, babyMonths: 2, feedingType: 'breast', style: 'first_app'),

  // ── 감정/상황 특화 그룹 (86~93) ──
  Persona(id: 'P86', name: '걱정맘', desc: '생후2개월 완분 불안', formality: 2, verbosity: 3, babyMonths: 2, feedingType: 'formula', style: 'worried'),
  Persona(id: 'P87', name: '행복맘', desc: '생후6개월 혼합 긍정', formality: 1, emojiRate: 0.6, verbosity: 2, babyMonths: 6, feedingType: 'mixed', style: 'happy'),
  Persona(id: 'P88', name: '피곤맘', desc: '생후3개월 완모 수면부족', formality: 0, verbosity: 1, babyMonths: 3, feedingType: 'breast', style: 'tired'),
  Persona(id: 'P89', name: '여유맘', desc: '생후12개월 이유식 경험', formality: 1, verbosity: 2, babyMonths: 12, feedingType: 'babyfood', style: 'relaxed'),
  Persona(id: 'P90', name: '급한맘', desc: '생후8개월 완분 빠른', formality: 0, abbrRate: 0.6, verbosity: 0, babyMonths: 8, feedingType: 'formula', style: 'rushed'),
  Persona(id: 'P91', name: '꼼꼼아빠', desc: '생후5개월 혼합 체크리스트', formality: 2, verbosity: 2, babyMonths: 5, feedingType: 'mixed', style: 'checklist'),
  Persona(id: 'P92', name: '재미맘', desc: '생후7개월 완분 유머', formality: 0, emojiRate: 0.5, verbosity: 2, babyMonths: 7, feedingType: 'formula', style: 'humorous'),
  Persona(id: 'P93', name: '정리맘', desc: '생후10개월 이유식 깔끔', formality: 2, verbosity: 1, babyMonths: 10, feedingType: 'babyfood', style: 'neat'),

  // ── 특수상황 그룹 (94~100) ──
  Persona(id: 'P94', name: '외국맘', desc: '생후4개월 완분 어색한한국어', formality: 2, typoRate: 0.4, verbosity: 1, babyMonths: 4, feedingType: 'formula', style: 'foreigner'),
  Persona(id: 'P95', name: '베이비시터', desc: '생후6개월 혼합 보고체', formality: 3, verbosity: 2, babyMonths: 6, feedingType: 'mixed', style: 'sitter'),
  Persona(id: 'P96', name: '어린이집교사', desc: '생후12개월 이유식 관찰', formality: 3, verbosity: 2, babyMonths: 12, feedingType: 'babyfood', style: 'teacher'),
  Persona(id: 'P97', name: '산후도우미', desc: '생후1개월 완모 전문', formality: 3, verbosity: 2, babyMonths: 1, feedingType: 'breast', style: 'doula'),
  Persona(id: 'P98', name: '이모돌봄', desc: '생후8개월 혼합 캐주얼', formality: 1, verbosity: 2, babyMonths: 8, feedingType: 'mixed', style: 'aunt'),
  Persona(id: 'P99', name: '군인아빠', desc: '생후3개월 완분 보고식', formality: 3, verbosity: 1, babyMonths: 3, feedingType: 'formula', style: 'military'),
  Persona(id: 'P100', name: '10대엄마', desc: '생후5개월 혼합 초약어', formality: 0, abbrRate: 0.8, emojiRate: 0.7, typoRate: 0.3, verbosity: 0, babyMonths: 5, feedingType: 'mixed', style: 'teen'),
];
