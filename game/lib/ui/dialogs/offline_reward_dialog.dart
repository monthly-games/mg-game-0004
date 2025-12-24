import 'package:flutter/material.dart';
import 'package:cafe_match_tycoon/game/logic/idle_income_manager.dart';

/// 오프라인 보상 다이얼로그
class OfflineRewardDialog extends StatelessWidget {
  final OfflineReward reward;

  const OfflineRewardDialog({
    super.key,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A5568),
              Color(0xFF2D3748),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이틀
            const Text(
              '돌아오신 것을 환영합니다!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // 오프라인 시간
            Text(
              '오프라인 시간: ${reward.formattedTime}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),

            // 골드 아이콘 + 금액
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.stars,
                    color: Color(0xFFFFD700),
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '+${reward.goldEarned} 골드',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(${reward.goldPerMinute} 골드/분)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 안내 메시지
            const Text(
              '카페가 당신을 기다리는 동안\n골드를 모았습니다!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // 확인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '수령하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 보상이 있을 때만 다이얼로그를 표시합니다.
  static void showIfHasReward(BuildContext context, OfflineReward reward) {
    if (reward.hasReward) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => OfflineRewardDialog(reward: reward),
      );
    }
  }
}
