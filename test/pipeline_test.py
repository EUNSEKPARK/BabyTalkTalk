#!/usr/bin/env python3
"""
ChatBabyTime NLP 파이프라인 v2 테스트 프로그램

재설계된 9단계 파이프라인을 시뮬레이션하여 각 단계별 결과를 확인합니다.

파이프라인 흐름:
  입력 → [1.입력정규화] → [2.문장구조분석] → [3.유형분류] → [4.의도파악]
       → [5.데이터정규화] → [6.기록생성] → [7.필드검증] → [8.최종확인] → [9.저장]

실행: python3 test/pipeline_test.py
"""

import re
import sys
import json
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, Dict, List, Tuple, Any
from datetime import datetime, timedelta


# ============================================================
# 모델 정의
# ============================================================

class GrowthStage(Enum):
    FORMULA = "분유기"      # 0~5개월
    WEANING = "이유식기"    # 5~15개월
    TODDLER = "유아식기"    # 15개월~

class RecordCategory(Enum):
    FEEDING = "수유"
    BABYFOOD = "이유식"
    SNACK = "간식"
    MEAL = "식사"
    MILK = "우유"
    SLEEP = "수면"
    DIAPER = "기저귀"
    HEALTH = "건강"
    OTHER = "기타"

class FeedingType(Enum):
    BREAST = "모유"
    FORMULA = "분유"

class DiaperType(Enum):
    PEE = "소변"
    POOP = "대변"
    BOTH = "소변+대변"

class SleepStatus(Enum):
    START = "잠듦"
    END = "깨어남"

class SentenceCompleteness(Enum):
    COMPLETE = "완전한 문장"
    PARTIAL = "부분 문장"
    FRAGMENT = "조각/파편"
    NOISE = "의미 없음"

class SentenceCount(Enum):
    SINGLE = "단문장"
    MULTI = "다문장"


# ============================================================
# 파이프라인 결과 모델
# ============================================================

@dataclass
class NodeResult:
    node_id: str
    node_name: str
    success: bool
    data: Any = None
    error: Optional[str] = None
    suggestion: Optional[str] = None
    debug_info: Dict[str, Any] = field(default_factory=dict)

@dataclass
class PipelineTrace:
    steps: List[NodeResult] = field(default_factory=list)

    def add(self, result: NodeResult):
        self.steps.append(result)

    def print_trace(self, input_text: str):
        """각 단계별 결과를 보기 좋게 출력"""
        print(f"\n{'='*70}")
        print(f"  입력: \"{input_text}\"")
        print(f"{'='*70}")
        for step in self.steps:
            icon = "✅" if step.success else "❌"
            print(f"  {icon} [{step.node_id}] {step.node_name}")
            if step.debug_info:
                for k, v in step.debug_info.items():
                    print(f"     📋 {k}: {v}")
            if step.data and not isinstance(step.data, str):
                print(f"     📦 결과: {step.data}")
            elif step.data and isinstance(step.data, str):
                print(f"     📦 결과: \"{step.data}\"")
            if not step.success:
                if step.error:
                    print(f"     ⚠️  오류: {step.error}")
                if step.suggestion:
                    print(f"     💬 재질문: {step.suggestion}")
        print(f"{'─'*70}")


@dataclass
class BabyRecord:
    category: RecordCategory
    timestamp: datetime
    raw_input: str
    feeding_type: Optional[FeedingType] = None
    amount_ml: Optional[int] = None
    duration_min: Optional[int] = None
    sleep_status: Optional[SleepStatus] = None
    diaper_type: Optional[DiaperType] = None
    temperature: Optional[float] = None
    medicine: Optional[str] = None
    memo: Optional[str] = None
    menu: Optional[str] = None

    def __repr__(self):
        parts = [f"{self.category.value}"]
        if self.feeding_type:
            parts.append(self.feeding_type.value)
        if self.amount_ml:
            parts.append(f"{self.amount_ml}ml")
        if self.duration_min:
            parts.append(f"{self.duration_min}분")
        if self.sleep_status:
            parts.append(self.sleep_status.value)
        if self.diaper_type:
            parts.append(self.diaper_type.value)
        if self.temperature:
            parts.append(f"{self.temperature}°C")
        if self.medicine:
            parts.append(f"약:{self.medicine}")
        if self.menu:
            parts.append(f"메뉴:{self.menu}")
        if self.memo:
            parts.append(f"메모:{self.memo}")
        time_str = self.timestamp.strftime("%H:%M")
        return f"[{time_str}] {' / '.join(parts)}"


# ============================================================
# 성장 단계별 키워드 정의
# ============================================================

