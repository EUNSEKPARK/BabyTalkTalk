#!/usr/bin/env python3
"""
ChatBabyTime NLP 파서 대화형 테스트 프로그램 v3

직접 채팅을 입력하면서 NLP 파서의 인식 결과를 실시간으로 확인할 수 있습니다.
- 시간 파싱 결과 표시
- 대변 상태(묽은/딱딱한/정상) 인식
- 메모 추출

실행: python3 test/nlp_interactive_test.py
"""

import re
from dataclasses import dataclass
from enum import Enum
from typing import Optional, Dict, List
from datetime import datetime, timedelta


# ============================================================
# 모델 정의
# ============================================================

class RecordCategory(Enum):
    FEEDING = "수유"
    SLEEP = "수면"
    DIAPER = "기저귀"
    HEALTH = "건강"
    OTHER = "기타"

class FeedingType(Enum):
    BREAST = "모유"
    FORMULA = "분유"
    BABYFOOD = "이유식"
    SNACK = "간식"

class DiaperType(Enum):
    PEE = "소변"
    POOP = "대변"
    BOTH = "소변+대변"

class SleepStatus(Enum):
    START = "잠듦"
    END = "깨어남"

class StoolCondition(Enum):
    WATERY = "묽음"
    SOFT = "무름"
    NORMAL = "정상"
    HARD = "딱딱함"

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
    stool_condition: Optional[StoolCondition] = None
    stool_color: Optional[str] = None
    temperature: Optional[float] = None
    medicine: Optional[str] = None
    parsed_time: Optional[datetime] = None
    time_source: str = "현재시간"  # 어떻게 시간을 파싱했는지
    memo: Optional[str] = None
    scores: Optional[Dict] = None


# ============================================================
# NLP 파서 v2 + 시간 파싱 + 대변 상태
# ============================================================

FEEDING_KEYWORDS = {
    '수유': 3.0, '분유': 3.0, '모유': 3.0, '이유식': 3.0,
    '젖병': 2.5, '젖꼭지': 2.0, '우유': 2.0, '간식': 2.0,
    '주스': 2.0, '밀리': 1.5, '씨씨': 1.5,
    '먹었': 1.5, '먹임': 1.5, '먹였': 1.5, '먹음': 1.5, '먹여': 1.5,
    '먹고': 1.5, '먹어': 1.5,
    '죽': 2.0, '미음': 2.5, '퓨레': 2.5, '반찬': 1.5, '밥': 1.5,
}

FEEDING_PATTERNS = [
    (re.compile(r'\d+\s*(ml|cc)'), 3.0),
    (re.compile(r'젖\s*(먹|물)'), 2.5),
    (re.compile(r'(반병|한병)'), 2.5),
    (re.compile(r'(한모금|두모금)'), 2.0),
]

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

