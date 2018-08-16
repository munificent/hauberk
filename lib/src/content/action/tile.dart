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
      game.stage.placeDrops(_pos, Motility.walk, _createDrop());

      log("{1} open[s] the $_name.", actor);
    }

    return ActionResult.success;
  }

  Drop _createDrop();
}

/// Open a barrel and place its drops.
class OpenBarrelAction extends _OpenTileAction {
  OpenBarrelAction(Vec pos) : super(pos);

  String get _name => "barrel";

  TileType get _openTile => Tiles.openBarrel;

  int get _minDepthEmptyChance => 40;

  int get _maxDepthEmptyChance => 10;

  // TODO: More sophisticated drop.
  Drop _createDrop() => parseDrop("food", game.depth);
}

/// Open a chest and place its drops.
class OpenChestAction extends _OpenTileAction {
  OpenChestAction(Vec pos) : super(pos);

  String get _name => "chest";

  TileType get _openTile => Tiles.openChest;

  int get _minDepthEmptyChance => 20;

  int get _maxDepthEmptyChance => 2;

  // TODO: Drop more than one item sometimes.
  Drop _createDrop() => dropOneOf({
        parseDrop("treasure", game.depth): 0.5,
        parseDrop("magic", game.depth): 0.2,
        parseDrop("equipment", game.depth): 0.3
      });
}
