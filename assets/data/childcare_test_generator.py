#!/usr/bin/env python3
"""
육아 기록 앱 NLP 파서 테스트용 문장 생성기
- 카테고리별로 다양한 패턴의 한국어 문장을 생성
- JSONL 형식으로 출력 (label 포함)
"""

import json
import random
import itertools
from datetime import datetime, timedelta

random.seed(42)

# ============================================================
# 1. 기본 사전 (Dictionary)
# ============================================================

# 아기 호칭
BABY_NAMES = [
    "아기", "애기", "아가", "우리 아기", "우리 애기", "둘째", "첫째",
    "아들", "딸", "우리 아들", "우리 딸", "큰애", "작은애", "막내",
    "아이", "우리 아이", "베이비", "쪼꼬미", "아긔", "",  # 빈 문자열 = 생략
]

# --- 수유 관련 ---
FEEDING_TYPES = ["분유", "모유", "우유", "유축", "젖"]
FEEDING_VERBS = [
    "먹였어", "줬어", "먹임", "먹었어", "수유했어", "수유함",
    "먹여줬어", "물렸어", "먹였음", "줬음", "먹었음", "마셨어",
    "수유 완료", "먹이기 완료", "먹였다", "줬다", "먹음",
]
FEEDING_AMOUNTS = list(range(10, 261, 10))  # 10~260ml
FEEDING_UNITS = ["ml", "밀리", "CC", "cc", ""]  # 빈 = 숫자만

# --- 이유식 관련 ---
BABYFOOD_TYPES = [
    "이유식", "미음", "죽", "퓨레", "간식", "과일",
    "바나나", "고구마", "감자", "당근", "사과", "배",
    "소고기죽", "야채죽", "쌀미음", "닭죽", "시금치죽",
]
BABYFOOD_VERBS = ["먹였어", "줬어", "먹임", "먹었어", "먹여줬어", "먹였음"]
BABYFOOD_AMOUNTS_GRAM = list(range(10, 201, 10))
BABYFOOD_AMOUNTS_SPOON = list(range(1, 21))

# --- 기저귀 관련 ---
DIAPER_TYPES = ["소변", "대변", "응가", "쉬", "쉬했어", "똥", "오줌", "소", "대"]
DIAPER_VERBS = [
    "갈아줬어", "갈았어", "교체했어", "갈아줌", "바꿔줬어", "갈아줬음",
    "교체함", "기저귀 갈음", "했어", "봤어", "쌌어", "쌌음",
]
DIAPER_STATES = ["묽은", "딱딱한", "보통", "물처럼", "녹색", "노란", "검은", ""]
DIAPER_KEYWORD = ["기저귀", "기져귀", "기저기", ""]

# --- 수면 관련 ---
SLEEP_START_VERBS = [
    "잠들었어", "잤어", "재웠어", "잠듦", "자기 시작했어", "눈 감았어",
    "잠들었음", "잠잤어", "자요", "재움", "잠투정 끝나고 잤어",
    "낮잠 시작", "낮잠 들었어", "밤잠 들었어",
]
SLEEP_END_VERBS = [
    "일어났어", "깼어", "기상했어", "일어남", "깸", "눈 떴어",
    "기상함", "일어났음", "깼음", "잠 깼어",
]
SLEEP_DURATION_HOURS = list(range(0, 5))
SLEEP_DURATION_MINS = list(range(0, 60, 5))

# --- 체온 관련 ---
TEMP_VERBS = ["체온", "열", "온도"]
TEMP_VALUES = [round(x * 0.1, 1) for x in range(360, 401)]  # 36.0~40.0
TEMP_ACTIONS = [
    "재봤어", "쟀어", "측정했어", "확인했어", "재봄", "쟀음", "재봤음",
]

# --- 목욕 관련 ---
BATH_VERBS = [
    "목욕했어", "목욕시켰어", "씻겼어", "씻겨줬어", "목욕함",
    "샤워했어", "샤워시켰어", "목욕 완료", "씻김",
]

# --- 약/병원 관련 ---
MED_TYPES = ["타이레놀", "해열제", "감기약", "시럽", "비타민", "유산균", "프로바이오틱스", "약"]
MED_VERBS = ["먹였어", "줬어", "복용했어", "먹임", "줬음", "투약함"]
HOSPITAL_VERBS = ["병원 다녀왔어", "소아과 갔어", "예방접종 했어", "건강검진 받았어"]

