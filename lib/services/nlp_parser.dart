import 'package:chat_baby_time/models/baby_record.dart';
import 'package:uuid/uuid.dart';
import 'package:chat_baby_time/pipeline/nlp_pipeline.dart';
import 'package:chat_baby_time/pipeline/growth_stage.dart';
import 'package:chat_baby_time/pipeline/models/pipeline_trace.dart';

/// 한국어 자연어 입력을 파싱하여 BabyRecord로 변환하는 NLP 파서
///
/// v2: 가중치 스코어링 기반 카테고리 감지
///
/// 입력 예시:
/// - "오후 2시에 분유 120ml 먹음"
/// - "방금 기저귀 갈았어 응가"
/// - "아기 잠들었어"
/// - "체온 37.5도"
/// - "모유 수유 15분"
/// - "약 먹였어" → 건강(약) ← 기존에는 수유로 오분류
class NlpParser {
  static const _uuid = Uuid();

  // ===== 가중치 키워드 정의 =====
  // weight가 높을수록 해당 카테고리에 대한 확신이 높음

  /// 수유 키워드 (가중치) - 모유/분유만 해당
  static const _feedingKeywords = <String, double>{
    '수유': 3.0,
    '분유': 3.0,
    '모유': 3.0,
    '젖병': 2.5,
    '젖꼭지': 2.0,
    '우유': 2.0,
    '밀리': 1.5,
    '씨씨': 1.5,
    // v3 추가: 모유 관련 누락 표현
    '직수': 3.0,      // "직수했어" (직접수유)
    '빨아': 1.5,      // "젖 잘 빨아요"
    '빨았': 1.5,      // "젖 잘 빨았어"
    // 유축 관련
    '유축': 3.0,
    '짜냈': 2.5,
    '짜놓': 2.5,
    // v4 추가: 오탈자
    '머겼': 1.5,       // "먹였" 오타
    '완뇨': 1.5,       // "완료" 오타
    // v7 추가: 흔한 약어/줄임말
    '완분': 3.0,       // 완전분유 (매우 흔한 줄임말)
    '완모': 3.0,       // 완전모유 (매우 흔한 줄임말)
    '혼합': 2.5,       // "혼합수유", "혼합이야"
  };

  /// 이유식 키워드 (가중치) - 독립 카테고리
  static const _babyfoodKeywords = <String, double>{
    '이유식': 3.0,
    '먹었': 1.0,
    '먹임': 1.0,
    '먹였': 1.0,
    '먹음': 1.0,
    '죽': 2.5,
    '미음': 2.5,
    '퓨레': 2.5,
    '반찬': 2.0,
    '밥': 1.5,
    // 이유식 반찬 재료 (단백질)
    '소고기': 2.5,
    '쇠고기': 2.5,
    '닭고기': 2.5,
    '돼지고기': 2.5,
    '오리고기': 2.5,
    '양고기': 2.5,
    '소간': 2.5,
    '닭간': 2.5,
    '달걀': 2.0,
    '계란': 2.0,
    '노른자': 2.0,
    '흰자': 2.0,
    '두부': 2.0,
    '생선': 2.0,
    '흰살생선': 2.5,
    '연어': 2.0,
    '대구': 2.0,
    '명태': 2.0,
    '가자미': 2.0,
    '참치': 2.0,
    '새우': 2.0,
    '치즈': 2.0,
    '리코타': 2.0,
    '크림치즈': 2.0,
    '모짜렐라': 2.0,
    // 이유식 반찬 재료 (채소)
    '감자': 2.0,
    '고구마': 2.0,
    '브로콜리': 2.0,
    '콜리플라워': 2.0,
    '당근': 2.0,
    '시금치': 2.0,
    '애호박': 2.0,
    '단호박': 2.0,
    '양배추': 2.0,
    '비트': 2.0,
    '오이': 2.0,
    '무': 1.5,
    '파프리카': 2.0,
    '옥수수': 2.0,
    '완두콩': 2.0,
    '청경채': 2.0,
    // 이유식 반찬 재료 (곡류)
    '쌀': 1.5,
    '오트밀': 2.5,
    '현미': 2.0,
    '찹쌀': 2.0,
    // v15 추가
    '국': 1.5,         // "국 먹었어" (이유식 후기 국)
  };

  /// 이유식 정규식 패턴
  static final _babyfoodPatterns = <RegExp, double>{
    RegExp(r'\d+\s*(g|그램|그람)', caseSensitive: false): 2.5,  // "50g", "100그램"
    RegExp(r'\d+\s*(숟가락|숟갈|스푼)'): 2.5,                     // "3숟가락"
  };

  /// 간식 키워드 (가중치) - 독립 카테고리
  static const _snackKeywords = <String, double>{
    '간식': 3.0,
    '먹었': 1.0,
    '먹임': 1.0,
    '먹였': 1.0,
    '먹음': 1.0,
    '주스': 2.0,
    // 과일
    '사과': 2.0,
    '딸기': 2.0,
    '바나나': 2.0,
    '귤': 2.0,
    '포도': 2.0,
    '수박': 2.0,
    '참외': 2.0,
    '블루베리': 2.0,
    '라즈베리': 2.0,
    '배': 1.5,
    '감귤': 2.0,
    '키위': 2.0,
    '복숭아': 2.0,
    '천도복숭아': 2.0,
    '자두': 2.0,
    '체리': 2.0,
    '망고': 2.0,
    '멜론': 2.0,
    '한라봉': 2.0,
    '토마토': 2.0,
    '아보카도': 2.0,
    // 과자류
    '과자': 2.0,
    '뻥튀기': 2.5,
    '떡뻥': 2.5,
    '쌀과자': 2.5,
    '요거트': 2.0,
    '요구르트': 2.0,
    '빵': 1.5,
    '과일': 2.0,
    '김': 1.5,
    '미숫가루': 2.0,
    '선식': 2.0,
    // v9 추가: BLW/핑거푸드 간식
    '오이 스틱': 3.5,   // "오이 스틱 줬어" → 간식 (babyfood "오이" 보다 우선)
    '스틱': 2.0,        // "당근 스틱", "고구마 스틱"
    // v15 추가
    '떡': 2.0,          // "떡 줬어" (아기 간식용 떡)
    // v12 추가: BLW/핑거푸드 확장
    '핑거푸드': 3.5,    // "핑거푸드 줬어"
    '퍼프': 2.5,        // "뻥튀기 퍼프" 등
    '웨이퍼': 2.0,      // 아기 웨이퍼
    '그래놀라': 2.0,
    '시리얼': 2.0,
    '크래커': 2.0,
    '젤리': 2.0,
    '푸딩': 2.0,
    '스무디': 2.0,
  };

  /// 간식 정규식 패턴
  static final _snackPatterns = <RegExp, double>{};

  /// 수유 정규식 패턴 (가중치)
  static final _feedingPatterns = <RegExp, double>{
    RegExp(r'\d+\s*(ml|cc)'): 3.0,    // "120ml", "100cc"
    RegExp(r'젖\s*(먹|물)'): 2.5,      // "젖 먹었어", "젖물렸어"
    RegExp(r'(반병|한병)'): 2.5,       // "반병 먹었어", "한병"
    RegExp(r'(한모금|두모금)'): 2.0,    // "한모금 먹었어"
    // v3 추가
    RegExp(r'젖\s*꼭지'): 2.0,        // "젖 꼭지 물림"
    RegExp(r'젖\s*빨'): 2.0,          // "젖 잘 빨아요"
    RegExp(r'직접\s*수유'): 3.0,       // "직접수유 했어"
    RegExp(r'양\s*(?:은|이|을|가|:)?\s*\d+'): 2.5,  // "양은 120이야", "양 120"
    RegExp(r'\d+\s*밀리리터'): 3.0,    // "160밀리리터"
    RegExp(r'(?:분유|모유|수유|젖병|유축)\s*\d{2,3}(?!\s*[가-힣a-z])'): 2.5, // "분유 100", "모유 80"
  };

  /// 수면 키워드 (가중치)
  static const _sleepKeywords = <String, double>{
    '잠들': 3.0,
    '잠잤': 3.0,
    '잠자': 3.0,
    '낮잠': 3.0,
    '밤잠': 3.0,
    '쪽잠': 3.0,
    '선잠': 3.0,
    '꿀잠': 3.0,
    '토닥': 2.0,
    '취침': 3.0,
    '수면': 3.0,
    '기상': 3.0,
    '재웠': 2.5,
    '재움': 2.5,
    '재워': 2.5,
    '재우': 2.0,
    '깼어': 2.5,
    '깸': 2.5,
    '눈떠': 2.5,
    '눈떴': 2.5,
    '눈뜨': 2.5,
    '일어났': 2.5,
    '일어나': 2.0,
    '잤어': 2.5,
    '잤다': 2.5,
    '잤음': 2.5,
    '잘잤': 2.5,
    '잠듬': 2.5,       // "잠듦" 구어체 변형
    '깼음': 2.5,       // "깼어" → "깼음" 변형
    '깼': 2.5,        // "깼어", "아기 깼어"
    // 추가 수면 표현
    '졸려': 1.5,     // 단독으로는 threshold 미달 (엄마 본인일 수 있음)
    '졸림': 1.5,
    '뒤척': 2.0,
    '자장가': 2.0,
    '잠투정': 2.5,
    '칭얼': 1.5,
    '안잠': 2.0,        // "안잠" (안 자)
    '자고': 2.0,
    '잘래': 2.0,
    '잘거': 2.0,
    // v3 추가: 누락된 수면 표현
    '잠듦': 2.5,       // 표준어 (기존 '잠듬'은 구어체)
    '하품': 1.5,       // "하품하더니 잠듦"
    '일어남': 2.5,     // "일어남" (명사형)
    // v3 추가: 오탈자 대응
    '잣어': 2.5,       // "잤어" 오타
    '잣다': 2.5,       // "잤다" 오타
    // v4 추가: 현재형/과거형 표현
    '자요': 2.5,       // "아기 자요" (현재형)
    '잠깨': 2.5,       // "잠깨고"
    '잠깼': 2.5,       // "잠깼어"
    // v4 추가: 약어
    '잠ㄱㄱ': 3.0,     // "잠 ㄱㄱ" = "잠 가자"
    // v5 추가: "자다" 활용형 (자서, 잤는데 등) — '자고'는 위에서 이미 정의됨
    '자서': 2.5,       // "1시에 자서 이제 일어났어"
    '잤는데': 2.5,     // "잤는데 깼어"
    // v6 추가: 단독 "잠" → 현재 시각 기준 낮잠/밤잠으로 바로 기록
    '잠': 2.0,         // "잠" (단독 입력 시 threshold 도달)
    // v15 추가: 현재형 수면 표현
    '잔다': 3.0,       // "잔다", "아기 잔다"
    '통잠': 3.0,       // "통잠 잤어"
  };

  /// 수면 정규식 패턴
  static final _sleepPatterns = <RegExp, double>{
    RegExp(r'깨\s*(어|었|서|고|남|요)'): 2.5,   // "깨었어", "깨서"
    RegExp(r'잠\s*(들|잤|잘|이)'): 3.0,         // "잠 들었어", "잠이 들었어"
    RegExp(r'(밤|낮|쪽|선|꿀)\s*잠'): 3.0,     // "밤잠", "낮잠 시작"
    RegExp(r'안\s*자'): 2.0,                    // "안 자", "안자"
    RegExp(r'자다\s*(깨|가)'): 2.5,             // "자다가 깼어"
    // v3 추가: 누락 패턴
    RegExp(r'자는\s*(중|거)'): 2.5,             // "자는 중", "자는 거야"
    RegExp(r'잠에\s*(빠|들)'): 2.5,             // "잠에 빠졌어"
    RegExp(r'눈\s*감'): 2.0,                    // "눈 감았어"
    RegExp(r'눈\s*떴'): 2.5,                    // "눈 떴어" (띄어쓰기 대응)
    RegExp(r'눈\s*뜨'): 2.5,                    // "눈 뜨다" (띄어쓰기 대응)
    RegExp(r'일어\s*났'): 2.5,                  // "일어 났어" (띄어쓰기)
    // v3 추가: 오탈자 패턴
    RegExp(r'잠\s*들?엇'): 2.5,                // "잠들엇어", "잠 들엇어"
    RegExp(r'잠\s*드럿'): 2.5,                  // "잠드럿어"
    RegExp(r'깨엇'): 2.5,                       // "깨엇어"
    RegExp(r'깻'): 2.5,                         // "깻어" (깼어 오타)
    RegExp(r'일어낫'): 2.5,                      // "일어낫어"
    // v4 추가: 현재형/과거형 표현
    RegExp(r'자기\s*시작'): 3.0,   // "자기 시작했어"
    RegExp(r'자들었'): 2.5,        // "자들었어" (잠들었어 오타)
    RegExp(r'이러났'): 2.5,        // "이러났어" (일어났어 오타)
    RegExp(r'잠잤'): 3.0,          // "잠잤어"
    RegExp(r'잠\s*ㄱㄱ'): 3.0,   // "잠 ㄱㄱ" (약어)
    // v5 추가: "자서...일어났" 패턴
    RegExp(r'자서\s*.+\s*일어'): 3.0,   // "자서 이제 일어났어"
    RegExp(r'자서\s*.+\s*깼'): 3.0,     // "자서 깼어"
    RegExp(r'자고\s*.+\s*일어'): 3.0,   // "자고 일어났어"
    // v15 추가
    RegExp(r'눈\s*붙'): 2.5,                    // "눈 붙였어" (짧은 수면)
    RegExp(r'잔다'): 3.0,                        // "아기 잔다" (현재형)
  };

  /// 기저귀 키워드 (가중치)
  static const _diaperKeywords = <String, double>{
    '기저귀': 3.0,
    '응가': 3.0,
    '대변': 3.0,
    '소변': 3.0,
    '오줌': 2.5,
    '배변': 2.5,
    '쌌어': 2.5,
    '갈았': 2.0,
    '갈아': 2.0,
    // 추가 기저귀 표현
    '똥': 2.5,
    '쉬했': 2.5,
    '갈아줬': 2.0,
    '갈아줘': 1.5,
    '기차갈': 2.0,  // 기저귀 → "기차갈" 음성인식 오류 대응
    '팬티': 1.5,     // 기저귀 팬티
    // v3 추가: 기저귀 문맥의 설사/변비
    '설사': 2.0,     // "설사했어" → 기저귀(대변) 관점도 존재 (건강에도 있음)
    '변비': 2.5,     // "변비 같아" → 기저귀 관점
    // v4 추가: 약자, 생략 표현, 오타
    '쌌음': 2.5,
    '갈아줬음': 2.0,
    '교체': 2.0,       // "교체했어", "교체함"
    '갈음': 2.0,       // "기저귀 갈음"
    '바꿔줬': 2.0,     // "바꿔줬어"
    '쉬': 2.0,         // "아기 쉬" (약칭)
    '묽은': 2.0,       // "묽은 변"
    '물변': 2.5,       // "물변 봤어"
    '딱딱한': 1.5,     // "딱딱한 변"
  };

  /// 기저귀 정규식 패턴
  static final _diaperPatterns = <RegExp, double>{
    RegExp(r'똥\s*(쌌|싸|나|봤|이)'): 3.0,     // "똥 쌌어", "똥 싸", "똥이"
    RegExp(r'쉬\s*(했|마려|마렵)'): 2.5,       // "쉬 했어", "쉬마려"
    RegExp(r'쉬\s*만'): 2.0,                   // v3: "쉬만 했어"
    RegExp(r'응가\s*(했|봤|함|나|를)'): 2.0,   // "응가 했어", "응가를"
    RegExp(r'기저귀\s*(갈|교|바)'): 2.0,       // "기저귀 갈아", "기저귀 교체", "기저귀 바꿨"
    RegExp(r'쌌\s*(어|다|요)'): 2.5,             // "쌌어", "쌌다" (과거형만 - "싸다"는 cheap과 중의)
    // v3 추가: 오탈자 대응
    RegExp(r'기저기\s*(갈|교|바)'): 2.0,       // "기저기 갈았어" (기저귀 오타)
    // v4 추가: 오탈자, 생략 표현
    RegExp(r'기져귀\s*(갈|교|바|했|봤)'): 2.0,  // "기져귀" 오탈자
    RegExp(r'(기저귀|기저기|기져귀)\s*(했|봤)'): 2.5,  // "기저귀 했어", "기저귀 봤어"
    RegExp(r'(묽은|노란|녹색|검은|물)\s*변'): 3.0,   // "묽은 변", "노란 변" 등
    RegExp(r'변\s*(봤|나|을|이)'): 2.5,              // "변 봤어", "변이 나왔어"
  };

