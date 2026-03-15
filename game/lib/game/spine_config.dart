import 'package:mg_common_game/core/assets/asset_types.dart';

/// Spine 통합 플래그. `--dart-define=SPINE_ENABLED=true`로 활성화.
const kSpineEnabled = bool.fromEnvironment(
  'SPINE_ENABLED',
  defaultValue: false,
);

// ── Cafe Owner ───────────────────────────────────────────────

const kCafeOwnerMeta = SpineAssetMeta(
  key: 'cafe_owner',
  path: 'spine/characters/cafe_owner',
  atlasPath: 'assets/spine/characters/cafe_owner/cafe_owner.atlas',
  skeletonPath:
      'assets/spine/characters/cafe_owner/cafe_owner.json',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);

// ── Barista ──────────────────────────────────────────────────

const kBaristaMeta = SpineAssetMeta(
  key: 'barista',
  path: 'spine/characters/barista',
  atlasPath: 'assets/spine/characters/barista/barista.atlas',
  skeletonPath: 'assets/spine/characters/barista/barista.json',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);

// ── Pastry Chef ──────────────────────────────────────────────

const kPastryChefMeta = SpineAssetMeta(
  key: 'pastry_chef',
  path: 'spine/characters/pastry_chef',
  atlasPath:
      'assets/spine/characters/pastry_chef/pastry_chef.atlas',
  skeletonPath:
      'assets/spine/characters/pastry_chef/pastry_chef.json',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);
