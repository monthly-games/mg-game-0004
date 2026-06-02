import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'entities/block.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:mg_common_game/core/ui/theme/app_colors.dart';
import 'package:mg_common_game/core/ui/components/floating_text_component.dart';
import 'package:mg_common_game/core/audio/audio_manager.dart';
import 'logic/cafe_manager.dart';

class Match3Game extends FlameGame {
  static const int gridSize = 8;
  late double tileSize;

  // Use a nullable 2D array
  final List<List<BlockEntity?>> _grid = List.generate(
    gridSize,
    (_) => List.filled(gridSize, null),
  );

  final Random _rng = Random();

  BlockEntity? _selectedBlock;

  // Combo System
  int _comboCount = 0;
  int get comboCount => _comboCount;
  double get comboMultiplier {
    if (_comboCount == 0) return 1.0;
    return 1.0 + (_comboCount * 0.25); // 1.25x, 1.5x, 1.75x, etc.
  }

  // Skill Items System
  int _hammerCount = 3;
  int _colorChangeCount = 2;
  SkillItemType? _activeSkill;

  int get hammerCount => _hammerCount;
  int get colorChangeCount => _colorChangeCount;
  bool get hasActiveSkill => _activeSkill != null;

  void useSkillItem(SkillItemType type) {
    if (type == SkillItemType.hammer && _hammerCount > 0) {
      _activeSkill = type;
    } else if (type == SkillItemType.colorChange && _colorChangeCount > 0) {
      _activeSkill = type;
    }
  }

  void cancelSkill() {
    _activeSkill = null;
    if (_selectedBlock != null) {
      _selectedBlock!.isSelected = false;
      _selectedBlock = null;
    }
  }

  @override
  Color backgroundColor() => AppColors.background;