  /// 건강 키워드 (가중치)
  static const _healthKeywords = <String, double>{
    '체온': 3.0,
    '온도': 2.5,
    '예방접종': 3.0,
    '병원': 1.5,  // 단독 "병원 갔어"는 milestone일 수 있으므로 가중치 하향
    '감기': 2.5,
    '기침': 2.5,
    '콧물': 2.5,
    '해열제': 3.0,
    '타이레놀': 3.0,
    '투약': 3.0,
    '복용': 2.5,
    '먹였': 1.0,  // "약 먹였어" 컨텍스트에서만 의미
    // 추가 건강 표현
    '구토': 3.0,
    '토했': 2.5,
    '토함': 2.5,
    '게워': 2.0,
    '발진': 2.5,
    '두드러기': 2.5,
    '아파': 2.0,
    '아프': 2.0,
    '울음': 1.0,   // 컨텍스트 의존
    '설사': 2.5,   // 건강 관점
    '소아과': 3.0,
    '진료': 2.5,
    '접종': 3.0,
    '주사': 2.5,
    '열남': 2.5,       // "열나" 줄임말
    '진물': 2.0,       // "배꼽에서 진물"
    '배꼽': 1.5,       // 신생아 배꼽
    '습진': 2.5,
    '알레르기': 2.5,
    // v13 추가: 증상/질환 키워드
    '중이염': 3.0,       // "중이염 진단받았어"
    '눈곱': 2.5,         // "눈곱 끼었어"
    '결막염': 3.0,
    '아토피': 2.5,
    '수족구': 3.0,
    // v15 추가: 누락된 건강 키워드
    '소화제': 3.0,       // "소화제 줬어"
    '경련': 3.0,         // "경련 일어났어"
    '탈수': 3.0,         // "탈수 증상"
    '황달': 3.0,         // "황달 수치"
    '장염': 3.0,         // "장염 걸렸어"
    // v3 추가: 약/보조제 관련
    '시럽': 2.5,       // "시럽 먹였어"
    '항생제': 3.0,     // "항생제 먹였어"
    '연고': 2.5,       // "연고 발랐어"
    '유산균': 2.5,     // "유산균 줬어"
    '프로바이오틱스': 2.5,
    '영양제': 2.5,     // "영양제 먹였어"
    // v3 추가: 접종/검진 관련 (대소문자 무관 → lowercase로 매칭)
    '검진': 2.5,       // "건강검진", "영유아 검진"
    '건강검진': 3.0,
    // v3 추가: 증상 키워드
    '코막': 2.5,       // "코 막혔어" (정규화로 "코막" 가능)
    '코딱지': 2.5,     // "코딱지 많이 나옴" → 건강
    '컨디션': 1.5,     // "컨디션이 안 좋아"
    // v4 추가: 약, 비타민, 체온 오타
    '감기약': 3.0,     // "감기약 먹였어"
    '비타민': 2.5,     // "비타민 줬어" → 건강(약)으로 분류
    '체운': 3.0,       // "체온" 오타
    // v6 추가: "약" 단독 입력 → 약 종류 선택지 제공
    '약': 2.0,         // "약" (단독 시 threshold 도달 → 약 종류 질문)
  };

  /// 건강 정규식 패턴
  static final _healthPatterns = <RegExp, double>{
    RegExp(r'\d{2}\.?\d?\s*(도|°)'): 3.0,       // "37.5도", "38°"
    RegExp(r'열\s*(이|나|있|높|났)'): 3.0,       // "열이 나", "열 높아"
    RegExp(r'약\s*(먹|줬|투|복|을|을\s*먹)'): 3.0, // "약 먹였어", "약 줬어"
    RegExp(r'토\s*(했|함|하)'): 2.5,             // "토 했어", "토함"
    RegExp(r'(배|머리|귀)\s*(아파|아프)'): 2.5,   // "배 아파", "머리 아파"
    // v3 추가
    RegExp(r'코\s*막'): 2.5,                    // "코 막혔어"
    RegExp(r'목이?\s*부'): 2.0,                  // "목이 부은 것 같아"
    RegExp(r'아픈\s*것\s*같'): 2.0,              // "아픈 것 같아"
    RegExp(r'(dtap|bcg|로타|폐렴구균|b형간염)', caseSensitive: false): 3.0, // 접종명
    RegExp(r'(발랐|바랐|바르)'): 1.5,            // "연고 발랐어" (도포)
    RegExp(r'약\s*(시럽|한\s*포|반\s*스푼)'): 3.0, // "약 시럽 줬어", "약 한 포"
    RegExp(r'토햇'): 2.5,                        // "토했어" 오타
    // v4 추가: 열 도 없이, 체온 도 없이
    RegExp(r'열\s+\d{2}\.\d'): 3.0,            // "열 38.7" (도 없이)
    RegExp(r'체온\s+\d{2}\.\d'): 3.0,          // "체온 37.5" (도 없이)
    // v4 추가: 병원/진료 이동
    RegExp(r'병원\s*(갔|다녀|방문|갈)'): 2.5,
    RegExp(r'(소아과|진료)\s*(갔|다녀|방문|갈)'): 3.0,
    // v15 추가
    RegExp(r'열\s*(떨어|내려|나아)'): 3.0,      // "열 떨어졌어", "열 내려갔어"
    RegExp(r'접종\s*후'): 2.5,                  // "접종 후 열남"
  };

  // ===== 복합 입력 분할 =====

  /// 시간 마커 패턴: "N시", "오전/오후 N시", "저녁 N시" 등
  static final _timeMarkerPattern = RegExp(
    r'(?:오전|오후|아침|저녁|밤)?\s*\d{1,2}\s*시\s*(?:반|\d{1,2}\s*분)?',
  );

  /// 복합 입력인지 판별 (시간 마커가 2개 이상)
  static bool isMultiInput(String input) {
    final lower = input.toLowerCase().trim();
    final timeMatches = _timeMarkerPattern.allMatches(lower).toList();
    return timeMatches.length >= 2;
  }

  /// 복합 입력을 세그먼트로 분할
  ///
  /// 전략: 접속사/시간 마커 조합으로 분할
  /// - "5시에 간식 사과 먹고 6시에 소고기 이유식 먹었어 그리고 7시 분유 110 먹고 8시에 잤어"
  /// → ["5시에 간식 사과 먹었어", "6시에 소고기 이유식 먹었어", "7시 분유 110 먹었어", "8시에 잤어"]
  static List<String> _splitSegments(String input) {
    final lower = input.trim();

    // 1단계: 접속사 뒤에 시간 마커가 오는 지점에서 분할
    //   "먹고 6시에" → split
    //   "그리고 7시" → split
    //   "그다음 8시" → split
    //   "그리고 " (뒤에 시간 없어도 분할)
    final splitPattern = RegExp(
      r'(?:,\s*|[.]?\s*)'                          // optional comma/period
      r'(?:'
        r'(?:먹고|하고|자고|깨고|갈고|쌌고|했고)\s+'  // 동사+고 + 공백
        r'(?=(?:오전|오후|아침|저녁|밤)?\s*\d{1,2}\s*시)'  // 시간 마커 lookahead
      r'|'
        r'(?:그리고|그다음에?|그\s*후에?|그런\s*다음|그러고\s*나서|그\s*뒤에?)\s+'  // 접속사
        r'(?=(?:오전|오후|아침|저녁|밤)?\s*\d{1,2}\s*시)?'  // optional time lookahead
      r'|'
        r'(?:먹고|하고|자고|깨고|갈고|쌌고|했고)\s+'  // 동사+고 (뒤에 시간 없어도, 다음 세그먼트 시작점)
        r'(?=(?:오전|오후|아침|저녁|밤)?\s*\d{1,2}\s*시)'
      r')',
    );

    // 먼저 접속사+시간 기반으로 분할 시도
    var segments = <String>[];
    final matches = splitPattern.allMatches(lower).toList();

    if (matches.isEmpty) {
      // 접속사 없이 시간 마커만 있는 경우: 시간 마커 직전에서 분할
      // "5시 사과 먹었어 6시 분유 먹었어 8시 잤어"
      segments = _splitByTimeMarkers(lower);
    } else {
      int lastEnd = 0;
      for (final m in matches) {
        final seg = lower.substring(lastEnd, m.start).trim();
        if (seg.isNotEmpty) segments.add(seg);
        lastEnd = m.end;
      }
      final last = lower.substring(lastEnd).trim();
      if (last.isNotEmpty) segments.add(last);
    }

    // 빈 세그먼트 제거 & 최소 길이 필터
    segments = segments.where((s) => s.trim().length >= 2).toList();

    // 접속사/연결어 기반 분할 (시간 마커 없는 복합 문장)
    if (segments.length <= 1) {
      final conjunctionPatterns = [
        RegExp(r'그리고\s+'),          // "잠깨고 그리고 분유 먹었어"
        RegExp(r'끝나고\s+'),          // "쉬했어 끝나고 유축 먹었어"
        RegExp(r'하고\s+(?=.*(?:먹|잤|잠|기저귀|분유|모유|체온|약))'),  // "응가하고 분유 먹었어"
        RegExp(r'(?:깨고|깨서|일어나서)\s+(?=.*(?:먹|분유|모유|젖|수유))'),  // "잠깨고 바로 젖 수유"
      ];
      for (final pattern in conjunctionPatterns) {
        final match = pattern.firstMatch(input);
        if (match != null) {
          final part1 = input.substring(0, match.start).trim();
          final part2 = input.substring(match.end).trim();
          if (part1.isNotEmpty && part2.isNotEmpty) {
            segments = [part1, part2];
            break;
          }
        }
      }
    }

    // 세그먼트가 1개 이하면 원본 반환
    if (segments.length <= 1) return [input.trim()];

    return segments;
  }

  /// 시간 마커 위치를 찾아 그 직전에서 분할
  static List<String> _splitByTimeMarkers(String input) {
    // 시간 마커의 시작 위치를 찾되, 첫 번째는 제외
    final timePattern = RegExp(
      r'(?:오전|오후|아침|저녁|밤)\s*\d{1,2}\s*시|(?<=\s)\d{1,2}\s*시',
    );
    final matches = timePattern.allMatches(input).toList();

    if (matches.length < 2) return [input];

    final segments = <String>[];
    int lastStart = 0;

    for (int i = 1; i < matches.length; i++) {
      // 시간 마커 직전의 자연스러운 분할 지점 찾기
      var splitPos = matches[i].start;

      // 시간 마커 앞에 접속사/조사가 있으면 그 앞에서 자르기
      final beforeTime = input.substring(lastStart, splitPos);
      // "먹고 ", "하고 ", "잤어 " 등의 패턴 뒤에서 분할
      final verbEndMatch = RegExp(
        r'(먹었어|먹음|먹고|하고|잤어|자고|깼어|갈았어|쌌어|했어|했고)\s*$',
      ).firstMatch(beforeTime);

      if (verbEndMatch != null) {
        // 동사 포함해서 현재 세그먼트에 넣음
        segments.add(input.substring(lastStart, splitPos).trim());
      } else {
        segments.add(input.substring(lastStart, splitPos).trim());
      }
      lastStart = splitPos;
    }

    // 마지막 세그먼트
    final lastSeg = input.substring(lastStart).trim();
    if (lastSeg.isNotEmpty) segments.add(lastSeg);

    return segments.where((s) => s.trim().length >= 2).toList();
  }

  /// 복합 입력을 파싱하여 여러 개의 ParseResult 반환
  ///
  /// 단일 입력이면 List에 하나만 담겨 반환되고,
  /// 복합 입력이면 세그먼트별로 각각 파싱한 결과가 담깁니다.
  ///
  /// 예시:
  /// "5시에 간식 사과 먹고 6시에 소고기 이유식 먹었어 그리고 7시 분유 110 먹고 8시에 잤어"
  /// → [ParseResult(간식/사과/5시), ParseResult(이유식/소고기/6시),
  ///    ParseResult(분유/110ml/7시), ParseResult(수면/8시)]
  static List<ParseResult> parseMulti(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return [ParseResult.failure('입력이 비어있습니다.')];
    }

    // 복합 입력 판별
    if (!isMultiInput(trimmed)) {
      return [parse(trimmed)];
    }

    // 세그먼트 분할
    final segments = _splitSegments(trimmed);

    if (segments.length <= 1) {
      return [parse(trimmed)];
    }

    // 각 세그먼트 개별 파싱
    final results = <ParseResult>[];
    for (final segment in segments) {
      final result = parse(segment);
      // 원본 rawInput은 세그먼트 텍스트로 보존
      results.add(result);
    }

