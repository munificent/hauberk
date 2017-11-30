import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart';
import 'game_screen.dart';
import 'input.dart';

// TODO: Support targeting floor tiles and not just actors.

/// Modal dialog for letting the user select a target to perform a [Command] on.
class TargetDialog extends Screen<Input> {
  static const _numFrames = 5;
  static const _ticksPerFrame = 5;

  final GameScreen _gameScreen;
  final num _range;
  final void Function(Vec target) _onSelect;
  final List<Monster> _monsters = <Monster>[];

  bool _targetingFloor = false;
  int _animateOffset = 0;

  bool get isTransparent => true;

  TargetDialog(this._gameScreen, this._range, this._onSelect) {
    // Find the targetable monsters.
    var hero = _gameScreen.game.hero;
    for (var actor in _gameScreen.game.stage.actors) {
      if (actor is! Monster) continue;
      if (!actor.isVisible) continue;

      // Must be within range.
      var toMonster = actor.pos - hero.pos;
      if (toMonster > _range) continue;

      _monsters.add(actor);
    }

    if (_monsters.isEmpty) {
      // No visible monsters, so switch to floor targeting.
      _targetingFloor = true;
      _gameScreen.targetFloor(_gameScreen.game.hero.pos);
    } else {
      // Default to targeting the nearest monster to the hero.
      _targetNearest(_gameScreen.game.hero.pos);
    }
  }

  bool _targetNearest(Vec pos) {
    if (_monsters.isEmpty) return false;

    Actor nearest;
    for (var monster in _monsters) {
      if (nearest == null || pos - monster.pos < pos - nearest.pos) {
        nearest = monster;
      }
    }

    _gameScreen.targetActor(nearest);
    return true;
  }

  bool handleInput(Input input) {
    switch (input) {
      case Input.ok:
        if (_gameScreen.currentTarget != null) {
          ui.pop();
          _onSelect(_gameScreen.currentTarget);
        }
        break;

      case Input.cancel:
        ui.pop();
        break;

      case Input.nw:
        _changeTarget(Direction.nw);
        break;
      case Input.n:
        _changeTarget(Direction.n);
        break;
      case Input.ne:
        _changeTarget(Direction.ne);
        break;
      case Input.w:
        _changeTarget(Direction.w);
        break;
      case Input.e:
        _changeTarget(Direction.e);
        break;
      case Input.sw:
        _changeTarget(Direction.sw);
        break;
      case Input.s:
        _changeTarget(Direction.s);
        break;
      case Input.se:
        _changeTarget(Direction.se);
        break;
    }

    return true;
  }

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (keyCode == KeyCode.tab && !_monsters.isEmpty) {
      _targetingFloor = !_targetingFloor;
      if (!_targetingFloor) {
        // Target the nearest monster to the floor tile we were previously
        // targeting.
        _targetNearest(_gameScreen.currentTarget ?? _gameScreen.game.hero.pos);
      } else {
        _gameScreen.targetFloor(_gameScreen.currentTarget);
      }
      return true;
    }