# --- 시간 표현 ---
TIME_RELATIVE = [
    "방금", "지금", "아까", "좀 전에", "조금 전에",
    "5분 전", "10분 전", "15분 전", "20분 전", "30분 전",
    "1시간 전", "2시간 전", "한 시간 전", "두 시간 전",
    "금방", "이제 막", "얼마 전에",
]
TIME_ABSOLUTE_HOUR = list(range(0, 24))
TIME_ABSOLUTE_MIN = list(range(0, 60, 5))
TIME_PERIODS = ["오전", "오후", "새벽", "아침", "점심", "저녁", "밤"]
TIME_DAY = ["오늘", "어제", "그제", "아침에", "점심에", "저녁에", ""]

# --- 말투 변형 ---
ENDINGS = ["", "요", "ㅋ", "ㅋㅋ", "~", "!", "..", "ㅎ"]
FILLER = ["", "음 ", "아 ", "어 ", "그 ", "그니까 ", "아 그리고 "]

# ============================================================
# 2. 문장 생성 함수
# ============================================================

def random_time_expr():
    """랜덤 시간 표현 생성"""
    choice = random.choice(["relative", "absolute", "period", "none"])
    if choice == "relative":
        return random.choice(TIME_RELATIVE), "relative"
    elif choice == "absolute":
        h = random.choice(TIME_ABSOLUTE_HOUR)
        m = random.choice(TIME_ABSOLUTE_MIN)
        fmt = random.choice([
            f"{h}시 {m}분에",
            f"{h}시{m}분에",
            f"{h}:{m:02d}에",
            f"{h}시에",
            f"{random.choice(TIME_PERIODS)} {h if h <= 12 else h-12}시에",
            f"{random.choice(TIME_PERIODS)} {h if h <= 12 else h-12}시 {m}분에",
        ])
        return fmt, f"{h:02d}:{m:02d}"
    elif choice == "period":
        day = random.choice(TIME_DAY)
        return f"{day} ".strip(), "period"
    else:
        return "", "none"


def gen_feeding():
    """수유 문장 생성"""
    baby = random.choice(BABY_NAMES)
    ftype = random.choice(FEEDING_TYPES)
    verb = random.choice(FEEDING_VERBS)
    amount = random.choice(FEEDING_AMOUNTS)
    unit = random.choice(FEEDING_UNITS)
    time_expr, time_label = random_time_expr()
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)
    day = random.choice(TIME_DAY)

    # 다양한 문장 패턴
    patterns = [
        f"{filler}{baby} {ftype} {amount}{unit} {verb}{ending}",
        f"{filler}{time_expr} {baby} {ftype} {amount}{unit} {verb}{ending}",
        f"{filler}{day} {time_expr} {ftype} {amount}{unit} {verb}{ending}",
        f"{filler}{baby}한테 {ftype} {amount}{unit} {verb}{ending}",
        f"{filler}{ftype} {amount}{unit}{ending}",
        f"{filler}{baby} {time_expr} {ftype} {verb} {amount}{unit}{ending}",
    ]
    text = random.choice(patterns).replace("  ", " ").strip()

    label = {
        "intent": "feeding",
        "entities": {
            "type": ftype,
            "amount": amount,
            "unit": "ml",
            "time": time_label,
        },
        "status": "complete",
    }
    return text, label


def gen_feeding_incomplete():
    """수유 - 정보 누락 문장"""
    baby = random.choice(BABY_NAMES)
    ftype = random.choice(FEEDING_TYPES)
    verb = random.choice(FEEDING_VERBS)
    time_expr, time_label = random_time_expr()
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    # 양(amount) 누락 패턴
    patterns = [
        f"{filler}{baby} {ftype} {verb}{ending}",
        f"{filler}{time_expr} {ftype} {verb}{ending}",
        f"{filler}{baby}한테 {ftype} 좀 {verb}{ending}",
        f"{filler}{ftype} 먹임{ending}",
        f"{filler}{baby} {ftype} 조금 {verb}{ending}",
        f"{filler}수유했어{ending}",
        f"{filler}{baby} 밥 줬어{ending}",
    ]
    text = random.choice(patterns).replace("  ", " ").strip()

    label = {
        "intent": "feeding",
        "entities": {
            "type": ftype,
            "amount": None,
            "unit": None,
            "time": time_label,
        },
        "status": "incomplete",
        "missing": ["amount"],
    }
    return text, label


