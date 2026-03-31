#!/usr/bin/env python3
"""
ChatBabyTime NLP 파서 테스트 프로그램 (Python 포팅)

nlp_parser.dart v2의 가중치 스코어링 로직을 동일하게 구현하여
Flutter 없이도 NLP 인식율을 검증할 수 있습니다.

실행: python3 test/nlp_parser_test.py
"""

import re
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, Dict, List, Tuple
from datetime import datetime


# ============================================================
# 모델 정의 (baby_record.dart 대응)
# ============================================================

class RecordCategory(Enum):
    FEEDING = "feeding"
    SLEEP = "sleep"
    DIAPER = "diaper"
    HEALTH = "health"
    MILESTONE = "milestone"
    OTHER = "other"

class FeedingType(Enum):
    BREAST = "breast"
    FORMULA = "formula"
    BABYFOOD = "babyfood"
    SNACK = "snack"

class DiaperType(Enum):
    PEE = "pee"
    POOP = "poop"
    BOTH = "both"

class SleepStatus(Enum):
    START = "start"
    END = "end"

@dataclass
class ParseResult:
    is_success: bool
    category: Optional[RecordCategory] = None
    confidence: float = 0.0
    message: str = ""
    feeding_type: Optional[FeedingType] = None
    amount_ml: Optional[int] = None
    duration_min: Optional[int] = None
    sleep_status: Optional[SleepStatus] = None
    diaper_type: Optional[DiaperType] = None
    temperature: Optional[float] = None
    medicine: Optional[str] = None


# ============================================================
# NLP 파서 v2 (nlp_parser.dart 동일 로직)
# ============================================================

# 수유 키워드 (가중치)
FEEDING_KEYWORDS = {
    '수유': 3.0, '분유': 3.0, '모유': 3.0, '이유식': 3.0,
    '젖병': 2.5, '젖꼭지': 2.0, '우유': 2.0, '간식': 2.0,
    '주스': 2.0, '밀리': 1.5, '씨씨': 1.5,
    '먹었': 1.5, '먹임': 1.5, '먹였': 1.5, '먹음': 1.5, '먹여': 1.5,
    '먹고': 1.5, '먹어': 1.5,
    # 유축 관련
    '유축': 3.0, '짜냈': 2.5, '짜놓': 2.5,
    '죽': 2.0, '미음': 2.5, '퓨레': 2.5, '반찬': 2.0, '밥': 1.5,
    # 이유식 반찬 재료 (단백질)
    '소고기': 2.5, '쇠고기': 2.5, '닭고기': 2.5, '돼지고기': 2.5,
    '달걀': 2.0, '계란': 2.0, '두부': 2.0, '생선': 2.0,
    '연어': 2.0, '대구': 2.0, '새우': 2.0, '치즈': 2.0,
    # 이유식 반찬 재료 (채소)
    '감자': 2.0, '고구마': 2.0, '브로콜리': 2.0, '당근': 2.0,
    '시금치': 2.0, '애호박': 2.0, '단호박': 2.0, '양배추': 2.0, '비타민': 1.5,
    # 간식 구체적 음식명 (과일)
    '사과': 2.0, '딸기': 2.0, '바나나': 2.0, '귤': 2.0, '포도': 2.0,
    '수박': 2.0, '참외': 2.0, '블루베리': 2.0, '배': 1.5, '감': 2.0,
    '키위': 2.0, '복숭아': 2.0, '자두': 2.0, '망고': 2.0, '멜론': 2.0,
    '토마토': 2.0, '아보카도': 2.0,
    # 간식 기타
    '과자': 2.0, '뻥튀기': 2.5, '떡뻥': 2.5, '요거트': 2.0,
    '요구르트': 2.0, '빵': 1.5, '과일': 2.0,
}

FEEDING_PATTERNS = [
    (re.compile(r'\d+\s*(ml|cc)'), 3.0),
    (re.compile(r'젖\s*(먹|물)'), 2.5),
    (re.compile(r'(반병|한병)'), 2.5),
    (re.compile(r'(한모금|두모금)'), 2.0),
]

# 수면 키워드 (가중치)
SLEEP_KEYWORDS = {
    '잠들': 3.0, '잠잤': 3.0, '잠자': 3.0, '낮잠': 3.0,
    '밤잠': 3.0, '쪽잠': 3.0, '선잠': 3.0, '꿀잠': 3.0,
    '토닥': 2.0,
    '취침': 3.0, '수면': 3.0, '기상': 3.0,
    '재웠': 2.5, '재움': 2.5, '재워': 2.5, '재우': 2.0,
    '깼어': 2.5, '깸': 2.5, '눈떠': 2.5, '눈떴': 2.5, '눈뜨': 2.5,
    '일어났': 2.5, '일어나': 2.0,
    '잤어': 2.5, '잤다': 2.5, '잤음': 2.5, '잘잤': 2.5,
    '잠듬': 2.5, '깼음': 2.5,
    '졸려': 1.5, '졸림': 1.5, '뒤척': 2.0, '자장가': 2.0,
    '잠투정': 2.5, '칭얼': 1.5, '안잠': 2.0,
    '자고': 2.0, '잘래': 2.0, '잘거': 2.0,
}

