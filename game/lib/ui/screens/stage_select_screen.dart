import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import '../../game/models/stage.dart';
import 'game_screen.dart';

class StageSelectScreen extends StatefulWidget {
  const StageSelectScreen({super.key});

  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen> {
  late final StageManager _stageManager;

  @override
  void initState() {
    super.initState();
    _stageManager = GetIt.I<StageManager>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Stage'),
        backgroundColor: MGColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MGColors.surface,
              Colors.brown.shade50,
            ],
          ),
        ),
        child: GridView.builder(
          padding: EdgeInsets.all(MGSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: MGSpacing.sm,
            crossAxisSpacing: MGSpacing.sm,
            childAspectRatio: 0.9,
          ),
          itemCount: _stageManager.stages.length,
          itemBuilder: (context, index) {
            final stage = _stageManager.stages[index];
            final isUnlocked = _stageManager.isStageUnlocked(index);
            final isCurrent = index == _stageManager.currentStageIndex;

            return _buildStageButton(stage, index, isUnlocked, isCurrent);
          },
        ),
      ),
    );
  }

  Widget _buildStageButton(
    Stage stage,
    int index,
    bool isUnlocked,
    bool isCurrent,
  ) {
    return GestureDetector(
      onTap: isUnlocked
          ? () {
              _stageManager.selectStage(index);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameScreen(stage: stage),
                ),
              ).then((_) => setState(() {}));
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? (isCurrent ? MGColors.primary : Colors.white)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? MGColors.primary
                : (isUnlocked ? Colors.brown.shade300 : Colors.grey),
            width: isCurrent ? 3 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stage Number or Lock Icon
            if (isUnlocked)
              Text(
                '${stage.id}',
                style: MGTextStyles.title.copyWith(
                  color: isCurrent ? Colors.white : MGColors.textPrimary,
                  fontSize: 24,
                ),
              )
            else
              Icon(Icons.lock, color: Colors.grey, size: 28),

            SizedBox(height: 4),

            // Stars
            if (isUnlocked)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Icon(
                    Icons.star,
                    size: 14,
                    color: i < stage.starsEarned
                        ? MGColors.gold
                        : Colors.grey.shade400,
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
