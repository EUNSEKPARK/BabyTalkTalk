import 'package:shared_preferences/shared_preferences.dart';

/// 첫 실행 시 '누가 / 어떤 아이로' 쓸지 안내하는 단계 완료 여부
class CareOnboardingService {
  CareOnboardingService._();

  static const _keyIdentityDone = 'care_identity_onboarding_done';
  static const _keyPrimaryCaregiver = 'care_is_primary_caregiver';

  static Future<bool> isIdentityStepDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyIdentityDone) ?? false;
  }

  static Future<void> markIdentityStepDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyIdentityDone, true);
  }

  /// 메인 육아 담당자로 표시할지 (UI·통계용, null이면 미선택)
  static Future<void> setPrimaryCaregiver(bool? value) async {
    final p = await SharedPreferences.getInstance();
    if (value == null) {
      await p.remove(_keyPrimaryCaregiver);
    } else {
      await p.setBool(_keyPrimaryCaregiver, value);
    }
  }

  static Future<bool?> getPrimaryCaregiver() async {
    final p = await SharedPreferences.getInstance();
    if (!p.containsKey(_keyPrimaryCaregiver)) return null;
    return p.getBool(_keyPrimaryCaregiver);
  }
}
