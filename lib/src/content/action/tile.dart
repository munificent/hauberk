import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../item/drops.dart';
import '../tiles.dart';

/// Base class for actions that open a container tile.
abstract class _OpenTileAction extends Action {
  final Vec _pos;

  _OpenTileAction(this._pos);

  String get _name;

  TileType get _openTile;

  // TODO: Do something more sophisticated. Take into account the theme where
  // the tile is.
  String get _drop;

  int get _minDepthEmptyChance;

  int get _maxDepthEmptyChance;

  ActionResult onPerform() {
    game.stage[_pos].type = _openTile;
    addEvent(EventType.openBarrel, pos: _pos);

    // TODO: Chance of monster in it?
    // TODO: Traps. Locks.
    if (rng.percent(lerpInt(game.depth, 1, Option.maxDepth,
        _minDepthEmptyChance, _maxDepthEmptyChance))) {
      log("The $_name is empty.", actor);
    } else {
      var drop = parseDrop(_drop, game.depth);
      game.stage.placeDrops(_pos, Motility.walk, drop);

      log("{1} open[s] the $_name.", actor);
    }

    return ActionResult.success;
  }
}

/// Open a barrel and place its drops.
class OpenBarrelAction extends _OpenTileAction {
  OpenBarrelAction(Vec pos) : super(pos);

  String get _name => "barrel";

  TileType get _openTile => Tiles.openBarrel;

  String get _drop => "food";

  int get _minDepthEmptyChance => 40;

  int get _maxDepthEmptyChance => 10;
}

/// Open a chest and place its drops.
class OpenChestAction extends _OpenTileAction {
  OpenChestAction(Vec pos) : super(pos);

  String get _name => "chest";

  TileType get _openTile => Tiles.openChest;

  // TODO: Drop more than one item sometimes.
  String get _drop => "item";

  int get _minDepthEmptyChance => 20;

  int get _maxDepthEmptyChance => 2;
}