SLEEP_PATTERNS = [
    (re.compile(r'깨\s*(어|었|서|고|남|요)'), 2.5),
    (re.compile(r'잠\s*(들|잤|잘|이)'), 3.0),
    (re.compile(r'(밤|낮|쪽|선|꿀)\s*잠'), 3.0),
    (re.compile(r'안\s*자'), 2.0),
    (re.compile(r'자다\s*(깨|가)'), 2.5),
]

# 기저귀 키워드 (가중치)
DIAPER_KEYWORDS = {
    '기저귀': 3.0, '응가': 3.0, '대변': 3.0, '소변': 3.0,
    '오줌': 2.5, '배변': 2.5, '쌌어': 2.5,
    '갈았': 2.0, '갈아': 2.0,
    '똥': 2.5, '쉬했': 2.5, '갈아줬': 2.0, '갈아줘': 1.5,
    '팬티': 1.5,
}

DIAPER_PATTERNS = [
    (re.compile(r'똥\s*(쌌|싸|나|봤|이)'), 3.0),
    (re.compile(r'쉬\s*(했|마려|마렵)'), 2.5),
    (re.compile(r'응가\s*(했|봤|함|나|를)'), 2.0),
    (re.compile(r'기저귀\s*(갈|교|바)'), 2.0),
    (re.compile(r'쌌\s*(어|다|요)'), 2.5),
]

# 건강 키워드 (가중치)
HEALTH_KEYWORDS = {
    '체온': 3.0, '온도': 2.5, '예방접종': 3.0, '병원': 1.5,
    '감기': 2.5, '기침': 2.5, '콧물': 2.5,
    '해열제': 3.0, '타이레놀': 3.0, '투약': 3.0, '복용': 2.5,
    '먹였': 1.0,
    '구토': 3.0, '토했': 2.5, '토함': 2.5, '게워': 2.0,
    '발진': 2.5, '두드러기': 2.5,
    '아파': 2.0, '아프': 2.0, '울음': 1.0,
    '설사': 2.5, '소아과': 3.0, '진료': 2.5, '접종': 3.0, '주사': 2.5,
    '열남': 2.5, '진물': 2.0, '배꼽': 1.5, '습진': 2.5, '알레르기': 2.5,
}

HEALTH_PATTERNS = [
    (re.compile(r'\d{2}\.?\d?\s*(도|°)'), 3.0),
    (re.compile(r'열\s*(이|나|있|높|났)'), 3.0),
    (re.compile(r'약\s*(먹|줬|투|복|을|을\s*먹)'), 3.0),
    (re.compile(r'토\s*(했|함|하)'), 2.5),
    (re.compile(r'(배|머리|귀)\s*(아파|아프)'), 2.5),
]

# 마일스톤 키워드 (가중치)
MILESTONE_KEYWORDS = {
    '뒤집기': 3.0, '뒤집었': 3.0, '기었': 3.0, '기어': 2.5,
    '걸었': 3.0, '걸음마': 3.0, '첫': 2.0, '처음': 2.0,
    '옹알이': 3.0, '이앓이': 2.5, '이빨': 2.0, '이나': 1.5,
    '목욕': 2.0, '외출': 2.0, '산책': 2.0,
}

MILESTONE_PATTERNS = [
    (re.compile(r'병원\s*(갔|다녀|방문|갈)'), 2.5),
    (re.compile(r'(소아과|진료)\s*(갔|다녀|방문|갈)'), 2.5),
    (re.compile(r'(뒤집|기어|걸어)\s*(어|었|다)'), 3.0),
]

MIN_THRESHOLD = 2.0


def score_category(text: str, keywords: dict, patterns: list) -> float:
    score = 0.0
    for kw, weight in keywords.items():
        if kw in text:
            score += weight
    for pat, weight in patterns:
        if pat.search(text):
            score += weight
    return score


def calculate_scores(text: str) -> Dict[RecordCategory, float]:
    return {
        RecordCategory.FEEDING: score_category(text, FEEDING_KEYWORDS, FEEDING_PATTERNS),
        RecordCategory.SLEEP: score_category(text, SLEEP_KEYWORDS, SLEEP_PATTERNS),
        RecordCategory.DIAPER: score_category(text, DIAPER_KEYWORDS, DIAPER_PATTERNS),
        RecordCategory.HEALTH: score_category(text, HEALTH_KEYWORDS, HEALTH_PATTERNS),
        RecordCategory.MILESTONE: score_category(text, MILESTONE_KEYWORDS, MILESTONE_PATTERNS),
    }


