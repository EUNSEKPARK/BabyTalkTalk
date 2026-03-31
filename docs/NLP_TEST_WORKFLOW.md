# 아기톡톡 NLP 테스트-수정 반복 워크플로우

## 빠른 시작

```bash
# 1. 테스트 실행 (프로젝트 루트에서)
flutter test test/nlp_full_test.dart

# 또는 스크립트로 (요약 자동 추출)
bash run_nlp_test.sh
```

## 반복 사이클

```
┌──────────────────────────────────────────┐
│  1. bash run_nlp_test.sh  실행           │
│         ↓                                │
│  2. 실패 목록 확인                        │
│     (test_result_summary.txt)            │
│         ↓                                │
│  3. 실패 목록을 Claude에게 붙여넣기       │
│     "아래 실패 고쳐줘"                    │
│         ↓                                │
│  4. Claude가 nlp_parser.dart 수정        │
│         ↓                                │
│  5. 다시 1번으로 → 0 failures 될 때까지   │
└──────────────────────────────────────────┘
```

## Claude에게 공유할 때 템플릿

```
NLP 테스트 실패 목록:

(여기에 test_result_summary.txt 내용 붙여넣기)

이것들 고쳐줘.
```

이것만 보내면 됩니다! 전체 코드를 다시 설명할 필요 없음.

## 테스트 문장 추가하기

`test/nlp_full_test.dart` 파일의 `testCases` 리스트에 추가:

```dart
{'input': '새 테스트 문장', 'expected': 'sleep'},  // 카테고리명
```

사용 가능한 카테고리: `feeding`, `sleep`, `diaper`, `health`, `babyfood`, `snack`, `milestone`, `other`

## 파일 구조

| 파일 | 용도 |
|------|------|
| `test/nlp_full_test.dart` | 145+ 문장 자동 테스트 |
| `run_nlp_test.sh` | 테스트 실행 + 요약 추출 |
| `test_result_summary.txt` | 실패 항목만 (Claude 공유용) |
| `test_result_full.txt` | 전체 테스트 로그 |
| `pipeline_test_interactive.html` | 수동 인터랙티브 테스트 (브라우저) |
| `test_sentences.txt` | 원본 테스트 문장 목록 |

## 팁

- **컨텍스트 절약**: 실패 목록만 공유하면 대화가 짧아져서 컨텍스트 부족 문제 해결
- **새 대화에서도 OK**: "NLP 테스트 실패 목록: ..." 만 보내면 Claude가 바로 수정 가능
- **테스트 추가**: 새로운 표현을 발견하면 testCases에 추가하고 다시 테스트
