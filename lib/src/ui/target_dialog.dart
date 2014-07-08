library hauberk.ui.target_dialog;

import '../engine.dart';
import '../util.dart';
import 'game_screen.dart';
import 'keyboard.dart';
import 'screen.dart';
import 'terminal.dart';

/// Modal dialog for letting the user select a direction to fire a missile.
class TargetDialog extends Screen {
  static const _NUM_FRAMES = 5;
  static const _TICKS_PER_FRAME = 5;

  final GameScreen _gameScreen;
  final Game _game;
  final num _minRange;
  final num _maxRange;
  final List<Monster> _monsters = <Monster>[];

  int _animateOffset = 0;

  // TODO: Don't store here, just get from game.
  Vec _target;

  TargetDialog(this._gameScreen, Game game, Command command)
      : _game = game,
        _minRange = command.getMinRange(game),
        _maxRange = command.getMaxRange(game) {
    // Default to targeting the nearest monster.
    var nearest;
    for (var actor in game.stage.actors) {
      if (actor is! Monster) continue;
      if (!_game.stage[actor.pos].visible) continue;

      // Must be within range.
      var toMonster = actor.pos - _game.hero.pos;
      if (toMonster > _maxRange) continue;

      _monsters.add(actor);

      if (nearest == null ||
          _game.hero.pos - actor.pos < _game.hero.pos - nearest.pos) {
        nearest = actor;
      }
    }

    if (nearest != null) {
      setTarget(nearest);
    } else {
      _target = game.hero.pos;
    }
  }

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
      case KeyCode.ESCAPE:
        ui.pop(false);
        break;

      case KeyCode.I: _changeTarget(Direction.NW); break;
      case KeyCode.O: _changeTarget(Direction.N); break;
      case KeyCode.P: _changeTarget(Direction.NE); break;
      case KeyCode.K: _changeTarget(Direction.W); break;
      case KeyCode.SEMICOLON: _changeTarget(Direction.E); break;
      case KeyCode.COMMA: _changeTarget(Direction.SW); break;
      case KeyCode.PERIOD: _changeTarget(Direction.S); break;
      case KeyCode.SLASH: _changeTarget(Direction.SE); break;

      case KeyCode.L:
        ui.pop(_target != _game.hero.pos);
        break;
    }

    return true;
  }

  void update() {
    _animateOffset = (_animateOffset + 1) % (_NUM_FRAMES * _TICKS_PER_FRAME);
    if (_animateOffset % _TICKS_PER_FRAME == 0) dirty();
  }

  void render(Terminal terminal) {
    // Show the range field.
    var reachedTarget = false;

    var black = new Glyph(" ");
    for (var pos in _game.stage.bounds) {
      var tile = _game.stage[pos];
      if (!tile.visible) {
        terminal.drawGlyph(pos.x, pos.y, black);
        continue;
      }

      if (!tile.isPassable) continue;
      if (_game.stage.actorAt(pos) != null) continue;
      if (_game.stage.itemAt(pos) != null) continue;

      // Must be in range.
      var toPos = pos - _game.hero.pos;
      if (toPos > _maxRange) {
        terminal.drawGlyph(pos.x, pos.y, black);
        continue;
      }

      // Show the damage ranges.
      var color = Color.YELLOW;
      if (toPos <= _minRange || toPos > _maxRange * 2 / 3) {
        color = Color.DARK_YELLOW;
      }

      var glyph = tile.type.appearance[1] as Glyph;
      terminal.drawGlyph(pos.x, pos.y,
          new Glyph.fromCharCode(glyph.char, color));
    }

    // Show the path that the bolt will trace, stopping when it hits an
    // obstacle.
    int i = _animateOffset ~/ _TICKS_PER_FRAME;
    if (_target != _game.hero.pos) {
      for (var pos in new Los(_game.hero.pos, _target)) {
        // Note if we made it to the target.
        if (pos == _target) {
          reachedTarget = true;
          break;
        }

        if (_game.stage.actorAt(pos) != null) break;
        if (!_game.stage[pos].isTransparent) break;

        terminal.drawGlyph(pos.x, pos.y, new Glyph.fromCharCode(CharCode.BULLET,
            (i == 0) ? Color.YELLOW : Color.DARK_YELLOW));
        i = (i + _NUM_FRAMES - 1) % _NUM_FRAMES;
      }
    }

    // Only show the reticle if the bolt will reach the target.
    if (reachedTarget) {
      var targetColor = Color.YELLOW;
      var toTarget = _target - _game.hero.pos;
      if (toTarget <= _minRange || toTarget > _maxRange * 2 / 3) {
        targetColor = Color.DARK_YELLOW;
      }

      terminal.writeAt(_target.x - 1, _target.y, '-', targetColor);
      terminal.writeAt(_target.x + 1, _target.y, '-', targetColor);
      terminal.writeAt(_target.x, _target.y - 1, '|', targetColor);
      terminal.writeAt(_target.x, _target.y + 1, '|', targetColor);
    }
  }

  void setTarget(Actor actor) {
    _target = actor.pos;
    _gameScreen.targetActor(actor);
    dirty();
  }

  /// Target the nearest monster in [dir] from the current target. Precisely,
  /// draws a line perpendicular to [dir] and divides the monsters into two
  /// half-planes. If the half-plane towards [dir] contains any monsters, then
  /// this targets the nearest one. Otherwise, it wraps around and targets the
  /// *farthest* monster in the other half-place.
  void _changeTarget(Direction dir) {
    var ahead = [];
    var behind = [];

    var perp = dir.rotateLeft90;
    for (var monster in _monsters) {
      var relative = monster.pos - _target;
      var dotProduct = perp.x * relative.y - perp.y * relative.x;
      if (dotProduct > 0) {
        ahead.add(monster);
      } else {
        behind.add(monster);
      }
    }

    var nearest = findLowest(ahead,
        (monster) => (monster.pos - _target).lengthSquared);
    if (nearest != null) {
      setTarget(nearest);
      return;
    }

    var farthest = findHighest(behind,
        (monster) => (monster.pos - _target).lengthSquared);
    if (farthest != null) {
      setTarget(farthest);
    }
  }
}

findLowest(Iterable collection, num callback(item)) {
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

findHighest(Iterable collection, num callback(item)) {
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