def select_best(scores: Dict[RecordCategory, float]) -> Optional[RecordCategory]:
    best = None
    best_score = 0.0
    for cat, score in scores.items():
        if score >= MIN_THRESHOLD and score > best_score:
            best = cat
            best_score = score
    return best


def calc_confidence(max_score: float, scores: Dict[RecordCategory, float]) -> float:
    sorted_scores = sorted(scores.values(), reverse=True)
    second = sorted_scores[1] if len(sorted_scores) > 1 else 0.0

    conf = max(0.4, min(0.95, max_score / 8.0))
    gap = max_score - second
    if gap >= 3.0:
        conf = min(0.95, conf + 0.1)
    elif gap < 1.0 and second > 0:
        conf = max(0.3, conf - 0.15)

    return round(conf, 2)


def parse(text: str) -> ParseResult:
    trimmed = text.strip()
    if not trimmed:
        return ParseResult(is_success=False, message='입력이 비어있습니다.')

    lower = trimmed.lower()
    scores = calculate_scores(lower)
    best = select_best(scores)

    if best is None:
        return ParseResult(
            is_success=True, category=RecordCategory.OTHER,
            confidence=0.3, message='기타 기록으로 저장됩니다.',
        )

    max_score = scores[best]
    confidence = calc_confidence(max_score, scores)

    result = ParseResult(is_success=True, category=best, confidence=confidence)

    if best == RecordCategory.MILESTONE:
        result.message = '성장/마일스톤 기록'
        return result

    if best == RecordCategory.FEEDING:
        # 간식 구체적 음식명
        snack_foods = [
            '사과', '딸기', '바나나', '귤', '포도', '수박', '참외', '블루베리',
            '배', '감', '키위', '복숭아', '자두', '망고', '멜론', '토마토',
            '아보카도', '과자', '뻥튀기', '떡뻥', '요거트', '요구르트', '빵', '과일',
        ]
        # 이유식 반찬 재료
        babyfood_ingredients = [
            '소고기', '쇠고기', '닭고기', '돼지고기', '달걀', '계란', '두부',
            '생선', '연어', '대구', '새우', '치즈',
            '감자', '고구마', '브로콜리', '당근', '시금치', '애호박', '단호박', '양배추',
        ]
        # 수유 타입
        if '모유' in lower or re.search(r'젖\s*(먹|물)', lower):
            result.feeding_type = FeedingType.BREAST
        elif '유축' in lower or '짜냈' in lower or '짜놓' in lower:
            result.feeding_type = FeedingType.BREAST
        elif '이유식' in lower or '죽' in lower or '미음' in lower or '퓨레' in lower:
            result.feeding_type = FeedingType.BABYFOOD
        elif '간식' in lower:
            result.feeding_type = FeedingType.SNACK
        else:
            matched_snacks = [f for f in snack_foods if f in lower]
            matched_babyfood = [f for f in babyfood_ingredients if f in lower]
            if matched_snacks and not matched_babyfood:
                result.feeding_type = FeedingType.SNACK
            elif matched_babyfood:
                result.feeding_type = FeedingType.BABYFOOD
            elif '반찬' in lower:
                result.feeding_type = FeedingType.BABYFOOD
            else:
                result.feeding_type = FeedingType.FORMULA
        # ml
        ml_match = re.search(r'(\d+)\s*(ml|밀리|씨씨|cc)', lower)
        if ml_match:
            result.amount_ml = int(ml_match.group(1))
        # "밥 120", "분유 110" 등 단독 숫자 (ml 단위 없이)
        if result.amount_ml is None:
            bare_num = re.search(r'(?:밥|분유|모유|이유식)\s*(\d+)', lower)
            if bare_num:
                result.amount_ml = int(bare_num.group(1))
        if result.amount_ml is None:
            bare_num2 = re.search(r'(\d+)\s*(?:먹|양)', lower)
            if bare_num2:
                result.amount_ml = int(bare_num2.group(1))
        # duration
        cleaned = lower.replace('분유', '  ').replace('분말', '  ')
        dur_match = re.search(r'(\d+)\s*분', cleaned)
        if dur_match and '전' not in cleaned[dur_match.start():]:
            result.duration_min = int(dur_match.group(1))
        result.message = f'수유({result.feeding_type.value}) 기록'

    elif best == RecordCategory.SLEEP:
        wake_kws = ['깼', '깸', '눈떠', '눈뜨', '일어났', '일어나', '기상']
        wake_pats = [re.compile(r'깨\s*(어|었|서|고|남|요)')]
        if any(k in lower for k in wake_kws) or any(p.search(lower) for p in wake_pats):
            result.sleep_status = SleepStatus.END
        else:
            result.sleep_status = SleepStatus.START
        result.message = '잠듦 기록' if result.sleep_status == SleepStatus.START else '깨어남 기록'

    elif best == RecordCategory.DIAPER:
        poop_kws = ['응가', '대변']
        poop_pats = [re.compile(r'똥\s*(쌌|싸|나|봤)')]
        pee_kws = ['소변', '오줌']
        pee_pats = [re.compile(r'쉬\s*(했|마려|마렵)')]
        has_poop = any(k in lower for k in poop_kws) or any(p.search(lower) for p in poop_pats)
        has_pee = any(k in lower for k in pee_kws) or any(p.search(lower) for p in pee_pats)
        if has_poop and has_pee:
            result.diaper_type = DiaperType.BOTH
        elif has_poop:
            result.diaper_type = DiaperType.POOP
        else:
            result.diaper_type = DiaperType.PEE
        result.message = f'기저귀 교체({result.diaper_type.value}) 기록'

    elif best == RecordCategory.HEALTH:
        temp_match = re.search(r'(\d{2}\.?\d?)\s*(도|°)', lower)
        if temp_match:
            result.temperature = float(temp_match.group(1))
        if re.search(r'약\s*(먹|줬|투|복|을)', lower) or any(k in lower for k in ['해열제','타이레놀','투약','복용']):
            result.medicine = '약 복용'
        result.message = f'체온 {result.temperature}°C 기록' if result.temperature else '건강 기록'

    return result