def gen_babyfood():
    """이유식 문장 생성"""
    baby = random.choice(BABY_NAMES)
    food = random.choice(BABYFOOD_TYPES)
    verb = random.choice(BABYFOOD_VERBS)
    time_expr, time_label = random_time_expr()
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    use_gram = random.choice([True, False])
    if use_gram:
        amount = random.choice(BABYFOOD_AMOUNTS_GRAM)
        unit_str = random.choice(["g", "그램", ""])
        unit_label = "g"
    else:
        amount = random.choice(BABYFOOD_AMOUNTS_SPOON)
        unit_str = random.choice(["숟가락", "스푼", "수저"])
        unit_label = "spoon"

    patterns = [
        f"{filler}{baby} {food} {amount}{unit_str} {verb}{ending}",
        f"{filler}{time_expr} {food} {amount}{unit_str} {verb}{ending}",
        f"{filler}{food} {verb} {amount}{unit_str}{ending}",
        f"{filler}{baby}한테 {food} {amount}{unit_str} {verb}{ending}",
    ]
    text = random.choice(patterns).replace("  ", " ").strip()

    label = {
        "intent": "babyfood",
        "entities": {
            "type": food,
            "amount": amount,
            "unit": unit_label,
            "time": time_label,
        },
        "status": "complete",
    }
    return text, label


def gen_diaper():
    """기저귀 문장 생성"""
    baby = random.choice(BABY_NAMES)
    dtype = random.choice(DIAPER_TYPES)
    verb = random.choice(DIAPER_VERBS)
    state = random.choice(DIAPER_STATES)
    keyword = random.choice(DIAPER_KEYWORD)
    time_expr, time_label = random_time_expr()
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    # 대변/소변 분류
    if dtype in ["대변", "응가", "똥", "대"]:
        dtype_label = "poop"
    elif dtype in ["소변", "쉬", "쉬했어", "오줌", "소"]:
        dtype_label = "pee"
    else:
        dtype_label = "unknown"

    patterns = [
        f"{filler}{baby} {keyword} {verb} {state} {dtype}{ending}",
        f"{filler}{time_expr} {baby} {dtype} {verb}{ending}",
        f"{filler}{baby} {state}{dtype} {verb}{ending}",
        f"{filler}{keyword} {verb}{ending}",
        f"{filler}{baby} {dtype}{ending}",
        f"{filler}{time_expr} {state}{dtype} {keyword} {verb}{ending}",
    ]
    text = random.choice(patterns).replace("  ", " ").strip()

    label = {
        "intent": "diaper",
        "entities": {
            "type": dtype_label,
            "state": state if state else None,
            "time": time_label,
        },
        "status": "complete",
    }
    return text, label


def gen_sleep_start():
    """수면 시작 문장"""
    baby = random.choice(BABY_NAMES)
    verb = random.choice(SLEEP_START_VERBS)
    time_expr, time_label = random_time_expr()
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    patterns = [
        f"{filler}{baby} {verb}{ending}",
        f"{filler}{time_expr} {baby} {verb}{ending}",
        f"{filler}{baby} {time_expr} {verb}{ending}",
        f"{filler}{verb}{ending}",
    ]
    text = random.choice(patterns).replace("  ", " ").strip()

    label = {
        "intent": "sleep_start",
        "entities": {"time": time_label},
        "status": "complete",
    }
    return text, label


def gen_sleep_end():
    """수면 종료 문장"""
    baby = random.choice(BABY_NAMES)
    verb = random.choice(SLEEP_END_VERBS)
    time_expr, time_label = random_time_expr()
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    patterns = [
        f"{filler}{baby} {verb}{ending}",
        f"{filler}{time_expr} {baby} {verb}{ending}",
        f"{filler}{baby} {time_expr} {verb}{ending}",
        f"{filler}{verb}{ending}",
    ]
    text = random.choice(patterns).replace("  ", " ").strip()

    label = {
        "intent": "sleep_end",
        "entities": {"time": time_label},
        "status": "complete",
    }
    return text, label


