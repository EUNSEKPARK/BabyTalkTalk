#!/usr/bin/env python3
"""
ChatBabyTime NLP 리얼월드 테스트 🍼

실제 아기 엄마가 육아하면서 입력하는 것처럼:
- 다양한 말투/어투 (반말, 존댓말, 아기말, 줄임말)
- 오타, 띄어쓰기 실수
- 불완전한 입력 (잘못 보낸 것)
- 중복 전송
- 감정 섞인 표현
- 하루 일과 시나리오

실행: python3 test/nlp_realworld_test.py
"""

import re
import sys
from dataclasses import dataclass
from enum import Enum
from typing import Optional, Dict, List, Tuple
from datetime import datetime, timedelta


# ============================================================
# 모델 (nlp_interactive_test.py와 동일)
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

# ============================================================
# NLP 파서 v3 (동일 로직)
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

MIN_THRESHOLD = 2.0

# 본인/타인 패턴 (아기가 아닌 주어) - 정규식으로 정밀 매칭
SELF_REFERENCE_PATTERNS = [
    re.compile(r'^나\s'),          # 문장 시작 "나 ..."
    re.compile(r'나는\s'),          # "나는"
    re.compile(r'내가\s'),          # "내가"
    re.compile(r'남편'),
    re.compile(r'엄마가\s'),
    re.compile(r'아빠가\s'),
    re.compile(r'드라마'),
    re.compile(r'영화'),
    re.compile(r'유튜브'),
]


def normalize_text(text):
    """텍스트 정규화: ㅠㅠ, !!!, 연속공백, 글자 사이 과도한 띄어쓰기 등 제거"""
    t = text
    t = re.sub(r'[ㅋㅎㅠㅜㅡ]+', ' ', t)
    t = re.sub(r'[!?~.]{2,}', ' ', t)
    # 한글 글자 사이에 공백이 1개씩 있는 패턴 → 붙여쓰기로 복원
    if re.search(r'[\uac00-\ud7af]\s[\uac00-\ud7af]\s[\uac00-\ud7af]', t):
        t = re.sub(r'(?<=[\uac00-\ud7af])\s(?=[\uac00-\ud7af])', '', t)
    t = re.sub(r'\s{2,}', ' ', t)
    return t.strip()


def has_self_reference(text):
    for pat in SELF_REFERENCE_PATTERNS:
        if pat.search(text):
            return True
    return False


def score_category(text, keywords, patterns):
    score = 0.0
    for kw, weight in keywords.items():
        if kw in text:
            score += weight
    for pat, weight in patterns:
        if pat.search(text):
            score += weight
    return score


def calculate_scores(text):
    return {
        RecordCategory.FEEDING: score_category(text, FEEDING_KEYWORDS, FEEDING_PATTERNS),
        RecordCategory.SLEEP: score_category(text, SLEEP_KEYWORDS, SLEEP_PATTERNS),
        RecordCategory.DIAPER: score_category(text, DIAPER_KEYWORDS, DIAPER_PATTERNS),
        RecordCategory.HEALTH: score_category(text, HEALTH_KEYWORDS, HEALTH_PATTERNS),
    }


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


def parse(text):
    trimmed = text.strip()
    if not trimmed:
        return None, RecordCategory.OTHER, 0.0, {}

    lower_raw = trimmed.lower()
    lower = normalize_text(lower_raw)
    scores = calculate_scores(lower)

    # 본인/타인 필터: 정규화 전 원본에서 체크 (공백이 보존된 상태)
    if has_self_reference(lower_raw):
        for cat in scores:
            if scores[cat] > 0:
                scores[cat] *= 0.3  # 70% 감점

    best = select_best(scores)

    if best is None:
        return RecordCategory.OTHER, RecordCategory.OTHER, 0.3, scores

    max_score = scores[best]
    confidence = calc_confidence(max_score, scores)
    return best, best, confidence, scores