STAGE_KEYWORDS = {
    GrowthStage.FORMULA: {
        RecordCategory.FEEDING: {
            '분유': 3.0, '모유': 3.0, '수유': 3.0, '젖병': 2.5,
            '직수': 3.0, '유축': 3.0, '젖': 2.0, '빨았': 1.5,
            '우유': 2.0, '밀리': 1.5, '씨씨': 1.5,
            '먹었': 1.0, '먹임': 1.0, '먹였': 1.0, '먹음': 1.0,
        },
        RecordCategory.SLEEP: {
            '잠들': 3.0, '잠잤': 3.0, '잠자': 3.0, '낮잠': 3.0,
            '밤잠': 3.0, '쪽잠': 3.0, '선잠': 3.0, '꿀잠': 3.0,
            '수면': 3.0, '취침': 3.0, '기상': 3.0,
            '재웠': 2.5, '재움': 2.5, '재워': 2.5,
            '깼어': 2.5, '깸': 2.5, '깼': 2.5,
            '눈떠': 2.5, '눈떴': 2.5, '눈뜨': 2.5,
            '일어났': 2.5, '일어나': 2.0,
            '잤어': 2.5, '잤다': 2.5, '잤음': 2.5,
            '잠듬': 2.5, '잠듦': 2.5, '깼음': 2.5,
            '자고': 2.0, '자요': 2.5, '잠깼': 2.5,
            '토닥': 2.0, '잠투정': 2.5,
        },
        RecordCategory.DIAPER: {
            '기저귀': 3.0, '응가': 3.0, '대변': 3.0, '소변': 3.0,
            '오줌': 2.5, '배변': 2.5, '쌌어': 2.5, '쌌음': 2.5,
            '갈았': 2.0, '갈아': 2.0, '갈아줬': 2.0,
            '똥': 2.5, '쉬했': 2.5, '교체': 2.0,
            '묽은': 2.0, '물변': 2.5,
        },
        RecordCategory.HEALTH: {
            '체온': 3.0, '온도': 2.5, '예방접종': 3.0, '병원': 2.5,
            '감기': 2.5, '기침': 2.5, '콧물': 2.5,
            '해열제': 3.0, '타이레놀': 3.0, '약': 2.0,
            '구토': 3.0, '토했': 2.5, '토함': 2.5,
            '발진': 2.5, '설사': 2.0, '열남': 2.5, '열': 2.0,
            '소아과': 3.0, '접종': 3.0,
        },
    },
    GrowthStage.WEANING: {
        RecordCategory.FEEDING: {
            '분유': 3.0, '모유': 3.0, '수유': 3.0, '젖병': 2.5,
            '직수': 3.0, '유축': 3.0,
            '먹었': 1.0, '먹임': 1.0, '먹였': 1.0, '먹음': 1.0,
        },
        RecordCategory.BABYFOOD: {
            '이유식': 3.0, '죽': 2.5, '미음': 2.5, '퓨레': 2.5,
            '반찬': 2.0, '밥': 2.0,  # 이유식기에서 '밥' = 이유식
            '소고기': 2.5, '쇠고기': 2.5, '닭고기': 2.5,
            '달걀': 2.0, '계란': 2.0, '두부': 2.0,
            '감자': 2.0, '고구마': 2.0, '브로콜리': 2.0,
            '당근': 2.0, '시금치': 2.0, '애호박': 2.0,
            '쌀': 1.5, '오트밀': 2.5,
            '먹었': 1.0, '먹임': 1.0, '먹였': 1.0, '먹음': 1.0,
        },
        RecordCategory.SNACK: {
            '간식': 3.0, '과일': 2.5, '사과': 2.0, '바나나': 2.0,
            '딸기': 2.0, '뻥튀기': 2.5, '떡뻥': 2.5, '쌀과자': 2.5,
            '요거트': 2.0,
        },
        RecordCategory.SLEEP: {
            '잠들': 3.0, '잠잤': 3.0, '잠자': 3.0, '낮잠': 3.0,
            '밤잠': 3.0, '수면': 3.0, '취침': 3.0, '기상': 3.0,
            '재웠': 2.5, '재움': 2.5, '재워': 2.5,
            '깼어': 2.5, '깸': 2.5, '깼': 2.5,
            '눈떠': 2.5, '눈떴': 2.5,
            '일어났': 2.5, '잤어': 2.5, '잤다': 2.5,
            '잠듬': 2.5, '잠듦': 2.5, '깼음': 2.5,
            '자고': 2.0, '자요': 2.5, '잠깼': 2.5,
            '토닥': 2.0, '잠투정': 2.5,
        },
        RecordCategory.DIAPER: {
            '기저귀': 3.0, '응가': 3.0, '대변': 3.0, '소변': 3.0,
            '오줌': 2.5, '쌌어': 2.5, '쌌음': 2.5,
            '갈았': 2.0, '갈아': 2.0, '갈아줬': 2.0,
            '똥': 2.5, '쉬했': 2.5, '교체': 2.0,
        },
        RecordCategory.HEALTH: {
            '체온': 3.0, '예방접종': 3.0, '병원': 2.5,
            '감기': 2.5, '기침': 2.5, '콧물': 2.5,
            '해열제': 3.0, '약': 2.0, '알레르기': 2.5,
            '구토': 3.0, '토했': 2.5, '발진': 2.5,
            '설사': 2.0, '열남': 2.5, '열': 2.0,
            '소아과': 3.0, '접종': 3.0,
        },
    },
    GrowthStage.TODDLER: {
        RecordCategory.MEAL: {
            '밥': 3.0, '메뉴': 2.5, '반찬': 2.5, '국': 2.0,
            '찌개': 2.0, '카레': 2.5, '국수': 2.5, '볶음밥': 2.5,
            '비빔밥': 2.5, '라면': 2.0,
            '먹었': 1.5, '먹임': 1.5, '먹였': 1.5, '먹음': 1.5,
        },
        RecordCategory.SNACK: {
            '간식': 3.0, '과일': 2.5, '과자': 2.0, '빵': 2.0,
            '사과': 2.0, '바나나': 2.0, '딸기': 2.0, '포도': 2.0,
            '요거트': 2.0, '젤리': 2.0, '쿠키': 2.0,
        },
        RecordCategory.MILK: {
            '우유': 3.0, '생우유': 3.0, '우유병': 2.5,
        },
        RecordCategory.FEEDING: {
            '분유': 1.5,  # 유아식기에서는 낮은 가중치
            '모유': 1.5,
            '수유': 1.5,
        },
        RecordCategory.SLEEP: {
            '잠들': 3.0, '잠잤': 3.0, '낮잠': 3.0, '밤잠': 3.0,
            '수면': 3.0, '취침': 3.0, '기상': 3.0,
            '재웠': 2.5, '깼어': 2.5, '깸': 2.5, '깼': 2.5,
            '일어났': 2.5, '잤어': 2.5, '잤다': 2.5,
            '잠듬': 2.5, '잠듦': 2.5, '깼음': 2.5,
            '자고': 2.0, '자요': 2.5,
        },
        RecordCategory.DIAPER: {
            '기저귀': 3.0, '응가': 3.0, '대변': 3.0, '소변': 3.0,
            '오줌': 2.5, '쌌어': 2.5, '쌌음': 2.5,
            '갈았': 2.0, '갈아': 2.0, '갈아줬': 2.0,
            '똥': 2.5, '변기': 2.5, '배변훈련': 3.0,
        },
        RecordCategory.HEALTH: {
            '체온': 3.0, '예방접종': 3.0, '병원': 2.5,
            '감기': 2.5, '기침': 2.5, '콧물': 2.5,
            '해열제': 3.0, '약': 2.0,
            '구토': 3.0, '토했': 2.5, '발진': 2.5,
            '열남': 2.5, '열': 2.0, '소아과': 3.0,
        },
    },
}

# 패턴 (성장 단계 공통)
COMMON_PATTERNS = {
    RecordCategory.FEEDING: [
        (re.compile(r'\d+\s*(ml|cc)'), 3.0),
        (re.compile(r'젖\s*(먹|물)'), 2.5),
        (re.compile(r'(반병|한병)'), 2.5),
        (re.compile(r'직접\s*수유'), 3.0),
        (re.compile(r'(?:분유|모유|수유)\s*\d{2,3}'), 2.5),
    ],
    RecordCategory.SLEEP: [
        (re.compile(r'깨\s*(어|었|서|고|남|요)'), 2.5),
        (re.compile(r'잠\s*(들|잤|잘|이)'), 3.0),
        (re.compile(r'(밤|낮|쪽|선|꿀)\s*잠'), 3.0),
        (re.compile(r'자다\s*(깨|가)'), 2.5),
        (re.compile(r'자기\s*시작'), 3.0),
    ],
    RecordCategory.DIAPER: [
        (re.compile(r'똥\s*(쌌|싸|나|봤|이)'), 3.0),
        (re.compile(r'쉬\s*(했|마려)'), 2.5),
        (re.compile(r'응가\s*(했|봤|함|나|를)'), 2.0),
        (re.compile(r'기저귀\s*(갈|교|바)'), 2.0),
        (re.compile(r'쌌\s*(어|다|요)'), 2.5),
        (re.compile(r'(묽은|노란|녹색|물)\s*변'), 3.0),
    ],
    RecordCategory.HEALTH: [
        (re.compile(r'\d{2}\.?\d?\s*(도|°)'), 3.0),
        (re.compile(r'열\s*(이|나|있|높|났)'), 3.0),
        (re.compile(r'약\s*(먹|줬|투|복)'), 3.0),
        (re.compile(r'토\s*(했|함|하)'), 2.5),
    ],
}

