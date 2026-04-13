import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final VoidCallback? onDailyHub;
  final VoidCallback? onGuildWar;
  final VoidCallback? onTournament;
  final VoidCallback? onSeasonalEvent;

  const MGPuzzleHud({
    super.key,
    required this.gold,
    this.moves = 0,
    this.score = 0,
    this.targetScore,
    this.onPause,
    this.onHint,
    this.onDailyHub,
    this.onGuildWar,
    this.onTournament,
    this.onSeasonalEvent,
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
        if (onGuildWar != null)
          MGIconButton(
            icon: Icons.shield,
            onPressed: onGuildWar,
            size: 44,
            backgroundColor: MGColors.info.withValues(alpha: 0.8),
            color: MGColors.textHighEmphasis,
            tooltip: 'Guild War',
          ),
        MGSpacing.hXs,
        if (onTournament != null)
          MGIconButton(
            icon: Icons.emoji_events,
            onPressed: onTournament,
            size: 44,
            backgroundColor: MGColors.info.withValues(alpha: 0.8),
            color: MGColors.textHighEmphasis,
            tooltip: 'Tournament',
          ),
        MGSpacing.hXs,
        if (onSeasonalEvent != null)
          MGIconButton(
            icon: Icons.celebration,
            onPressed: onSeasonalEvent,
            size: 44,
            backgroundColor: MGColors.info.withValues(alpha: 0.8),
            color: MGColors.textHighEmphasis,
            tooltip: 'Seasonal Event',
          ),
        MGSpacing.hXs,
        if (onDailyHub != null)
          MGIconButton(
            icon: Icons.calendar_today,
            onPressed: onDailyHub,
            size: 44,
            backgroundColor: MGColors.info.withValues(alpha: 0.8),
            color: MGColors.textHighEmphasis,
            tooltip: 'Daily Hub',
          ),
        MGSpacing.hXs,
                if (onPause != null)
                  MGIconButton(
                    icon: Icons.pause,
                    onPressed: onPause,
                    size: 44,
                    backgroundColor: Colors.black54,
                    color: MGColors.textHighEmphasis,
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
          // Spine 캐릭터
          _buildSpineCharacter(),
          const SizedBox(height: 50),

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
              color: MGColors.textHighEmphasis,
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
            color: MGColors.textHighEmphasis,
            size: 20,
          ),
          MGSpacing.hXs,
          Text(
            'Moves: $moves',
            style: MGTextStyles.hud.copyWith(
              color: MGColors.textHighEmphasis,
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


  Widget _buildSpineCharacter() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.purple.withAlpha(150), width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 24, color: Colors.white),
            SizedBox(height: 2),
            Text(
              'Puzzle Master',
              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

}
