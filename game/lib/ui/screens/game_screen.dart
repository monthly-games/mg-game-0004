import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import '../../game/match3_game.dart';
import '../../game/models/stage.dart';
import '../hud/mg_puzzle_hud.dart';

class GameScreen extends StatefulWidget {
  final Stage stage;

  const GameScreen({super.key, required this.stage});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Match3Game _game;
  bool _isCompleted = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    _game = Match3Game();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game
          GameWidget(game: _game),

          // HUD Overlay
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  _buildStageHUD(),
                  Spacer(),
                ],
              ),
            ),
          ),

          // Win/Lose Overlay
          if (_isCompleted || _isFailed) _buildResultOverlay(),
        ],
      ),
    );
  }

  Widget _buildStageHUD() {
    return Container(
      margin: EdgeInsets.all(MGSpacing.md),
      padding: EdgeInsets.all(MGSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Top row: Back, Stage Name, Moves
          Row(
            children: [
              MGIconButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.pop(context),
                size: 36,
                backgroundColor: Colors.transparent,
                color: Colors.white,
              ),
              SizedBox(width: MGSpacing.sm),
              Expanded(
                child: Text(
                  'Stage ${widget.stage.id}: ${widget.stage.name}',
                  style: MGTextStyles.hud.copyWith(color: Colors.white),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MGSpacing.sm,
                  vertical: MGSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      '${widget.stage.movesRemaining}',
                      style: MGTextStyles.hud.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: MGSpacing.xs),

          // Goals row
          Row(
            children: widget.stage.goals.map((goal) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  padding: EdgeInsets.all(MGSpacing.xs),
                  decoration: BoxDecoration(
                    color: goal.isCompleted
                        ? Colors.green.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: goal.isCompleted ? Colors.green : Colors.white30,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        goal.isCompleted
                            ? Icons.check_circle
                            : _getGoalIcon(goal.type),
                        color: goal.isCompleted ? Colors.green : Colors.white70,
                        size: 16,
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${goal.currentAmount}/${goal.targetAmount}',
                        style: MGTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon(StageGoalType type) {
    switch (type) {
      case StageGoalType.collectIngredients:
        return Icons.inventory_2;
      case StageGoalType.reachScore:
        return Icons.star;
      case StageGoalType.serveCustomers:
        return Icons.person;
      case StageGoalType.clearBlocks:
        return Icons.grid_view;
    }
  }

  Widget _buildResultOverlay() {
    final stars = widget.stage.calculateStars();
    final isWin = _isCompleted && widget.stage.allGoalsCompleted;

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: EdgeInsets.all(MGSpacing.xl),
          padding: EdgeInsets.all(MGSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Result Icon
              Icon(
                isWin ? Icons.celebration : Icons.sentiment_dissatisfied,
                size: 64,
                color: isWin ? MGColors.gold : Colors.grey,
              ),

              SizedBox(height: MGSpacing.md),

              // Result Text
              Text(
                isWin ? 'Stage Clear!' : 'Try Again',
                style: MGTextStyles.display.copyWith(
                  color: isWin ? MGColors.success : Colors.grey,
                ),
              ),

              SizedBox(height: MGSpacing.md),

              // Stars
              if (isWin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Icon(
                      Icons.star,
                      size: 40,
                      color: i < stars ? MGColors.gold : Colors.grey.shade300,
                    );
                  }),
                ),

              SizedBox(height: MGSpacing.md),

              // Score
              Text(
                'Score: ${widget.stage.score}',
                style: MGTextStyles.body,
              ),

              SizedBox(height: MGSpacing.lg),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: Text('Home'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Reset and retry
                      setState(() {
                        _isCompleted = false;
                        _isFailed = false;
                        widget.stage.movesUsed = 0;
                        widget.stage.score = 0;
                        for (final goal in widget.stage.goals) {
                          goal.currentAmount = 0;
                        }
                        _game = Match3Game();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MGColors.primary,
                    ),
                    child: Text(isWin ? 'Next' : 'Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
