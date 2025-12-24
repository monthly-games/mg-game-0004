import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// MG UI 기반 퍼즐 게임 HUD
/// mg_common_game의 공통 UI 컴포넌트 활용
class MGPuzzleHud extends StatelessWidget {
  final int gold;
  final int moves;
  final int score;
  final int? targetScore;
  final VoidCallback? onPause;
  final VoidCallback? onHint;

  const MGPuzzleHud({
    super.key,
    required this.gold,
    this.moves = 0,
    this.score = 0,
    this.targetScore,
    this.onPause,
    this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;

    return Positioned.fill(
      child: Column(
        children: [
          // 상단 HUD: 점수 + 골드
          Container(
            padding: EdgeInsets.only(
              top: safeArea.top + MGSpacing.hudMargin,
              left: safeArea.left + MGSpacing.hudMargin,
              right: safeArea.right + MGSpacing.hudMargin,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 일시정지 버튼
                if (onPause != null)
                  MGIconButton(
                    icon: Icons.pause,
                    onPressed: onPause,
                    size: 44,
                    backgroundColor: Colors.black54,
                    color: Colors.white,
                  )
                else
                  const SizedBox(width: 44),

                // 점수 표시
                _buildScoreDisplay(),

                // 골드 표시
                MGResourceBar(
                  icon: Icons.monetization_on,
                  value: _formatNumber(gold),
                  iconColor: MGColors.gold,
                  onTap: null,
                ),
              ],
            ),
          ),

          // 중앙 영역 확장 (퍼즐 보드)
          const Expanded(child: SizedBox()),

          // 하단 HUD: 남은 이동 + 힌트
          Container(
            padding: EdgeInsets.only(
              bottom: safeArea.bottom + MGSpacing.hudMargin,
              left: safeArea.left + MGSpacing.hudMargin,
              right: safeArea.right + MGSpacing.hudMargin,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMovesDisplay(),
                if (onHint != null)
                  MGButton(
                    label: 'HINT',
                    icon: Icons.lightbulb,
                    size: MGButtonSize.small,
                    style: MGButtonStyle.outlined,
                    onPressed: onHint,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MGColors.warning.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatNumber(score),
            style: MGTextStyles.hudLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (targetScore != null)
            Text(
              '/ ${_formatNumber(targetScore!)}',
              style: MGTextStyles.caption.copyWith(
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMovesDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.swap_horiz,
            color: Colors.white,
            size: 20,
          ),
          MGSpacing.hXs,
          Text(
            'Moves: $moves',
            style: MGTextStyles.hud.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