# ============================================================
# 테스트 케이스 정의
# ============================================================

# (입력 텍스트, 기대 카테고리, 설명/상황)
# None = 기타(OTHER)로 가야 정상

EMOJI = {
    RecordCategory.FEEDING: "🍼",
    RecordCategory.SLEEP: "😴",
    RecordCategory.DIAPER: "🧷",
    RecordCategory.HEALTH: "🌡️",
    RecordCategory.OTHER: "📝",
}

# ──────────────────────────────────────────────────
# 1. 하루 일과 시뮬레이션 (새벽~밤)
# ──────────────────────────────────────────────────
DAILY_SCENARIO = [
    # ── 새벽 ──
    ("새벽 2시에 깼어", RecordCategory.SLEEP, "새벽 기상"),
    ("분유 80ml 먹었어", RecordCategory.FEEDING, "새벽 수유"),
    ("다시 재웠어", RecordCategory.SLEEP, "새벽 재움"),
    # ── 아침 ──
    ("7시에 눈떴어", RecordCategory.SLEEP, "아침 기상"),
    ("아침에 모유 수유했어", RecordCategory.FEEDING, "아침 모유"),
    ("기저귀 갈았어 소변", RecordCategory.DIAPER, "아침 기저귀"),
    ("체온 36.5도", RecordCategory.HEALTH, "아침 체온 체크"),
    # ── 오전 ──
    ("10시 이유식 먹였어", RecordCategory.FEEDING, "오전 이유식"),
    ("응가 했어 노란색이야", RecordCategory.DIAPER, "오전 응가"),
    ("11시에 낮잠 잤어", RecordCategory.SLEEP, "오전 낮잠"),
    # ── 점심 ──
    ("12시 반에 깼어", RecordCategory.SLEEP, "낮잠 깨어남"),
    ("분유 120ml", RecordCategory.FEEDING, "점심 분유"),
    ("기저귀 갈았어", RecordCategory.DIAPER, "점심 기저귀"),
    # ── 오후 ──
    ("오후 2시 분유 100ml 먹음", RecordCategory.FEEDING, "오후 수유"),
    ("3시에 응가 대변", RecordCategory.DIAPER, "오후 응가"),
    ("3시 반부터 낮잠", RecordCategory.SLEEP, "오후 낮잠"),
    ("4시 반에 깼어", RecordCategory.SLEEP, "오후 기상"),
    # ── 저녁 ──
    ("6시 이유식 먹였어", RecordCategory.FEEDING, "저녁 이유식"),
    ("소변 봤어", RecordCategory.DIAPER, "저녁 소변"),
    ("8시에 목욕시키고 분유 150ml", RecordCategory.FEEDING, "저녁 수유"),
    # ── 밤 ──
    ("9시에 잠들었어", RecordCategory.SLEEP, "밤잠 시작"),
]

# ──────────────────────────────────────────────────
# 2. 실제 엄마 말투 (반말, 줄임말, 구어체)
# ──────────────────────────────────────────────────
MOM_CASUAL = [
    # 반말/구어체
    ("분유먹었어", RecordCategory.FEEDING, "띄어쓰기 없이"),
    ("분유 먹었음", RecordCategory.FEEDING, "~음 체"),
    ("분유먹음", RecordCategory.FEEDING, "붙여쓰기+~음"),
    ("모유수유함", RecordCategory.FEEDING, "~함 체"),
    ("젖먹였어", RecordCategory.FEEDING, "젖 붙여쓰기"),
    ("잠듬", RecordCategory.SLEEP, "~듬 (잠듦 변형)"),
    ("잤음", RecordCategory.SLEEP, "~음 체"),
    ("깼음", RecordCategory.SLEEP, "깼음"),
    ("기저귀갈았어", RecordCategory.DIAPER, "붙여쓰기"),
    ("응가함", RecordCategory.DIAPER, "~함 체"),
    ("똥쌌어", RecordCategory.DIAPER, "똥 붙여쓰기"),
    ("열남", RecordCategory.HEALTH, "줄임말"),
    ("약먹였어", RecordCategory.HEALTH, "약 붙여쓰기"),

    # 존댓말
    ("분유 먹었어요", RecordCategory.FEEDING, "존댓말"),
    ("잠들었어요", RecordCategory.SLEEP, "존댓말"),
    ("기저귀 갈았어요", RecordCategory.DIAPER, "존댓말"),
    ("열이 나요", RecordCategory.HEALTH, "존댓말"),

    # 아기한테 말하는 투
    ("우리 아가 잘잤네~", RecordCategory.SLEEP, "아기한테 말하는 투"),
    ("우리 아가 밥 잘 먹었네", RecordCategory.FEEDING, "아기한테 말하는 투"),
    ("우리 아기 응가 했구나", RecordCategory.DIAPER, "아기한테 말하는 투"),
]

