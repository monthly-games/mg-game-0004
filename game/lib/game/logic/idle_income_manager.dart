import 'package:shared_preferences/shared_preferences.dart';

/// 방치형 수익 관리자
/// 오프라인 시간 동안 자동으로 골드를 생성합니다.
class IdleIncomeManager {
  static const String _lastLoginKey = 'last_login_time';
  static const double _baseGoldPerMinute = 25.0;

  /// 마지막 로그인 시간을 저장합니다.
  Future<void> saveLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastLoginKey, now);
  }

  /// 오프라인 시간 동안 획득한 골드를 계산합니다.
  ///
  /// [cafeLevel]: 카페 레벨 (의자 + 테이블 레벨의 합)
  ///
  /// 계산 공식:
  /// - 기본 골드: 5골드/분
  /// - 카페 레벨 보너스: 레벨당 +10%
  /// - 최대 오프라인 시간: 8시간 (480분)
  Future<OfflineReward> calculateOfflineReward(int cafeLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginMs = prefs.getInt(_lastLoginKey);

    // 첫 실행 시
    if (lastLoginMs == null) {
      await saveLoginTime();
      return OfflineReward(goldEarned: 0, minutesElapsed: 0);
    }

    final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginMs);
    final now = DateTime.now();
    final elapsed = now.difference(lastLogin);

    // 최소 1분 이상 경과해야 보상
    if (elapsed.inMinutes < 1) {
      return OfflineReward(goldEarned: 0, minutesElapsed: 0);
    }

    // 최대 8시간 (480분)으로 제한
    final minutesElapsed = elapsed.inMinutes.clamp(0, 480);

    // 카페 레벨 보너스 (레벨당 +10%)
    final cafeMultiplier = 1.0 + (cafeLevel * 0.1);

    // 골드 계산
    final goldEarned = (minutesElapsed * _baseGoldPerMinute * cafeMultiplier)
        .floor();

    // 현재 시간으로 업데이트
    await saveLoginTime();

    return OfflineReward(
      goldEarned: goldEarned,
      minutesElapsed: minutesElapsed,
    );
  }

  /// 카페 레벨 계산 (의자 + 테이블 레벨)
  static int calculateCafeLevel(int chairLevel, int tableLevel) {
    return chairLevel + tableLevel;
  }
}

/// 오프라인 보상 데이터
class OfflineReward {
  final int goldEarned;
  final int minutesElapsed;

  OfflineReward({required this.goldEarned, required this.minutesElapsed});

  /// 시간 표시 문자열 (예: "2h 30m", "45m", "8h")
  String get formattedTime {
    if (minutesElapsed < 60) {
      return '$minutesElapsed분';
    } else {
      final hours = minutesElapsed ~/ 60;
      final minutes = minutesElapsed % 60;
      if (minutes == 0) {
        return '$hours시간';
      }
      return '$hours시간 $minutes분';
    }
  }

  /// 분당 골드 표시 (소수점 1자리)
  String get goldPerMinute {
    if (minutesElapsed == 0) return '0.0';
    return (goldEarned / minutesElapsed).toStringAsFixed(1);
  }

  /// 보상이 있는지 확인
  bool get hasReward => goldEarned > 0;
}