def gen_sleep_duration():
    """수면 기간 보고 문장"""
    baby = random.choice(BABY_NAMES)
    h = random.choice(SLEEP_DURATION_HOURS)
    m = random.choice(SLEEP_DURATION_MINS)
    if h == 0 and m == 0:
        m = 30
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    if h > 0 and m > 0:
        dur_str = random.choice([f"{h}시간 {m}분", f"{h}시간반" if m == 30 else f"{h}시간 {m}분"])
    elif h > 0:
        dur_str = f"{h}시간"
    else:
        dur_str = f"{m}분"

    patterns = [
        f"{filler}{baby} {dur_str} 잤어{ending}",
        f"{filler}낮잠 {dur_str}{ending}",
        f"{filler}{baby} 낮잠 {dur_str} 잤어{ending}",
        f"{filler}{dur_str} 동안 잤어{ending}",
    ]
    text = random.choice(patterns).replace("  ", " ").strip()

    label = {
        "intent": "sleep_duration",
        "entities": {"hours": h, "minutes": m},
        "status": "complete",
    }
    return text, label


def gen_temperature():
    """체온 기록 문장"""
    baby = random.choice(BABY_NAMES)
    temp = random.choice(TEMP_VALUES)
    temp_word = random.choice(TEMP_VERBS)
    action = random.choice(TEMP_ACTIONS)
    time_expr, time_label = random_time_expr()
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    patterns = [
        f"{filler}{baby} {temp_word} {action} {temp}도{ending}",
        f"{filler}{temp_word} {temp}도{ending}",
        f"{filler}{baby} {temp}도{ending}",
        f"{filler}{time_expr} {temp_word} {temp}도{ending}",
        f"{filler}{baby} {temp_word} {temp}{ending}",
    ]
    text = random.choice(patterns).replace("  ", " ").strip()

    label = {
        "intent": "temperature",
        "entities": {"value": temp, "time": time_label},
        "status": "complete",
    }
    return text, label


def gen_bath():
    """목욕 기록 문장"""
    baby = random.choice(BABY_NAMES)
    verb = random.choice(BATH_VERBS)
    time_expr, time_label = random_time_expr()
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    patterns = [
        f"{filler}{baby} {verb}{ending}",
        f"{filler}{time_expr} {baby} {verb}{ending}",
        f"{filler}{verb}{ending}",
    ]
    text = random.choice(patterns).replace("  ", " ").strip()

    label = {
        "intent": "bath",
        "entities": {"time": time_label},
        "status": "complete",
    }
    return text, label


def gen_medicine():
    """약 투약 문장"""
    baby = random.choice(BABY_NAMES)
    med = random.choice(MED_TYPES)
    verb = random.choice(MED_VERBS)
    time_expr, time_label = random_time_expr()
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    patterns = [
        f"{filler}{baby} {med} {verb}{ending}",
        f"{filler}{time_expr} {med} {verb}{ending}",
        f"{filler}{baby}한테 {med} {verb}{ending}",
        f"{filler}{med} {verb}{ending}",
    ]
    text = random.choice(patterns).replace("  ", " ").strip()

    label = {
        "intent": "medicine",
        "entities": {"type": med, "time": time_label},
        "status": "complete",
    }
    return text, label


def gen_hospital():
    """병원 방문 문장"""
    baby = random.choice(BABY_NAMES)
    verb = random.choice(HOSPITAL_VERBS)
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    patterns = [
        f"{filler}{baby} {verb}{ending}",
        f"{filler}{verb}{ending}",
        f"{filler}오늘 {baby} {verb}{ending}",
    ]
    text = random.choice(patterns).replace("  ", " ").strip()

    label = {
        "intent": "hospital",
        "entities": {},
        "status": "complete",
    }
    return text, label