# ──────────────────────────────────────────────────
# 3. 오타/실수 입력
# ──────────────────────────────────────────────────
TYPO_INPUTS = [
    ("분유 먹엇어", RecordCategory.FEEDING, "먹었어→먹엇어 오타"),
    ("분ㅠ 120ml", RecordCategory.FEEDING, "분유→분ㅠ 오타 (ml이 있어서)"),
    ("분유120", RecordCategory.FEEDING, "ml 빠짐"),
    ("기저기 갈았어", RecordCategory.DIAPER, "기저귀→기저기 오타"),
    ("응가했엉", RecordCategory.DIAPER, "했어→했엉 귀여운 오타"),
    ("잠들었엉", RecordCategory.SLEEP, "잠들었어→잠들었엉"),
    ("모유수유 15붕", RecordCategory.FEEDING, "분→붕 오타 (모유수유 키워드)"),
    ("낮잠 잼", RecordCategory.SLEEP, "잤어→잼? (낮잠 키워드)"),
]

# ──────────────────────────────────────────────────
# 4. 불완전한 입력 / 잘못 보낸 것
# ──────────────────────────────────────────────────
INCOMPLETE_INPUTS = [
    ("분유", RecordCategory.FEEDING, "분유만 입력"),
    ("모유", RecordCategory.FEEDING, "모유만 입력"),
    ("이유식", RecordCategory.FEEDING, "이유식만 입력"),
    ("응가", RecordCategory.DIAPER, "응가만 입력"),
    ("기저귀", RecordCategory.DIAPER, "기저귀만 입력"),
    ("잠", RecordCategory.OTHER, "잠 한글자만 (인식 안돼야 정상)"),
    ("ㅋ", RecordCategory.OTHER, "의미없는 입력"),
    ("ㅎㅎ", RecordCategory.OTHER, "웃음만"),
    ("아", RecordCategory.OTHER, "한글자만"),
    ("네", RecordCategory.OTHER, "대답만"),
    ("120ml", RecordCategory.FEEDING, "양만 입력"),
    ("37.5도", RecordCategory.HEALTH, "체온만 입력"),
]

# ──────────────────────────────────────────────────
# 5. 중복 전송 (연달아 같은 내용)
# ──────────────────────────────────────────────────
DUPLICATE_SENDS = [
    ("분유 먹었어", RecordCategory.FEEDING, "1차 전송"),
    ("분유 먹었어", RecordCategory.FEEDING, "중복 전송"),
    ("응가 했어", RecordCategory.DIAPER, "1차 전송"),
    ("응가 했어", RecordCategory.DIAPER, "중복 전송"),
]