# ============================================================
# 복합 입력 파싱 (parseMulti)
# ============================================================

_TIME_MARKER_PATTERN = re.compile(
    r'(?:오전|오후|아침|저녁|밤)?\s*\d{1,2}\s*시\s*(?:반|\d{1,2}\s*분)?'
)

def is_multi_input(text: str) -> bool:
    """시간 마커가 2개 이상이면 복합 입력"""
    matches = _TIME_MARKER_PATTERN.findall(text.lower().strip())
    return len(matches) >= 2


def _split_segments(text: str) -> List[str]:
    """복합 입력을 세그먼트로 분할"""
    lower = text.strip()

    # 접속사+시간 기반 분할
    split_pattern = re.compile(
        r'(?:,\s*|[.]?\s*)'
        r'(?:'
          r'(?:먹고|하고|자고|깨고|갈고|쌌고|했고)\s+'
          r'(?=(?:오전|오후|아침|저녁|밤)?\s*\d{1,2}\s*시)'
        r'|'
          r'(?:그리고|그다음에?|그\s*후에?|그런\s*다음|그러고\s*나서|그\s*뒤에?)\s+'
        r')'
    )

    matches = list(split_pattern.finditer(lower))

    if not matches:
        # 시간 마커만으로 분할
        return _split_by_time_markers(lower)

    segments = []
    last_end = 0
    for m in matches:
        seg = lower[last_end:m.start()].strip()
        if seg:
            segments.append(seg)
        last_end = m.end()
    last = lower[last_end:].strip()
    if last:
        segments.append(last)

    segments = [s for s in segments if len(s.strip()) >= 2]
    return segments if len(segments) > 1 else [text.strip()]


def _split_by_time_markers(text: str) -> List[str]:
    """시간 마커 위치에서 분할"""
    time_pattern = re.compile(
        r'(?:오전|오후|아침|저녁|밤)\s*\d{1,2}\s*시|(?<=\s)\d{1,2}\s*시'
    )
    matches = list(time_pattern.finditer(text))
    if len(matches) < 2:
        return [text]

    segments = []
    last_start = 0
    for i in range(1, len(matches)):
        split_pos = matches[i].start()
        seg = text[last_start:split_pos].strip()
        if seg:
            segments.append(seg)
        last_start = split_pos

    last = text[last_start:].strip()
    if last:
        segments.append(last)

    return [s for s in segments if len(s.strip()) >= 2]


def parse_multi(text: str) -> List[ParseResult]:
    """복합 입력을 여러 ParseResult로 분할 파싱"""
    trimmed = text.strip()
    if not trimmed:
        return [ParseResult(is_success=False, message='입력이 비어있습니다.')]

    if not is_multi_input(trimmed):
        return [parse(trimmed)]

    segments = _split_segments(trimmed)
    if len(segments) <= 1:
        return [parse(trimmed)]

    return [parse(seg) for seg in segments]


# ============================================================
# 테스트 프레임워크
# ============================================================