def gen_multi_intent():
    """복합 의도 문장 (한 문장에 2개 이상 행위)"""
    connectors = ["하고", "그리고", "다음에", "후에", "끝나고", "이후에", "해서"]
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)
    baby = random.choice(BABY_NAMES)

    # 복합 의도 템플릿
    templates = [
        # 수면 + 수유
        (
            f"{filler}{baby} 일어나서 {random.choice(FEEDING_TYPES)} {random.choice(FEEDING_AMOUNTS)}{random.choice(FEEDING_UNITS)} {random.choice(FEEDING_VERBS)}{ending}",
            {"intents": ["sleep_end", "feeding"]},
        ),
        (
            f"{filler}{baby} 잠깨고 바로 {random.choice(FEEDING_TYPES)} {random.choice(FEEDING_VERBS)}{ending}",
            {"intents": ["sleep_end", "feeding"]},
        ),
        # 기저귀 + 수유
        (
            f"{filler}{random.choice(DIAPER_KEYWORD)} 갈아주고 {random.choice(FEEDING_TYPES)} {random.choice(FEEDING_AMOUNTS)}{random.choice(FEEDING_UNITS)} {random.choice(FEEDING_VERBS)}{ending}",
            {"intents": ["diaper", "feeding"]},
        ),
        (
            f"{filler}{baby} {random.choice(DIAPER_TYPES)} {random.choice(connectors)} {random.choice(FEEDING_TYPES)} {random.choice(FEEDING_VERBS)}{ending}",
            {"intents": ["diaper", "feeding"]},
        ),
        # 수유 + 수면
        (
            f"{filler}{random.choice(FEEDING_TYPES)} 먹고 바로 잠들었어{ending}",
            {"intents": ["feeding", "sleep_start"]},
        ),
        (
            f"{filler}{baby} {random.choice(FEEDING_TYPES)} {random.choice(FEEDING_AMOUNTS)}ml 먹이고 재웠어{ending}",
            {"intents": ["feeding", "sleep_start"]},
        ),
        # 목욕 + 수유
        (
            f"{filler}{baby} {random.choice(BATH_VERBS)} {random.choice(connectors)} {random.choice(FEEDING_TYPES)} {random.choice(FEEDING_VERBS)}{ending}",
            {"intents": ["bath", "feeding"]},
        ),
        # 기저귀 + 수면
        (
            f"{filler}{baby} {random.choice(DIAPER_TYPES)} 치우고 다시 재웠어{ending}",
            {"intents": ["diaper", "sleep_start"]},
        ),
        # 체온 + 약
        (
            f"{filler}{baby} 열 {random.choice(TEMP_VALUES)}도라서 {random.choice(MED_TYPES)} {random.choice(MED_VERBS)}{ending}",
            {"intents": ["temperature", "medicine"]},
        ),
        # 이유식 + 기저귀
        (
            f"{filler}{random.choice(BABYFOOD_TYPES)} 먹이고 {random.choice(DIAPER_TYPES)} {random.choice(DIAPER_VERBS)}{ending}",
            {"intents": ["babyfood", "diaper"]},
        ),
    ]

    text, label_info = random.choice(templates)
    text = text.replace("  ", " ").strip()

    label = {
        "intent": "multi",
        "intents": label_info["intents"],
        "status": "needs_separation",
    }
    return text, label


def gen_update():
    """수정/취소 요청 문장"""
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    amount_old = random.choice(FEEDING_AMOUNTS)
    amount_new = random.choice([a for a in FEEDING_AMOUNTS if a != amount_old])

    templates = [
        # 수량 정정
        (
            f"{filler}아까 먹인 거 {amount_old}ml 아니라 {amount_new}ml야{ending}",
            {"intent": "update", "field": "amount", "old": amount_old, "new": amount_new},
        ),
        (
            f"{filler}방금 기록한 거 {amount_old}이 아니라 {amount_new}이야{ending}",
            {"intent": "update", "field": "amount", "old": amount_old, "new": amount_new},
        ),
        (
            f"{filler}아까 거 수정해줘 {amount_new}ml로{ending}",
            {"intent": "update", "field": "amount", "new": amount_new},
        ),
        # 시간 정정
        (
            f"{filler}아까 기록한 시간 잘못 됐어 {random.choice(TIME_ABSOLUTE_HOUR)}시로 바꿔줘{ending}",
            {"intent": "update", "field": "time"},
        ),
        # 삭제/취소
        (
            f"{filler}방금 기록한 거 취소해줘{ending}",
            {"intent": "delete", "target": "last"},
        ),
        (
            f"{filler}마지막 기록 삭제해줘{ending}",
            {"intent": "delete", "target": "last"},
        ),
        (
            f"{filler}아까 수유 기록 지워줘{ending}",
            {"intent": "delete", "target": "feeding"},
        ),
        (
            f"{filler}잘못 입력했어 취소{ending}",
            {"intent": "delete", "target": "last"},
        ),
        # 종류 변경
        (
            f"{filler}아까 분유라고 했는데 모유야{ending}",
            {"intent": "update", "field": "type", "old": "분유", "new": "모유"},
        ),
        (
            f"{filler}대변이 아니라 소변이었어{ending}",
            {"intent": "update", "field": "type", "old": "대변", "new": "소변"},
        ),
    ]

    text, label_info = random.choice(templates)
    text = text.replace("  ", " ").strip()

    label = {
        "intent": label_info["intent"],
        "entities": {k: v for k, v in label_info.items() if k != "intent"},
        "status": "action_required",
    }
    return text, label