# ──────────────────────────────────────────────────
# 6. 감정/상황 섞인 표현
# ──────────────────────────────────────────────────
EMOTIONAL_INPUTS = [
    ("드디어 잠들었다 ㅠㅠ", RecordCategory.SLEEP, "감정 표현"),
    ("또 깼어 ㅜㅜ", RecordCategory.SLEEP, "짜증 섞인"),
    ("겨우 분유 100ml 먹었어...", RecordCategory.FEEDING, "한숨"),
    ("아 응가 또 했어", RecordCategory.DIAPER, "짜증"),
    ("드디어 낮잠 잤다!!!", RecordCategory.SLEEP, "느낌표 다수"),
    ("헐 열이 나네", RecordCategory.HEALTH, "놀람"),
    ("세상에 토했어ㅜㅜ", RecordCategory.HEALTH, "놀람+슬픔"),
    ("에효 기저귀 또 갈아야해", RecordCategory.DIAPER, "한숨"),
    ("오예 꿀잠 자는중~", RecordCategory.SLEEP, "기쁨"),
    ("맛있게 분유 잘 먹었어 ㅎㅎ", RecordCategory.FEEDING, "기쁨 (분유 키워드 포함)"),
    ("콧물이 계속 나 ㅠ", RecordCategory.HEALTH, "걱정"),
    ("밤새 안자 미치겠다", RecordCategory.SLEEP, "짜증"),
]

# ──────────────────────────────────────────────────
# 7. 복합 입력 (여러 정보 한번에)
# ──────────────────────────────────────────────────
COMPLEX_INPUTS = [
    ("아까 분유 120ml 먹고 바로 잠들었어", RecordCategory.FEEDING, "수유+수면 복합 (수유 스코어 높음)"),
    ("오후 3시에 기저귀 갈았는데 응가 묽었어", RecordCategory.DIAPER, "기저귀+상태 복합"),
    ("분유 먹다가 토했어", RecordCategory.HEALTH, "수유+건강 복합 (건강 스코어 높음)"),
    ("열나서 병원 갔다왔어", RecordCategory.HEALTH, "복합 건강"),
    ("이유식 먹이고 기저귀 갈았어", RecordCategory.DIAPER, "수유+기저귀 (기저귀 스코어가 더 높음)"),
    ("낮잠 자다가 깼어", RecordCategory.SLEEP, "수면 복합"),
    ("콧물 나고 기침해요", RecordCategory.HEALTH, "복합 증상"),
    ("모유 먹이다가 잠들었어", RecordCategory.SLEEP, "수유+수면 (수면 스코어가 더 높음)"),
]

# ──────────────────────────────────────────────────
# 8. 음성인식 오류 시뮬레이션 (STT 오인식)
# ──────────────────────────────────────────────────
STT_ERRORS = [
    ("분유 백이십 먹었어", RecordCategory.FEEDING, "STT: 120→백이십"),
    ("체온이 삼십칠도 오", RecordCategory.HEALTH, "STT: 37.5→삼십칠도오"),
    ("모유 수유 했어요", RecordCategory.FEEDING, "STT 정상 케이스"),
    ("기저귀 가라 줬어", RecordCategory.DIAPER, "STT: 갈아→가라"),
    ("낮잠 잤어요", RecordCategory.SLEEP, "STT 정상 케이스"),
]

# ──────────────────────────────────────────────────
# 9. 시간 표현 다양성
# ──────────────────────────────────────────────────
TIME_EXPRESSIONS = [
    ("방금 분유 먹었어", RecordCategory.FEEDING, "방금"),
    ("아까 잠들었어", RecordCategory.SLEEP, "아까"),
    ("10분 전에 깼어", RecordCategory.SLEEP, "N분 전"),
    ("1시간 전에 분유 먹었어", RecordCategory.FEEDING, "N시간 전"),
    ("오전 10시에 이유식", RecordCategory.FEEDING, "오전 N시"),
    ("오후 2시 30분에 잠들었어", RecordCategory.SLEEP, "오후 N시 M분"),
    ("밤 11시에 분유", RecordCategory.FEEDING, "밤 N시"),
    ("새벽 3시에 깼어", RecordCategory.SLEEP, "새벽 N시"),
    ("8:30에 분유 먹음", RecordCategory.FEEDING, "HH:MM"),
    ("3시쯤 잠들었어", RecordCategory.SLEEP, "~쯤"),
]