# 오타 사전
TYPO_MAP = {
    '기저기': '기저귀',
    '먹엇어': '먹었어',
    '먹엇음': '먹었음',
    '잠들엇어': '잠들었어',
    '깨엇어': '깼어',
    '일어낫어': '일어났어',
    '잣어': '잤어',
    '잣다': '잤다',
    '머겼': '먹였',
    '완뇨': '완료',
    '기차갈': '기저귀 갈',
}

# 본인/타인 참조 패턴
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
    re.compile(r'커피'),
]

# 의도/계획 패턴 (실제 기록이 아닌)
INTENT_PLAN_PATTERNS = [
    re.compile(r'(해야|할\s*거|할래|할게|해볼|하려고|해야겠)'),
    re.compile(r'(먹어야|먹을|먹자|먹을래)(?!.*먹었|.*먹임|.*먹음)'),
    re.compile(r'(갈아야|갈아줘야)'),
    re.compile(r'언제\s*(먹|자|할)'),
]

# 다문장 분리 패턴
MULTI_SENTENCE_PATTERNS = [
    re.compile(r'(?:하고|그리고|그다음|그다음에|다음에|후에|뒤에)'),
    re.compile(r'\d+시.*\d+시'),  # 시간 2개 이상
    re.compile(r'(?:먹고|자고|갈고|하고|먹었고|잤고|갈았고)\s'),
]


# ============================================================
# 노드 1: 입력 정규화
# ============================================================

def node_input_normalization(raw_input: str) -> NodeResult:
    """입력 텍스트를 정규화"""
    original = raw_input.strip()
    if not original:
        return NodeResult(
            node_id="N1", node_name="입력 정규화",
            success=False, error="빈 입력", suggestion="기록할 내용을 입력해주세요."
        )

    text = original.lower()
    corrections = []

    # 이모티콘/특수문자 제거
    cleaned = re.sub(r'[ㅋㅎㅠㅜㅡ]+', ' ', text)
    if cleaned != text:
        corrections.append("이모티콘 제거")
    text = cleaned

    # 반복 부호 제거
    text = re.sub(r'[!?~.]{2,}', ' ', text)

    # 한글 사이 과도한 띄어쓰기 복원
    if re.search(r'[\uac00-\ud7af]\s[\uac00-\ud7af]\s[\uac00-\ud7af]', text):
        text = re.sub(r'(?<=[\uac00-\ud7af])\s(?=[\uac00-\ud7af])', '', text)
        corrections.append("띄어쓰기 복원")

    # 오타 보정
    for typo, fix in TYPO_MAP.items():
        if typo in text:
            text = text.replace(typo, fix)
            corrections.append(f"오타보정: {typo}→{fix}")

    # 숫자 한글 변환
    num_map = {
        '백이십': '120', '백사십': '140', '백육십': '160',
        '이백': '200', '팔십': '80', '육십': '60', '백': '100',
        '삼십칠도오': '37.5도', '삼십팔도': '38도',
        '삼십육도오': '36.5도',
    }
    for kr, num in num_map.items():
        if kr in text:
            text = text.replace(kr, num)
            corrections.append(f"숫자변환: {kr}→{num}")

    # 연속 공백 정리
    text = re.sub(r'\s{2,}', ' ', text).strip()

    return NodeResult(
        node_id="N1", node_name="입력 정규화",
        success=True,
        data=text,
        debug_info={
            "원본": original,
            "정규화": text,
            "보정사항": corrections if corrections else "없음",
        }
    )


# ============================================================
# 노드 2: 문장 구조 분석
# ============================================================

def node_sentence_analysis(normalized: str) -> NodeResult:
    """문장 구조를 분석 (단/다문장, 완성도)"""

    # 의미 없는 입력 판별 (육아 키워드가 아닌 짧은 입력)
    baby_keywords = re.compile(r'(분유|모유|수유|젖|이유식|죽|밥|간식|과일|우유|잠|기저귀|응가|체온|약|열|기침|소변|대변|똥|쉬|ml|cc|도)')
    noise_pattern = re.compile(r'^[ㅋㅎㅠㅜㅡ가-힣]{0,2}$|^(네|응|아|어|음|ㅋ|ㅎ|ㅠ|ok|ㅇㅇ)$')
    if noise_pattern.match(normalized) and not baby_keywords.search(normalized):
        return NodeResult(
            node_id="N2", node_name="문장 구조 분석",
            success=True,
            data={
                "count": SentenceCount.SINGLE,
                "completeness": SentenceCompleteness.NOISE,
                "segments": [normalized],
                "missing_fields": [],
            },
            debug_info={"판정": "의미 없는 입력 (NOISE)"}
        )

    # 다문장 판별
    is_multi = False
    segments = [normalized]
    for pat in MULTI_SENTENCE_PATTERNS:
        if pat.search(normalized):
            is_multi = True
            # 접속사로 분리 (먹고, 하고, 그리고 등)
            parts = re.split(r'(?:하고|그리고|그다음에?|후에|뒤에)\s*', normalized)
            # "먹고 잠들었어", "먹었고 잠들었어" 같은 패턴도 분리
            if len(parts) <= 1:
                parts = re.split(r'(?:먹고|자고|갈고|먹었고|잤고|갈았고)\s+', normalized)
            parts = [p.strip() for p in parts if p.strip()]
            if len(parts) > 1:
                segments = parts
            # 시간 마커로 분리
            time_parts = re.split(r'(\d+시\s*(?:\d+분)?(?:에|쯤|부터)?)', normalized)
            if len(time_parts) > 2:
                combined = []
                for i in range(0, len(time_parts)-1, 2):
                    seg = (time_parts[i] + time_parts[i+1]).strip()
                    if seg:
                        combined.append(seg)
                if len(time_parts) % 2 == 1 and time_parts[-1].strip():
                    if combined:
                        combined[-1] += ' ' + time_parts[-1].strip()
                    else:
                        combined.append(time_parts[-1].strip())
                if len(combined) > 1:
                    segments = combined
            break

    count = SentenceCount.MULTI if is_multi and len(segments) > 1 else SentenceCount.SINGLE

    # 완성도 판별 (첫 번째 세그먼트 기준)
    text = segments[0] if segments else normalized

    has_verb = bool(re.search(r'(먹었|먹임|먹였|먹음|먹고|잠들|잤어|잤다|깼어|깸|갈았|쌌어|응가했|재웠|재움|깼|일어났|먹여|줬|했어|했음|봤어|잠듦|잠듬)', text))
    has_object = bool(re.search(r'(분유|모유|이유식|죽|밥|간식|과일|우유|기저귀|응가|잠|약|체온|소변|대변|똥|젖|수유|열|카레|국수)', text))
    has_quantity = bool(re.search(r'\d+\s*(ml|cc|도|°|g|분|시)', text))
    has_number_only = bool(re.search(r'^\d+$', text))

    missing = []
    if has_verb and has_object and has_quantity:
        completeness = SentenceCompleteness.COMPLETE
    elif has_verb and has_object:
        completeness = SentenceCompleteness.PARTIAL
        if not has_quantity:
            missing.append("수량/시간")
    elif has_object and not has_verb:
        completeness = SentenceCompleteness.FRAGMENT
        missing.append("서술어")
        if not has_quantity:
            missing.append("수량")
    elif has_number_only:
        completeness = SentenceCompleteness.FRAGMENT
        missing.append("대상")
        missing.append("서술어")
    elif has_verb and not has_object:
        completeness = SentenceCompleteness.PARTIAL
        missing.append("대상")
    elif has_object and not has_verb:
        completeness = SentenceCompleteness.FRAGMENT
        missing.append("서술어")
    else:
        # 어떤 육아 키워드라도 있는지
        if re.search(r'(분유|모유|이유식|잠|기저귀|응가|체온|약|열|ml|cc|도)', text):
            completeness = SentenceCompleteness.FRAGMENT
            missing.append("서술어")
        else:
            completeness = SentenceCompleteness.NOISE

    # 주어 감지
    detected_subject = None
    if re.search(r'^나\s|나는|내가|엄마가|아빠가', text):
        detected_subject = "본인/타인"
    elif re.search(r'아기|아가|우리\s*(아기|아가)|애기', text):
        detected_subject = "아기"

    return NodeResult(
        node_id="N2", node_name="문장 구조 분석",
        success=True,
        data={
            "count": count,
            "completeness": completeness,
            "segments": segments,
            "missing_fields": missing,
            "detected_subject": detected_subject,
        },
        debug_info={
            "문장수": f"{count.value} ({len(segments)}개)",
            "완성도": completeness.value,
            "누락정보": missing if missing else "없음",
            "주어": detected_subject or "생략(기본=아기)",
            "세그먼트": segments if len(segments) > 1 else segments[0],
        }
    )