def gen_query():
    """조회/질문 문장"""
    baby = random.choice(BABY_NAMES)
    filler = random.choice(FILLER)
    ending = random.choice(ENDINGS)

    templates = [
        f"{filler}{baby} 오늘 몇 번 먹었어?{ending}",
        f"{filler}오늘 수유량 얼마야?{ending}",
        f"{filler}{baby} 마지막으로 먹은 게 언제야?{ending}",
        f"{filler}어제 총 수면시간 알려줘{ending}",
        f"{filler}{baby} 오늘 기저귀 몇 번 갈았어?{ending}",
        f"{filler}지난주 수유 패턴 보여줘{ending}",
        f"{filler}{baby} 체온 기록 보여줘{ending}",
        f"{filler}오늘 뭐 먹었는지 알려줘{ending}",
        f"{filler}마지막 기록이 뭐야?{ending}",
        f"{filler}{baby} 이번 주 수면 패턴은?{ending}",
        f"{filler}오늘 총 수유량?{ending}",
        f"{filler}{baby} 언제 마지막으로 잤어?{ending}",
    ]

    text = random.choice(templates).replace("  ", " ").strip()
    label = {"intent": "query", "status": "query"}
    return text, label


def gen_noise():
    """노이즈/일상 대화 (기록 아님)"""
    templates = [
        "오늘 날씨 좋다",
        "아기가 너무 예쁘다",
        "힘들다..",
        "남편이 퇴근했어",
        "오늘 뭐 먹지",
        "장 봐야 하는데",
        "내일 소아과 예약해야 하나",
        "잠이 너무 부족해",
        "ㅋㅋㅋ",
        "ㅎㅎ",
        "감사합니다",
        "안녕하세요",
        "네",
        "아니요",
        "좋아요",
        "알겠어요",
        "ㅠㅠ",
        "엄마도 밥 먹어야지",
        "배달 시켜야겠다",
        "빨래 돌려야지",
        "아기 옷 사야 하는데",
        "우유 사와야 해",
        "기저귀 주문해야지",
        "남편한테 전화해야지",
        "이유식 레시피 찾아봐야지",
        "오늘 산책 갈까",
        "아기 사진 찍어야지",
        "할머니한테 영상통화 해야지",
        "TV 볼까",
        "음악 틀어줘",
        "조용히 해",
        "ㅋㅋ 귀여워",
        "하.. 피곤해",
        "내일 뭐하지",
        "주말에 어디 갈까",
        "이거 뭐야?",
        "그래",
        "응",
        "몰라",
        "진짜?",
        "대박",
        "헐",
        "에구",
        "아이고",
        "잠깐만",
        "기다려",
        "시간이 너무 빨라",
        "벌써 한 달이야",
        "100일 사진 찍어야 하는데",
        "돌잔치 준비해야지",
    ]

    text = random.choice(templates)
    label = {"intent": "none", "status": "noise"}
    return text, label