# ──────────────────────────────────────────────────
# 10. 절대 육아가 아닌 것 (오탐 방지 스트레스)
# ──────────────────────────────────────────────────
FALSE_POSITIVE_STRESS = [
    ("나 배고파 밥 먹어야겠다", RecordCategory.OTHER, "엄마 본인 식사"),
    ("나 좀 자고싶다", RecordCategory.OTHER, "엄마 본인 수면"),
    ("남편한테 약 먹으라고 했어", RecordCategory.OTHER, "남편 약"),
    ("오늘 뭐 먹지", RecordCategory.OTHER, "엄마 고민"),
    ("장 봐야 하는데", RecordCategory.OTHER, "일상 대화"),
    ("물 마셔야겠다", RecordCategory.OTHER, "엄마 본인"),
    ("커피 마셨어", RecordCategory.OTHER, "엄마 음료"),
    ("드라마 보다가 잠들뻔", RecordCategory.OTHER, "엄마 일상"),
    ("택배 왔어", RecordCategory.OTHER, "무관한 내용"),
    ("날씨 좋다", RecordCategory.OTHER, "무관한 내용"),
    ("아 졸려", RecordCategory.OTHER, "엄마 본인 졸림"),  # 이것은 까다로움
    ("오늘 힘들다", RecordCategory.OTHER, "감정 토로"),
    ("물건 싸게 샀어", RecordCategory.OTHER, "쇼핑 이야기"),
    ("이거 비싸다", RecordCategory.OTHER, "가격 이야기"),
    ("반찬 만들어야지", RecordCategory.OTHER, "요리 이야기"),
]

# ──────────────────────────────────────────────────
# 11. 월령별 특수 표현
# ──────────────────────────────────────────────────
AGE_SPECIFIC = [
    # 신생아 (0~3개월)
    ("젖 물렸어", RecordCategory.FEEDING, "신생아 모유"),
    ("젖꼭지 거부해", RecordCategory.FEEDING, "젖꼭지"),
    ("배꼽에서 진물 나", RecordCategory.HEALTH, "신생아 배꼽"),  # 까다로운 케이스
    # 이유식기 (5~12개월)
    ("죽 먹였어", RecordCategory.FEEDING, "이유식기 죽"),
    ("미음 먹였어", RecordCategory.FEEDING, "이유식기 미음"),
    ("퓨레 한 병 먹었어", RecordCategory.FEEDING, "이유식기 퓨레"),
    # 돌 이후 (12개월+)
    ("밥 먹었어", RecordCategory.FEEDING, "돌 이후 밥"),
    ("우유 먹었어", RecordCategory.FEEDING, "돌 이후 우유"),
    ("간식 줬어", RecordCategory.FEEDING, "돌 이후 간식"),
]

# ──────────────────────────────────────────────────
# 12. 띄어쓰기 변형
# ──────────────────────────────────────────────────
SPACING_VARIANTS = [
    ("분유먹었어", RecordCategory.FEEDING, "전부 붙여쓰기"),
    ("분 유 먹 었 어", RecordCategory.FEEDING, "전부 띄어쓰기"),
    ("기 저 귀 갈았어", RecordCategory.DIAPER, "이상한 띄어쓰기"),
    ("응가했어", RecordCategory.DIAPER, "붙여쓰기"),
    ("잠 들었어", RecordCategory.SLEEP, "잠+들었어"),
    ("낮 잠잤어", RecordCategory.SLEEP, "낮+잠잤어"),
    ("체온37.5도", RecordCategory.HEALTH, "체온 붙여쓰기"),
    ("열 이 나", RecordCategory.HEALTH, "이상한 띄어쓰기"),
]