# ============================================================
# 노드 3: 유형 분류
# ============================================================

def node_type_classification(text: str, stage: GrowthStage, sentence_data: dict) -> NodeResult:
    """입력을 카테고리로 분류"""

    # NOISE면 기타 처리
    if sentence_data.get("completeness") == SentenceCompleteness.NOISE:
        return NodeResult(
            node_id="N3", node_name="유형 분류",
            success=True,
            data={
                "primary": RecordCategory.OTHER,
                "scores": {},
                "confidence": 0.1,
                "needs_disambiguation": False,
            },
            debug_info={"판정": "의미 없는 입력 → 기타"}
        )

    # 본인/타인 참조 체크
    is_self_ref = any(p.search(text) for p in SELF_REFERENCE_PATTERNS)

    # 카테고리 스코어링
    keywords = STAGE_KEYWORDS.get(stage, {})
    scores = {}

    for category, kw_map in keywords.items():
        score = 0.0
        for kw, weight in kw_map.items():
            if kw in text:
                score += weight
        # 패턴 매칭
        for cat_patterns_key, patterns_list in COMMON_PATTERNS.items():
            if cat_patterns_key == category:
                for pat, weight in patterns_list:
                    if pat.search(text):
                        score += weight
        if is_self_ref and score > 0:
            score *= 0.3
        scores[category] = score

    # 최고 점수 선택
    sorted_scores = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    best_cat = sorted_scores[0][0] if sorted_scores and sorted_scores[0][1] >= 2.0 else None
    best_score = sorted_scores[0][1] if sorted_scores else 0.0
    second_score = sorted_scores[1][1] if len(sorted_scores) > 1 else 0.0

    # confidence 계산
    if best_score > 0:
        confidence = max(0.3, min(0.95, best_score / 8.0))
        gap = best_score - second_score
        if gap >= 3.0:
            confidence = min(0.95, confidence + 0.1)
        elif gap < 1.0 and second_score > 0:
            confidence = max(0.3, confidence - 0.15)
    else:
        confidence = 0.1

    # 객관식 필요 여부
    needs_disambiguation = False
    ambiguity_reason = None
    if best_cat is None:
        needs_disambiguation = True
        ambiguity_reason = "어떤 카테고리에도 매칭되지 않음"
    elif second_score >= 1.85 and (best_score - second_score) < 1.25:
        needs_disambiguation = True
        second_cat = sorted_scores[1][0]
        ambiguity_reason = f"{best_cat.value}과 {second_cat.value} 사이 구분 어려움"

    if best_cat is None:
        best_cat = RecordCategory.OTHER

    # 의도/계획 표현 필터
    is_plan = any(p.search(text) for p in INTENT_PLAN_PATTERNS)
    if is_plan and not re.search(r'(먹었|먹음|먹임|먹였|잤어|잤다|잠들|깼|갈았|쌌어|했어|했음)', text):
        return NodeResult(
            node_id="N3", node_name="유형 분류",
            success=True,
            data={
                "primary": RecordCategory.OTHER,
                "scores": {k.value: round(v, 1) for k, v in scores.items() if v > 0},
                "confidence": 0.3,
                "needs_disambiguation": False,
                "is_plan": True,
            },
            debug_info={
                "판정": "의도/계획 표현 (기록 아님)",
                "스코어": {k.value: round(v, 1) for k, v in sorted_scores[:3] if v > 0},
            }
        )

    return NodeResult(
        node_id="N3", node_name="유형 분류",
        success=not needs_disambiguation or best_cat != RecordCategory.OTHER,
        data={
            "primary": best_cat,
            "secondary": sorted_scores[1][0] if len(sorted_scores) > 1 and sorted_scores[1][1] > 0 else None,
            "scores": {k.value: round(v, 1) for k, v in scores.items() if v > 0},
            "confidence": round(confidence, 2),
            "needs_disambiguation": needs_disambiguation,
            "ambiguity_reason": ambiguity_reason,
        },
        error=ambiguity_reason if needs_disambiguation and best_cat == RecordCategory.OTHER else None,
        suggestion="어떤 기록인가요?" if needs_disambiguation and best_cat == RecordCategory.OTHER else None,
        debug_info={
            "1순위": f"{best_cat.value} ({best_score:.1f}점)",
            "2순위": f"{sorted_scores[1][0].value} ({second_score:.1f}점)" if len(sorted_scores) > 1 and second_score > 0 else "없음",
            "신뢰도": f"{confidence:.0%}",
            "본인참조": "예" if is_self_ref else "아니오",
            "객관식필요": "예" if needs_disambiguation else "아니오",
        }
    )


# ============================================================
# 노드 4: 의도 파악
# ============================================================