def gen_typo_variant():
    """오타/줄임말 포함 문장"""
    baby = random.choice(BABY_NAMES)
    ending = random.choice(ENDINGS)

    templates = [
        # 오타
        (f"{baby} 분유 머겼어{ending}", {"intent": "feeding", "note": "typo:먹였어→머겼어"}),
        (f"기저기 갈았어{ending}", {"intent": "diaper", "note": "typo:기저귀→기저기"}),
        (f"{baby} 자들었어{ending}", {"intent": "sleep_start", "note": "typo:잠들었어→자들었어"}),
        (f"수유완뇨{ending}", {"intent": "feeding", "note": "typo:완료→완뇨"}),
        (f"{baby} 이러났어{ending}", {"intent": "sleep_end", "note": "typo:일어났어→이러났어"}),
        (f"체운 재봤어{ending}", {"intent": "temperature", "note": "typo:체온→체운"}),
        (f"{baby} 모곡했어{ending}", {"intent": "bath", "note": "typo:목욕→모곡"}),
        # 줄임말
        (f"분유 100 ㄱ{ending}", {"intent": "feeding", "note": "abbr:ㄱ=먹음/기록"}),
        (f"응가 ㅇ{ending}", {"intent": "diaper", "note": "abbr:ㅇ=응/확인"}),
        (f"수유 ㅇㅋ{ending}", {"intent": "feeding", "note": "abbr:ㅇㅋ=완료"}),
        (f"잠 ㄱㄱ{ending}", {"intent": "sleep_start", "note": "abbr:ㄱㄱ=시작"}),
        (f"기귀 갈음{ending}", {"intent": "diaper", "note": "abbr:기귀=기저귀"}),
        # 이모티콘/특수문자 포함
        (f"{baby} 분유 120ml 먹었어 👶{ending}", {"intent": "feeding", "note": "emoji"}),
        (f"응가 💩{ending}", {"intent": "diaper", "note": "emoji"}),
        (f"😴 잠들었어{ending}", {"intent": "sleep_start", "note": "emoji"}),
    ]

    text, label_info = random.choice(templates)
    text = text.replace("  ", " ").strip()

    label = {
        "intent": label_info["intent"],
        "status": "needs_normalization",
        "note": label_info.get("note", ""),
    }
    return text, label


def gen_contextual_followup():
    """맥락 의존 후속 응답 (이전 질문에 대한 짧은 답변)"""
    templates = [
        # 양에 대한 답변 (이전: "얼마나 먹였어?")
        ("120", {"intent": "followup_amount", "value": 120}),
        ("100ml", {"intent": "followup_amount", "value": 100}),
        ("한 80정도?", {"intent": "followup_amount", "value": 80}),
        ("150 먹었어", {"intent": "followup_amount", "value": 150}),
        ("잘 모르겠는데 한 100?", {"intent": "followup_amount", "value": 100}),
        # 시간에 대한 답변 (이전: "몇 시에?")
        ("2시", {"intent": "followup_time", "value": "14:00"}),
        ("방금", {"intent": "followup_time", "value": "relative_now"}),
        ("10분 전쯤", {"intent": "followup_time", "value": "relative_10m"}),
        ("오후 3시", {"intent": "followup_time", "value": "15:00"}),
        # 예/아니오
        ("응", {"intent": "confirm", "value": True}),
        ("네", {"intent": "confirm", "value": True}),
        ("맞아", {"intent": "confirm", "value": True}),
        ("ㅇㅇ", {"intent": "confirm", "value": True}),
        ("아니", {"intent": "deny", "value": False}),
        ("아니야", {"intent": "deny", "value": False}),
        ("ㄴㄴ", {"intent": "deny", "value": False}),
        ("아닌데", {"intent": "deny", "value": False}),
        # 종류에 대한 답변
        ("분유", {"intent": "followup_type", "value": "formula"}),
        ("모유", {"intent": "followup_type", "value": "breast"}),
        ("대변", {"intent": "followup_type", "value": "poop"}),
        ("소변", {"intent": "followup_type", "value": "pee"}),
    ]

    text, label_info = random.choice(templates)
    label = {
        "intent": label_info["intent"],
        "entities": {"value": label_info["value"]},
        "status": "contextual",
    }
    return text, label


# ============================================================
# 3. 메인: 1만 문장 생성
# ============================================================