HEALTH_KEYWORDS = {
    '체온': 3.0, '온도': 2.5, '예방접종': 3.0, '병원': 2.5,
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

# 대변 상태 키워드
STOOL_CONDITIONS = {
    StoolCondition.WATERY: ['묽', '물같', '설사', '질퍽', '질척', '찔끔', '수양변'],
    StoolCondition.SOFT: ['무른', '무르', '부드러', '흐물'],
    StoolCondition.HARD: ['딱딱', '단단', '변비', '굳'],
    StoolCondition.NORMAL: ['정상', '보통'],
}

# 대변 색상 키워드
STOOL_COLORS = {
    '노란': '노란색', '황금': '황금색', '녹색': '녹색', '초록': '초록색',
    '갈색': '갈색', '검은': '검은색', '검정': '검은색', '빨간': '빨간색',
    '하얀': '흰색', '흰': '흰색', '회색': '회색',
}

MIN_THRESHOLD = 2.0

# 본인/타인 패턴
SELF_REFERENCE_PATTERNS = [
    re.compile(r'^나\s'),
    re.compile(r'나는\s'),
    re.compile(r'내가\s'),
    re.compile(r'남편'),
    re.compile(r'엄마가\s'),
    re.compile(r'아빠가\s'),
    re.compile(r'드라마'),
    re.compile(r'영화'),
    re.compile(r'유튜브'),
]


def normalize_text(text):
    t = text
    t = re.sub(r'[ㅋㅎㅠㅜㅡ]+', ' ', t)
    t = re.sub(r'[!?~.]{2,}', ' ', t)
    if re.search(r'[\uac00-\ud7af]\s[\uac00-\ud7af]\s[\uac00-\ud7af]', t):
        t = re.sub(r'(?<=[\uac00-\ud7af])\s(?=[\uac00-\ud7af])', '', t)
    t = re.sub(r'\s{2,}', ' ', t)
    return t.strip()


def has_self_reference(text):
    for pat in SELF_REFERENCE_PATTERNS:
        if pat.search(text):
            return True
    return False


CATEGORY_EMOJI = {
    RecordCategory.FEEDING: "🍼",
    RecordCategory.SLEEP: "😴",
    RecordCategory.DIAPER: "🧷",
    RecordCategory.HEALTH: "🌡️",
    RecordCategory.OTHER: "📝",
}


def score_category(text, keywords, patterns):
    score = 0.0
    matched_kws = []
    for kw, weight in keywords.items():
        if kw in text:
            score += weight
            matched_kws.append((kw, weight))
    for pat, weight in patterns:
        if pat.search(text):
            score += weight
            matched_kws.append((pat.pattern, weight))
    return score, matched_kws


def calculate_scores(text):
    scores = {}
    details = {}
    for cat, kws, pats in [
        (RecordCategory.FEEDING, FEEDING_KEYWORDS, FEEDING_PATTERNS),
        (RecordCategory.SLEEP, SLEEP_KEYWORDS, SLEEP_PATTERNS),
        (RecordCategory.DIAPER, DIAPER_KEYWORDS, DIAPER_PATTERNS),
        (RecordCategory.HEALTH, HEALTH_KEYWORDS, HEALTH_PATTERNS),
    ]:
        score, matched = score_category(text, kws, pats)
        scores[cat] = score
        details[cat] = matched
    return scores, details


def select_best(scores):
    best = None
    best_score = 0.0
    for cat, score in scores.items():
        if score >= MIN_THRESHOLD and score > best_score:
            best = cat
            best_score = score
    return best


def calc_confidence(max_score, scores):
    sorted_scores = sorted(scores.values(), reverse=True)
    second = sorted_scores[1] if len(sorted_scores) > 1 else 0.0
    conf = max(0.4, min(0.95, max_score / 8.0))
    gap = max_score - second
    if gap >= 3.0:
        conf = min(0.95, conf + 0.1)
    elif gap < 1.0 and second > 0:
        conf = max(0.3, conf - 0.15)
    return round(conf, 2)


# ===== 시간 파싱 (nlp_parser.dart 동일 로직) =====

def remove_keywords_for_time(text):
    cleaned = text
    for kw in ['분유', '분말', '분량']:
        cleaned = cleaned.replace(kw, ' ' * len(kw))
    return cleaned


def infer_best_hour(raw_hour, minute, now):
    if 13 <= raw_hour <= 23:
        return raw_hour
    if raw_hour == 0:
        return 0
    am_hour = 0 if raw_hour == 12 else raw_hour
    pm_hour = 12 if raw_hour == 12 else raw_hour + 12
    am_cand = now.replace(hour=am_hour, minute=minute, second=0, microsecond=0)
    pm_cand = now.replace(hour=pm_hour, minute=minute, second=0, microsecond=0)
    am_diff = now - am_cand
    pm_diff = now - pm_cand
    am_neg = am_diff.total_seconds() < 0
    pm_neg = pm_diff.total_seconds() < 0
    if am_neg and pm_neg:
        return am_hour if abs(am_diff.total_seconds()) < abs(pm_diff.total_seconds()) else pm_hour
    if not am_neg and pm_neg:
        return am_hour
    if am_neg and not pm_neg:
        return pm_hour
    return am_hour if am_diff < pm_diff else pm_hour


def parse_time(text):
    now = datetime.now()
    cleaned = remove_keywords_for_time(text)

    # "방금", "지금"
    if any(k in cleaned for k in ['방금', '지금']):
        return now, "방금/지금"

    # "아까" (약 30분 전 추정)
    if '아까' in cleaned:
        return now - timedelta(minutes=30), "아까 (~30분 전)"

    # "N분 전"
    m = re.search(r'(\d+)\s*분\s*전', cleaned)
    if m:
        mins = int(m.group(1))
        return now - timedelta(minutes=mins), f"{mins}분 전"

    # "N시간 전"
    m = re.search(r'(\d+)\s*시간\s*전', cleaned)
    if m:
        hrs = int(m.group(1))
        return now - timedelta(hours=hrs), f"{hrs}시간 전"

    # "오전/오후 N시 [M분]"
    m = re.search(r'(오전|오후|아침|저녁|밤)\s*(\d{1,2})\s*시\s*(\d{1,2})?\s*분?', cleaned)
    if m:
        hour = int(m.group(2))
        minute = int(m.group(3)) if m.group(3) else 0
        period = m.group(1)
        if period in ('오후', '저녁', '밤') and hour < 12:
            hour += 12
        elif period in ('오전', '아침') and hour == 12:
            hour = 0
        t = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
        return t, f"{period} {m.group(2)}시{(' ' + m.group(3) + '분') if m.group(3) else ''}"

    # "N시 [M분]"
    m = re.search(r'(\d{1,2})\s*시\s*(\d{1,2})?\s*분?', cleaned)
    if m:
        raw_hour = int(m.group(1))
        minute = int(m.group(2)) if m.group(2) else 0
        hour = infer_best_hour(raw_hour, minute, now)
        t = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
        ampm = "오전" if hour < 12 else "오후"
        display_h = hour if hour <= 12 else hour - 12
        return t, f"{raw_hour}시 → {ampm} {display_h}시{f' {minute}분' if minute else ''} (추론)"

    # "HH:MM"
    m = re.search(r'(\d{1,2}):(\d{2})', cleaned)
    if m:
        raw_hour = int(m.group(1))
        minute = int(m.group(2))
        if raw_hour >= 13:
            t = now.replace(hour=raw_hour, minute=minute, second=0, microsecond=0)
            return t, f"{raw_hour}:{minute:02d}"
        hour = infer_best_hour(raw_hour, minute, now)
        t = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
        return t, f"{raw_hour}:{minute:02d} → {hour}:{minute:02d} (추론)"

    return now, "현재시간 (시간 미입력)"


# ===== 대변 상태 파싱 =====

def parse_stool_condition(text):
    for condition, keywords in STOOL_CONDITIONS.items():
        if any(kw in text for kw in keywords):
            return condition
    return None


# ===== 메인 파서 =====

def parse(text):
    trimmed = text.strip()
    if not trimmed:
        return ParseResult(is_success=False, message='입력이 비어있습니다.')

    lower_raw = trimmed.lower()
    lower = normalize_text(lower_raw)
    scores, details = calculate_scores(lower)

    # 본인/타인 필터
    if has_self_reference(lower_raw):
        for cat in scores:
            if scores[cat] > 0:
                scores[cat] *= 0.3

    best = select_best(scores)

    # 시간 파싱
    parsed_time, time_source = parse_time(lower)

    if best is None:
        return ParseResult(
            is_success=True, category=RecordCategory.OTHER,
            confidence=0.3, message='기타 기록으로 저장됩니다.',
            scores=scores, parsed_time=parsed_time, time_source=time_source,
            memo=trimmed,
        )

    max_score = scores[best]
    confidence = calc_confidence(max_score, scores)

    result = ParseResult(
        is_success=True, category=best, confidence=confidence,
        scores=scores, parsed_time=parsed_time, time_source=time_source,
    )

    if best == RecordCategory.FEEDING:
        if '모유' in lower or re.search(r'젖\s*(먹|물)', lower):
            result.feeding_type = FeedingType.BREAST
        elif '이유식' in lower or '죽' in lower:
            result.feeding_type = FeedingType.BABYFOOD
        elif '간식' in lower:
            result.feeding_type = FeedingType.SNACK
        else:
            result.feeding_type = FeedingType.FORMULA
        ml_match = re.search(r'(\d+)\s*(ml|밀리|씨씨|cc)', lower)
        if ml_match:
            result.amount_ml = int(ml_match.group(1))
        cleaned = lower.replace('분유', '  ').replace('분말', '  ')
        dur_match = re.search(r'(\d+)\s*분', cleaned)
        if dur_match and '전' not in cleaned[dur_match.start():]:
            result.duration_min = int(dur_match.group(1))
        result.message = f'수유({result.feeding_type.value}) 기록'

    elif best == RecordCategory.SLEEP:
        wake_kws = ['깼', '깸', '눈떠', '눈떴', '눈뜨', '일어났', '일어나', '기상']
        wake_pats = [re.compile(r'깨\s*(어|었|서|고|남|요)'), re.compile(r'자다\s*(깨|가)')]
        if any(k in lower for k in wake_kws) or any(p.search(lower) for p in wake_pats):
            result.sleep_status = SleepStatus.END
        else:
            result.sleep_status = SleepStatus.START
        result.message = f'수면({result.sleep_status.value}) 기록'

    elif best == RecordCategory.DIAPER:
        poop_kws = ['응가', '대변', '똥']
        poop_pats = [re.compile(r'똥\s*(쌌|싸|나|봤|이)')]
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
        # 대변 상태 파싱
        result.stool_condition = parse_stool_condition(lower)
        # 색상 파싱
        for color_kw, color_name in STOOL_COLORS.items():
            if color_kw in lower:
                result.stool_color = color_name
                break
        memo_parts = []
        if result.stool_condition:
            memo_parts.append(result.stool_condition.value)
        if result.stool_color:
            memo_parts.append(result.stool_color)
        result.memo = ', '.join(memo_parts) if memo_parts else None
        result.message = f'기저귀({result.diaper_type.value}) 기록'
        if result.memo:
            result.message += f' ({result.memo})'

    elif best == RecordCategory.HEALTH:
        temp_match = re.search(r'(\d{2}\.?\d?)\s*(도|°)', lower)
        if temp_match:
            result.temperature = float(temp_match.group(1))
        if re.search(r'약\s*(먹|줬|투|복|을)', lower) or any(k in lower for k in ['해열제','타이레놀','투약','복용']):
            result.medicine = '약 복용'
        # 증상 메모
        symptoms = []
        if any(k in lower for k in ['구토', '토했', '토함', '게워']):
            symptoms.append('구토')
        if any(k in lower for k in ['발진', '두드러기']):
            symptoms.append('발진')
        if '콧물' in lower: symptoms.append('콧물')
        if '기침' in lower: symptoms.append('기침')
        if '설사' in lower: symptoms.append('설사')
        if symptoms:
            result.memo = ', '.join(symptoms)
        result.message = f'체온 {result.temperature}°C 기록' if result.temperature else '건강 기록'
        if result.memo:
            result.message += f' ({result.memo})'

    return result


# ============================================================
# 대화형 테스트 UI
# ============================================================

def confidence_bar(conf: float) -> str:
    filled = int(conf * 20)
    bar = "█" * filled + "░" * (20 - filled)
    if conf >= 0.7:
        label = "높음 ✓자동저장"
    elif conf >= 0.5:
        label = "보통"
    else:
        label = "낮음"
    return f"[{bar}] {conf:.0%} ({label})"


def print_result(text: str, result: ParseResult, scores: dict, idx: int):
    emoji = CATEGORY_EMOJI.get(result.category, "❓")

    print()
    print(f"  ┌─────────────────────────────────────────────────")
    print(f"  │ #{idx}  나: \"{text}\"")
    print(f"  ├─────────────────────────────────────────────────")

    if not result.is_success:
        print(f"  │ ❌ 인식 실패: {result.message}")
        print(f"  └─────────────────────────────────────────────────")
        return

    print(f"  │ {emoji} 카테고리:  {result.category.value}")
    print(f"  │ 📊 신뢰도:    {confidence_bar(result.confidence)}")

    # 시간 정보 (항상 표시)
    if result.parsed_time:
        time_str = result.parsed_time.strftime("%H:%M")
        print(f"  │ 🕐 시간:      {time_str}  ({result.time_source})")

    # 세부 정보
    details = []
    if result.feeding_type:
        details.append(f"수유타입: {result.feeding_type.value}")
    if result.amount_ml is not None:
        details.append(f"양: {result.amount_ml}ml")
    if result.duration_min is not None:
        details.append(f"시간: {result.duration_min}분")
    if result.sleep_status:
        details.append(f"상태: {result.sleep_status.value}")
    if result.diaper_type:
        details.append(f"종류: {result.diaper_type.value}")
    if result.stool_condition:
        details.append(f"변 상태: {result.stool_condition.value}")
    if result.stool_color:
        details.append(f"변 색상: {result.stool_color}")
    if result.temperature is not None:
        details.append(f"체온: {result.temperature}°C")
    if result.medicine:
        details.append(f"약: {result.medicine}")
    if result.memo:
        details.append(f"메모: {result.memo}")

    if details:
        print(f"  │ 📋 상세:      {', '.join(details)}")

    # 앱 동작 안내
    if result.confidence > 0.7:
        print(f"  │ ✅ → 자동 저장됩니다")
    elif result.confidence >= 0.3:
        print(f"  │ ❓ → \"이렇게 기록할까요?\" 확인 카드가 표시됩니다")
    else:
        print(f"  │ ❌ → 인식 실패")

    # 스코어 막대 그래프
    print(f"  │")
    print(f"  │ 📈 카테고리별 스코어:")
    max_score = max(scores.values()) if scores else 1
    for cat in [RecordCategory.FEEDING, RecordCategory.SLEEP, RecordCategory.DIAPER, RecordCategory.HEALTH]:
        s = scores.get(cat, 0)
        bar_len = int(s / max(max_score, 1) * 15) if s > 0 else 0
        bar = "▓" * bar_len
        marker = " ◀" if cat == result.category else ""
        print(f"  │   {CATEGORY_EMOJI[cat]} {cat.value:4s} {s:5.1f}  {bar}{marker}")

    print(f"  └─────────────────────────────────────────────────")


def print_user_feedback_prompt():
    print()
    print("  ┌─ 이 결과가 맞나요? ─────────────────────────────")
    print("  │  [Enter] 맞아요 (다음 입력)")
    print("  │  [1] 수유여야 해요    [2] 수면이어야 해요")
    print("  │  [3] 기저귀여야 해요  [4] 건강이어야 해요")
    print("  │  [5] 기타여야 해요 (인식 안 됐어야 해요)")
    print("  └─────────────────────────────────────────────────")


FEEDBACK_MAP = {
    '1': RecordCategory.FEEDING,
    '2': RecordCategory.SLEEP,
    '3': RecordCategory.DIAPER,
    '4': RecordCategory.HEALTH,
    '5': RecordCategory.OTHER,
}


def main():
    print()
    print("╔══════════════════════════════════════════════════════════╗")
    print("║  🍼 ChatBabyTime NLP 대화형 테스트 v3                   ║")
    print("╠══════════════════════════════════════════════════════════╣")
    print("║  채팅을 입력하면 NLP 파서가 어떻게 인식하는지           ║")
    print("║  실시간으로 확인할 수 있습니다.                         ║")
    print("║                                                          ║")
    print("║  ✨ v3 개선사항:                                        ║")
    print("║    • 건강: 구토/발진/두드러기/아파 등 증상 인식         ║")
    print("║    • 수면: 졸려/뒤척/잠투정/자다가 깼어 등 추가        ║")
    print("║    • 기저귀: 똥/갈아줬어/싸다 등 추가                  ║")
    print("║    • 수유: 죽/미음/퓨레/반병/한병 추가                  ║")
    print("║    • 시간: 아까(~30분전), 한시간/두시간 파싱           ║")
    print("║                                                          ║")
    print("║  종료: 'q' 또는 '끝' 입력                               ║")
    print("╚══════════════════════════════════════════════════════════╝")

    log_entries = []
    idx = 0

    while True:
        print()
        try:
            user_input = input("  💬 채팅 입력 > ").strip()
        except (EOFError, KeyboardInterrupt):
            break

        if user_input.lower() in ('q', '끝', 'quit', 'exit', '종료'):
            break

        if not user_input:
            continue

        idx += 1
        result = parse(user_input)
        scores = result.scores or {}

        print_result(user_input, result, scores, idx)
        print_user_feedback_prompt()

        try:
            feedback = input("  👉 ").strip()
        except (EOFError, KeyboardInterrupt):
            feedback = ''

        # 숫자만 추출 (사용자가 "3번" 같이 입력해도 처리)
        feedback_num = re.search(r'[1-5]', feedback)
        feedback_key = feedback_num.group(0) if feedback_num else None

        correct_category = FEEDBACK_MAP.get(feedback_key) if feedback_key else None

        # 카테고리가 맞는데 번호를 누른 경우 → 맞음으로 처리
        is_correct = (correct_category is None) or (correct_category == result.category)

        entry = {
            'idx': idx,
            'input': user_input,
            'detected': result.category.value if result.category else None,
            'confidence': result.confidence,
            'correct': is_correct,
            'expected': correct_category.value if (correct_category and not is_correct) else (result.category.value if result.category else None),
            'parsed_time': result.parsed_time.strftime("%H:%M") if result.parsed_time else None,
            'time_source': result.time_source,
            'stool_condition': result.stool_condition.value if result.stool_condition else None,
            'scores': {k.value: v for k, v in scores.items()} if scores else {},
            'feedback_raw': feedback,
        }
        log_entries.append(entry)

        if is_correct:
            print("  ✅ 정확하게 인식했군요!")
        else:
            print(f"  📝 기록: \"{user_input}\" → {correct_category.value}(이)여야 함 (현재: {result.category.value})")

    # ===== 세션 종료 & 리포트 =====
    if not log_entries:
        print("\n  테스트 기록이 없습니다. 다음에 다시 해보세요!")
        return

    total = len(log_entries)
    correct = sum(1 for e in log_entries if e['correct'])
    wrong = total - correct
    rate = correct / total * 100

    print()
    print("╔══════════════════════════════════════════════════════════╗")
    print("║              📊 테스트 세션 결과                        ║")
    print("╠══════════════════════════════════════════════════════════╣")
    print(f"║  총 테스트:    {total:>3}개                                   ║")
    print(f"║  정확 인식:    {correct:>3}개                                   ║")
    print(f"║  오인식:       {wrong:>3}개                                   ║")
    print(f"║  인식율:     {rate:>5.1f}%                                  ║")
    print("╚══════════════════════════════════════════════════════════╝")

    if wrong > 0:
        print()
        print("❌ 오인식 목록:")
        print("─" * 60)
        for e in log_entries:
            if not e['correct']:
                print(f"  \"{e['input']}\"")
                print(f"    인식: {e['detected']} → 정답: {e['expected']}")
                print(f"    스코어: {e['scores']}")
                print()
        print("─" * 60)

    # 전체 로그 요약
    print()
    print("📝 전체 테스트 로그:")
    print("─" * 70)
    print(f"  {'#':>3s}  {'입력':28s} {'카테고리':8s} {'시간':>7s} {'신뢰도':>6s} {'결과':4s}")
    print("─" * 70)
    for e in log_entries:
        status = "✅" if e['correct'] else "❌"
        time_str = e['parsed_time'] or '-'
        print(f"  {e['idx']:>3d}  {e['input']:28s} {e['detected'] or '-':8s} {time_str:>7s} {e['confidence']:>5.0%}  {status}")
    print("─" * 70)

    # 로그 저장
    log_path = "test/nlp_test_log.txt"
    try:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(f"\n{'='*60}\n")
            f.write(f"테스트 세션: {timestamp}\n")
            f.write(f"총 {total}건, 정확 {correct}건, 오인식 {wrong}건 ({rate:.1f}%)\n")
            f.write(f"{'='*60}\n")
            for e in log_entries:
                status = "✅" if e['correct'] else "❌"
                f.write(f"{status} \"{e['input']}\" → 인식: {e['detected']} (conf: {e['confidence']}) 시간: {e['parsed_time']} ({e['time_source']})")
                if not e['correct']:
                    f.write(f" [정답: {e['expected']}]")
                if e['stool_condition']:
                    f.write(f" [변상태: {e['stool_condition']}]")
                f.write(f"\n")
                f.write(f"   스코어: {e['scores']}\n")
            f.write("\n")

        print(f"\n💾 테스트 로그가 {log_path}에 저장되었습니다.")
    except Exception as ex:
        print(f"\n⚠️ 로그 저장 실패: {ex}")


if __name__ == '__main__':
    main()