def node_intent_detection(text: str, stage: GrowthStage, classification: dict) -> NodeResult:
    """분류된 유형 내에서 구체적 의도 파악"""

    primary = classification["primary"]
    extracted = {}
    missing_required = []
    missing_optional = []

    if primary in (RecordCategory.FEEDING, RecordCategory.BABYFOOD, RecordCategory.MEAL, RecordCategory.SNACK, RecordCategory.MILK):
        # 수유/음식 관련 의도
        if '모유' in text or '젖' in text or '직수' in text:
            extracted['feeding_type'] = FeedingType.BREAST
            extracted['intent'] = 'breast_feeding'
        elif '분유' in text or '젖병' in text:
            extracted['feeding_type'] = FeedingType.FORMULA
            extracted['intent'] = 'formula_feeding'
        elif primary == RecordCategory.BABYFOOD:
            extracted['intent'] = 'babyfood'
        elif primary == RecordCategory.MEAL:
            extracted['intent'] = 'meal'
        elif primary == RecordCategory.SNACK:
            extracted['intent'] = 'snack'
        elif primary == RecordCategory.MILK:
            extracted['intent'] = 'milk'
        else:
            extracted['intent'] = 'feeding_unknown'
            if stage == GrowthStage.FORMULA:
                missing_required.append("수유타입(모유/분유)")

        # 양 추출
        ml_match = re.search(r'(\d+)\s*(ml|cc|밀리)', text)
        if ml_match:
            extracted['amount_ml'] = int(ml_match.group(1))
        else:
            num_match = re.search(r'(?:분유|모유|수유|이유식|죽|밥)\s*(\d{2,3})(?!\s*[가-힣])', text)
            if num_match:
                extracted['amount_ml'] = int(num_match.group(1))
            else:
                missing_optional.append("양(ml)")

        # 시간 추출
        dur_match = re.search(r'(\d+)\s*분', text)
        if dur_match and ('수유' in text or '모유' in text or '젖' in text):
            extracted['duration_min'] = int(dur_match.group(1))

        # 메뉴 추출 (유아식기)
        menu_keywords = ['카레', '국수', '볶음밥', '비빔밥', '라면', '죽', '미음', '퓨레']
        for menu in menu_keywords:
            if menu in text:
                extracted['menu'] = menu
                break

        # 재료 추출 (이유식기)
        ingredients = ['소고기', '닭고기', '달걀', '계란', '두부', '감자', '고구마',
                       '브로콜리', '당근', '시금치', '애호박', '오트밀']
        found_ingredients = [i for i in ingredients if i in text]
        if found_ingredients:
            extracted['ingredients'] = found_ingredients

    elif primary == RecordCategory.SLEEP:
        # 수면 의도
        if re.search(r'(잠들|재웠|재움|취침|잠자|밤잠|낮잠|잠\s*들|자기\s*시작|잠듬|잠듦)', text):
            extracted['sleep_status'] = SleepStatus.START
            extracted['intent'] = 'sleep_start'
        elif re.search(r'(깼|깸|눈떠|눈떴|일어났|일어나|기상|깼음|잠깼)', text):
            extracted['sleep_status'] = SleepStatus.END
            extracted['intent'] = 'sleep_end'
        else:
            extracted['intent'] = 'sleep_unknown'
            missing_required.append("잠듦/깨어남")

    elif primary == RecordCategory.DIAPER:
        # 기저귀 의도
        if re.search(r'(응가|대변|똥|물변)', text):
            extracted['diaper_type'] = DiaperType.POOP
            extracted['intent'] = 'diaper_poop'
        elif re.search(r'(소변|오줌|쉬했|쉬\s*했)', text):
            extracted['diaper_type'] = DiaperType.PEE
            extracted['intent'] = 'diaper_pee'
        elif re.search(r'(둘\s*다|소변.*대변|대변.*소변)', text):
            extracted['diaper_type'] = DiaperType.BOTH
            extracted['intent'] = 'diaper_both'
        else:
            extracted['intent'] = 'diaper_unknown'
            missing_optional.append("소변/대변")  # 기저귀만 입력해도 기록 가능

    elif primary == RecordCategory.HEALTH:
        # 건강 의도
        temp_match = re.search(r'(\d{2}\.?\d?)\s*(도|°)', text)
        if temp_match:
            extracted['temperature'] = float(temp_match.group(1).replace('.', '', 1) if '.' not in temp_match.group(1) else temp_match.group(1))
            if extracted['temperature'] < 50:
                extracted['intent'] = 'temperature'
        if re.search(r'(약|해열제|타이레놀|투약)', text):
            extracted['intent'] = 'medicine'
            extracted['medicine'] = '해열제' if '해열제' in text or '타이레놀' in text else '약'
        if re.search(r'(예방접종|접종|주사)', text):
            extracted['intent'] = 'vaccination'
        if re.search(r'(토했|구토|토함)', text):
            extracted['intent'] = 'vomit'
        if not extracted.get('intent'):
            extracted['intent'] = 'health_general'

    else:
        extracted['intent'] = 'other'

    return NodeResult(
        node_id="N4", node_name="의도 파악",
        success=len(missing_required) == 0,
        data={
            "intent": extracted.get('intent', 'unknown'),
            "extracted": extracted,
            "missing_required": missing_required,
            "missing_optional": missing_optional,
        },
        error=f"필수 정보 누락: {', '.join(missing_required)}" if missing_required else None,
        suggestion=_generate_intent_question(missing_required, primary) if missing_required else None,
        debug_info={
            "의도": extracted.get('intent', 'unknown'),
            "추출필드": {k: str(v) for k, v in extracted.items() if k != 'intent'},
            "필수누락": missing_required if missing_required else "없음",
            "선택누락": missing_optional if missing_optional else "없음",
        }
    )


def _generate_intent_question(missing: list, category: RecordCategory) -> str:
    if "수유타입(모유/분유)" in missing:
        return "모유인가요, 분유인가요?"
    if "잠듦/깨어남" in missing:
        return "잠들었나요, 깼나요?"
    if "소변/대변" in missing:
        return "소변인가요, 대변인가요?"
    return f"{category.value} 기록에 필요한 정보가 부족합니다."


# ============================================================
# 노드 5: 데이터 정규화 (시간 파싱 포함)
# ============================================================

def node_record_normalization(text: str, intent_data: dict) -> NodeResult:
    """추출된 정보를 BabyRecord 형태로 정규화"""

    now = datetime.now()
    timestamp = now

    # 시간 파싱
    time_match = re.search(r'(오전|오후|새벽|밤|아침|저녁)?\s*(\d{1,2})\s*시\s*(\d{1,2})?분?', text)
    if time_match:
        period = time_match.group(1) or ''
        hour = int(time_match.group(2))
        minute = int(time_match.group(3)) if time_match.group(3) else 0
        if period in ('오후', '밤', '저녁') and hour < 12:
            hour += 12
        elif period == '새벽' and hour == 12:
            hour = 0
        timestamp = now.replace(hour=hour, minute=minute, second=0, microsecond=0)

    relative_match = re.search(r'(\d+)\s*(분|시간)\s*전', text)
    if relative_match:
        amount = int(relative_match.group(1))
        unit = relative_match.group(2)
        if unit == '분':
            timestamp = now - timedelta(minutes=amount)
        elif unit == '시간':
            timestamp = now - timedelta(hours=amount)

    if '방금' in text:
        timestamp = now - timedelta(minutes=2)
    elif '아까' in text:
        timestamp = now - timedelta(minutes=15)

    extracted = intent_data.get('extracted', {})

    return NodeResult(
        node_id="N5", node_name="데이터 정규화",
        success=True,
        data={
            "timestamp": timestamp,
            "extracted": extracted,
        },
        debug_info={
            "시간": timestamp.strftime("%H:%M"),
            "파싱된 필드": {k: str(v) for k, v in extracted.items()},
        }
    )