  @override
  Future<void> onLoad() async {
    // Load Background
    add(SpriteComponent(sprite: await loadSprite('bg_puzzle.png'), size: size));

    // Calculate Tile Size based on screen width
    tileSize = (size.x - 32) / gridSize;

    // Fill Grid
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        _spawnBlock(x, y);
      }
    }
  }

  void _spawnBlock(int x, int y) {
    // Only spawn ingredients, not special blocks
    final ingredientTypes = [
      BlockType.bean,
      BlockType.milk,
      BlockType.sugar,
      BlockType.cup,
      BlockType.ice,
    ];
    final type = ingredientTypes[_rng.nextInt(ingredientTypes.length)];

    final block = BlockEntity(
      type: type,
      gridX: x,
      gridY: y,
      onSelected: _onBlockSelected,
      position: _getGridPosition(x, y),
      size: Vector2.all(tileSize - 4),
    );

    _grid[y][x] = block;
    add(block);
  }

  void _spawnSpecialBlock(int x, int y, BlockType type) {
    final block = BlockEntity(
      type: type,
      gridX: x,
      gridY: y,
      onSelected: _onBlockSelected,
      position: _getGridPosition(x, y),
      size: Vector2.all(tileSize - 4),
    );

    _grid[y][x] = block;
    add(block);
  }

  void _onBlockSelected(BlockEntity block) {
    // Handle skill item targeting
    if (_activeSkill != null) {
      _applySkillToBlock(block);
      return;
    }

    // GetIt.I<AudioManager>().playSfx('sfx_select.wav');
    if (_selectedBlock == null) {
      // Select first
      _selectedBlock = block;
      block.isSelected = true;
    } else if (_selectedBlock == block) {
      // Toggle off
      block.isSelected = false;
      _selectedBlock = null;
    } else {
      // Second selection
      if (_isAdjacent(_selectedBlock!, block)) {
        final otherBlock = _selectedBlock!; // Cache it
        _swapBlocks(otherBlock, block);

        // Reset selection, but maybe track 'last swapped' for special spawn logic
        // In _swapBlocks we pass a and b, so we know them there.
        _selectedBlock!.isSelected = false;
        _selectedBlock = null;
      } else {
        // Switch selection to new block
        _selectedBlock!.isSelected = false;
        _selectedBlock = block;
        block.isSelected = true;
      }
    }
  }

  bool _isAdjacent(BlockEntity a, BlockEntity b) {
    final dx = (a.gridX - b.gridX).abs();
    final dy = (a.gridY - b.gridY).abs();
    // Allow horizontal or vertical adjacency only
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }

  Future<void> _swapBlocks(BlockEntity a, BlockEntity b) async {
    // 1. Swap Data
    _performSwapData(a, b);

    // 2. Animate Swap
    final posA = _getGridPosition(a.gridX, a.gridY);
    final posB = _getGridPosition(b.gridX, b.gridY);

    a.add(
      MoveEffect.to(
        posA,
        EffectController(duration: 0.2, curve: Curves.easeInOut),
      ),
    );
    b.add(
      MoveEffect.to(
        posB,
        EffectController(duration: 0.2, curve: Curves.easeInOut),
      ),
    );

    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 200));

    // 3. Check Matches
    final matches = _findMatches();

    if (matches.isNotEmpty) {
      // Valid Swap - Reset combo for new player move
      _comboCount = 0;
      await _processMatches(matches);
    } else {
      // Invalid Swap - Animate Back
      _performSwapData(a, b); // Swap back data

      a.add(
        MoveEffect.to(
          posB,
          EffectController(duration: 0.2, curve: Curves.easeInOut),
        ),
      );
      b.add(
        MoveEffect.to(
          posA,
          EffectController(duration: 0.2, curve: Curves.easeInOut),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _performSwapData(BlockEntity a, BlockEntity b) {
    // Grid Array Swap
    final tempBlock = _grid[a.gridY][a.gridX];
    _grid[a.gridY][a.gridX] = _grid[b.gridY][b.gridX];
    _grid[b.gridY][b.gridX] = tempBlock;

    // Grid Coords Update
    final tempX = a.gridX;
    final tempY = a.gridY;
    a.gridX = b.gridX;
    a.gridY = b.gridY;
    b.gridX = tempX;
    b.gridY = tempY;

    // Visual Position is NOT swapped here, it is animated
  }

  Set<BlockEntity> _findMatches() {
    final matchedBlocks = <BlockEntity>{};

    // Horizontal
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize - 2; x++) {
        final b1 = _grid[y][x];
        final b2 = _grid[y][x + 1];
        final b3 = _grid[y][x + 2];

        if (b1 != null &&
            b2 != null &&
            b3 != null &&
            b1.type == b2.type &&
            b1.type == b3.type) {
          matchedBlocks.add(b1);
          matchedBlocks.add(b2);
          matchedBlocks.add(b3);
        }
      }
    }

    // Vertical
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize - 2; y++) {
        final b1 = _grid[y][x];
        final b2 = _grid[y + 1][x];
        final b3 = _grid[y + 2][x];

        if (b1 != null &&
            b2 != null &&
            b3 != null &&
            b1.type == b2.type &&
            b1.type == b3.type) {
          matchedBlocks.add(b1);
          matchedBlocks.add(b2);
          matchedBlocks.add(b3);
        }
      }
    }

    return matchedBlocks;
  }

  Future<void> _processMatches(Set<BlockEntity> matches) async {
    // ... (Match Analysis Logic same as before) ...
    final goldManager = GetIt.I<GoldManager>();
    int earnings = 0;
    Vector2 centerSum = Vector2.zero();

    // Increment combo for cascade matches
    _comboCount++;

    // Determine if we should spawn a special block
    BlockEntity? specialSpawnLocation;
    BlockType? specialSpawnType;

    if (matches.length >= 5) {
      specialSpawnType = BlockType.bomb;
    } else if (matches.length == 4) {
      specialSpawnType = _rng.nextBool()
          ? BlockType.rocketH
          : BlockType.rocketV;
    }

    if (specialSpawnType != null && matches.isNotEmpty) {
      if (_selectedBlock != null && matches.contains(_selectedBlock)) {
        specialSpawnLocation = _selectedBlock;
      } else {
        specialSpawnLocation = matches.first;
      }
    }

    // Play Match Sound
    if (matches.isNotEmpty) {
      try {
        GetIt.I<AudioManager>().playSfx('sfx_match.wav');
      } catch (_) {}
    }

    // Animate removal
    for (final block in matches) {
      centerSum += block.position;
      _grid[block.gridY][block.gridX] = null;
      earnings += 10;

      // Scale down and fade out
      block.add(
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.2, curve: Curves.easeIn),
          onComplete: () => block.removeFromParent(),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 200));

    // Spawn Special Block if any
    if (specialSpawnType != null && specialSpawnLocation != null) {
      _spawnSpecialBlock(
        specialSpawnLocation.gridX,
        specialSpawnLocation.gridY,
        specialSpawnType,
      );
    }

    if (earnings > 0) {
      // Apply combo multiplier
      final multiplier = comboMultiplier;
      final finalEarnings = (earnings * multiplier).round();

      goldManager.addGold(finalEarnings);

      // Award XP via CafeManager
      try {
        final cafeManager = GetIt.I<CafeManager>();
        cafeManager.addStars((matches.length * multiplier).round());

        // Add Ingredients
        for (final block in matches) {
          String ingredientId = '';
          switch (block.type) {
            case BlockType.bean:
              ingredientId = 'bean';
              break;
            case BlockType.milk:
              ingredientId = 'milk';
              break;
            case BlockType.sugar:
              ingredientId = 'sugar';
              break;
            case BlockType.cup:
              ingredientId = 'cup';
              break;
            case BlockType.ice:
              ingredientId = 'ice';
              break;
            default:
              break;
          }

          if (ingredientId.isNotEmpty) {
            cafeManager.addIngredient(ingredientId, 1);
          }
        }
      } catch (e) {
        // Ignore
      }

      // Visual Feedback
      if (matches.isNotEmpty) {
        final center = centerSum / matches.length.toDouble();

        // Show combo indicator if applicable
        if (_comboCount > 1) {
          add(
            FloatingTextComponent(
              text: 'x${multiplier.toStringAsFixed(1)} COMBO!',
              position: center + Vector2(0, -30),
              color: Colors.orange,
              fontSize: 20,
            ),
          );
        }

        add(
          FloatingTextComponent(
            text: '+$finalEarnings G',
            position: center,
            color: multiplier > 1.0 ? Colors.orangeAccent : Colors.amber,
            fontSize: 24,
          ),
        );
      }
    }

    // 2. Gravity & Refill
    await Future.delayed(const Duration(milliseconds: 100)); // Small pause
    await _applyGravity();

    // 3. Chain Reaction
    final newMatches = _findMatches();
    if (newMatches.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      await _processMatches(newMatches);
    } else {
      // Reset combo when no more cascades
      _comboCount = 0;
    }
  }

  Future<void> _applyGravity() async {
    // For each column
    for (int x = 0; x < gridSize; x++) {
      int writeY = gridSize - 1;

      // Shift down existing blocks
      for (int y = gridSize - 1; y >= 0; y--) {
        if (_grid[y][x] != null) {
          if (writeY != y) {
            final block = _grid[y][x]!;
            _grid[writeY][x] = block;
            _grid[y][x] = null;
            block.gridY = writeY;

            // Animate Fall
            final targetPos = _getGridPosition(x, writeY);
            // Distance check to calculate duration?
            // Fixed duration for now or based on distance
            double distance = (block.position.y - targetPos.y).abs();
            double duration = distance / 500.0; // speed px/sec
            if (duration < 0.1) duration = 0.1;

            block.add(
              MoveEffect.to(
                targetPos,
                EffectController(duration: duration, curve: Curves.bounceOut),
              ),
            );
          }
          writeY--;
        }
      }

      // Fill empty spots at top
      while (writeY >= 0) {
        // Spawn above screen
        final targetPos = _getGridPosition(x, writeY);
        final startPos = Vector2(
          targetPos.x,
          targetPos.y - 100,
        ); // Start slightly above

        final block = _spawnBlockAt(x, writeY, startPos);
        block.add(
          MoveEffect.to(
            targetPos,
            EffectController(duration: 0.3, curve: Curves.bounceOut),
          ),
        );
        writeY--;
      }
    }

    // Wait for all moves
    await Future.delayed(const Duration(milliseconds: 300));
  }

  BlockEntity _spawnBlockAt(int x, int y, Vector2 startPos) {
    // Only spawn ingredients, not special blocks
    final ingredientTypes = [
      BlockType.bean,
      BlockType.milk,
      BlockType.sugar,
      BlockType.cup,
      BlockType.ice,
    ];
    final type = ingredientTypes[_rng.nextInt(ingredientTypes.length)];

    final block = BlockEntity(
      type: type,
      gridX: x,
      gridY: y,
      onSelected: _onBlockSelected,
      position: startPos, // Start Position
      size: Vector2.all(tileSize - 4),
    );

    _grid[y][x] = block;
    add(block);
    return block;
  }

  Vector2 _getGridPosition(int x, int y) {
    final startX = 16.0;
    final startY = (size.y - (tileSize * gridSize)) / 2;
    return Vector2(
      startX + (x * tileSize) + tileSize / 2,
      startY + (y * tileSize) + tileSize / 2,
    );
  }

  void _applySkillToBlock(BlockEntity block) {
    if (_activeSkill == null) return;

    try {
      GetIt.I<AudioManager>().playSfx('sfx_skill.wav');
    } catch (_) {}

    if (_activeSkill == SkillItemType.hammer) {
      // Hammer: Destroy single block
      _hammerCount--;
      _destroySingleBlock(block);
    } else if (_activeSkill == SkillItemType.colorChange) {
      // Color Change: Convert block type to a random ingredient
      _colorChangeCount--;
      _changeBlockType(block);
    }

    _activeSkill = null;
  }

  Future<void> _destroySingleBlock(BlockEntity block) async {
    final goldManager = GetIt.I<GoldManager>();
    final center = block.position;

    // Remove from grid
    _grid[block.gridY][block.gridX] = null;

    // Award earnings
    goldManager.addGold(5);

    // Visual feedback
    add(
      FloatingTextComponent(
        text: '+5 G',
        position: center,
        color: Colors.redAccent,
        fontSize: 20,
      ),
    );

    // Animate removal
    block.add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.2, curve: Curves.easeIn),
        onComplete: () => block.removeFromParent(),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 200));

    // Apply gravity to fill the gap
    await _applyGravity();

    // Check for new matches
    final newMatches = _findMatches();
    if (newMatches.isNotEmpty) {
      _comboCount = 0; // Reset combo for skill-triggered matches
      await _processMatches(newMatches);
    }
  }

  Future<void> _changeBlockType(BlockEntity block) async {
    // Get new random ingredient type (different from current)
    final ingredientTypes = [
      BlockType.bean,
      BlockType.milk,
      BlockType.sugar,
      BlockType.cup,
      BlockType.ice,
    ];

    final availableTypes = ingredientTypes.where((t) => t != block.type).toList();
    final newType = availableTypes[_rng.nextInt(availableTypes.length)];

    // Visual feedback
    final center = block.position;
    add(
      FloatingTextComponent(
        text: 'CHANGED!',
        position: center + Vector2(0, -20),
        color: Colors.purpleAccent,
        fontSize: 16,
      ),
    );

    // Replace the block with a new one of the desired type
    _grid[block.gridY][block.gridX] = null;
    block.removeFromParent();

    final newBlock = BlockEntity(
      type: newType,
      gridX: block.gridX,
      gridY: block.gridY,
      onSelected: _onBlockSelected,
      position: block.position,
      size: block.size,
    );

    _grid[block.gridY][block.gridX] = newBlock;
    add(newBlock);

    await Future.delayed(const Duration(milliseconds: 200));

    // Check for new matches
    final newMatches = _findMatches();
    if (newMatches.isNotEmpty) {
      _comboCount = 0; // Reset combo for skill-triggered matches
      await _processMatches(newMatches);
    }
  }

  void addSkillItem(SkillItemType type, int amount) {
    if (type == SkillItemType.hammer) {
      _hammerCount += amount;
    } else if (type == SkillItemType.colorChange) {
      _colorChangeCount += amount;
    }
  }
}

enum SkillItemType {
  hammer,
  colorChange,
}
