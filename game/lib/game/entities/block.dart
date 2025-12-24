import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

enum BlockType {
  // Ingredients
  bean, // Coffee Bean
  milk, // Milk Carton
  sugar, // Sugar Cube
  cup, // Paper Cup
  ice, // Ice Cube / Water
  // Special
  rocketH, // Mobile clearer Horizontal
  rocketV, // Mobile clearer Vertical
  bomb, // Area clearer
  rainbow, // Color clearer
}

class BlockEntity extends SpriteComponent with TapCallbacks, HasGameRef {
  final BlockType type;
  int gridX;
  int gridY;
  final Function(BlockEntity) onSelected;
  bool isSelected = false;

  BlockEntity({
    required this.type,
    required this.gridX,
    required this.gridY,
    required this.onSelected,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    String spriteName;
    switch (type) {
      case BlockType.bean:
        spriteName = 'block_purple.png';
        break;
      case BlockType.milk:
        spriteName = 'block_white.png';
        break;
      case BlockType.sugar:
        spriteName = 'block_blue.png';
        break;
      case BlockType.cup:
        spriteName = 'block_red.png';
        break;
      case BlockType.ice:
        spriteName = 'block_green.png';
        break;
      case BlockType.rocketH:
        spriteName = 'block_rocket_h.png';
        break;
      case BlockType.rocketV:
        spriteName = 'block_rocket_v.png';
        break;
      case BlockType.bomb:
        spriteName = 'block_bomb.png';
        break;
      case BlockType.rainbow:
        spriteName = 'block_rainbow.png';
        break;
    }
    sprite = await gameRef.loadSprite(spriteName);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw Selection Halo
    if (isSelected) {
      canvas.drawRect(
        size.toRect(),
        BasicPalette.white.paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onSelected(this);
  }
}