# ============================================================
# 노드 6: 기록 생성
# ============================================================

def node_record_generation(text: str, classification: dict, normalized_data: dict) -> NodeResult:
    """BabyRecord 객체 생성"""

    primary = classification["primary"]
    extracted = normalized_data["extracted"]
    timestamp = normalized_data["timestamp"]

    record = BabyRecord(
        category=primary,
        timestamp=timestamp,
        raw_input=text,
        feeding_type=extracted.get('feeding_type'),
        amount_ml=extracted.get('amount_ml'),
        duration_min=extracted.get('duration_min'),
        sleep_status=extracted.get('sleep_status'),
        diaper_type=extracted.get('diaper_type'),
        temperature=extracted.get('temperature'),
        medicine=extracted.get('medicine'),
        menu=extracted.get('menu'),
        memo=extracted.get('memo'),
    )

    return NodeResult(
        node_id="N6", node_name="기록 생성",
        success=True,
        data=record,
        debug_info={"기록": str(record)}
    )


# ============================================================
# 노드 7: 필드 검증
# ============================================================

def node_field_validation(record: BabyRecord) -> NodeResult:
    """생성된 기록의 필드 유효성 검증"""

    errors = []
    warnings = []

    if record.category in (RecordCategory.FEEDING, RecordCategory.BABYFOOD, RecordCategory.MEAL):
        if record.amount_ml is not None:
            if record.amount_ml < 10:
                errors.append("양이 너무 적습니다 (10ml 미만)")
            elif record.amount_ml > 500:
                errors.append("양이 너무 많습니다 (500ml 초과)")
        else:
            warnings.append("양(ml) 미입력")

    if record.category == RecordCategory.SLEEP:
        if record.sleep_status is None:
            warnings.append("잠듦/깨어남 미구분 (잠듦으로 기록)")
            record.sleep_status = SleepStatus.START

    if record.category == RecordCategory.DIAPER:
        if record.diaper_type is None:
            warnings.append("소변/대변 미구분")

    if record.category == RecordCategory.HEALTH:
        if record.temperature is not None:
            if record.temperature < 34.0 or record.temperature > 42.0:
                errors.append(f"체온 범위 이상: {record.temperature}°C")

    success = len(errors) == 0

    return NodeResult(
        node_id="N7", node_name="필드 검증",
        success=success,
        data={"record": record, "warnings": warnings},
        error="; ".join(errors) if errors else None,
        suggestion=_generate_validation_question(errors) if errors else None,
        debug_info={
            "오류": errors if errors else "없음",
            "경고": warnings if warnings else "없음",
        }
    )


def _generate_validation_question(errors: list) -> str:
    if any("양이 너무" in e for e in errors):
        return "양을 다시 확인해주세요. 몇 ml 먹었나요?"
    if any("체온 범위" in e for e in errors):
        return "체온을 다시 확인해주세요."
    return "입력 내용을 다시 확인해주세요."


# ============================================================
# 노드 8: 최종 확인
# ============================================================

def node_final_confirmation(record: BabyRecord, confidence: float) -> NodeResult:
    """최종 확인 (신뢰도 기반 자동저장/확인카드)"""

    if confidence > 0.7:
        action = "자동 저장"
    elif confidence > 0.4:
        action = "확인 카드 표시"
    else:
        action = "재확인 필요"

    return NodeResult(
        node_id="N8", node_name="최종 확인",
        success=True,
        data={"record": record, "action": action, "confidence": confidence},
        debug_info={
            "처리방식": action,
            "신뢰도": f"{confidence:.0%}",
            "최종기록": str(record),
        }
    )


# ============================================================
# 전체 파이프라인 실행
# ============================================================

def run_pipeline(raw_input: str, stage: GrowthStage = GrowthStage.FORMULA) -> Tuple[PipelineTrace, Optional[BabyRecord]]:
    """전체 파이프라인 실행"""
    trace = PipelineTrace()

    # 노드 1: 입력 정규화
    n1 = node_input_normalization(raw_input)
    trace.add(n1)
    if not n1.success:
        return trace, None
    normalized = n1.data

    # 노드 2: 문장 구조 분석
    n2 = node_sentence_analysis(normalized)
    trace.add(n2)
    sentence_data = n2.data

    # 다문장이면 첫 번째 세그먼트만 처리 (테스트 단순화)
    segments = sentence_data.get("segments", [normalized])
    text_to_process = segments[0]

    # 노드 3: 유형 분류
    n3 = node_type_classification(text_to_process, stage, sentence_data)
    trace.add(n3)
    if not n3.success:
        return trace, None
    classification = n3.data

    # 노드 4: 의도 파악
    n4 = node_intent_detection(text_to_process, stage, classification)
    trace.add(n4)
    # 의도 파악 실패해도 계속 진행 (경고만)

    # 노드 5: 데이터 정규화
    n5 = node_record_normalization(text_to_process, n4.data)
    trace.add(n5)

    # 노드 6: 기록 생성
    n6 = node_record_generation(text_to_process, classification, n5.data)
    trace.add(n6)
    record = n6.data

    # 노드 7: 필드 검증
    n7 = node_field_validation(record)
    trace.add(n7)
    if not n7.success:
        return trace, None
    record = n7.data["record"]

    # 노드 8: 최종 확인
    confidence = classification.get("confidence", 0.5)
    n8 = node_final_confirmation(record, confidence)
    trace.add(n8)

    return trace, record


# ============================================================
# 테스트 케이스 정의
# ============================================================

# 각 케이스: (입력, 성장단계, 기대카테고리, 설명)