    return false;
  }

  void update() {
    _animateOffset = (_animateOffset + 1) % (_numFrames * _ticksPerFrame);
    if (_animateOffset % _ticksPerFrame == 0) dirty();
  }

  void render(Terminal terminal) {
    var stage = _gameScreen.game.stage;

    // Show the range field.
    var black = new Glyph(" ");
    for (var pos in _gameScreen.cameraBounds) {
      var tile = stage[pos];
      if (!tile.visible) {
        _gameScreen.drawStageGlyph(terminal, pos.x, pos.y, black);
        continue;
      }

      if (!tile.isWalkable && !tile.isFlyable) continue;
      if (stage.actorAt(pos) != null) continue;
      if (stage.isItemAt(pos)) continue;

      // Must be in range.
      var toPos = pos - _gameScreen.game.hero.pos;
      if (toPos > _range) {
        _gameScreen.drawStageGlyph(terminal, pos.x, pos.y, black);
        continue;
      }

      // Show the damage ranges.
      var color = gold;
      if (toPos > _range * 2 / 3) {
        color = persimmon;
      }

      var glyph = tile.type.appearance[1] as Glyph;
      _gameScreen.drawStageGlyph(
          terminal, pos.x, pos.y, new Glyph.fromCharCode(glyph.char, color));
    }

    var target = _gameScreen.currentTarget;
    if (target == null) return;

    // Show the path that the bolt will trace, stopping when it hits an
    // obstacle.
    int i = _animateOffset ~/ _ticksPerFrame;
    var reachedTarget = false;
    for (var pos in new Line(_gameScreen.game.hero.pos, target)) {
      // Note if we made it to the target.
      if (pos == target) {
        reachedTarget = true;
        break;
      }

      if (stage.actorAt(pos) != null) break;
      if (!stage[pos].isFlyable) break;

      _gameScreen.drawStageGlyph(terminal, pos.x, pos.y,
          new Glyph.fromCharCode(CharCode.bullet, (i == 0) ? gold : persimmon));
      i = (i + _numFrames - 1) % _numFrames;
    }

    // Only show the reticle if the bolt will reach the target.
    if (reachedTarget) {
      var targetColor = gold;
      var toTarget = target - _gameScreen.game.hero.pos;
      if (toTarget > _range * 2 / 3) {
        targetColor = persimmon;
      }

      _gameScreen.drawStageGlyph(
          terminal, target.x - 1, target.y, new Glyph('-', targetColor));
      _gameScreen.drawStageGlyph(
          terminal, target.x + 1, target.y, new Glyph('-', targetColor));
      _gameScreen.drawStageGlyph(
          terminal, target.x, target.y - 1, new Glyph('|', targetColor));
      _gameScreen.drawStageGlyph(
          terminal, target.x, target.y + 1, new Glyph('|', targetColor));
    }

    if (_monsters.isEmpty) {
      terminal.writeAt(0, terminal.height - 1, "[↕↔] Choose tile, [Esc] Cancel",
          UIHue.helpText);
    } else if (_targetingFloor) {
      terminal.writeAt(
          0,
          terminal.height - 1,
          "[↕↔] Choose tile, [Tab] Target monsters, [Esc] Cancel",
          UIHue.helpText);
    } else {
      terminal.writeAt(
          0,
          terminal.height - 1,
          "[↕↔] Choose monster, [Tab] Target floor, [Esc] Cancel",
          UIHue.helpText);
    }
  }

  /// Target the nearest monster in [dir] from the current target. Precisely,
  /// draws a line perpendicular to [dir] and divides the monsters into two
  /// half-planes. If the half-plane towards [dir] contains any monsters, then
  /// this targets the nearest one. Otherwise, it wraps around and targets the
  /// *farthest* monster in the other half-place.
  void _changeTarget(Direction dir) {
    if (_targetingFloor) {
      var pos = _gameScreen.currentTarget + dir;
      var tile = _gameScreen.game.stage[pos];
      if ((_gameScreen.game.hero.pos - pos) <= _range &&
          tile.isFlyable &&
          tile.visible) {
        _gameScreen.targetFloor(pos);
      }
    } else {
      var ahead = [];
      var behind = [];

      var perp = dir.rotateLeft90;
      for (var monster in _monsters) {
        var relative = monster.pos - _gameScreen.currentTarget;
        var dotProduct = perp.x * relative.y - perp.y * relative.x;
        if (dotProduct > 0) {
          ahead.add(monster);
        } else {
          behind.add(monster);
        }
      }

      var nearest = _findLowest(ahead,
          (monster) => (monster.pos - _gameScreen.currentTarget).lengthSquared);
      if (nearest != null) {
        _gameScreen.targetActor(nearest);
        return;
      }

      var farthest = _findHighest(behind,
          (monster) => (monster.pos - _gameScreen.currentTarget).lengthSquared);
      if (farthest != null) {
        _gameScreen.targetActor(farthest);
      }
    }
  }
}

/// Finds the item in [collection] whose score is lowest.
///
/// The score for an item is determined by calling [callback] on it. Returns
/// `null` if the [collection] is `null` or empty.
_findLowest(Iterable collection, num callback(item)) {
  if (collection == null) return null;

  var bestItem;
  var bestScore;

  for (var item in collection) {
    var score = callback(item);
    if (bestScore == null || score < bestScore) {
      bestItem = item;
      bestScore = score;
    }
  }

  return bestItem;
}

/// Finds the item in [collection] whose score is highest.
///
/// The score for an item is determined by calling [callback] on it. Returns
/// `null` if the [collection] is `null` or empty.
_findHighest(Iterable collection, num callback(item)) {
  if (collection == null) return null;

  var bestItem;
  var bestScore;

  for (var item in collection) {
    var score = callback(item);
    if (bestScore == null || score > bestScore) {
      bestItem = item;
      bestScore = score;
    }
  }

  return bestItem;
}