# ============================================================
# 테스트 러너
# ============================================================

class RealisticTestRunner:
    def __init__(self):
        self.results = []
        self.current_group = ""

    def run_group(self, name, test_cases):
        self.current_group = name
        group_pass = 0
        group_fail = 0
        group_results = []

        for text, expected, desc in test_cases:
            actual, _, confidence, scores = parse(text)
            if actual is None:
                actual = RecordCategory.OTHER

            is_pass = (actual == expected)
            if is_pass:
                group_pass += 1
            else:
                group_fail += 1

            group_results.append({
                'text': text,
                'expected': expected,
                'actual': actual,
                'confidence': confidence,
                'desc': desc,
                'is_pass': is_pass,
                'scores': scores,
            })

        self.results.append({
            'group': name,
            'cases': group_results,
            'pass': group_pass,
            'fail': group_fail,
            'total': group_pass + group_fail,
        })

        return group_pass, group_fail

    def print_report(self):
        total_pass = 0
        total_fail = 0
        all_failures = []

        print()
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║     🍼 ChatBabyTime NLP 리얼월드 테스트 결과               ║")
        print("╠══════════════════════════════════════════════════════════════╣")

        for group in self.results:
            status = "✅" if group['fail'] == 0 else "⚠️ "
            rate = group['pass'] / group['total'] * 100 if group['total'] > 0 else 0
            print(f"║  {status} {group['group']:30s}  {group['pass']:>3}/{group['total']:<3} ({rate:5.1f}%) ║")
            total_pass += group['pass']
            total_fail += group['fail']
            for case in group['cases']:
                if not case['is_pass']:
                    all_failures.append(case)

        total = total_pass + total_fail
        rate = total_pass / total * 100 if total > 0 else 0

        print("╠══════════════════════════════════════════════════════════════╣")
        print(f"║  📊 총 {total}건 테스트 | ✅ {total_pass}건 통과 | ❌ {total_fail}건 실패    ║")
        print(f"║  🎯 전체 인식율: {rate:.1f}%                                     ║")
        print("╚══════════════════════════════════════════════════════════════╝")

        # 실패 상세
        if all_failures:
            print()
            print(f"❌ 실패 목록 ({len(all_failures)}건):")
            print("─" * 80)
            for f in all_failures:
                print(f"  \"{f['text']}\"")
                print(f"    상황: {f['desc']}")
                print(f"    기대: {EMOJI[f['expected']]} {f['expected'].value}  →  실제: {EMOJI[f['actual']]} {f['actual'].value}  (신뢰도: {f['confidence']:.0%})")
                scores_str = {k.value: v for k, v in f['scores'].items() if v > 0}
                if scores_str:
                    print(f"    스코어: {scores_str}")
                print()
            print("─" * 80)

        # 카테고리별 분석
        print()
        print("📊 카테고리별 인식율:")
        print("─" * 50)
        for cat in [RecordCategory.FEEDING, RecordCategory.SLEEP, RecordCategory.DIAPER, RecordCategory.HEALTH, RecordCategory.OTHER]:
            cat_total = 0
            cat_pass = 0
            for group in self.results:
                for case in group['cases']:
                    if case['expected'] == cat:
                        cat_total += 1
                        if case['is_pass']:
                            cat_pass += 1
            if cat_total > 0:
                cat_rate = cat_pass / cat_total * 100
                bar = "█" * int(cat_rate / 5) + "░" * (20 - int(cat_rate / 5))
                print(f"  {EMOJI[cat]} {cat.value:4s}  [{bar}] {cat_pass}/{cat_total} ({cat_rate:.1f}%)")
        print("─" * 50)

        # 신뢰도 분포
        print()
        print("📊 신뢰도 분포 (정확히 인식된 것만):")
        print("─" * 50)
        conf_buckets = {'자동저장 (>70%)': 0, '확인카드 (30~70%)': 0, '낮음 (<30%)': 0}
        for group in self.results:
            for case in group['cases']:
                if case['is_pass'] and case['expected'] != RecordCategory.OTHER:
                    if case['confidence'] > 0.7:
                        conf_buckets['자동저장 (>70%)'] += 1
                    elif case['confidence'] >= 0.3:
                        conf_buckets['확인카드 (30~70%)'] += 1
                    else:
                        conf_buckets['낮음 (<30%)'] += 1
        for label, count in conf_buckets.items():
            bar = "▓" * count
            print(f"  {label:20s}  {count:>3}건  {bar}")
        print("─" * 50)

        # 최종 평가
        print()
        if rate >= 95:
            print("🎉 우수! 실제 사용 환경에서도 95% 이상 인식!")
        elif rate >= 90:
            print("👍 양호! 90% 이상이지만 일부 개선 필요")
        elif rate >= 80:
            print("⚠️  보통. 80% 이상이지만 상당한 개선 필요")
        else:
            print(f"🚨 미흡. 인식율 {rate:.1f}% — 대폭 개선 필요")

        return rate, all_failures