def generate_dataset(total=10000):
    """카테고리 비중에 맞춰 데이터셋 생성"""

    # 카테고리별 비중 설정
    distribution = {
        "feeding": (gen_feeding, 0.15),
        "feeding_incomplete": (gen_feeding_incomplete, 0.08),
        "babyfood": (gen_babyfood, 0.08),
        "diaper": (gen_diaper, 0.12),
        "sleep_start": (gen_sleep_start, 0.07),
        "sleep_end": (gen_sleep_end, 0.05),
        "sleep_duration": (gen_sleep_duration, 0.04),
        "temperature": (gen_temperature, 0.05),
        "bath": (gen_bath, 0.03),
        "medicine": (gen_medicine, 0.04),
        "hospital": (gen_hospital, 0.02),
        "multi_intent": (gen_multi_intent, 0.08),
        "update": (gen_update, 0.06),
        "query": (gen_query, 0.04),
        "noise": (gen_noise, 0.04),
        "typo": (gen_typo_variant, 0.03),
        "contextual": (gen_contextual_followup, 0.02),
    }

    dataset = []
    for category, (gen_func, ratio) in distribution.items():
        count = int(total * ratio)
        for _ in range(count):
            text, label = gen_func()
            dataset.append({
                "text": text,
                "category": category,
                "label": label,
            })

    # 나머지 랜덤으로 채우기
    remaining = total - len(dataset)
    all_funcs = [(name, func) for name, (func, _) in distribution.items()]
    for _ in range(remaining):
        name, func = random.choice(all_funcs)
        text, label = func()
        dataset.append({
            "text": text,
            "category": name,
            "label": label,
        })

    random.shuffle(dataset)
    return dataset


def save_jsonl(dataset, filepath):
    """JSONL 형식으로 저장"""
    with open(filepath, "w", encoding="utf-8") as f:
        for item in dataset:
            f.write(json.dumps(item, ensure_ascii=False) + "\n")


def save_summary(dataset, filepath):
    """카테고리별 통계 요약 저장"""
    from collections import Counter
    counter = Counter(item["category"] for item in dataset)

    with open(filepath, "w", encoding="utf-8") as f:
        f.write("=" * 60 + "\n")
        f.write("육아 기록 앱 NLP 테스트 데이터셋 요약\n")
        f.write(f"생성일: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"총 문장 수: {len(dataset):,}\n")
        f.write("=" * 60 + "\n\n")

        f.write("카테고리별 분포:\n")
        f.write("-" * 40 + "\n")
        for cat, count in sorted(counter.items(), key=lambda x: -x[1]):
            pct = count / len(dataset) * 100
            f.write(f"  {cat:<25} {count:>5}  ({pct:5.1f}%)\n")
        f.write("-" * 40 + "\n")
        f.write(f"  {'합계':<25} {len(dataset):>5}  (100.0%)\n")

        # 샘플 출력
        f.write("\n\n" + "=" * 60 + "\n")
        f.write("카테고리별 샘플 (각 3개):\n")
        f.write("=" * 60 + "\n\n")

        samples_by_cat = {}
        for item in dataset:
            cat = item["category"]
            if cat not in samples_by_cat:
                samples_by_cat[cat] = []
            if len(samples_by_cat[cat]) < 3:
                samples_by_cat[cat].append(item)

        for cat in sorted(samples_by_cat.keys()):
            f.write(f"\n[{cat}]\n")
            for sample in samples_by_cat[cat]:
                f.write(f"  입력: {sample['text']}\n")
                f.write(f"  라벨: {json.dumps(sample['label'], ensure_ascii=False)}\n\n")


if __name__ == "__main__":
    print("육아 기록 앱 NLP 테스트 데이터 생성 중...")

    dataset = generate_dataset(10000)

    output_dir = "/Users/pes/Desktop/"
    jsonl_path = output_dir + "childcare_test_10k.jsonl"
    summary_path = output_dir + "childcare_test_summary.txt"

    save_jsonl(dataset, jsonl_path)
    save_summary(dataset, summary_path)

    print(f"\n완료!")
    print(f"  데이터: {jsonl_path}")
    print(f"  요약: {summary_path}")
    print(f"  총 문장: {len(dataset):,}개")

    # 카테고리 통계 출력
    from collections import Counter
    counter = Counter(item["category"] for item in dataset)
    print(f"\n카테고리별 분포:")
    for cat, count in sorted(counter.items(), key=lambda x: -x[1]):
        print(f"  {cat:<25} {count:>5}  ({count/len(dataset)*100:5.1f}%)")