# ─── 분유기 테스트 ───
FORMULA_STAGE_TESTS = [
    # 완전한 문장
    ("분유 120ml 먹었어", GrowthStage.FORMULA, RecordCategory.FEEDING, "분유+양+서술어 (완전)"),
    ("모유 수유 15분 했어", GrowthStage.FORMULA, RecordCategory.FEEDING, "모유+시간+서술어 (완전)"),
    ("오후 2시에 분유 120ml 먹음", GrowthStage.FORMULA, RecordCategory.FEEDING, "시간+분유+양 (완전)"),

    # 부분 문장
    ("분유 먹었어", GrowthStage.FORMULA, RecordCategory.FEEDING, "양 누락 (부분)"),
    ("모유 수유했어", GrowthStage.FORMULA, RecordCategory.FEEDING, "시간 누락 (부분)"),

    # 조각/파편
    ("분유", GrowthStage.FORMULA, RecordCategory.FEEDING, "키워드만 (조각)"),
    ("120ml", GrowthStage.FORMULA, RecordCategory.FEEDING, "양만 (조각)"),

    # 수면
    ("잠들었어", GrowthStage.FORMULA, RecordCategory.SLEEP, "잠듦 (완전)"),
    ("깼어", GrowthStage.FORMULA, RecordCategory.SLEEP, "깨어남 (완전)"),
    ("낮잠 잤어", GrowthStage.FORMULA, RecordCategory.SLEEP, "낮잠 (완전)"),
    ("3시에 재웠어", GrowthStage.FORMULA, RecordCategory.SLEEP, "시간+재움 (완전)"),

    # 기저귀
    ("기저귀 갈았어 응가", GrowthStage.FORMULA, RecordCategory.DIAPER, "기저귀+대변 (완전)"),
    ("소변 봤어", GrowthStage.FORMULA, RecordCategory.DIAPER, "소변 (완전)"),
    ("응가 했어", GrowthStage.FORMULA, RecordCategory.DIAPER, "응가 (완전)"),

    # 건강
    ("체온 37.5도", GrowthStage.FORMULA, RecordCategory.HEALTH, "체온 (완전)"),
    ("약 먹였어", GrowthStage.FORMULA, RecordCategory.HEALTH, "약 (부분)"),

    # 감정 포함
    ("드디어 잠들었다 ㅠㅠ", GrowthStage.FORMULA, RecordCategory.SLEEP, "감정 포함"),
    ("또 깼어 ㅜㅜ", GrowthStage.FORMULA, RecordCategory.SLEEP, "짜증 포함"),
    ("겨우 분유 100ml 먹었어...", GrowthStage.FORMULA, RecordCategory.FEEDING, "한숨 포함"),

    # 오탐 방지
    ("나 밥 먹어야겠다", GrowthStage.FORMULA, RecordCategory.OTHER, "엄마 본인 식사"),
    ("커피 마셨어", GrowthStage.FORMULA, RecordCategory.OTHER, "엄마 음료"),
    ("날씨 좋다", GrowthStage.FORMULA, RecordCategory.OTHER, "무관한 내용"),
    ("ㅋ", GrowthStage.FORMULA, RecordCategory.OTHER, "의미없는 입력"),

    # 오타/STT 오류
    ("분유 백이십 먹었어", GrowthStage.FORMULA, RecordCategory.FEEDING, "STT: 숫자 한글"),
    ("기저기 갈았어", GrowthStage.FORMULA, RecordCategory.DIAPER, "오타: 기저기"),
    ("분 유 먹 었 어", GrowthStage.FORMULA, RecordCategory.FEEDING, "이상한 띄어쓰기"),

    # 다문장
    ("분유 120ml 먹고 잠들었어", GrowthStage.FORMULA, RecordCategory.FEEDING, "다문장: 수유+수면"),
]

# ─── 이유식기 테스트 ───
WEANING_STAGE_TESTS = [
    ("이유식 먹였어", GrowthStage.WEANING, RecordCategory.BABYFOOD, "이유식 기본"),
    ("소고기 죽 먹였어", GrowthStage.WEANING, RecordCategory.BABYFOOD, "재료+이유식"),
    ("감자 브로콜리 죽 먹임", GrowthStage.WEANING, RecordCategory.BABYFOOD, "복합 재료"),
    ("분유 100ml 먹었어", GrowthStage.WEANING, RecordCategory.FEEDING, "이유식기 분유"),
    ("밥 먹였어", GrowthStage.WEANING, RecordCategory.BABYFOOD, "밥=이유식 (이유식기)"),
    ("뻥튀기 줬어", GrowthStage.WEANING, RecordCategory.SNACK, "간식"),
    ("딸기 먹였어", GrowthStage.WEANING, RecordCategory.SNACK, "과일 간식"),
    ("잠들었어", GrowthStage.WEANING, RecordCategory.SLEEP, "수면"),
    ("응가 했어", GrowthStage.WEANING, RecordCategory.DIAPER, "기저귀"),
    ("알레르기 반응 있어", GrowthStage.WEANING, RecordCategory.HEALTH, "알레르기"),
]

# ─── 유아식기 테스트 ───
TODDLER_STAGE_TESTS = [
    ("밥 먹었어", GrowthStage.TODDLER, RecordCategory.MEAL, "밥=식사 (유아식기)"),
    ("카레 먹었어", GrowthStage.TODDLER, RecordCategory.MEAL, "메뉴 인식"),
    ("국수 먹였어", GrowthStage.TODDLER, RecordCategory.MEAL, "메뉴 인식"),
    ("간식 먹었어", GrowthStage.TODDLER, RecordCategory.SNACK, "간식"),
    ("사과 먹었어", GrowthStage.TODDLER, RecordCategory.SNACK, "과일"),
    ("우유 먹었어", GrowthStage.TODDLER, RecordCategory.MILK, "우유"),
    ("잠들었어", GrowthStage.TODDLER, RecordCategory.SLEEP, "수면"),
    ("응가 했어", GrowthStage.TODDLER, RecordCategory.DIAPER, "기저귀"),
    ("배변훈련 했어", GrowthStage.TODDLER, RecordCategory.DIAPER, "배변훈련"),
    ("열이 나요", GrowthStage.TODDLER, RecordCategory.HEALTH, "건강"),
]

# ─── 문장 구조 분석 전용 테스트 ───
SENTENCE_STRUCTURE_TESTS = [
    # (입력, 기대 완성도, 기대 문장수, 설명)
    ("분유 120ml 먹었어", SentenceCompleteness.COMPLETE, SentenceCount.SINGLE, "완전+단문"),
    ("분유 먹었어", SentenceCompleteness.PARTIAL, SentenceCount.SINGLE, "부분+단문 (양 누락)"),
    ("분유", SentenceCompleteness.FRAGMENT, SentenceCount.SINGLE, "조각 (키워드만)"),
    ("120", SentenceCompleteness.FRAGMENT, SentenceCount.SINGLE, "조각 (숫자만)"),
    ("ㅋ", SentenceCompleteness.NOISE, SentenceCount.SINGLE, "노이즈"),
    ("네", SentenceCompleteness.NOISE, SentenceCount.SINGLE, "노이즈 (대답)"),
    ("분유 먹고 잠들었어", SentenceCompleteness.PARTIAL, SentenceCount.MULTI, "부분+다문장"),
    ("3시에 분유 120ml 먹었고 4시에 잠들었어", SentenceCompleteness.COMPLETE, SentenceCount.MULTI, "완전+다문장"),
    ("잠들었어", SentenceCompleteness.PARTIAL, SentenceCount.SINGLE, "완전+단문 (잠은 추가정보 불필요)"),
    ("드디어 잠들었다 ㅠㅠ", SentenceCompleteness.PARTIAL, SentenceCount.SINGLE, "감정포함 부분"),
]