# ============================================================
# 메인
# ============================================================

def main():
    print()
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  🍼 ChatBabyTime NLP 리얼월드 테스트                       ║")
    print("║                                                              ║")
    print("║  실제 육아맘이 입력하는 것처럼 다양한 상황을 시뮬레이션     ║")
    print("║  오타, 말투, 감정, 불완전 입력, 중복 전송 등 테스트         ║")
    print("╚══════════════════════════════════════════════════════════════╝")

    runner = RealisticTestRunner()

    groups = [
        ("1️⃣  하루 일과 시뮬레이션", DAILY_SCENARIO),
        ("2️⃣  엄마 말투 (반말/존댓말/아기말)", MOM_CASUAL),
        ("3️⃣  오타/실수 입력", TYPO_INPUTS),
        ("4️⃣  불완전한 입력", INCOMPLETE_INPUTS),
        ("5️⃣  중복 전송", DUPLICATE_SENDS),
        ("6️⃣  감정 섞인 표현", EMOTIONAL_INPUTS),
        ("7️⃣  복합 입력 (여러 정보)", COMPLEX_INPUTS),
        ("8️⃣  음성인식 오류 (STT)", STT_ERRORS),
        ("9️⃣  시간 표현 다양성", TIME_EXPRESSIONS),
        ("🔟 오탐 방지 스트레스", FALSE_POSITIVE_STRESS),
        ("1️⃣1️⃣ 월령별 특수 표현", AGE_SPECIFIC),
        ("1️⃣2️⃣ 띄어쓰기 변형", SPACING_VARIANTS),
    ]

    for name, cases in groups:
        runner.run_group(name, cases)

    rate, failures = runner.print_report()

    # 로그 저장
    log_path = "test/nlp_realworld_log.txt"
    try:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(log_path, 'a', encoding='utf-8') as f:
            total = sum(g['total'] for g in runner.results)
            passed = sum(g['pass'] for g in runner.results)
            failed = sum(g['fail'] for g in runner.results)
            f.write(f"\n{'='*60}\n")
            f.write(f"리얼월드 테스트: {timestamp}\n")
            f.write(f"총 {total}건, 정확 {passed}건, 오인식 {failed}건 ({rate:.1f}%)\n")
            f.write(f"{'='*60}\n")
            if failures:
                f.write(f"\n실패 목록 ({len(failures)}건):\n")
                for fl in failures:
                    f.write(f"  \"{fl['text']}\" → 기대: {fl['expected'].value}, 실제: {fl['actual'].value} (conf: {fl['confidence']}) [{fl['desc']}]\n")
            f.write("\n")
        print(f"\n💾 로그 저장: {log_path}")
    except Exception as ex:
        print(f"\n⚠️ 로그 저장 실패: {ex}")


if __name__ == '__main__':
    main()
