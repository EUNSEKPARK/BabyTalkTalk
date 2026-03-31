#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 아기톡톡 NLP 파서 테스트 실행 스크립트
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 사용법:
#   chmod +x run_nlp_test.sh
#   ./run_nlp_test.sh
#
# 또는:
#   bash run_nlp_test.sh
#
# 결과가 test_result.txt에 저장됩니다.
# 실패 항목만 Claude에게 붙여넣기 하세요!
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "🧪 아기톡톡 NLP 테스트 시작..."
echo ""

# flutter test 실행하고 결과 저장
flutter test test/nlp_full_test.dart 2>&1 | tee test_result_full.txt

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📋 실패 항목만 추출 (Claude에 공유용)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 실패 항목만 추출
grep -E "^  ❌|^━|^  📊|^  전체:|^  🍼|^  😴|^  🧷|^  🏥|^  🥣|^  🍎|^  📝|^  ⭐|^  💡|^  🎉|── 실패" test_result_full.txt > test_result_summary.txt 2>/dev/null

# 요약 표시
if [ -f test_result_summary.txt ] && [ -s test_result_summary.txt ]; then
    cat test_result_summary.txt
    echo ""
    echo "📁 요약이 test_result_summary.txt에 저장됨"
    echo "💡 이 내용을 Claude에게 붙여넣기 하세요!"
else
    echo "🎉 모든 테스트 통과! 실패 항목이 없습니다."
fi

echo ""
echo "📁 전체 로그: test_result_full.txt"