# ============================================================
# 테스트 러너
# ============================================================

EMOJI_MAP = {
    RecordCategory.FEEDING: "🍼",
    RecordCategory.BABYFOOD: "🥣",
    RecordCategory.SNACK: "🍪",
    RecordCategory.MEAL: "🍚",
    RecordCategory.MILK: "🥛",
    RecordCategory.SLEEP: "😴",
    RecordCategory.DIAPER: "🧷",
    RecordCategory.HEALTH: "🌡️",
    RecordCategory.OTHER: "📝",
}


def run_category_tests(test_name: str, tests: list, verbose: bool = False) -> Tuple[int, int, list]:
    """카테고리 분류 테스트 실행"""
    passed = 0
    failed = 0
    failures = []

    for text, stage, expected_cat, desc in tests:
        trace, record = run_pipeline(text, stage)

        actual_cat = record.category if record else RecordCategory.OTHER
        is_pass = (actual_cat == expected_cat)

        if is_pass:
            passed += 1
        else:
            failed += 1
            failures.append({
                'text': text, 'stage': stage.value,
                'expected': expected_cat, 'actual': actual_cat,
                'desc': desc, 'trace': trace,
            })

        if verbose:
            trace.print_trace(text)
        elif not is_pass:
            icon = "❌"
            print(f"  {icon} \"{text}\" [{stage.value}]")
            print(f"     기대: {EMOJI_MAP[expected_cat]} {expected_cat.value}  →  실제: {EMOJI_MAP[actual_cat]} {actual_cat.value}")
            print(f"     상황: {desc}")

    return passed, failed, failures


def run_sentence_tests(verbose: bool = False) -> Tuple[int, int]:
    """문장 구조 분석 테스트"""
    passed = 0
    failed = 0

    print(f"\n{'─'*60}")
    print(f"  📝 문장 구조 분석 테스트")
    print(f"{'─'*60}")

    for text, expected_comp, expected_count, desc in SENTENCE_STRUCTURE_TESTS:
        # 먼저 정규화
        n1 = node_input_normalization(text)
        normalized = n1.data if n1.success else text
        n2 = node_sentence_analysis(normalized)
        result = n2.data

        actual_comp = result["completeness"]
        actual_count = result["count"]

        comp_pass = (actual_comp == expected_comp)
        count_pass = (actual_count == expected_count)
        is_pass = comp_pass and count_pass

        if is_pass:
            passed += 1
            if verbose:
                print(f"  ✅ \"{text}\" → {actual_comp.value} / {actual_count.value}")
        else:
            failed += 1
            print(f"  ❌ \"{text}\"")
            if not comp_pass:
                print(f"     완성도: 기대={expected_comp.value}, 실제={actual_comp.value}")
            if not count_pass:
                print(f"     문장수: 기대={expected_count.value}, 실제={actual_count.value}")
            print(f"     설명: {desc}")

    return passed, failed


def main():
    verbose = '--verbose' in sys.argv or '-v' in sys.argv

    print()
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  🍼 ChatBabyTime NLP 파이프라인 v2 테스트                   ║")
    print("║                                                              ║")
    print("║  9단계 노드 기반 파이프라인 각 단계별 결과 검증              ║")
    print("║  성장 단계별 (분유기/이유식기/유아식기) 키워드 테스트        ║")
    print("╚══════════════════════════════════════════════════════════════╝")

    total_pass = 0
    total_fail = 0
    all_failures = []

    # 1. 문장 구조 분석 테스트
    sp, sf = run_sentence_tests(verbose)
    total_pass += sp
    total_fail += sf

    # 2. 분유기 테스트
    print(f"\n{'─'*60}")
    print(f"  🍼 분유기 (0~5개월) 카테고리 테스트")
    print(f"{'─'*60}")
    p, f, fl = run_category_tests("분유기", FORMULA_STAGE_TESTS, verbose)
    total_pass += p
    total_fail += f
    all_failures.extend(fl)
    rate = p / (p + f) * 100 if (p + f) > 0 else 0
    print(f"  📊 결과: {p}/{p+f} ({rate:.1f}%)")

    # 3. 이유식기 테스트
    print(f"\n{'─'*60}")
    print(f"  🥣 이유식기 (5~15개월) 카테고리 테스트")
    print(f"{'─'*60}")
    p, f, fl = run_category_tests("이유식기", WEANING_STAGE_TESTS, verbose)
    total_pass += p
    total_fail += f
    all_failures.extend(fl)
    rate = p / (p + f) * 100 if (p + f) > 0 else 0
    print(f"  📊 결과: {p}/{p+f} ({rate:.1f}%)")

    # 4. 유아식기 테스트
    print(f"\n{'─'*60}")
    print(f"  🍚 유아식기 (15개월~) 카테고리 테스트")
    print(f"{'─'*60}")
    p, f, fl = run_category_tests("유아식기", TODDLER_STAGE_TESTS, verbose)
    total_pass += p
    total_fail += f
    all_failures.extend(fl)
    rate = p / (p + f) * 100 if (p + f) > 0 else 0
    print(f"  📊 결과: {p}/{p+f} ({rate:.1f}%)")

    # 최종 결과
    total = total_pass + total_fail
    overall_rate = total_pass / total * 100 if total > 0 else 0

    print()
    print("╔══════════════════════════════════════════════════════════════╗")
    print(f"║  📊 전체 결과: {total_pass}/{total} ({overall_rate:.1f}%)                          ║")
    print(f"║  ✅ 통과: {total_pass}건  ❌ 실패: {total_fail}건                          ║")
    print("╚══════════════════════════════════════════════════════════════╝")

    # 실패 상세 (트레이스 포함)
    if all_failures and not verbose:
        print(f"\n💡 실패 케이스의 상세 트레이스를 보려면: python3 test/pipeline_test.py -v")

    # 샘플 트레이스 출력 (항상)
    print("\n" + "="*60)
    print("  📋 샘플 파이프라인 트레이스 (각 성장 단계별 1건)")
    print("="*60)

    samples = [
        ("분유 120ml 먹었어", GrowthStage.FORMULA),
        ("소고기 죽 먹였어", GrowthStage.WEANING),
        ("카레 먹었어", GrowthStage.TODDLER),
        ("드디어 잠들었다 ㅠㅠ", GrowthStage.FORMULA),
        ("기저기 갈았어 응가", GrowthStage.FORMULA),
        ("나 밥 먹어야겠다", GrowthStage.FORMULA),
    ]

    for text, stage in samples:
        trace, record = run_pipeline(text, stage)
        print(f"\n  [성장단계: {stage.value}]")
        trace.print_trace(text)
        if record:
            print(f"  📦 최종 기록: {record}")
        else:
            print(f"  ⚠️  기록 생성 실패")

    return 0 if total_fail == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