class TestRunner:
    def __init__(self):
        self.total = 0
        self.passed = 0
        self.failed = 0
        self.failures: List[str] = []
        self.group_name = ""
        self.group_total = 0
        self.group_passed = 0

    def group(self, name: str):
        if self.group_name and self.group_total > 0:
            status = "✅" if self.group_passed == self.group_total else "⚠️"
            print(f"  {status} {self.group_name}: {self.group_passed}/{self.group_total} 통과")
        self.group_name = name
        self.group_total = 0
        self.group_passed = 0
        print(f"\n📋 {name}")

    def expect_category(self, text: str, expected: RecordCategory, desc: str = ""):
        self.total += 1
        self.group_total += 1
        result = parse(text)
        actual = result.category
        label = desc or text
        if actual == expected:
            self.passed += 1
            self.group_passed += 1
        else:
            self.failed += 1
            msg = f'  ✗ "{label}" → 기대: {expected.value}, 실제: {actual.value if actual else "null"} (conf: {result.confidence})'
            self.failures.append(msg)
            print(msg)

    def expect_not_category(self, text: str, not_expected: RecordCategory, desc: str = ""):
        self.total += 1
        self.group_total += 1
        result = parse(text)
        actual = result.category
        label = desc or text
        if actual != not_expected:
            self.passed += 1
            self.group_passed += 1
        else:
            self.failed += 1
            msg = f'  ✗ "{label}" → {not_expected.value}으로 오분류됨 (conf: {result.confidence})'
            self.failures.append(msg)
            print(msg)

    def expect_field(self, text: str, field_name: str, expected_value, desc: str = ""):
        self.total += 1
        self.group_total += 1
        result = parse(text)
        actual = getattr(result, field_name, None)
        label = desc or f'{text} → {field_name}'
        if actual == expected_value:
            self.passed += 1
            self.group_passed += 1
        else:
            self.failed += 1
            msg = f'  ✗ "{label}" → 기대: {expected_value}, 실제: {actual}'
            self.failures.append(msg)
            print(msg)

    def expect_confidence_gt(self, text: str, threshold: float, desc: str = ""):
        self.total += 1
        self.group_total += 1
        result = parse(text)
        label = desc or text
        if result.confidence > threshold:
            self.passed += 1
            self.group_passed += 1
        else:
            self.failed += 1
            msg = f'  ✗ "{label}" → confidence {result.confidence} <= {threshold}'
            self.failures.append(msg)
            print(msg)

    def finish(self):
        # 마지막 그룹 결과 출력
        if self.group_name and self.group_total > 0:
            status = "✅" if self.group_passed == self.group_total else "⚠️"
            print(f"  {status} {self.group_name}: {self.group_passed}/{self.group_total} 통과")

        rate = (self.passed / self.total * 100) if self.total > 0 else 0

        print()
        print("╔══════════════════════════════════════════════════╗")
        print("║       NLP 파서 v2 종합 테스트 결과               ║")
        print("╠══════════════════════════════════════════════════╣")
        print(f"║  총 테스트:  {self.total:>4}개                            ║")
        print(f"║  통과:       {self.passed:>4}개                            ║")
        print(f"║  실패:       {self.failed:>4}개                            ║")
        print(f"║  인식율:     {rate:>6.1f}%                           ║")
        print("╚══════════════════════════════════════════════════╝")

        if self.failures:
            print(f"\n❌ 실패 목록 ({len(self.failures)}건):")
            for f in self.failures:
                print(f)

        if rate >= 95:
            print("\n🎉 우수! 인식율 95% 이상 달성!")
        elif rate >= 90:
            print("\n👍 양호! 인식율 90% 이상.")
        else:
            print(f"\n⚠️  인식율 {rate:.1f}% — 추가 개선 필요")

        return rate


# ============================================================
# 테스트 실행
# ============================================================