    return results;
  }

  // ===== 메인 파싱 =====

  /// 텍스트를 파싱하여 BabyRecord 생성
  /// 텍스트 정규화: 감정 표현 제거, 이모티콘/특수문자 제거, 초성 약어 변환
  static String _normalizeText(String text) {
    var normalized = text;

    // v15: 문장 시작 이모지를 한글 키워드로 변환 (제거 전에 처리)
    // "💩 묵직함" → "응가 묵직함", "🌡️ 36.9" → "체온 36.9"
    // 문장 끝 장식 이모지("잤어 😴")는 변환하지 않음 — 아래에서 제거됨
    const emojiLeadMap = {
      '💩': '응가 ', '🍼': '분유 ', '🌡️': '체온 ', '🌡': '체온 ',
      '🛁': '목욕 ', '🥣': '이유식 ',
    };
    for (final entry in emojiLeadMap.entries) {
      if (normalized.startsWith(entry.key)) {
        normalized = entry.value + normalized.substring(entry.key.length);
      }
    }

    // v7: 이모지(유니코드) 제거 — 한글 범위(U+AC00~U+D7AF) 절대 포함 금지!
    // Supplementary Multilingual Plane 이모지만 제거 (U+1Fxxx)
    normalized = normalized.replaceAll(
      RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}'
             r'\u{1F1E0}-\u{1F1FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}'
             r'\u{1FA70}-\u{1FAFF}]+', unicode: true),
      ' ',
    );
    // Basic Multilingual Plane 기호 이모지 (한글 범위 회피: U+2600~U+27BF만)
    normalized = normalized.replaceAll(
      RegExp(r'[\u{2600}-\u{26FF}\u{2700}-\u{27BF}]+', unicode: true),
      ' ',
    );

    // v7: 초성 약어 → 실제 단어로 변환 (육아 맥락)
    normalized = normalized.replaceAllMapped(
      RegExp(r'ㅂㄴ\s*(\d+)'),     // "ㅂㄴ 120" → "분유 120"
      (m) => '분유 ${m.group(1)}',
    );
    normalized = normalized.replaceAllMapped(
      RegExp(r'ㅁㅇ\s*(\d+)'),     // "ㅁㅇ 15" → "모유 15"
      (m) => '모유 ${m.group(1)}',
    );
    normalized = normalized.replaceAll(RegExp(r'(?:^|\s)ㅂㄴ(?:\s|$)'), ' 분유 ');
    normalized = normalized.replaceAll(RegExp(r'(?:^|\s)ㅁㅇ(?:\s|$)'), ' 모유 ');
    normalized = normalized.replaceAll(RegExp(r'(?:^|\s)ㅇㅇㅅ(?:\s|$)'), ' 이유식 ');
    normalized = normalized.replaceAll(RegExp(r'(?:^|\s)ㄱㅈㄱ(?:\s|$)'), ' 기저귀 ');
    // v8 추가: "기갈" → "기저귀 갈았어" (흔한 초약어)
    normalized = normalized.replaceAll(RegExp(r'(?:^|\s)기갈(?:\s|$)'), ' 기저귀 갈았어 ');
    // v9 추가: "기갈요" → "기저귀 갈았어요" (존댓말 조합)
    normalized = normalized.replaceAll(RegExp(r'(?:^|\s)기갈요(?:\s|$)'), ' 기저귀 갈았어요 ');

    // v10: 유아 도메인 오타 사전 — 체계적 복원
    // 카테고리별 정리: 수유, 이유식, 수면, 기저귀, 건강, 간식, 기타
    final typoCorrections = <String, String>{
      // ── 수유 관련 ──
      '분루': '분유',       // ㅠ→ㅜ 혼동
      '분뉴': '분유',       // ㅇ→ㄴ 혼동
      '분유ㅜ': '분유',     // 실수 입력
      '무유': '모유',       // ㅗ→ㅜ 혼동
      '모우': '모유',       // ㅠ→ㅜ 혼동
      '쉬유': '수유',       // ㅜ→ㅟ 혼동
      '수우': '수유',       // ㅠ→ㅜ 혼동
      '직쑤': '직수',       // ㅅ→ㅆ 혼동
      '짃수': '직수',       // ㄱ→ㅅ 혼동
      '유촉': '유축',       // ㅜ→ㅗ 혼동
      '유출': '유축',       // ㅊ→ㅎ 혼동 (흔한 오타)
      '젖벼': '젖병',       // ㅕ→ㅗ 혼동
      '완몬': '완모',       // ㅗ→ㅓ 혼동 + ㄴ추가
      '완붕': '완분',       // ㅜ→ㅗ 혼동
      // ── 이유식 관련 ──
      '이윳식': '이유식',   // ㅜ→ㅠ+ㅅ 혼동
      '이유싟': '이유식',   // 받침 오타
      '이유시': '이유식',   // 받침 누락
      '이육식': '이유식',   // ㅠ→ㅜ+ㄱ 오타
      '퓨래': '퓨레',       // ㅔ→ㅐ 혼동
      '미은': '미음',       // ㅁ→ㄴ 받침 혼동
      '부로콜리': '브로콜리', // ㅡ→ㅜ 혼동
      '브로클리': '브로콜리', // 음절 누락
      // ── 수면 관련 ──
      '잤엇': '잤었',       // ㅓ→ㅗ 받침 혼동
      '잣어': '잤어',       // ㅆ→ㅅ 쌍자음 누락
      '잘었': '잤어',       // 과거형 오타
      '잠들엇': '잠들었',   // 받침 혼동
      '잠들엇어': '잠들었어',
      '재웟어': '재웠어',   // 받침 혼동
      '재웟': '재웠',
      '깻어': '깼어',       // ㅆ→ㅅ 쌍자음 누락
      '꺤어': '깼어',       // 자음 혼동
      '깨엇어': '깼어',     // 과거형 혼동
      '일어낫어': '일어났어', // ㅆ→ㅅ 누락
      '낫잠': '낮잠',       // ㅈ→ㅅ 받침 혼동
      '발잠': '밤잠',       // ㅁ→ㄹ 혼동
      // ── 기저귀 관련 ──
      '기져귀': '기저귀',   // ㅓ→ㅕ 혼동
      '기저기': '기저귀',   // ㅟ→ㅣ 혼동
      '기지귀': '기저귀',   // ㅓ→ㅣ 혼동
      '읏가': '응가',       // ㅇ→ㅡ+ㅅ 혼동
      '응까': '응가',       // ㄱ→ㄲ 쌍자음 과잉
      '갈앗어': '갈았어',   // 받침 혼동
      // ── 건강 관련 ──
      '체운': '체온',       // ㅗ→ㅜ 혼동
      '채온': '체온',       // ㅔ→ㅐ 혼동
      '예방접정': '예방접종', // ㅗ→ㅓ 혼동
      '해열재': '해열제',   // ㅔ→ㅐ 혼동
      '타일레놀': '타이레놀', // 음절 혼동
      '항셍제': '항생제',   // ㅐ→ㅔ 혼동
      '유산귤': '유산균',   // ㄴ→ㄹ 받침 혼동
      '비타밍': '비타민',   // ㄴ→ㅇ 받침 혼동
      // ── 간식 관련 ──
      '뻥투기': '뻥튀기',   // ㅟ→ㅜ 혼동
      '바나낭': '바나나',   // 받침 과잉
      '딸깃': '딸기',       // 받침 과잉
      '요거투': '요거트',   // ㅡ→ㅜ 혼동
      // ── 기타 ──
      '모곡': '목욕',       // 자음 혼동
      '목용': '목욕',       // ㅗ→ㅛ 혼동
      '산첵': '산책',       // ㅐ→ㅔ 혼동
      '먹엇': '먹었',       // ㅆ→ㅅ 받침 혼동
      '먹엿어': '먹였어',   // 과거형 혼동
      '먹혔어': '먹였어',   // ㅕ→ㅖ 혼동
      '줫어': '줬어',       // ㅆ→ㅅ 누락
    };
    for (final entry in typoCorrections.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }

    // ㅠㅠ, ㅜㅜ, ㅋㅋ, ㅎㅎ 등 자음 반복 제거
    normalized = normalized.replaceAll(RegExp(r'[ㅋㅎㅠㅜㅡ]+'), ' ');
    // 느낌표, 물음표 연속 제거
    normalized = normalized.replaceAll(RegExp(r'[!?~.]{2,}'), ' ');

    // v7: 감정 표현·감탄사 제거 (장문에서 노이즈 제거)
    normalized = normalized.replaceAll(RegExp(r'아\s*진짜|아\s*몰라|ㅜㅜ|ㅠㅠ|하아|휴|아이고|세상에'), ' ');

    // v12: 글자 사이 과도한 띄어쓰기 복원 ("분 유 먹 었 어" → "분유먹었어")
    // v12 fix: 3연속 → 4연속으로 강화 (정상 띄어쓰기 "오후 눈 맞춤" 오탈지 방지)
    if (RegExp(r'[\uac00-\ud7af]\s[\uac00-\ud7af]\s[\uac00-\ud7af]\s[\uac00-\ud7af]').hasMatch(normalized)) {
      normalized = normalized.replaceAllMapped(
        RegExp(r'(?<=[\uac00-\ud7af])\s(?=[\uac00-\ud7af])'),
        (m) => '',
      );
    }
    // 연속 공백 정리
    normalized = normalized.replaceAll(RegExp(r'\s{2,}'), ' ');
    return normalized.trim();
  }

  /// 본인/타인 언급 감지 → 아기 관련이 아닌 경우 스코어 감점
  /// "나 배고파", "남편 약", "드라마 보다가" 등
  static final _selfReferencePatterns = [
    RegExp(r'^나\s'),        // 문장 시작 "나 ..."
    RegExp(r'나는\s'),        // "나는"
    RegExp(r'내가\s'),        // "내가"
    RegExp(r'남편'),
    RegExp(r'엄마가\s'),
    RegExp(r'아빠가\s'),
    RegExp(r'엄마도\s'),      // "엄마도 밥 먹어야지"
    RegExp(r'아빠도\s'),      // "아빠도"
    RegExp(r'드라마'),
    RegExp(r'영화'),
    RegExp(r'유튜브'),
  ];

  /// 아기 관련 강한 키워드 — 이 키워드가 있으면 self-ref 감점 면제
  static const _babyContextKeywords = [
    '분유', '모유', '이유식', '젖병', '젖', '수유', '기저귀', '응가',
    '유축', '간식', '뻥튀기', '떡뻥', '체온', '예방접종',
    '낮잠', '밤잠', '재웠', '재움',
  ];

  static bool _hasSelfReference(String text) {
    for (final pat in _selfReferencePatterns) {
      if (pat.hasMatch(text)) {
        // v3: 아기 관련 키워드가 함께 있으면 감점하지 않음
        // 예: "아빠가 분유 먹였어" → 아기 기록이므로 감점 면제
        for (final bkw in _babyContextKeywords) {
          if (text.contains(bkw)) return false;
        }
        return true;
      }
    }
    return false;
  }

  static ParseResult parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return ParseResult.failure('입력이 비어있습니다.');
    }

    final lowerRaw = trimmed.toLowerCase();
    final lower = _normalizeText(lowerRaw);

    // 시간 파싱 (키워드 제거된 텍스트로)
    final cleanedForTime = _removeKeywordsForTimeParsing(lower);
    final timestamp = _parseTime(cleanedForTime);

    // ── 수정/삭제 요청 감지 ──
    final _updatePatterns = [
      RegExp(r'아니라\s*\d+'),                    // "240ml 아니라 100ml야"
      RegExp(r'(잘못|틀렸|틀림|오류)'),            // "시간 잘못 됐어"
      RegExp(r'(바꿔|변경|수정|고쳐)\s*(줘|해|주)'), // "바꿔줘", "수정해줘"
      RegExp(r'(취소|삭제|지워)\s*(해|줘|주|할)'),  // "취소해줘", "삭제해줘"
      RegExp(r'아까\s*(기록|먹인|적은).*아니'),     // "아까 먹인 거 아니라"
      // 타입 수정: "대변이 아니라 소변", "분유라고 했는데 모유야"
      RegExp(r'(대변|소변|분유|모유)이?\s*아니라\s*(대변|소변|분유|모유)'),
      RegExp(r'(분유|모유)(라고|이라고)\s*했는데'),
    ];
    if (_updatePatterns.any((p) => p.hasMatch(lower))) {
      return ParseResult.success(
        BabyRecord(
          id: _uuid.v4(),
          category: RecordCategory.other,
          timestamp: DateTime.now(),
          rawInput: trimmed,
          memo: '수정/삭제 요청: $trimmed',
        ),
        confidence: 0.7,
        message: '수정/삭제 요청',
      );
    }

    // ── 질문/조회 패턴 감지 (query → other) ──
    final _queryPatterns = [
      RegExp(r'[?？]'),                        // 물음표
      RegExp(r'(보여줘|알려줘|알려주|보여주)'),  // 조회 요청
      RegExp(r'(몇\s*(번|개|회))'),             // "몇 번", "몇 개"
      RegExp(r'(얼마야|얼마인|얼마나\s*됐)'),   // "얼마야" (조회), "얼마 전" 제외
      RegExp(r'얼마나\s*(먹|줘|줄|마셔)'),      // "얼마나 먹어야 해" (질문)
      RegExp(r'(먹어야|줘야|마셔야)\s*(해|하|할|되)'), // "먹어야 해" (질문)
      RegExp(r'언제'),                          // "언제 잤어?"
      RegExp(r'패턴\s*(은|이)?'),               // "수면 패턴은?"
      RegExp(r'(기록|히스토리|내역).*보'),       // "기록 보여줘"
    ];
    // lower + lowerRaw 모두 체크 (normalize에서 ?.. 등이 삭제될 수 있으므로)
    final bool isQuery = _queryPatterns.any((p) => p.hasMatch(lower) || p.hasMatch(lowerRaw));
    if (isQuery) {
      // 질문 문장은 기록이 아니므로 other로 처리
      return ParseResult.success(
        BabyRecord(
          id: _uuid.v4(),
          category: RecordCategory.other,
          timestamp: DateTime.now(),
          rawInput: trimmed,
          memo: trimmed,
        ),
        confidence: 0.5,
        message: '조회 요청',
      );
    }

    // ── 부정문 필터: "안 먹어", "안 자", "안 먹어" 등 → 기록이 아님 ──
    // "분유 안 먹어", "잠을 안 자" 등은 상태 표현/불만이지 기록이 아님
    final _negationPattern = RegExp(
      r'(안\s*(먹|자|잤|잠들|마셔|먹어|먹었|먹음)|못\s*(먹|자|잤|잠들|마셔))',
    );
    // 단, "안 먹어서 걱정" 속에 실제 기록이 있는 경우 제외:
    // "안 먹어서 분유 120ml 겨우 먹였어" → 120ml 기록 있으므로 패스
    final hasActualRecord = RegExp(r'\d{2,3}\s*(ml|cc|밀리|분)').hasMatch(lower);
    if (_negationPattern.hasMatch(lower) && !hasActualRecord) {
      // "안 먹어"가 문장의 주된 내용인지 확인 (뒤에 기록 동사가 없어야)
      final hasRecordVerb = RegExp(r'(먹였|줬|먹음|먹었어|갈았|재웠|먹임)').hasMatch(lower);
      // v13: "안 자다가 겨우 잤어" → 부정 후 전환이 있으면 실제 수면 기록
      final hasSleepTransition = RegExp(r'(자다가|안\s*자다가)\s*.*(잤|잠들|재웠|깼)').hasMatch(lower);
      if (!hasRecordVerb && !hasSleepTransition) {
        return ParseResult.success(
          BabyRecord(
            id: _uuid.v4(),
            category: RecordCategory.other,
            timestamp: DateTime.now(),
            rawInput: trimmed,
            memo: trimmed,
          ),
          confidence: 0.3,
          message: '기타 (상태/불만 표현)',
        );
      }
    }

    // ── 의도/계획 표현 필터 (noise → other) ──
    final _intentPatterns = [
      RegExp(r'(해야지|해야겠|해야\s*할|해야\s*하는)'),   // "밥 먹어야지"
      RegExp(r'만들어야|만들자|준비해야'),                 // "이유식 만들어야지"
      RegExp(r'사와야|사야\s*(해|하|될)'),                // "우유 사와야 해"
      RegExp(r'(찾아봐야|알아봐야|찾아보자|알아보자)'),    // "레시피 찾아봐야지"
      RegExp(r'뭐\s*(먹지|할까|하지|해주지|해줄까)'),     // "뭐 먹지", "뭐 해주지" (계획만)
      RegExp(r'갈까$|갈까\s'),                            // "산책 갈까"
      RegExp(r'(예약|예약해)'),                          // "소아과 예약해야 하나"
      RegExp(r'부족\s*(해|하다|한)'),                     // "잠이 너무 부족해"
      RegExp(r'(너무|진짜|정말)\s*(빠르|느리|힘들|피곤)'), // "시간이 너무 빨라"
      RegExp(r'(예쁘|귀엽|사랑스러)'),                    // "아기가 너무 예쁘다"
      RegExp(r'감사합니다|고마워|고맙'),                   // "감사합니다"
      RegExp(r'배고파|배고프|배고픈'),                     // "아기 배고파" (상태 표현, 기록 아님)
      // v7 추가: 잡담/감정/질문 표현
      RegExp(r'(어떡해|어떻게\s*해|어쩌지)'),              // "어떡해 안 먹어"
      RegExp(r'(?<!분리)(걱정|불안|스트레스)'),              // "걱정돼" (단, "분리불안"은 milestone이므로 제외)
      RegExp(r'(왜\s*이렇게|왜\s*이리|왜\s*이런)'),        // "왜 이렇게 안 먹지"
      RegExp(r'(잘\s*크|잘\s*자라|건강하).*(\?|까|나|지)'), // "잘 크고 있나?" (질문)
      RegExp(r'(좋은|좋겠|좋을)\s*(것|거|듯|텐데)'),       // "좋은 거 같아" (의견)
      RegExp(r'(안녕|반가|하이|헬로)'),                    // 인사말
      // v8 추가: 브랜드/추천/레시피 질문
      RegExp(r'(어떤|무슨)\s*(브랜드|제품|종류)'),          // "어떤 브랜드가 좋을까"
      RegExp(r'(추천|추천좀|추천해|추천\s*해줘)'),          // "이유식 레시피 추천좀"
      RegExp(r'레시피'),                                    // "레시피" 단독
      RegExp(r'(좋을까|좋을까요|좋아요|괜찮을까)'),          // "분유 어떤 브랜드가 좋을까요"
      RegExp(r'들쭉날쭉|고르지|불규칙'),                    // "먹는 양이 들쭉날쭉"
      // v9 추가: 불확실/걱정 표현 (기록이 아닌 고민)
      RegExp(r'(잘\s*나오는지|잘\s*먹는지|잘\s*자는지)\s*(모르겠|걱정|불안)'),  // "모유 잘 나오는지 모르겠어"
      RegExp(r'(젖몸살|젖꼭지\s*아프)'),                    // "젖몸살 올 것 같아"
      // v11 추가: 정상/괜찮은지 질문 (고민형 — 숫자 데이터 없는 순수 질문만)
      RegExp(r'(정상|괜찮)(인가|인지|이야|인 건지|일까|인건지)$'),  // "이거 정상인가" (문장 끝)
      RegExp(r'(맞나|맞는\s*건지|맞는지|맞을까)$'),                  // "이렇게 하는 게 맞나"
      // v11 추가: 확인/연락 등 계획 표현
      RegExp(r'(확인해야|체크해야|챙겨야)'),                 // "소아과 검진 예약 확인해야함"
      RegExp(r'(연락해야|전화해야|문의해야)'),               // "엄마한테 연락해야 하나요"
      // v11 추가: 비교/질문 표현
      RegExp(r'(다른\s*애|다른\s*아기|또래|평균)'),          // "다른 애들은 얼마나 먹어?"
      // v11 추가: 소망/희망 표현 (기록 동사 없이 바람만 표현)
      RegExp(r'(좋겠다|했으면\s*좋겠|됐으면\s*좋겠)'),       // "빨리 잤으면 좋겠다"
      // v13 추가: 양/방법 질문
      RegExp(r'(늘려야|줄여야|바꿔야)\s*(하나|할까|해)'),    // "수유량 늘려야 하나"
      RegExp(r'어떻게\s*(하지|해야|해줘야|할까)'),            // "변비 어떻게 하지"
    ];
    // v11: 강한 기록 데이터(ml/cc/도/분 + 숫자)가 있으면 의도 필터 우회
    // 예: "힘든데 분유 120ml 먹었어" → 기록 데이터 있으므로 의도 필터 스킵
    final hasStrongRecordData = RegExp(
      r'(\d{2,3}\s*(ml|cc|밀리)|체온\s*\d|\d+\.?\d*\s*도|\d+\s*분\s*(먹|수유|했|잤|직수|모유))',
    ).hasMatch(lower);
    if (_intentPatterns.any((p) => p.hasMatch(lower)) && !hasStrongRecordData) {
      return ParseResult.success(
        BabyRecord(
          id: _uuid.v4(),
          category: RecordCategory.other,
          timestamp: DateTime.now(),
          rawInput: trimmed,
          memo: trimmed,
        ),
        confidence: 0.3,
        message: '기타 (의도/계획 표현)',
      );
    }

    // ── 기저귀 약칭 감지: "소", "대", "쉬" 단독/짧은 표현 ──
    // "아기 소", "대 봤어", "쉬했어" 등 기저귀 약칭이 점수가 부족할 때 객관식 제공
    final _diaperAbbrevPattern = RegExp(
      r'(?:^|\s)(소|대|쉬)\s*(봤|했|요|$|[.!~ㅋㅎ])',
    );
    final _diaperColorAbbrev = RegExp(
      r'(녹색|노란|검은|묽은|물처럼|딱딱한|보통)(소|대|쉬)',
    );
    if (_diaperAbbrevPattern.hasMatch(lower) || _diaperColorAbbrev.hasMatch(lower)) {
      // 다른 강한 카테고리 키워드가 없으면 기저귀 약칭으로 간주 → 객관식
      final hasStrongOther = RegExp(r'(분유|모유|이유식|수유|잠|체온|약)').hasMatch(lower);
      if (!hasStrongOther) {
        // 소/대 구분
        final hasPoop = RegExp(r'(대|응가|똥)').hasMatch(lower);
        final hasPee = RegExp(r'(소|오줌|쉬)').hasMatch(lower) && !hasPoop;
        final guessedType = hasPoop ? '대변' : hasPee ? '소변' : null;

        return ParseResult.needsCategoryChoice(
          message: guessedType != null
              ? '기저귀($guessedType) 기록이 맞나요?'
              : '어떤 기록인가요?',
          rawInput: trimmed,
          options: [
            CategoryDisambiguationOption(
              category: RecordCategory.diaper,
              label: '기저귀(소변)',
              description: '쉬/소변',
            ),
            CategoryDisambiguationOption(
              category: RecordCategory.diaper,
              label: '기저귀(대변)',
              description: '응가/대변',
            ),
            CategoryDisambiguationOption(
              category: RecordCategory.diaper,
              label: '기저귀(소변+대변)',
              description: '둘 다',
            ),
            CategoryDisambiguationOption(
              category: RecordCategory.other,
              label: '기타',
              description: '기저귀가 아니에요',
            ),
          ],
        );
      }
    }

    // ── "젖 120", "젖 줬어" 등 → 모유 수유로 직접 분류 ──
    final _breastShortPattern = RegExp(r'젖\s*(\d+|줬|먹|물|조금)');
    if (_breastShortPattern.hasMatch(lower) &&
        !RegExp(r'(분유|이유식|죽|간식|잠|수면|기저귀|체온)').hasMatch(lower)) {
      return _parseFeedingRecord(lower, timestamp, 0.75,
          forcedFeedingType: FeedingType.breast);
    }

    // v7: 장문 입력에서 감정/설명 노이즈 제거 후 핵심만 추출
    // "아 진짜 안 먹어서 걱정인데 분유 120ml 겨우 먹였어" → "분유 120ml 겨우 먹였어"
    var scoringInput = lower;
    if (lower.length > 25) {
      // 접속사/감정 표현 기준으로 분리하여, 기록 키워드가 있는 부분만 사용
      final segments = lower.split(RegExp(r'[,\s]*(근데|그래서|그런데|인데|는데|서|지만|고\s)'));
      if (segments.length > 1) {
        // 각 세그먼트에서 기록 키워드를 가진 것만 결합
        final recordKeywords = RegExp(
          r'(분유|모유|수유|이유식|간식|잠|잤|깼|재웠|기저귀|응가|체온|열|약|먹|밀리|ml|cc|\d{2,3})'
        );
        final relevantSegments = segments.where((s) => recordKeywords.hasMatch(s)).toList();
        if (relevantSegments.isNotEmpty) {
          scoringInput = relevantSegments.join(' ');
        }
      }
    }

    // 가중치 스코어링으로 카테고리 판별
    final scores = _calculateCategoryScores(scoringInput);

    // 본인/타인 필터: 정규화 전 원본에서 체크 (공백이 보존된 상태)
    if (_hasSelfReference(lowerRaw)) {
      for (final key in scores.keys) {
        if (scores[key]! > 0) {
          scores[key] = scores[key]! * 0.3; // 70% 감점
        }
      }
    }

    // v12: Phrase-first 문맥 충돌 해결 (구문 > 단어)
    // ── 동음이의어 해결: phrase 매칭으로 개별 단어 스코어 무효화 ──

    // "두부 지탱" → milestone(머리=頭部), babyfood(두부=豆腐) 제거
    if (RegExp(r'두부\s*지탱').hasMatch(lower)) {
      scores[RecordCategory.babyfood] = 0.0;
    }
    // "XX 스틱" → 간식(핑거푸드), babyfood 감점
    if (RegExp(r'(오이|당근|고구마|사과|감자|바나나|치즈)\s*스틱').hasMatch(lower)) {
      scores[RecordCategory.babyfood] = (scores[RecordCategory.babyfood] ?? 0) * 0.2;
      scores[RecordCategory.snack] = (scores[RecordCategory.snack] ?? 0) + 2.0;
    }
    // "XX 퍼프" / "핑거푸드" → 간식
    if (RegExp(r'(퍼프|핑거\s*푸드|핑거푸드)').hasMatch(lower)) {
      scores[RecordCategory.snack] = (scores[RecordCategory.snack] ?? 0) + 3.0;
      scores[RecordCategory.babyfood] = (scores[RecordCategory.babyfood] ?? 0) * 0.3;
    }
    // "손으로 먹" / "BLW" / "손으로 집어 먹" → 간식 (BLW)
    if (RegExp(r'(손으로\s*먹|손으로\s*집|blw)', caseSensitive: false).hasMatch(lower)) {
      scores[RecordCategory.snack] = (scores[RecordCategory.snack] ?? 0) + 2.0;
    }

    // ── Babyfood 구문 확정: "XX죽", "XX미음", "XX퓨레" → babyfood 강화 ──
    if (RegExp(r'(소고기|닭고기|감자|고구마|당근|시금치|브로콜리|오트밀|쌀)\s*(죽|미음|퓨레)').hasMatch(lower)) {
      scores[RecordCategory.babyfood] = (scores[RecordCategory.babyfood] ?? 0) + 2.0;
      scores[RecordCategory.snack] = (scores[RecordCategory.snack] ?? 0) * 0.3;
    }

    // ── Milestone 구문 확정: 발달 문맥에서 음식 키워드 무효화 ──
    // "두부" + 발달 문맥 (지탱/발달/확인/성장)
    if (RegExp(r'두부').hasMatch(lower) &&
        RegExp(r'(지탱|발달|성장|확인|머리|목)').hasMatch(lower)) {
      scores[RecordCategory.babyfood] = 0.0;
    }
    // 성장 키워드가 강할 때 (3.0+) 음식 키워드 간섭 최소화
    if ((scores[RecordCategory.milestone] ?? 0) >= 5.0) {
      // milestone이 확실할 때, babyfood/snack의 간접 키워드 감점
      if ((scores[RecordCategory.babyfood] ?? 0) < 4.0) {
        scores[RecordCategory.babyfood] = (scores[RecordCategory.babyfood] ?? 0) * 0.3;
      }
    }

    // v15: 건강 문맥에서 수면 키워드 오탐 방지
    // "경련 일어났어" → "일어났"은 "발생했다"(health), "깨어남"(sleep)이 아님
    if (RegExp(r'(경련|발작|탈수|구토)').hasMatch(lower)) {
      if (RegExp(r'일어났|일어나').hasMatch(lower)) {
        scores[RecordCategory.sleep] = (scores[RecordCategory.sleep] ?? 0) * 0.2;
      }
    }

    // v7→v9: "120 먹었어", "80 줬어", "방금 200 줬어" 등 숫자+동사 → 수유로 추정
    // v9: ^앵커 제거 → 시간 접두사("방금", "아까", "새벽 2시에") 뒤에도 매칭
    if (RegExp(r'(?:^|\s)\d{2,3}\s*(먹|줬|먹었|먹임|먹음|줌|마심|마셨)').hasMatch(lower) &&
        !RegExp(r'(이유식|죽|미음|간식|과일)').hasMatch(lower)) {
      scores[RecordCategory.feeding] = (scores[RecordCategory.feeding] ?? 0) + 3.0;
    }

    // ── 복합문장 보정: "A 하고/먹고/먹이고 B" → 먼저 나온 행위 우선 ──
    // "분유 먹다 잠들었어" → 수유가 주된 행위
    // "분유 먹이고 기저귀 갈았어" → 수유가 주된 행위
    // "이유식 먹고 낮잠 잤어" → 이유식이 주된 행위
    final compoundConnector = RegExp(r'(먹다|먹고|먹이고|하고|끝나고|마치고|시키고|주고)\s*');
    final compoundSleepPattern = RegExp(
      r'(먹다|먹고|먹이고|하고|끝나고|마치고|시키고|주고)\s*(잠들|잤|재웠|잠|자|낮잠)',
    );
    if (compoundSleepPattern.hasMatch(lower)) {
      final nonSleepMax = scores.entries
          .where((e) => e.key != RecordCategory.sleep && e.value >= 2.0)
          .fold<double>(0, (a, e) => e.value > a ? e.value : a);
      if (nonSleepMax >= 2.0) {
        // v8: 0.3 → 0.1로 강화 (앞 행위가 확실히 우선하도록)
        scores[RecordCategory.sleep] = (scores[RecordCategory.sleep]! * 0.1);
      }
    }
    final compoundDiaperPattern = RegExp(
      r'(먹다|먹고|먹이고|하고|끝나고|마치고|시키고|주고)\s*(응가|똥|대변|소변|기저귀|갈았)',
    );
    if (compoundDiaperPattern.hasMatch(lower)) {
      final nonDiaperMax = scores.entries
          .where((e) => e.key != RecordCategory.diaper && e.value >= 2.0)
          .fold<double>(0, (a, e) => e.value > a ? e.value : a);
      if (nonDiaperMax >= 2.0) {
        // v8: 0.3 → 0.1로 강화
        scores[RecordCategory.diaper] = (scores[RecordCategory.diaper]! * 0.1);
      }
    }
    // "수유 중 잠들었어", "모유 먹으면서 잠들었어" → 수유가 주된 행위
    // v10: "직수 5분만에 잠들어버렸어" 등 시간 표현 사이에 끼인 패턴도 커버
    final feedingDuringSleepPattern = RegExp(
      r'(수유|분유|모유|젖|직수|유축)\s*(\d+\s*분\s*만에|중|하다가|하면서|먹다가|먹으면서|도중)\s*(잠들|잤|잠)',
    );
    if (feedingDuringSleepPattern.hasMatch(lower)) {
      scores[RecordCategory.sleep] = (scores[RecordCategory.sleep]! * 0.2);
    }

    // "먹다 토했어" → 건강(구토)이 주된 이벤트, 수유는 배경
    // v10: "수유 후 게워냈어", "분유 먹고 토했어" 등 수유 후 구토 패턴 확장
    final compoundVomitPattern = RegExp(r'(먹다|먹고|먹다가)\s*(토했|토함|게워|구토)');
    final feedingVomitPattern = RegExp(
      r'(수유|분유|모유|이유식|젖|직수)\s*(후|뒤에?|하고|끝나고|먹고)\s*(토했|토함|게워|구토|올렸|올림)',
    );
    if (compoundVomitPattern.hasMatch(lower) || feedingVomitPattern.hasMatch(lower)) {
      // 수유/이유식 점수를 감점하여 건강이 이기도록
      scores[RecordCategory.feeding] = (scores[RecordCategory.feeding]! * 0.3);
      scores[RecordCategory.babyfood] = (scores[RecordCategory.babyfood]! * 0.3);
      // v10: 건강 점수 부스트 (구토가 명확한 건강 이벤트)
      scores[RecordCategory.health] = (scores[RecordCategory.health] ?? 0) + 3.0;
    }

    // ── "이유식 100ml" 보정: 이유식 키워드 + ml → feeding에 ml 보너스가 붙지만 이유식이 맞음 ──
    if (RegExp(r'(이유식|죽|미음|퓨레)').hasMatch(lower) &&
        RegExp(r'\d+\s*(ml|cc|밀리)', caseSensitive: false).hasMatch(lower)) {
      // 이유식 점수에 ml 보너스를, feeding에서는 ml 보너스 제거
      scores[RecordCategory.babyfood] = scores[RecordCategory.babyfood]! + 3.0;
      scores[RecordCategory.feeding] = (scores[RecordCategory.feeding]! - 3.0).clamp(0, 999);
    }

    // 최고 점수 카테고리 선택
    final bestCategory = _selectBestCategory(scores);
    final maxAcross =
        scores.values.fold<double>(0, (a, b) => a > b ? a : b);

    // "밥 120" 등: 분유(ml) vs 이유식 구분 필요 (밥상·숫자 없는 밥 문장은 제외)
    if (_needsRiceFeedingDisambiguation(lower) &&
        (bestCategory == null ||
            bestCategory == RecordCategory.feeding ||
            bestCategory == RecordCategory.babyfood)) {
      return ParseResult.needsCategoryChoice(
        message:
            "'밥'과 숫자만으로는 분유(젖병·ml)인지 이유식인지 알 수 없어요. 해당하는 항목을 눌러주세요.",
        rawInput: trimmed,
        options: [
          const CategoryDisambiguationOption(category: RecordCategory.feeding, label: '분유', description: '젖병·ml'),
          const CategoryDisambiguationOption(category: RecordCategory.babyfood, label: '이유식', description: '밥·먹이'),
        ],
      );
    }

    if (bestCategory == null) {
      // 신호가 거의 없으면 기타 기록 (잡담·무관 입력)
      if (maxAcross < 1.5) {
        return ParseResult.success(
          BabyRecord(
            id: _uuid.v4(),
            category: RecordCategory.other,
            timestamp: timestamp,
            rawInput: trimmed,
            memo: trimmed,
          ),
          confidence: 0.3,
          message: '기타 기록으로 저장됩니다.',
        );
      }
      return ParseResult.needsCategoryChoice(
        message: '어떤 기록인지 잘 모르겠어요. 아래에서 골라주세요.',
        rawInput: trimmed,
        options: _defaultDisambiguationOptions(),
      );
    }

    // 동적 confidence 계산
    final maxScore = scores[bestCategory]!;
    final confidence = _calculateConfidence(maxScore, scores);

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final secondScore =
        sorted.length > 1 ? sorted[1].value : 0.0;
    final gap = maxScore - secondScore;

    if (_needsDisambiguation(
          bestCategory: bestCategory,
          maxScore: maxScore,
          secondScore: secondScore,
          gap: gap,
          confidence: confidence,
        )) {
      return ParseResult.needsCategoryChoice(
        message:
            '의도가 애매해요. 맞는 항목을 눌러주시면 그에 맞게 기록할게요.',
        rawInput: trimmed,
        options: _prioritizeOptions(bestCategory),
      );
    }

    switch (bestCategory) {
      case RecordCategory.feeding:
        return _parseFeedingRecord(lower, timestamp, confidence);
      case RecordCategory.babyfood:
        return _parseBabyfoodRecord(lower, timestamp, confidence, trimmed);
      case RecordCategory.snack:
        return _parseSnackRecord(lower, timestamp, confidence, trimmed);
      case RecordCategory.sleep:
        return _parseSleepRecord(lower, timestamp, confidence);
      case RecordCategory.diaper:
        return _parseDiaperRecord(lower, timestamp, confidence);
      case RecordCategory.health:
        return _parseHealthRecord(lower, timestamp, confidence);
      case RecordCategory.milestone:
        return ParseResult.success(
          BabyRecord(
            id: _uuid.v4(),
            category: RecordCategory.milestone,
            timestamp: timestamp,
            rawInput: trimmed,
            memo: trimmed,
          ),
          confidence: confidence,
          message: '성장/마일스톤 기록',
        );
      default:
        // 외출/산책/목욕 등 기타 카테고리
        final otherLabel = lower.contains('외출') ? '외출' :
            lower.contains('산책') ? '산책' :
            lower.contains('목욕') ? '목욕' : '기타';
        return ParseResult.success(
          BabyRecord(
            id: _uuid.v4(),
            category: RecordCategory.other,
            timestamp: timestamp,
            rawInput: trimmed,
            memo: trimmed,
          ),
          confidence: confidence,
          message: '$otherLabel 기록 완료',
        );
    }
  }

  /// 사용자가 객관식으로 고른 카테고리로만 파싱 (시간·세부 필드는 동일 규칙)
  static ParseResult parseWithCategory(String input, RecordCategory category) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return ParseResult.failure('입력이 비어있습니다.');
    }
    final lowerRaw = trimmed.toLowerCase();
    final lower = _normalizeText(lowerRaw);
    final cleanedForTime = _removeKeywordsForTimeParsing(lower);
    final timestamp = _parseTime(cleanedForTime);
    const confidence = 0.85;

    switch (category) {
      case RecordCategory.feeding:
        return _parseFeedingRecord(lower, timestamp, confidence);
      case RecordCategory.babyfood:
        return _parseBabyfoodRecord(lower, timestamp, confidence, trimmed);
      case RecordCategory.snack:
        return _parseSnackRecord(lower, timestamp, confidence, trimmed);
      case RecordCategory.sleep:
        return _parseSleepRecord(lower, timestamp, confidence);
      case RecordCategory.diaper:
        return _parseDiaperRecord(lower, timestamp, confidence);
      case RecordCategory.health:
        return _parseHealthRecord(lower, timestamp, confidence);
      case RecordCategory.milestone:
        return ParseResult.success(
          BabyRecord(
            id: _uuid.v4(),
            category: RecordCategory.milestone,
            timestamp: timestamp,
            rawInput: trimmed,
            memo: trimmed,
          ),
          confidence: confidence,
          message: '성장/마일스톤 기록',
        );
      case RecordCategory.other:
        return ParseResult.success(
          BabyRecord(
            id: _uuid.v4(),
            category: RecordCategory.other,
            timestamp: timestamp,
            rawInput: trimmed,
            memo: trimmed,
          ),
          confidence: confidence,
          message: '기타 기록',
        );
    }
  }

  /// '밥' + 숫자(양) 패턴이 있는데 분유/이유식 등 명시가 없을 때
  static bool _needsRiceFeedingDisambiguation(String input) {
    if (!_hasRicePlusNumberPattern(input)) return false;
    if (input.contains('분유') ||
        input.contains('모유') ||
        input.contains('이유식')) {
      return false;
    }
    if (input.contains('죽') ||
        input.contains('미음') ||
        input.contains('퓨레')) {
      return false;
    }
    if (RegExp(r'젖\s*(먹|물)').hasMatch(input) || input.contains('젖병')) {
      return false;
    }
    return true;
  }

  /// "밥 120", "밥120" (밥상 제외). `\d+\s*밥`은 제외 — "14:30 밥 먹었어"의 분·밥 오탐 방지
  static bool _hasRicePlusNumberPattern(String input) {
    return RegExp(r'밥\s*\d+').hasMatch(input);
  }

  /// 객관식으로 고른 수유 종류(분유/이유식)로 파싱
  static ParseResult parseWithFeedingType(String input, FeedingType feedingType) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return ParseResult.failure('입력이 비어있습니다.');
    }
    final lowerRaw = trimmed.toLowerCase();
    final lower = _normalizeText(lowerRaw);
    final cleanedForTime = _removeKeywordsForTimeParsing(lower);
    final timestamp = _parseTime(cleanedForTime);
    const confidence = 0.85;
    return _parseFeedingRecord(
      lower,
      timestamp,
      confidence,
      forcedFeedingType: feedingType,
    );
  }

  /// 약 종류 선택 후 재파싱
  static ParseResult parseWithMedicineType(String input, String medicineType) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return ParseResult.failure('입력이 비어있습니다.');
    }
    final lowerRaw = trimmed.toLowerCase();
    final lower = _normalizeText(lowerRaw);
    final cleanedForTime = _removeKeywordsForTimeParsing(lower);
    final timestamp = _parseTime(cleanedForTime);

    // 체온 파싱
    double? temperature;
    final tempMatch = RegExp(r'(\d{2}\.?\d?)\s*(도|°)').firstMatch(lower);
    if (tempMatch != null) {
      temperature = double.parse(tempMatch.group(1)!);
    }

    // 증상 메모 생성
    String? memo;
    final symptoms = <String>[];
    if (lower.contains('구토') || lower.contains('토했') || lower.contains('토함') || lower.contains('게워')) {
      symptoms.add('구토');
    }
    if (lower.contains('발진') || lower.contains('두드러기')) {
      symptoms.add('발진');
    }
    if (lower.contains('콧물')) symptoms.add('콧물');
    if (lower.contains('기침')) symptoms.add('기침');
    if (lower.contains('설사')) symptoms.add('설사');
    if (symptoms.isNotEmpty) {
      memo = symptoms.join(', ');
    }

    final record = BabyRecord(
      id: _uuid.v4(),
      category: RecordCategory.health,
      timestamp: timestamp,
      rawInput: trimmed,
      temperature: temperature,
      medicine: medicineType,
      memo: memo,
    );

    return ParseResult.success(
      record,
      confidence: 0.9,
      message: '$medicineType 복용 기록',
    );
  }

  static bool _needsDisambiguation({
    required RecordCategory bestCategory,
    required double maxScore,
    required double secondScore,
    required double gap,
    required double confidence,
  }) {
    // v7: 오분류보다 "물어보기"가 낫다 — threshold 강화
    // 1. 1·2등 점수가 가까우면 객관식 (gap < 1.5 이고 둘 다 점수가 있을 때)
    if (secondScore >= 1.5 && gap < 1.5) return true;
    // 2. confidence가 낮고 경쟁 카테고리가 의미있는 점수면 객관식
    if (confidence < 0.48 && secondScore >= 1.5 && gap < 2.0) return true;
    // 3. 1등 점수가 매우 낮고(2.0~2.5) 2등과 거의 동점이면 객관식
    if (maxScore <= 2.5 && secondScore >= 1.5 && gap < 1.0) return true;
    return false;
  }

  static List<CategoryDisambiguationOption> _defaultDisambiguationOptions() {
    return [
      const CategoryDisambiguationOption(category: RecordCategory.feeding),
      const CategoryDisambiguationOption(category: RecordCategory.babyfood),
      const CategoryDisambiguationOption(category: RecordCategory.snack),
      const CategoryDisambiguationOption(category: RecordCategory.sleep),
      const CategoryDisambiguationOption(category: RecordCategory.diaper),
      const CategoryDisambiguationOption(category: RecordCategory.health),
      const CategoryDisambiguationOption(category: RecordCategory.milestone),
      const CategoryDisambiguationOption(category: RecordCategory.other),
    ];
  }

  /// 객관식: 추정 1순위를 맨 위에
  static List<CategoryDisambiguationOption> _prioritizeOptions(
    RecordCategory best,
  ) {
    const order = <RecordCategory>[
      RecordCategory.feeding,
      RecordCategory.babyfood,
      RecordCategory.snack,
      RecordCategory.sleep,
      RecordCategory.diaper,
      RecordCategory.health,
      RecordCategory.milestone,
      RecordCategory.other,
    ];
    final rest = order.where((c) => c != best).toList();
    return [
      CategoryDisambiguationOption(category: best),
      ...rest.map((c) => CategoryDisambiguationOption(category: c)),
    ];
  }

  // ===== 가중치 스코어링 =====

  /// 마일스톤 키워드 (가중치) - 병원 방문, 성장 기록 등
  static const _milestoneKeywords = <String, double>{
    '뒤집기': 3.0,
    '뒤집었': 3.0,
    '기었': 3.0,
    '기어': 2.5,
    '걸었': 3.0,
    '걸음마': 3.0,
    '첫': 2.0,
    '처음': 2.0,
    '옹알이': 3.0,
    '이앓이': 2.5,
    '이빨': 2.0,
    '이나': 1.5,  // "이 나왔어"
    // v3 추가: 발달 마일스톤
    '앉았': 3.0,       // "앉았어", "혼자 앉았어"
    '앉기': 2.5,       // "혼자 앉기"
    '섰어': 3.0,       // "혼자 섰어"
    '서있': 2.5,       // "혼자 서있어"
    '웃었': 2.0,       // "웃었어", "처음 웃었어"
    '웃음': 2.0,       // "첫 웃음"
    '손뼉': 2.5,       // "손뼉 치기"
    '까꿍': 2.0,       // "까꿍 놀이"
    // v3 추가: 오탈자 대응
    '뒤집엇': 2.5,     // "뒤집엇어" 오타
    // v8 추가: 목 가누기
    '가누기': 3.0,     // "목 가누기 성공"
    '가눴': 3.0,       // "목 가눴어"
    '가누': 2.5,       // "목 가누는 중"
    // v9 추가: 두부 지탱 (머리 가누기 의학 용어) + 사회적 미소
    '두부 지탱': 4.0,  // "두부 지탱 발달 확인" (head support)
    '지탱': 2.5,       // "목 지탱"
    '사회적 미소': 4.0, // "사회적 미소 관찰됨" (social smile)
    '미소 관찰': 3.5,  // "미소 관찰됨"
    '관찰됨': 2.0,     // "발달 관찰됨"
    '발달 확인': 3.0,  // "발달 확인"
    '박수': 2.5,       // "박수 쳤어"
    '혼자 서기': 3.0,  // "혼자 서기 성공"
    '서기': 2.0,       // "서기 성공"
    // v12 추가: 대운동 발달 (gross motor)
    '배밀이': 3.0,       // belly crawling
    '네발 기기': 3.0,    // hands-and-knees crawling
    '잡고 서기': 3.5,    // pull to stand
    '잡고 걷기': 3.5,    // cruising
    '혼자 걷기': 3.5,    // independent walking
    '혼자 걸었': 3.5,    // "혼자 걸었어"
    '두 발짝': 3.0,      // "두 발짝 걸었어"
    '세 발짝': 3.0,
    '고개 들기': 3.0,    // head lifting
    '고개 들었': 3.0,
    '터미타임': 2.5,     // tummy time milestone
    // v12 추가: 소운동 발달 (fine motor)
    '손가락 잡기': 3.0,  // finger grasp
    '물건 잡기': 3.0,    // object grasp
    '물건 잡았': 3.0,
    '집게 잡기': 3.0,    // pincer grasp
    '가리키기': 3.0,     // pointing
    '가리켰': 3.0,
    '손짓': 2.5,         // gesturing
    '바이바이': 2.5,     // waving bye-bye
    // v12 추가: 사회/인지 발달
    '낯가림': 3.0,       // stranger anxiety
    '분리불안': 3.0,     // separation anxiety
    '눈 맞춤': 3.0,      // eye contact
    '이름 반응': 3.0,    // name recognition
    '소리 반응': 2.5,    // sound response
    '까꿍 반응': 3.0,    // peekaboo response
    '따라 하기': 3.0,    // imitation
    '따라했': 3.0,
    // v12 추가: 언어 발달
    '첫 단어': 3.5,      // first word
    '첫 말': 3.5,
    '옹알': 2.5,         // babbling (shorter form)
    '다다': 2.0,         // babbling sounds
    '마마': 2.0,
    '빠빠': 2.0,         // "빠빠" (bye bye)
    // v12 추가: 이/치아 발달
    '젖니': 3.0,         // baby tooth
    '유치': 2.5,         // primary tooth
    '이가 났': 3.0,      // tooth eruption
  };

  /// 기타 키워드 (목욕, 외출 등)
  static const _otherKeywords = <String, double>{
    '목욕': 3.0,
    '모곡': 2.5,       // "목욕" 오타
    '샤워': 2.0,
    '씻겼': 2.5,
    '씻김': 2.5,
    '외출': 3.0,       // "외출" 빠른 입력 지원
    '산책': 2.5,       // "산책 갔어"
  };

  /// 기타 정규식 패턴
  static final _otherPatterns = <RegExp, double>{
    RegExp(r'목욕\s*(했|시|함)'): 3.0,
    RegExp(r'씻\s*(겼|김|었)'): 2.5,
    RegExp(r'외출\s*(했|함|갔|나갔)'): 3.0,
    RegExp(r'산책\s*(했|함|갔|나갔)'): 2.5,
  };

  /// 마일스톤 정규식 패턴
  static final _milestonePatterns = <RegExp, double>{
    RegExp(r'(뒤집|기어|걸어)\s*(어|었|다)'): 3.0,
    // v3 추가: 발달 마일스톤 패턴
    RegExp(r'이\s*(나왔|났)'): 2.5,            // "이 나왔어", "이가 났어"
    RegExp(r'이가\s*(나|났|보)'): 2.5,          // "이가 났어", "이가 보여"
    RegExp(r'(엄마|아빠|맘마)\s*라고'): 3.0,    // "엄마라고 했어" (첫 말)
    RegExp(r'첫\s*말'): 3.0,                   // "첫 말을 했어"
    RegExp(r'혼자\s*(앉|서|섰|걸)'): 3.0,       // "혼자 앉았어", "혼자 서있어"
    RegExp(r'소리\s*내'): 1.5,                  // "소리 내서 웃었어"
    // v12 추가: 대운동 발달 패턴
    RegExp(r'목\s*(가누|지탱|세우)'): 3.0,      // "목 가누기", "목 세웠어"
    RegExp(r'고개\s*(들|세|숙)'): 2.5,          // "고개 들었어"
    RegExp(r'(잡고|벽잡고|가구잡고)\s*(서|걸)'): 3.0, // "잡고 섰어", "벽잡고 걸었어"
    RegExp(r'기어\s*다니'): 3.0,               // "기어다니기 시작"
    RegExp(r'(한|두|세|네)\s*발(짝|걸음)'): 3.0, // "두 발짝 걸었어"
    // v12 추가: 소운동/인지 발달 패턴
    RegExp(r'(물건|장난감)\s*(잡|쥐|집)'): 2.5, // "물건 잡았어"
    RegExp(r'(손|손가락)\s*으로\s*(잡|집|쥐)'): 2.5,
    RegExp(r'(낯|낯선\s*사람)\s*(가리|울)'): 3.0, // "낯가림 시작"
    RegExp(r'(이름|자기\s*이름)\s*(부르|불러).*반응'): 3.0,
    RegExp(r'따라\s*(하|했|해)'): 2.5,          // "따라했어"
    RegExp(r'바이\s*바이'): 2.5,                // "바이바이 했어"
    // v15 추가
    RegExp(r'이\s*\d+\s*개\s*(째|나)'): 3.0,    // "이 5개째 나왔어" (치아 발달)
  };

  /// 각 카테고리별 스코어 계산
  static Map<RecordCategory, double> _calculateCategoryScores(String input) {
    return {
      RecordCategory.feeding: _scoreCategory(input, _feedingKeywords, _feedingPatterns),
      RecordCategory.babyfood: _scoreCategory(input, _babyfoodKeywords, _babyfoodPatterns),
      RecordCategory.snack: _scoreCategory(input, _snackKeywords, _snackPatterns),
      RecordCategory.sleep: _scoreCategory(input, _sleepKeywords, _sleepPatterns),
      RecordCategory.diaper: _scoreCategory(input, _diaperKeywords, _diaperPatterns),
      RecordCategory.health: _scoreCategory(input, _healthKeywords, _healthPatterns),
      RecordCategory.milestone: _scoreCategory(input, _milestoneKeywords, _milestonePatterns),
      RecordCategory.other: _scoreCategory(input, _otherKeywords, _otherPatterns),
    };
  }

  /// 단일 카테고리 스코어 계산
  /// 짧은 키워드(1~2글자)가 다른 단어의 일부로 포함될 때 오탐 방지용 블랙리스트.
  /// 예: "무" → "무서워", "배" → "배고파", "약" → "약속", "쉬" → "쉬는 날"
  static final _shortKeywordFalsePositives = <String, List<RegExp>>{
    '무': [RegExp(r'무서|무리|무슨|무엇|무조건|무척|무시|무관')],
    '배': [RegExp(r'배고프|배고파|배고픈|배가\s*아파|배달|배우|배경|배려')],
    '쉬': [RegExp(r'쉬는\s*(날|시간|중)|쉬어|쉬었|쉬자|쉬고\s*싶|쉬세요|쉬운|쉬워')],
    '이나': [RegExp(r'이나\s*마찬|하이나|거나|시이나')],
    '약': [RegExp(r'약속|약간|약해|약하|약자|약점|계약|예약(?!접종)')],
    '김': [RegExp(r'김치|김밥|김이\s*모락|김빠|김서|김태|김현|김영|김민|감김')],
    '빵': [RegExp(r'빵꾸|빵터|빵빵')],
    '잠': [RegExp(r'잠깐|잠시|잠재|잠금|잠수')],
    '갈았': [RegExp(r'갈았다\s*놓|갈아\s*엎')],
    '교체': [RegExp(r'폰\s*교체|기기\s*교체|교체\s*주기')],
    '젖': [RegExp(r'젖었|젖은|젖히')],
    '열': [RegExp(r'열심|열쇠|열어|열린|열렬|열정|열기|나열|열차')],
    '병원': [RegExp(r'병원\s*(비|비용|값)이?\s*(비싸|부담)')],
  };

  /// 짧은 키워드가 오탐 블랙리스트에 해당하는지 체크
  static bool _isShortKeywordFalsePositive(String input, String keyword) {
    final fpList = _shortKeywordFalsePositives[keyword];
    if (fpList == null) return false;
    return fpList.any((fp) => fp.hasMatch(input));
  }

  /// v14: Phrase-first 스코어링 엔진
  /// 1) 긴 키워드(구문)를 먼저 매칭 → 매칭된 구문의 개별 단어는 중복 스코어 방지
  /// 2) 짧은 키워드는 오탐 블랙리스트 체크
  /// 3) 정규식 패턴 매칭
  static double _scoreCategory(
    String input,
    Map<String, double> keywords,
    Map<RegExp, double> patterns,
  ) {
    double score = 0;

    // Phase 1: 키워드를 길이 내림차순 정렬 (구문 우선)
    final sortedKeywords = keywords.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    // 매칭된 구문에 포함된 짧은 키워드 추적
    final consumedSubstrings = <String>{};

    for (final entry in sortedKeywords) {
      if (input.contains(entry.key)) {
        // 이미 더 긴 구문에 포함된 짧은 키워드는 스킵
        if (consumedSubstrings.any((phrase) => phrase.contains(entry.key) && phrase != entry.key)) {
          continue;
        }
        // 2글자 이하 키워드는 false positive 체크
        if (entry.key.length <= 2 && _isShortKeywordFalsePositive(input, entry.key)) {
          continue;
        }
        score += entry.value;
        // 3글자+ 구문이 매칭되면, 하위 키워드 중복 방지용으로 등록
        if (entry.key.length >= 3) {
          consumedSubstrings.add(entry.key);
        }
      }
    }

    // Phase 2: 정규식 패턴 매칭
    for (final entry in patterns.entries) {
      if (entry.key.hasMatch(input)) {
        score += entry.value;
      }
    }

    return score;
  }

  /// 최고 점수 카테고리 선택 (최소 임계값 2.0 이상)
  static RecordCategory? _selectBestCategory(Map<RecordCategory, double> scores) {
    const minThreshold = 2.0;

    RecordCategory? best;
    double bestScore = 0;

    for (final entry in scores.entries) {
      if (entry.value >= minThreshold && entry.value > bestScore) {
        best = entry.key;
        bestScore = entry.value;
      }
    }

    return best;
  }

  /// 동적 confidence 계산
  /// - 최고 점수가 높을수록 confidence 상승
  /// - 2등과의 차이가 클수록 confidence 상승
  static double _calculateConfidence(
    double maxScore,
    Map<RecordCategory, double> scores,
  ) {
    // 2등 점수 찾기
    final sortedScores = scores.values.toList()..sort((a, b) => b.compareTo(a));
    final secondScore = sortedScores.length > 1 ? sortedScores[1] : 0.0;

    // 기본 confidence: 최고 점수 기반 (2.0~6.0 → 0.5~0.95)
    double conf = (maxScore / 8.0).clamp(0.4, 0.95);

    // 1등과 2등 차이가 크면 보너스
    final gap = maxScore - secondScore;
    if (gap >= 3.0) {
      conf = (conf + 0.1).clamp(0.0, 0.95);
    } else if (gap < 1.0 && secondScore > 0) {
      // 차이가 너무 작으면 감점 (애매한 입력)
      conf = (conf - 0.15).clamp(0.3, 0.95);
    }

    return double.parse(conf.toStringAsFixed(2));
  }

  // ===== 시간 파싱 (기존과 동일) =====

  /// 시간 파싱 전에 키워드를 제거하여 "분유"의 "분"이 시간으로 잘못 파싱되는 것을 방지
  static String _removeKeywordsForTimeParsing(String input) {
    var cleaned = input;
    final feedingKeywords = ['분유', '분말', '분량'];
    for (final kw in feedingKeywords) {
      cleaned = cleaned.replaceAll(kw, ' ' * kw.length);
    }
    return cleaned;
  }

  /// "반" 표현을 "30분"으로 정규화하여 시간 파싱 안정성 확보.
  /// 일부 키보드에서 자모 분리("바ㄴ"), 보이지 않는 문자 삽입 등으로
  /// "시\s*반" 패턴이 실패할 수 있으므로, 사전에 통일된 형태로 변환한다.
  static String _normalizeHalfHour(String input) {
    // "N시반" / "N시 반" → "N시 30분" (오전/오후 포함 가능)
    // "반" 대신 "30분"으로 변환하면 하위 regex에서 확실히 매칭됨
    var result = input;

    // 자모 분리된 "바ㄴ"을 "반"으로 복원
    result = result.replaceAll('바ㄴ', '반');

    // "N시반" / "N시 반" → "N시 30분"
    result = result.replaceAllMapped(
      RegExp(r'(\d{1,2})\s*시\s*반'),
      (m) => '${m.group(1)}시 30분',
    );

    return result;
  }

  static DateTime _parseTime(String input) {
    final now = DateTime.now();

    // "반" → "30분" 사전 정규화 (키보드 자모 분리 등 대응)
    final normalized = _normalizeHalfHour(input);

    // "방금", "지금", "아까" 패턴
    if (normalized.contains('방금') || normalized.contains('지금') || normalized.contains('막')) {
      return now;
    }

    // "아까" 패턴 (약 30분 전으로 추정)
    if (normalized.contains('아까')) {
      return now.subtract(const Duration(minutes: 30));
    }

    // "N분 전" 패턴
    final minAgo = RegExp(r'(\d+)\s*분\s*전').firstMatch(normalized);
    if (minAgo != null) {
      return now.subtract(Duration(minutes: int.parse(minAgo.group(1)!)));
    }

    // "N시간 전" 패턴
    final hourAgo = RegExp(r'(\d+)\s*시간\s*전').firstMatch(normalized);
    if (hourAgo != null) {
      return now.subtract(Duration(hours: int.parse(hourAgo.group(1)!)));
    }

    // "오전/오후 N시 M분" 패턴 ("반"은 이미 "30분"으로 정규화됨)
    final ampm = RegExp(r'(오전|오후|아침|저녁|밤)\s*(\d{1,2})\s*시\s*(\d{1,2})?\s*분?')
        .firstMatch(normalized);
    if (ampm != null) {
      int hour = int.parse(ampm.group(2)!);
      final minute = ampm.group(3) != null ? int.parse(ampm.group(3)!) : 0;
      final period = ampm.group(1)!;

      if ((period == '오후' || period == '저녁' || period == '밤') && hour < 12) {
        hour += 12;
      } else if (period == '오전' || period == '아침') {
        if (hour == 12) hour = 0;
      }

      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    // "N시 M분" 패턴 (오전/오후 없이; "반"은 이미 "30분"으로 정규화됨)
    final timeOnly = RegExp(r'(\d{1,2})\s*시\s*(\d{1,2})?\s*분?').firstMatch(normalized);
    if (timeOnly != null) {
      final rawHour = int.parse(timeOnly.group(1)!);
      final minute = timeOnly.group(2) != null ? int.parse(timeOnly.group(2)!) : 0;
      final hour = _inferBestHour(rawHour, minute, now);
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    // "HH:MM" 패턴
    final colonTime = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(input);
    if (colonTime != null) {
      final rawHour = int.parse(colonTime.group(1)!);
      final minute = int.parse(colonTime.group(2)!);
      if (rawHour >= 13) {
        return DateTime(now.year, now.month, now.day, rawHour, minute);
      }
      final hour = _inferBestHour(rawHour, minute, now);
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    return now;
  }

  static int _inferBestHour(int rawHour, int minute, DateTime now) {
    if (rawHour >= 13 && rawHour <= 23) return rawHour;
    if (rawHour == 0) return 0;

    final amHour = rawHour == 12 ? 0 : rawHour;
    final pmHour = rawHour == 12 ? 12 : rawHour + 12;

    final amCandidate = DateTime(now.year, now.month, now.day, amHour, minute);
    final pmCandidate = DateTime(now.year, now.month, now.day, pmHour, minute);

    final amDiff = now.difference(amCandidate);
    final pmDiff = now.difference(pmCandidate);

    if (amDiff.isNegative && pmDiff.isNegative) {
      return amDiff.abs() < pmDiff.abs() ? amHour : pmHour;
    }
    if (!amDiff.isNegative && pmDiff.isNegative) return amHour;
    if (amDiff.isNegative && !pmDiff.isNegative) return pmHour;
    return amDiff < pmDiff ? amHour : pmHour;
  }

  // ===== 수유 기록 파싱 =====

  static ParseResult _parseFeedingRecord(
    String input,
    DateTime timestamp,
    double confidence, {
    FeedingType? forcedFeedingType,
  }) {
    FeedingType feedingType = FeedingType.formula;

    if (forcedFeedingType != null) {
      feedingType = forcedFeedingType;
    } else if (input.contains('모유') || input.contains('완모') ||
               RegExp(r'젖\s*(먹|물)').hasMatch(input) ||
               input.contains('직수') || RegExp(r'직접\s*수유').hasMatch(input) ||
               RegExp(r'젖\s*꼭지').hasMatch(input) || RegExp(r'젖\s*빨').hasMatch(input) ||
               RegExp(r'젖\s*수유').hasMatch(input)) {
      feedingType = FeedingType.breast;
    } else if (input.contains('유축') || input.contains('짜냈') || input.contains('짜놓')) {
      feedingType = FeedingType.breast;
    } else if (input.contains('혼합')) {
      // 혼합수유 → 기본적으로 분유로 기록하되 메모에 혼합 표시
      feedingType = FeedingType.formula;
    }

    // 양 파싱 (ml / 한국어 "양" — 분유 양 표현)
    int? amountMl;
    final mlMatch = RegExp(
      r'(\d+)\s*(ml|밀리|씨씨|cc|양)',
      caseSensitive: false,
    ).firstMatch(input);
    if (mlMatch != null) {
      amountMl = int.parse(mlMatch.group(1)!);
    }
    if (amountMl == null) {
      final yangLead = RegExp(r'양\s*[:\：]?\s*(\d+)').firstMatch(input);
      if (yangLead != null) {
        amountMl = int.parse(yangLead.group(1)!);
      }
    }
    if (amountMl == null) {
      final yangTopic =
          RegExp(r'양\s*(?:은|는|이|가|을|를)?\s*(\d+)').firstMatch(input);
      if (yangTopic != null) {
        amountMl = int.parse(yangTopic.group(1)!);
      }
    }
    if (amountMl == null) {
      final numYang = RegExp(r'(\d+)\s*(?:이|을|를)?\s*양').firstMatch(input);
      if (numYang != null) {
        amountMl = int.parse(numYang.group(1)!);
      }
    }
    if (amountMl == null) {
      final hangulMl = RegExp(r'(\d+)\s*밀리리터').firstMatch(input);
      if (hangulMl != null) {
        amountMl = int.parse(hangulMl.group(1)!);
      }
    }
    // "밥 120", "120 밥 먹었어"
    if (amountMl == null) {
      final riceAfter = RegExp(r'밥\s*(\d+)').firstMatch(input);
      if (riceAfter != null) {
        amountMl = int.parse(riceAfter.group(1)!);
      }
    }
    if (amountMl == null) {
      final riceBefore = RegExp(r'(\d+)\s*밥').firstMatch(input);
      if (riceBefore != null) {
        amountMl = int.parse(riceBefore.group(1)!);
      }
    }
    // "반병" → 약 100ml, "한병" → 약 200ml 추정
    if (amountMl == null) {
      if (input.contains('반병')) {
        amountMl = 100;
      } else if (input.contains('한병')) {
        amountMl = 200;
      }
    }
    // v7: 비정형 양 표현 처리
    if (amountMl == null) {
      if (RegExp(r'(반쯤|반\s*정도|반만)').hasMatch(input)) {
        amountMl = 100; // 반 → 약 100ml
      } else if (RegExp(r'(거의\s*다|다\s*먹|완(?:음|료|식))').hasMatch(input) &&
                 !RegExp(r'\d').hasMatch(input)) {
        amountMl = 200; // 다 먹었어 → 약 200ml
      } else if (RegExp(r'(조금|살짝|찔끔|조금만)').hasMatch(input)) {
        amountMl = 40; // 조금 → 약 40ml
      } else if (RegExp(r'(2/3|삼분의\s*이|3분의\s*2)').hasMatch(input)) {
        amountMl = 130; // 2/3 → 약 130ml
      } else if (RegExp(r'(1/3|삼분의\s*일|3분의\s*1)').hasMatch(input)) {
        amountMl = 70; // 1/3 → 약 70ml
      }
    }
    // "분유 100", "모유 80" 등: 수유 키워드 + 단위 없는 숫자 → ml로 추정
    // 단, 온도(도/°/℃)나 시간(시/분) 단위가 뒤에 오면 제외
    if (amountMl == null) {
      final feedingWithNum = RegExp(r'(?:분유|모유|수유|젖병|유축)\s*(\d{2,3})(?!\s*(?:도|°|℃|시|분))').firstMatch(input);
      if (feedingWithNum != null) {
        amountMl = int.parse(feedingWithNum.group(1)!);
      }
    }
    // "100 먹었어", "120 줬어", "80 먹음" 등: 숫자 + 동사 → ml로 추정
    if (amountMl == null) {
      final numVerb = RegExp(r'(\d{2,3})\s*(먹|줬|먹였|줌|먹음|먹임|마심|마셨)').firstMatch(input);
      if (numVerb != null) {
        amountMl = int.parse(numVerb.group(1)!);
      }
    }
    // "분유 80", "모유 120" 등: 수유 키워드 + 숫자만 단독으로 올 때 → ml
    if (amountMl == null) {
      final kwNum = RegExp(r'(?:분유|모유|수유|젖병|유축)\s+(\d{2,3})\s').firstMatch('$input ');
      if (kwNum != null) {
        amountMl = int.parse(kwNum.group(1)!);
      }
    }

    // 시간(분) 파싱
    int? durationMin;
    final korDurMatch = RegExp(r'(한|두|세|네)\s*시간\s*(반)?').firstMatch(input);
    if (korDurMatch != null) {
      final korNum = {'한': 1, '두': 2, '세': 3, '네': 4};
      final hours = korNum[korDurMatch.group(1)] ?? 1;
      final half = korDurMatch.group(2) != null ? 30 : 0;
      durationMin = hours * 60 + half;
    } else {
      final cleanedForDuration = input.replaceAll('분유', '  ').replaceAll('분말', '  ');
      // "5분 전 … 모유 10분 수유" 처럼 상대시각(N분 전)과 수유 시간(분)이 같이 있을 때
      // 첫 (\d+)분만 보면 수유 분이 누락되므로, "N분 전"이 아닌 항목만 채택
      for (final m in RegExp(r'(\d+)\s*분').allMatches(cleanedForDuration)) {
        final tail = cleanedForDuration.substring(m.end);
        if (RegExp(r'^\s*전').hasMatch(tail)) continue;
        durationMin = int.parse(m.group(1)!);
        break;
      }
    }

    String? memo;
    if (input.contains('유축') || input.contains('짜냈') || input.contains('짜놓')) {
      memo = '유축';
    }

    final record = BabyRecord(
      id: _uuid.v4(),
      category: RecordCategory.feeding,
      timestamp: timestamp,
      rawInput: input,
      feedingType: feedingType,
      amountMl: amountMl,
      durationMinutes: durationMin,
      memo: memo,
    );

    final typeName = feedingType == FeedingType.breast ? '모유' : '분유';

    // 모유 수유 시 시간 미입력이면 시간을 물어봄 (단, "모유 수유했어" 완료형은 추가 질문 생략)
    if (feedingType == FeedingType.breast && amountMl == null && durationMin == null) {
      if (!RegExp(r'모유\s*수유했').hasMatch(input)) {
        return ParseResult.needsAmountChoice(
          message: '모유 수유 시간이 어느 정도였나요?',
          rawInput: input,
          pendingRecord: record,
          options: const [
            AmountOption(label: '5분', durationText: '5'),
            AmountOption(label: '10분', durationText: '10'),
            AmountOption(label: '15분', durationText: '15'),
            AmountOption(label: '20분', durationText: '20'),
            AmountOption(label: '30분', durationText: '30'),
            AmountOption(label: '모름', durationText: null),
          ],
        );
      }
    }

    // 분유인데 양 미입력이면 양을 물어봄
    if (feedingType == FeedingType.formula && amountMl == null && durationMin == null) {
      return ParseResult.needsAmountChoice(
        message: '분유 양은 얼마였나요?',
        rawInput: input,
        pendingRecord: record,
        options: const [
          AmountOption(label: '60ml', amountMl: 60),
          AmountOption(label: '80ml', amountMl: 80),
          AmountOption(label: '100ml', amountMl: 100),
          AmountOption(label: '120ml', amountMl: 120),
          AmountOption(label: '160ml', amountMl: 160),
          AmountOption(label: '200ml', amountMl: 200),
          AmountOption(label: '모름', amountMl: null),
        ],
      );
    }

    // 양/시간 미입력 시 양 없이 바로 저장 (신뢰도 낮춤)
    final adjustedConf = (amountMl == null && durationMin == null)
        ? (confidence * 0.85).clamp(0.3, 0.95)
        : confidence;

    return ParseResult.success(
      record,
      confidence: adjustedConf,
      message: '수유($typeName) ${amountMl != null ? "${amountMl}ml" : ""}${durationMin != null ? " ${durationMin}분" : ""} 기록',
    );
  }

  // ===== 이유식 기록 파싱 =====

  static ParseResult _parseBabyfoodRecord(
    String input,
    DateTime timestamp,
    double confidence,
    String rawInput,
  ) {
    const babyfoodIngredients = [
      '소고기', '쇠고기', '닭고기', '돼지고기', '오리고기', '양고기', '소간', '닭간',
      '달걀', '계란', '노른자', '흰자', '두부',
      '생선', '흰살생선', '연어', '대구', '명태', '가자미', '참치', '새우',
      '치즈', '리코타', '크림치즈', '모짜렐라',
      '감자', '고구마', '브로콜리', '콜리플라워', '당근', '시금치',
      '애호박', '단호박', '양배추', '비트', '오이', '무', '파프리카',
      '옥수수', '완두콩', '청경채',
      '쌀', '오트밀', '현미', '찹쌀',
    ];

    // 재료 감지
    final detected = babyfoodIngredients.where((f) => input.contains(f)).toList();
    final foodMemo = detected.isNotEmpty ? detected.join(', ') : null;

    // 양 파싱 (ml 또는 g)
    int? amountMl;
    final mlMatch = RegExp(r'(\d+)\s*(ml|cc|밀리|씨씨)', caseSensitive: false).firstMatch(input);
    if (mlMatch != null) {
      amountMl = int.parse(mlMatch.group(1)!);
    }
    if (amountMl == null) {
      final gMatch = RegExp(r'(\d+)\s*(g|그램|그람)', caseSensitive: false).firstMatch(input);
      if (gMatch != null) {
        amountMl = int.parse(gMatch.group(1)!);
      }
    }
    // "밥 120"
    if (amountMl == null) {
      final riceAfter = RegExp(r'밥\s*(\d+)').firstMatch(input);
      if (riceAfter != null) {
        amountMl = int.parse(riceAfter.group(1)!);
      }
    }

    final record = BabyRecord(
      id: _uuid.v4(),
      category: RecordCategory.babyfood,
      timestamp: timestamp,
      rawInput: rawInput,
      amountMl: amountMl,
      memo: foodMemo,
    );

    final memoSuffix = foodMemo != null ? ' [$foodMemo]' : '';

    // 양 미입력 시 양 없이 바로 저장 (신뢰도 낮춤)
    if (amountMl == null) {
      return ParseResult.success(
        record,
        confidence: (confidence * 0.85).clamp(0.3, 0.95),
        message: '이유식$memoSuffix 기록',
      );
    }

    return ParseResult.success(
      record,
      confidence: confidence,
      message: '이유식 ${amountMl}ml$memoSuffix 기록',
    );
  }

  // ===== 간식 기록 파싱 =====

  static ParseResult _parseSnackRecord(
    String input,
    DateTime timestamp,
    double confidence,
    String rawInput,
  ) {
    const snackFoods = [
      '사과', '딸기', '바나나', '귤', '포도', '수박', '참외', '블루베리',
      '라즈베리', '배', '감귤', '키위', '복숭아', '천도복숭아', '자두', '체리',
      '망고', '멜론', '한라봉', '토마토', '아보카도',
      '과자', '뻥튀기', '떡뻥', '쌀과자', '요거트', '요구르트', '빵', '과일',
      '김', '미숫가루', '선식',
    ];

    final detected = snackFoods.where((f) => input.contains(f)).toList();
    final foodMemo = detected.isNotEmpty ? detected.join(', ') : null;

    int? amountGram;
    final gMatch = RegExp(r'(\d+)\s*(g|그램)', caseSensitive: false).firstMatch(input);
    if (gMatch != null) {
      amountGram = int.parse(gMatch.group(1)!);
    }

    final record = BabyRecord(
      id: _uuid.v4(),
      category: RecordCategory.snack,
      timestamp: timestamp,
      rawInput: rawInput,
      amountMl: amountGram,
      memo: foodMemo,
    );

    final gramSuffix = amountGram != null ? ' ${amountGram}g' : '';
    final memoSuffix = foodMemo != null ? ' [$foodMemo]' : '';

    return ParseResult.success(
      record,
      confidence: confidence,
      message: '간식$gramSuffix$memoSuffix 기록',
    );
  }

  // ===== 수면 기록 파싱 =====

  /// 시간 텍스트에서 시/분 추출 헬퍼
  static int? _extractHour(String text) {
    // "오후 2시", "밤 10시" 등
    final ampmMatch = RegExp(r'(오전|오후|아침|저녁|밤|새벽)\s*(\d{1,2})\s*시?\s*(\d{1,2})?\s*분?')
        .firstMatch(text);
    if (ampmMatch != null) {
      int h = int.parse(ampmMatch.group(2)!);
      final p = ampmMatch.group(1)!;
      if ((p == '오후' || p == '저녁' || p == '밤') && h < 12) h += 12;
      if ((p == '오전' || p == '아침' || p == '새벽') && h == 12) h = 0;
      return h;
    }
    // "2시", "14시" 등
    final hourMatch = RegExp(r'(\d{1,2})\s*시').firstMatch(text);
    if (hourMatch != null) return int.parse(hourMatch.group(1)!);
    return null;
  }

  static int? _extractMinute(String text) {
    final minMatch = RegExp(r'(\d{1,2})\s*시\s*(\d{1,2})\s*분').firstMatch(text);
    if (minMatch != null) return int.parse(minMatch.group(2)!);
    // "반" → 30분 (이미 normalizeHalfHour로 변환되었을 수 있음)
    if (text.contains('반')) return 30;
    return 0;
  }

  static ParseResult _parseSleepRecord(String input, DateTime timestamp, double confidence) {
    final now = DateTime.now();
    final normalized = _normalizeHalfHour(input);
    SleepStatus status = SleepStatus.start;

    final wakeKeywords = ['깼', '깸', '깼음', '눈떠', '눈떴', '눈뜨', '일어났', '일어나', '기상', '일어남'];
    final wakePatterns = [
      RegExp(r'깨\s*(어|었|서|고|남|요)'),
      RegExp(r'자다\s*(깨|가)'),
      RegExp(r'눈\s*떴'),
      RegExp(r'눈\s*뜨'),
      RegExp(r'일어\s*났'),
      RegExp(r'깨엇'),
      RegExp(r'깻'),
      RegExp(r'일어낫'),
    ];

    final isWake = wakeKeywords.any((kw) => normalized.contains(kw)) ||
        wakePatterns.any((p) => p.hasMatch(normalized));
    if (isWake) {
      status = SleepStatus.end;
    }

    // ── 수면 시간 범위 파싱 ──
    // "2시부터 자서 4시에 깼어", "1시에 자서 3시에 깼어", "밤10시~새벽2시"
    DateTime? sleepStart;
    DateTime? sleepEnd;
    int? durationMin;

    // 패턴 1: "N시(부터/에) 자서 M시(에) 깼어/일어났어"
    final rangePattern = RegExp(
      r'((?:오전|오후|아침|저녁|밤|새벽)?\s*\d{1,2}\s*시\s*(?:\d{1,2}\s*분)?)\s*(?:부터|에)?\s*(?:자서|잠들어서?|자다가?|재워서?)\s*((?:오전|오후|아침|저녁|밤|새벽)?\s*\d{1,2}\s*시\s*(?:\d{1,2}\s*분)?)\s*(?:에)?\s*(?:깼|깸|일어|기상|눈떠|눈떴)',
    );
    final rangeMatch = rangePattern.firstMatch(normalized);

    // 패턴 2: "N시~M시 잤어", "N시-M시 잠"
    final tildePattern = RegExp(
      r'((?:오전|오후|아침|저녁|밤|새벽)?\s*\d{1,2}\s*시\s*(?:\d{1,2}\s*분)?)\s*[~\-–부터]\s*((?:오전|오후|아침|저녁|밤|새벽)?\s*\d{1,2}\s*시\s*(?:\d{1,2}\s*분)?)',
    );
    final tildeMatch = tildePattern.firstMatch(normalized);

    // 패턴 3: "N시에 자서 (이제) 일어났어" — 시작 시각만 있고 끝은 "이제/방금/지금" = 현재 시각
    final nowWakePattern = RegExp(
      r'((?:오전|오후|아침|저녁|밤|새벽)?\s*\d{1,2}\s*시\s*(?:\d{1,2}\s*분)?)\s*(?:부터|에)?\s*(?:자서|잠들어서?|자다가?|재워서?)\s*(?:이제|방금|지금|금방)?\s*(?:깼|깸|일어|기상|눈떠|눈떴)',
    );
    final nowWakeMatch = nowWakePattern.firstMatch(normalized);

    if (rangeMatch != null) {
      final startStr = rangeMatch.group(1)!;
      final endStr = rangeMatch.group(2)!;
      final sh = _extractHour(startStr);
      final sm = _extractMinute(startStr);
      final eh = _extractHour(endStr);
      final em = _extractMinute(endStr);
      if (sh != null && eh != null) {
        sleepStart = DateTime(now.year, now.month, now.day, sh, sm ?? 0);
        sleepEnd = DateTime(now.year, now.month, now.day, eh, em ?? 0);
        // 자정 넘김 (예: 밤10시~새벽2시)
        if (sleepEnd!.isBefore(sleepStart!)) {
          sleepEnd = sleepEnd!.add(const Duration(days: 1));
        }
        durationMin = sleepEnd!.difference(sleepStart!).inMinutes;
        status = SleepStatus.end; // 범위 입력은 이미 끝난 수면
      }
    } else if (tildeMatch != null) {
      final startStr = tildeMatch.group(1)!;
      final endStr = tildeMatch.group(2)!;
      final sh = _extractHour(startStr);
      final sm = _extractMinute(startStr);
      final eh = _extractHour(endStr);
      final em = _extractMinute(endStr);
      if (sh != null && eh != null) {
        sleepStart = DateTime(now.year, now.month, now.day, sh, sm ?? 0);
        sleepEnd = DateTime(now.year, now.month, now.day, eh, em ?? 0);
        if (sleepEnd!.isBefore(sleepStart!)) {
          sleepEnd = sleepEnd!.add(const Duration(days: 1));
        }
        durationMin = sleepEnd!.difference(sleepStart!).inMinutes;
        status = SleepStatus.end;
      }
    } else if (nowWakeMatch != null) {
      // "1시에 자서 이제 일어났어" → 시작=1시(오후 추론), 끝=현재
      final startStr = nowWakeMatch.group(1)!;
      var sh = _extractHour(startStr);
      final sm = _extractMinute(startStr);
      if (sh != null) {
        // 오전/오후 명시가 없는 bare hour인 경우 스마트 AM/PM 추론
        final hasAmPm = RegExp(r'(오전|오후|아침|저녁|밤|새벽)').hasMatch(startStr);
        if (!hasAmPm && sh >= 1 && sh <= 12) {
          // "1시에 자서 이제 일어났어" → 현재가 오후면 오후 1시로 추론
          // 규칙: sh를 PM(+12)으로 해석했을 때 now보다 과거이고,
          //       AM으로 해석했을 때 미래이거나 너무 오래 전이면 PM 선택
          final amStart = DateTime(now.year, now.month, now.day, sh, sm ?? 0);
          final pmStart = DateTime(now.year, now.month, now.day, sh < 12 ? sh + 12 : sh, sm ?? 0);
          if (pmStart.isBefore(now) && now.difference(pmStart).inHours < 12) {
            sh = sh < 12 ? sh + 12 : sh; // PM으로 해석
          } else if (amStart.isBefore(now) && now.difference(amStart).inHours < 12) {
            // AM이 합리적
          } else if (pmStart.isBefore(now)) {
            sh = sh < 12 ? sh + 12 : sh; // PM fallback
          }
        }
        sleepStart = DateTime(now.year, now.month, now.day, sh, sm ?? 0);
        sleepEnd = now;
        // 자정 넘김 방지: sleepStart가 미래면 전날로
        if (sleepStart!.isAfter(now)) {
          sleepStart = sleepStart!.subtract(const Duration(days: 1));
        }
        durationMin = sleepEnd!.difference(sleepStart!).inMinutes;
        status = SleepStatus.end;
      }
    }

    // "N시간 잤어", "N시간 반 잤어" 패턴
    if (durationMin == null) {
      final hourDur = RegExp(r'(\d+)\s*시간\s*(반)?').firstMatch(normalized);
      if (hourDur != null) {
        final hours = int.parse(hourDur.group(1)!);
        final half = hourDur.group(2) != null ? 30 : 0;
        durationMin = hours * 60 + half;
      }
    }

    // "N분 잤어" 패턴 (수면 시간)
    if (durationMin == null) {
      final minDur = RegExp(r'(\d+)\s*분\s*(?:잤|잠|낮잠|밤잠|수면)').firstMatch(normalized);
      if (minDur != null) {
        durationMin = int.parse(minDur.group(1)!);
      }
    }

    // ── 낮잠/밤잠 구분 ──
    String? sleepType;
    if (normalized.contains('낮잠')) {
      sleepType = '낮잠';
    } else if (normalized.contains('밤잠')) {
      sleepType = '밤잠';
    } else if (normalized.contains('쪽잠')) {
      sleepType = '쪽잠';
    } else if (normalized.contains('선잠')) {
      sleepType = '선잠';
    } else if (normalized.contains('꿀잠')) {
      sleepType = '꿀잠';
    } else {
      // 시간 기반 자동 판단 (sleepStart 있으면 그것 기준, 없으면 timestamp 기준)
      // "잠", "잤어" 등 단독 입력도 현재 시각 기준으로 낮잠/밤잠 자동 분류
      final refHour = sleepStart?.hour ?? timestamp.hour;
      if (refHour >= 20 || refHour < 6) {
        sleepType = '밤잠';
      } else {
        sleepType = '낮잠';
      }
    }

    // 수면 시작 시각을 timestamp로 사용 (범위 입력이면)
    final recordTimestamp = sleepStart ?? timestamp;

    // 메모 구성
    final memoList = <String>[];
    if (sleepType != null) memoList.add(sleepType);
    if (sleepStart != null && sleepEnd != null) {
      final sf = '${sleepStart.hour.toString().padLeft(2, '0')}:${sleepStart.minute.toString().padLeft(2, '0')}';
      final ef = '${sleepEnd!.hour.toString().padLeft(2, '0')}:${sleepEnd!.minute.toString().padLeft(2, '0')}';
      memoList.add('$sf~$ef');
    }
    final memo = memoList.isNotEmpty ? memoList.join(' ') : null;

    final record = BabyRecord(
      id: _uuid.v4(),
      category: RecordCategory.sleep,
      timestamp: recordTimestamp,
      rawInput: input,
      sleepStatus: status,
      durationMinutes: durationMin,
      memo: memo,
    );

    // 메시지 구성
    final typeLabel = sleepType != null ? '$sleepType ' : '';
    String durStr = '';
    if (durationMin != null) {
      if (durationMin >= 60) {
        final h = durationMin ~/ 60;
        final m = durationMin % 60;
        durStr = m > 0 ? ' (${h}시간 ${m}분)' : ' (${h}시간)';
      } else {
        durStr = ' (${durationMin}분)';
      }
    }

    return ParseResult.success(
      record,
      confidence: sleepStart != null ? 0.95 : confidence,
      message: status == SleepStatus.end
          ? '$typeLabel깨어남$durStr 기록'
          : '$typeLabel잠듦 기록',
    );
  }

  // ===== 기저귀 기록 파싱 =====

  static ParseResult _parseDiaperRecord(String input, DateTime timestamp, double confidence) {
    DiaperType diaperType = DiaperType.pee;

    final poopKeywords = ['응가', '대변'];
    final poopPatterns = [RegExp(r'똥\s*(쌌|싸|나|봤)')];
    final peeKeywords = ['소변', '오줌'];
    final peePatterns = [RegExp(r'쉬\s*(했|마려|마렵)')];

    final hasPoop = poopKeywords.any((kw) => input.contains(kw)) ||
        poopPatterns.any((p) => p.hasMatch(input)) ||
        input.contains('똥');
    final hasPee = peeKeywords.any((kw) => input.contains(kw)) ||
        peePatterns.any((p) => p.hasMatch(input));

    if (hasPoop && hasPee) {
      diaperType = DiaperType.both;
    } else if (hasPoop) {
      diaperType = DiaperType.poop;
    } else {
      diaperType = DiaperType.pee;
    }

    // 대변 상태/색상 파싱 → memo에 저장
    final memoDetails = <String>[];

    // 상태
    final stoolConditions = {
      '묽': '묽음', '물같': '묽음', '설사': '설사', '질퍽': '묽음', '수양변': '묽음',
      '무른': '무름', '무르': '무름', '부드러': '무름', '흐물': '무름',
      '딱딱': '딱딱함', '단단': '딱딱함', '변비': '변비', '굳': '딱딱함',
    };
    for (final entry in stoolConditions.entries) {
      if (input.contains(entry.key)) {
        memoDetails.add(entry.value);
        break;
      }
    }

    // 색상
    final stoolColors = {
      '노란': '노란색', '황금': '황금색', '녹색': '녹색', '초록': '초록색',
      '갈색': '갈색', '검은': '검은색', '검정': '검은색', '빨간': '빨간색',
      '하얀': '흰색', '흰': '흰색', '회색': '회색',
    };
    for (final entry in stoolColors.entries) {
      if (input.contains(entry.key)) {
        memoDetails.add(entry.value);
        break;
      }
    }

    final memo = memoDetails.isNotEmpty ? memoDetails.join(', ') : null;

    final record = BabyRecord(
      id: _uuid.v4(),
      category: RecordCategory.diaper,
      timestamp: timestamp,
      rawInput: input,
      diaperType: diaperType,
      memo: memo,
    );

    final typeName = diaperType == DiaperType.pee
        ? '소변'
        : diaperType == DiaperType.poop
            ? '대변'
            : '소변+대변';

    // 대변(또는 소변+대변)인데 상태/색상 정보가 없으면 묽기+색깔 질문
    if ((diaperType == DiaperType.poop || diaperType == DiaperType.both) &&
        memoDetails.isEmpty) {
      return ParseResult.needsStoolDetailChoice(
        message: '대변 상태는 어땠나요?',
        rawInput: input,
        pendingRecord: record,
        consistencyOptions: defaultStoolConsistencyOptions,
        colorOptions: defaultStoolColorOptions,
      );
    }

    final memoText = memo != null ? ' ($memo)' : '';
    return ParseResult.success(
      record,
      confidence: confidence,
      message: '기저귀 교체($typeName)$memoText 기록',
    );
  }

  // ===== 건강 기록 파싱 =====

  static ParseResult _parseHealthRecord(String input, DateTime timestamp, double confidence) {
    double? temperature;
    String? medicine;

    // 체온 파싱
    final tempMatch = RegExp(r'(\d{2}\.?\d?)\s*(도|°)').firstMatch(input);
    if (tempMatch != null) {
      temperature = double.parse(tempMatch.group(1)!);
    }

    // 약 파싱 (v3: 시럽, 연고, 항생제, 유산균 등 추가)
    // 구체적인 약 이름이 있는지 확인
    final specificMedicines = [
      '해열제', '타이레놀', '감기약', '기침약', '항생제',
      '소화제', '유산균', '영양제', '비타민', '프로바이오틱스',
      '시럽', '연고',
    ];
    final hasSpecificMedicine = specificMedicines.any((m) => input.contains(m));

    if (RegExp(r'약\s*(먹|줬|투|복|을)').hasMatch(input) ||
        hasSpecificMedicine ||
        input.contains('투약') ||
        input.contains('복용') ||
        input.contains('약') ||
        RegExp(r'[\uac00-\ud7a3a-zA-Z0-9]{2,}\s*먹였').hasMatch(input)) {
      if (hasSpecificMedicine) {
        // 구체적인 약 이름이 있으면 그대로 사용
        for (final m in specificMedicines) {
          if (input.contains(m)) {
            medicine = m;
            break;
          }
        }
      } else {
        if (RegExp(r'약\s*먹였').hasMatch(input)) {
          medicine = '약 복용';
        } else {
          final customMed =
              RegExp(r'([\uac00-\ud7a3a-zA-Z0-9/+·]+)\s+먹였').firstMatch(input);
          if (customMed != null) {
            final name = customMed.group(1)!.trim();
            if (name.length >= 2 && !RegExp(r'^\d+$').hasMatch(name)) {
              medicine = name;
            }
          }
        }
        if (medicine == null) {
          return ParseResult.needsMedicineTypeChoice(
            message: '어떤 약을 먹었나요?',
            rawInput: input,
            options: defaultMedicineTypeOptions,
          );
        }
      }
    }

    // 증상 메모 생성
    String? memo;
    final symptoms = <String>[];
    if (input.contains('구토') || input.contains('토했') || input.contains('토함') || input.contains('게워')) {
      symptoms.add('구토');
    }
    if (input.contains('발진') || input.contains('두드러기')) {
      symptoms.add('발진');
    }
    if (input.contains('콧물')) symptoms.add('콧물');
    if (input.contains('기침')) symptoms.add('기침');
    if (input.contains('설사')) symptoms.add('설사');
    if (symptoms.isNotEmpty) {
      memo = symptoms.join(', ');
    }

    final record = BabyRecord(
      id: _uuid.v4(),
      category: RecordCategory.health,
      timestamp: timestamp,
      rawInput: input,
      temperature: temperature,
      medicine: medicine,
      memo: memo,
    );

    final memoText = memo != null ? ' ($memo)' : '';
    return ParseResult.success(
      record,
      confidence: confidence,
      message: temperature != null ? '체온 ${temperature}°C 기록$memoText' : '건강 기록$memoText',
    );
  }

  // ===== Pipeline Integration =====

  /// 새 파이프라인을 통한 파싱 (v2)
  /// growthStageIndex: 0=분유기, 1=이유식기, 2=유아식기
  static ParseResult parseWithPipeline(String input, {int growthStageIndex = 0}) {
    try {
      final stage = GrowthStage.values[growthStageIndex.clamp(0, 2)];
      final pipeline = NlpPipeline(growthStage: stage);
      final result = pipeline.run(input);

      if (result.success && result.record != null) {
        return ParseResult.success(
          result.record!,
          confidence: result.confidence,
          message: '기록이 저장되었어요.',
        );
      }

      if (result.needsDisambiguation) {
        return ParseResult._(
          isSuccess: false,
          confidence: result.confidence,
          message: result.suggestion ?? '어떤 기록인가요?',
          pendingRawInput: input,
        );
      }

      // Pipeline failed with suggestion for re-questioning
      return ParseResult._(
        isSuccess: false,
        confidence: result.confidence,
        message: result.suggestion ?? result.error ?? '입력을 이해하지 못했어요.',
        pendingRawInput: input,
      );
    } catch (e) {
      // Fallback to legacy parser
      return parse(input);
    }
  }

  /// 파이프라인 트레이스 포함 파싱 (디버깅용)
  static (ParseResult, PipelineTrace?) parseWithTrace(String input, {int growthStageIndex = 0}) {
    try {
      final stage = GrowthStage.values[growthStageIndex.clamp(0, 2)];
      final pipeline = NlpPipeline(growthStage: stage);
      final result = pipeline.run(input);

      final parseResult = result.success && result.record != null
          ? ParseResult.success(
              result.record!,
              confidence: result.confidence,
              message: '기록이 저장되었어요.',
            )
          : ParseResult._(
              isSuccess: false,
              confidence: result.confidence,
              message: result.suggestion ?? result.error ?? '입력을 이해하지 못했어요.',
              pendingRawInput: input,
            );

      return (parseResult, result.trace);
    } catch (e) {
      return (parse(input), null);
    }
  }
}

/// 객관식 카테고리 선택지
class CategoryDisambiguationOption {
  final RecordCategory category;
  final String label;
  final String description;

  const CategoryDisambiguationOption({
    required this.category,
    this.label = '',
    this.description = '',
  });
}

/// NLP 파싱 결과
class ParseResult {
  final bool isSuccess;
  final BabyRecord? record;
  final double confidence; // 0.0 ~ 1.0
  final String message;
  final List<CategoryDisambiguationOption>? disambiguationOptions;
  final List<FeedingType>? feedingTypeDisambiguationOptions;
  final String? pendingRawInput;

  /// 수유량 미입력 시 객관식 선택지 (예: [60, 80, 100, 120, 160, 200])
  final List<AmountOption>? amountOptions;

  /// 수유량 질문 시 이미 파싱된 중간 레코드 (amount만 채우면 완성)
  final BabyRecord? pendingRecord;

  /// 복합 입력에서 분할된 세그먼트 텍스트 (단일 입력이면 null)
  final String? segmentText;

  /// 약 종류 선택지 (해열제, 기침약, 감기약, 항생제 등)
  final List<MedicineTypeOption>? medicineTypeOptions;

  /// 대변 상세 정보 (묽기/색깔 선택)
  final List<StoolDetailOption>? stoolConsistencyOptions;
  final List<StoolDetailOption>? stoolColorOptions;

  bool get needsDisambiguation =>
      disambiguationOptions != null && disambiguationOptions!.isNotEmpty;

  bool get needsFeedingTypeDisambiguation =>
      feedingTypeDisambiguationOptions != null &&
      feedingTypeDisambiguationOptions!.isNotEmpty;

  bool get needsAmountInput =>
      amountOptions != null && amountOptions!.isNotEmpty;

  bool get needsMedicineTypeDisambiguation =>
      medicineTypeOptions != null && medicineTypeOptions!.isNotEmpty;

  bool get needsStoolDetailInput =>
      stoolConsistencyOptions != null && stoolConsistencyOptions!.isNotEmpty;

  const ParseResult._({
    required this.isSuccess,
    this.record,
    required this.confidence,
    required this.message,
    this.disambiguationOptions,
    this.feedingTypeDisambiguationOptions,
    this.pendingRawInput,
    this.amountOptions,
    this.pendingRecord,
    this.segmentText,
    this.medicineTypeOptions,
    this.stoolConsistencyOptions,
    this.stoolColorOptions,
  });

  factory ParseResult.success(
    BabyRecord record, {
    required double confidence,
    required String message,
  }) {
    return ParseResult._(
      isSuccess: true,
      record: record,
      confidence: confidence,
      message: message,
    );
  }

  factory ParseResult.failure(String message) {
    return ParseResult._(
      isSuccess: false,
      confidence: 0,
      message: message,
    );
  }

  factory ParseResult.needsCategoryChoice({
    required String message,
    required String rawInput,
    required List<CategoryDisambiguationOption> options,
  }) {
    return ParseResult._(
      isSuccess: false,
      confidence: 0,
      message: message,
      disambiguationOptions: options,
      pendingRawInput: rawInput,
    );
  }

  factory ParseResult.needsFeedingTypeChoice({
    required String message,
    required String rawInput,
    required List<FeedingType> options,
  }) {
    return ParseResult._(
      isSuccess: false,
      confidence: 0,
      message: message,
      feedingTypeDisambiguationOptions: options,
      pendingRawInput: rawInput,
    );
  }

  /// 약 종류 미입력 시 객관식 선택지 제공
  factory ParseResult.needsMedicineTypeChoice({
    required String message,
    required String rawInput,
    required List<MedicineTypeOption> options,
  }) {
    return ParseResult._(
      isSuccess: false,
      confidence: 0,
      message: message,
      medicineTypeOptions: options,
      pendingRawInput: rawInput,
    );
  }

  /// 수유량 미입력 시 객관식 선택지 제공
  factory ParseResult.needsAmountChoice({
    required String message,
    required String rawInput,
    required BabyRecord pendingRecord,
    required List<AmountOption> options,
  }) {
    return ParseResult._(
      isSuccess: false,
      confidence: 0,
      message: message,
      pendingRawInput: rawInput,
      pendingRecord: pendingRecord,
      amountOptions: options,
    );
  }

  /// 대변 상세 정보(묽기/색깔) 선택 제공
  factory ParseResult.needsStoolDetailChoice({
    required String message,
    required String rawInput,
    required BabyRecord pendingRecord,
    required List<StoolDetailOption> consistencyOptions,
    required List<StoolDetailOption> colorOptions,
  }) {
    return ParseResult._(
      isSuccess: false,
      confidence: 0,
      message: message,
      pendingRawInput: rawInput,
      pendingRecord: pendingRecord,
      stoolConsistencyOptions: consistencyOptions,
      stoolColorOptions: colorOptions,
    );
  }
}

/// 약 종류 선택지
class MedicineTypeOption {
  final String label;       // 표시 텍스트 ("해열제", "기침약" 등)
  final String medicineName; // 저장될 약 이름

  const MedicineTypeOption({
    required this.label,
    required this.medicineName,
  });
}

/// 기본 약 종류 목록
const defaultMedicineTypeOptions = [
  MedicineTypeOption(label: '해열제', medicineName: '해열제'),
  MedicineTypeOption(label: '감기약', medicineName: '감기약'),
  MedicineTypeOption(label: '기침약', medicineName: '기침약'),
  MedicineTypeOption(label: '항생제', medicineName: '항생제'),
  MedicineTypeOption(label: '소화제', medicineName: '소화제'),
  MedicineTypeOption(label: '유산균', medicineName: '유산균'),
  MedicineTypeOption(label: '비타민/영양제', medicineName: '비타민/영양제'),
  MedicineTypeOption(label: '기타 약', medicineName: '약 복용'),
];

/// 수유량 객관식 선택지
class AmountOption {
  final String label;   // 표시 텍스트 ("60ml", "조금", "반병" 등)
  final int? amountMl;  // ml 값 (null이면 직접 입력)
  final String? durationText; // 시간 기반일 때 ("10분", "15분" 등)

  const AmountOption({
    required this.label,
    this.amountMl,
    this.durationText,
  });
}

/// 대변 상세 정보 (묽기 + 색깔)
class StoolDetailOption {
  final String label;
  final String value;

  const StoolDetailOption({required this.label, required this.value});
}

/// 기본 대변 묽기 선택지
const defaultStoolConsistencyOptions = [
  StoolDetailOption(label: '보통', value: '보통'),
  StoolDetailOption(label: '묽음', value: '묽음'),
  StoolDetailOption(label: '꾸덕', value: '꾸덕'),
  StoolDetailOption(label: '설사', value: '설사'),
  StoolDetailOption(label: '변비', value: '변비'),
];

/// 기본 대변 색깔 선택지
const defaultStoolColorOptions = [
  StoolDetailOption(label: '노란색', value: '노란색'),
  StoolDetailOption(label: '갈색', value: '갈색'),
  StoolDetailOption(label: '녹색', value: '녹색'),
  StoolDetailOption(label: '검은색', value: '검은색'),
  StoolDetailOption(label: '빨간색', value: '빨간색'),
  StoolDetailOption(label: '흰색', value: '흰색'),
];