def main():
    t = TestRunner()

    # ------- 1. 수유 -------
    t.group("수유(Feeding) 인식 테스트")
    t.expect_category('분유 먹었어', RecordCategory.FEEDING)
    t.expect_category('분유 120ml', RecordCategory.FEEDING)
    t.expect_category('분유 먹음', RecordCategory.FEEDING)
    t.expect_category('모유 수유 15분', RecordCategory.FEEDING)
    t.expect_category('모유 먹었어', RecordCategory.FEEDING)
    t.expect_category('이유식 먹였어', RecordCategory.FEEDING)
    t.expect_category('간식 먹었어', RecordCategory.FEEDING)
    t.expect_field('분유 120ml 먹었어', 'amount_ml', 120, '분유 120ml → amount_ml=120')
    t.expect_field('분유 100cc', 'amount_ml', 100, '분유 100cc → amount_ml=100')
    t.expect_field('모유 수유 15분', 'duration_min', 15, '모유 수유 15분 → duration_min=15')
    t.expect_field('모유 먹었어', 'feeding_type', FeedingType.BREAST)
    t.expect_field('분유 120ml', 'feeding_type', FeedingType.FORMULA)
    t.expect_field('이유식 먹였어', 'feeding_type', FeedingType.BABYFOOD)
    t.expect_field('간식 먹었어', 'feeding_type', FeedingType.SNACK)

    # ------- 1b. 수유 추가 -------
    t.group("수유 추가 표현 테스트")
    t.expect_category('죽 먹었어', RecordCategory.FEEDING)
    t.expect_category('미음 먹였어', RecordCategory.FEEDING)
    t.expect_category('퓨레 먹음', RecordCategory.FEEDING)
    t.expect_category('분유 반병 먹었어', RecordCategory.FEEDING)
    t.expect_category('우유 한병 먹음', RecordCategory.FEEDING)

    # ------- 2. 수면 -------
    t.group("수면(Sleep) 인식 테스트")
    t.expect_category('아기 잠들었어', RecordCategory.SLEEP)
    t.expect_category('낮잠 잤어', RecordCategory.SLEEP)
    t.expect_category('재웠어', RecordCategory.SLEEP)
    t.expect_category('취침', RecordCategory.SLEEP)
    t.expect_category('아기 깼어', RecordCategory.SLEEP)
    t.expect_category('기상했어', RecordCategory.SLEEP)
    t.expect_category('눈떴어', RecordCategory.SLEEP)
    t.expect_category('잠투정 심해', RecordCategory.SLEEP)
    t.expect_category('졸려하는데 안자', RecordCategory.SLEEP)
    t.expect_category('뒤척이다 깼어', RecordCategory.SLEEP)
    t.expect_category('자다가 깼어', RecordCategory.SLEEP)
    t.expect_field('아기 잠들었어', 'sleep_status', SleepStatus.START)
    t.expect_field('아기 깼어', 'sleep_status', SleepStatus.END)
    t.expect_field('기상했어', 'sleep_status', SleepStatus.END)
    t.expect_field('자다가 깼어', 'sleep_status', SleepStatus.END)

    # ------- 3. 기저귀 -------
    t.group("기저귀(Diaper) 인식 테스트")
    t.expect_category('기저귀 갈았어', RecordCategory.DIAPER)
    t.expect_category('기저귀 교체', RecordCategory.DIAPER)
    t.expect_category('응가 했어', RecordCategory.DIAPER)
    t.expect_category('똥 쌌어', RecordCategory.DIAPER)
    t.expect_category('기저귀 갈아줬어', RecordCategory.DIAPER)
    t.expect_category('똥이 나왔어', RecordCategory.DIAPER)
    t.expect_field('응가 했어', 'diaper_type', DiaperType.POOP)
    t.expect_field('기저귀 갈았어 대변 소변', 'diaper_type', DiaperType.BOTH)
    t.expect_field('소변 봤어 기저귀 갈았어', 'diaper_type', DiaperType.PEE)

    # ------- 4. 건강 -------
    t.group("건강(Health) 인식 테스트")
    t.expect_category('체온 37.5도', RecordCategory.HEALTH)
    t.expect_field('체온 37.5도', 'temperature', 37.5)
    t.expect_category('열이 나요', RecordCategory.HEALTH)
    t.expect_category('열 높아요', RecordCategory.HEALTH)
    t.expect_category('약 먹였어', RecordCategory.HEALTH)
    t.expect_category('해열제 먹였어', RecordCategory.HEALTH)
    t.expect_category('병원 다녀왔어', RecordCategory.MILESTONE)
    t.expect_category('예방접종 맞았어', RecordCategory.HEALTH)
    t.expect_category('콧물 나요', RecordCategory.HEALTH)
    t.expect_category('기침 해요', RecordCategory.HEALTH)
    t.expect_category('구토했어', RecordCategory.HEALTH)
    t.expect_category('토했어', RecordCategory.HEALTH)
    t.expect_category('발진이 생겼어', RecordCategory.HEALTH)
    t.expect_category('소아과 다녀왔어', RecordCategory.HEALTH)
    t.expect_category('배 아파해', RecordCategory.HEALTH)
    t.expect_category('접종했어', RecordCategory.HEALTH)

    # ------- 5. ★ 오탐 방지 (핵심!) -------
    t.group("★ 오탐 방지 테스트 (v2 핵심 개선)")
    t.expect_category('분유도 먹었어', RecordCategory.FEEDING, '"도" 조사 → 수유 유지')
    t.expect_category('잠도 잤어', RecordCategory.SLEEP, '"도" 조사 → 수면 유지')
    t.expect_not_category('오늘도 힘내자', RecordCategory.HEALTH, '"도" 조사 오탐 방지')
    t.expect_not_category('일정 변경했어', RecordCategory.DIAPER, '"변경"의 "변" 오탐 방지')
    t.expect_not_category('변화가 생겼어', RecordCategory.DIAPER, '"변화"의 "변" 오탐 방지')
    t.expect_not_category('좀 쉬어야겠다', RecordCategory.DIAPER, '"쉬다"의 "쉬" 오탐 방지')
    t.expect_not_category('물건이 싸다', RecordCategory.DIAPER, '"싸다"의 "싸" 오탐 방지')
    t.expect_not_category('자두 먹었어', RecordCategory.SLEEP, '"자두"의 "자" 오탐 방지')
    t.expect_not_category('물건을 샀어', RecordCategory.FEEDING, '"물건"의 "물" 오탐 방지')
    t.expect_not_category('물론이지', RecordCategory.FEEDING, '"물론"의 "물" 오탐 방지')
    t.expect_category('약 먹였어', RecordCategory.HEALTH, '"약 먹였어" → 건강(기존: 수유 오분류)')
    t.expect_category('약 먹었어', RecordCategory.HEALTH, '"약 먹었어" → 건강')
    t.expect_not_category('밥상 차리자', RecordCategory.FEEDING, '"밥상"의 "밥" 오탐 방지')

    # ------- 6. Confidence 테스트 -------
    t.group("Confidence 동적 계산 테스트")
    t.expect_confidence_gt('분유 120ml 먹었어', 0.7, '명확한 수유 입력 → 높은 confidence')
    result_other = parse('안녕하세요')
    t.total += 1; t.group_total += 1
    if result_other.confidence == 0.3:
        t.passed += 1; t.group_passed += 1
    else:
        t.failed += 1
        t.failures.append(f'  ✗ "안녕하세요" → confidence {result_other.confidence} != 0.3')

    # ------- 7. 엣지 케이스 -------
    t.group("엣지 케이스 테스트")
    result_empty = parse('')
    t.total += 1; t.group_total += 1
    if not result_empty.is_success:
        t.passed += 1; t.group_passed += 1
    else:
        t.failed += 1; t.failures.append('  ✗ 빈 입력 → is_success=True (기대: False)')

    result_space = parse('   ')
    t.total += 1; t.group_total += 1
    if not result_space.is_success:
        t.passed += 1; t.group_passed += 1
    else:
        t.failed += 1; t.failures.append('  ✗ 공백 입력 → is_success=True (기대: False)')

    t.expect_category('오늘 날씨가 좋다', RecordCategory.OTHER, '무관한 텍스트 → 기타')

    # ------- 8. 실제 사용자 시나리오 -------
    t.group("실제 사용자 입력 시나리오")
    scenarios = {
        '방금 분유 120ml 먹었어': RecordCategory.FEEDING,
        '오후 2시에 분유 먹음': RecordCategory.FEEDING,
        '모유 수유 15분': RecordCategory.FEEDING,
        '이유식 먹였어': RecordCategory.FEEDING,
        '아기 잠들었어': RecordCategory.SLEEP,
        '낮잠 잤어': RecordCategory.SLEEP,
        '아기 깼어': RecordCategory.SLEEP,
        '기저귀 갈았어 응가': RecordCategory.DIAPER,
        '기저귀 갈았어': RecordCategory.DIAPER,
        '응가했어': RecordCategory.DIAPER,
        '체온 37.5도': RecordCategory.HEALTH,
        '열이 나요': RecordCategory.HEALTH,
        '약 먹였어': RecordCategory.HEALTH,
        '병원 다녀왔어': RecordCategory.MILESTONE,
        '예방접종 맞았어': RecordCategory.HEALTH,
    }
    for text, expected in scenarios.items():
        t.expect_category(text, expected)

    # ------- 9. 종합 벤치마크 -------
    t.group("★ 종합 인식율 벤치마크")
    benchmark = {
        # 수유 (15개)
        '분유 먹었어': RecordCategory.FEEDING,
        '분유 120ml': RecordCategory.FEEDING,
        '분유 100cc 먹음': RecordCategory.FEEDING,
        '모유 수유 15분': RecordCategory.FEEDING,
        '모유 먹었어': RecordCategory.FEEDING,
        '이유식 먹였어': RecordCategory.FEEDING,
        '간식 먹었어': RecordCategory.FEEDING,
        '젖병으로 먹였어': RecordCategory.FEEDING,
        '우유 먹었어': RecordCategory.FEEDING,
        '오후 2시에 분유 120ml 먹음': RecordCategory.FEEDING,
        '방금 분유 먹었어': RecordCategory.FEEDING,
        '수유했어': RecordCategory.FEEDING,
        '분유 먹임': RecordCategory.FEEDING,
        '모유 수유': RecordCategory.FEEDING,
        '분유도 먹었어': RecordCategory.FEEDING,
        # 수면 (13개)
        '아기 잠들었어': RecordCategory.SLEEP,
        '낮잠 잤어': RecordCategory.SLEEP,
        '재웠어': RecordCategory.SLEEP,
        '취침했어': RecordCategory.SLEEP,
        '아기 깼어': RecordCategory.SLEEP,
        '기상했어': RecordCategory.SLEEP,
        '눈떴어': RecordCategory.SLEEP,
        '잠자요': RecordCategory.SLEEP,
        '수면 시작': RecordCategory.SLEEP,
        '아기 재움': RecordCategory.SLEEP,
        '10시 밤잠 시작': RecordCategory.SLEEP,
        '쪽잠만 잤어': RecordCategory.SLEEP,
        '꿀잠 잤다': RecordCategory.SLEEP,
        '잠투정 심해': RecordCategory.SLEEP,
        '졸려하는데 안자': RecordCategory.SLEEP,
        '자다가 깼어': RecordCategory.SLEEP,
        # 기저귀 (10개+)
        '기저귀 갈았어': RecordCategory.DIAPER,
        '기저귀 갈았어 응가': RecordCategory.DIAPER,
        '응가했어': RecordCategory.DIAPER,
        '대변 봤어': RecordCategory.DIAPER,
        '소변 봤어': RecordCategory.DIAPER,
        '오줌 쌌어': RecordCategory.DIAPER,
        '기저귀 교체': RecordCategory.DIAPER,
        '배변했어': RecordCategory.DIAPER,
        '응가 대변': RecordCategory.DIAPER,
        '기저귀 갈아줬어': RecordCategory.DIAPER,
        '응가가 7시에 묽게 쌌어': RecordCategory.DIAPER,
        '6시 노란색 대변': RecordCategory.DIAPER,
        '똥 쌌어': RecordCategory.DIAPER,
        '똥이 나왔어': RecordCategory.DIAPER,
        # 건강 (10개+)
        '체온 37.5도': RecordCategory.HEALTH,
        '열이 나요': RecordCategory.HEALTH,
        '약 먹였어': RecordCategory.HEALTH,
        '병원 다녀왔어': RecordCategory.MILESTONE,
        '예방접종 맞았어': RecordCategory.HEALTH,
        '콧물 나요': RecordCategory.HEALTH,
        '기침 해요': RecordCategory.HEALTH,
        '감기 걸렸어': RecordCategory.HEALTH,
        '해열제 먹였어': RecordCategory.HEALTH,
        '체온 38도': RecordCategory.HEALTH,
        '구토했어': RecordCategory.HEALTH,
        '토했어': RecordCategory.HEALTH,
        '발진이 생겼어': RecordCategory.HEALTH,
        '소아과 다녀왔어': RecordCategory.HEALTH,
        '배 아파해': RecordCategory.HEALTH,
        '접종했어': RecordCategory.HEALTH,
        # 기타 / 오탐 방지 (10개)
        '안녕하세요': RecordCategory.OTHER,
        '오늘 날씨가 좋다': RecordCategory.OTHER,
        '물건을 샀어': RecordCategory.OTHER,
        '일정 변경했어': RecordCategory.OTHER,
        '좀 쉬어야겠다': RecordCategory.OTHER,
        '물론이지': RecordCategory.OTHER,
        '밥상 차리자': RecordCategory.OTHER,
        '변화가 생겼어': RecordCategory.OTHER,
        '오늘도 힘내자': RecordCategory.OTHER,
        '물건이 싸다': RecordCategory.OTHER,
    }
    for text, expected in benchmark.items():
        t.expect_category(text, expected)

    # ------- 결과 출력 -------
    rate = t.finish()

    # 상세 스코어 테이블 (디버깅용)
    print("\n\n📊 주요 입력 스코어 상세 분석:")
    print("─" * 90)
    print(f"{'입력':30s} │ {'수유':>6s} │ {'수면':>6s} │ {'기저귀':>6s} │ {'건강':>6s} │ {'결과':8s} │ {'conf':>5s}")
    print("─" * 90)

    detail_cases = [
        '분유 120ml 먹었어', '약 먹였어', '분유도 먹었어', '자두 먹었어',
        '일정 변경했어', '아기 잠들었어', '기저귀 갈았어', '체온 37.5도',
        '열이 나요', '좀 쉬어야겠다', '물건이 싸다', '오늘도 힘내자',
        '안녕하세요', '잠도 잤어', '약 먹었어',
    ]

    for text in detail_cases:
        scores = calculate_scores(text)
        result = parse(text)
        cat = result.category.value if result.category else "null"
        print(f"  {text:28s} │ {scores[RecordCategory.FEEDING]:6.1f} │ {scores[RecordCategory.SLEEP]:6.1f} │ {scores[RecordCategory.DIAPER]:6.1f} │ {scores[RecordCategory.HEALTH]:6.1f} │ {cat:8s} │ {result.confidence:5.2f}")

    print("─" * 90)


if __name__ == '__main__':
    main()
