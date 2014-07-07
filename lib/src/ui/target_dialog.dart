library hauberk.ui.target_dialog;

import '../engine.dart';
import '../util.dart';
import 'game_screen.dart';
import 'keyboard.dart';
import 'screen.dart';
import 'terminal.dart';

/// Modal dialog for letting the user select a direction to fire a missile.
class TargetDialog extends Screen {
  static const NUM_FRAMES = 5;
  static const TICKS_PER_FRAME = 5;

  final GameScreen gameScreen;
  final Game game;
  final List<Monster> monsters = <Monster>[];

  int animateOffset = 0;

  // TODO(bob): Don't store here, just get from game.
  Vec target;

  TargetDialog(this.gameScreen, this.game) {
    // Default to targeting the nearest monster.
    var nearest;
    for (var actor in game.stage.actors) {
      if (actor is! Monster) continue;
      if (!game.stage[actor.pos].visible) continue;

      monsters.add(actor);

      if (nearest == null ||
          game.hero.pos - actor.pos < game.hero.pos - nearest.pos) {
        nearest = actor;
      }
    }

    if (nearest != null) {
      setTarget(nearest);
    } else {
      target = game.hero.pos;
    }
  }

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
      case KeyCode.ESCAPE:
        ui.pop(false);
        break;

      case KeyCode.I: changeTarget(Direction.NW); break;
      case KeyCode.O: changeTarget(Direction.N); break;
      case KeyCode.P: changeTarget(Direction.NE); break;
      case KeyCode.K: changeTarget(Direction.W); break;
      case KeyCode.SEMICOLON: changeTarget(Direction.E); break;
      case KeyCode.COMMA: changeTarget(Direction.SW); break;
      case KeyCode.PERIOD: changeTarget(Direction.S); break;
      case KeyCode.SLASH: changeTarget(Direction.SE); break;

      case KeyCode.L:
        ui.pop(target != game.hero.pos);
        break;
    }

    return true;
  }

  void update() {
    animateOffset = (animateOffset + 1) % (NUM_FRAMES * TICKS_PER_FRAME);
    if (animateOffset % TICKS_PER_FRAME == 0) dirty();
  }

  void render(Terminal terminal) {
    // Show the path that the bolt will trace, stopping when it hits an
    // obstacle.
    int i = animateOffset ~/ TICKS_PER_FRAME;
    if (target != game.hero.pos) {
      for (var pos in new Los(game.hero.pos, target)) {
        if (game.stage.actorAt(pos) != null) break;
        if (!game.stage[pos].isTransparent) break;

        terminal.drawGlyph(pos.x, pos.y, new Glyph.fromCharCode(CharCode.BULLET,
            (i == 0) ? Color.YELLOW : Color.DARK_YELLOW));
        i = (i + NUM_FRAMES - 1) % NUM_FRAMES;
      }
    }

    terminal.writeAt(target.x - 1, target.y, '-', Color.YELLOW);
    terminal.writeAt(target.x + 1, target.y, '-', Color.YELLOW);
    terminal.writeAt(target.x, target.y - 1, '|', Color.YELLOW);
    terminal.writeAt(target.x, target.y + 1, '|', Color.YELLOW);
  }

  void setTarget(Actor actor) {
    target = actor.pos;
    gameScreen.targetActor(actor);
    dirty();
  }

  /// Target the nearest monster in [dir] from the current target. Precisely,
  /// draws a line perpendicular to [dir] and divides the monsters into two
  /// half-planes. If the half-plane towards [dir] contains any monsters, then
  /// this targets the nearest one. Otherwise, it wraps around and targets the
  /// *farthest* monster in the other half-place.
  void changeTarget(Direction dir) {
    var ahead = [];
    var behind = [];

    var perp = dir.rotateLeft90;
    for (var monster in monsters) {
      var relative = monster.pos - target;
      var dotProduct = perp.x * relative.y - perp.y * relative.x;
      if (dotProduct > 0) {
        ahead.add(monster);
      } else {
        behind.add(monster);
      }
    }

    var nearest = findLowest(ahead,
        (monster) => (monster.pos - target).lengthSquared);
    if (nearest != null) {
      setTarget(nearest);
      return;
    }

    var farthest = findHighest(behind,
        (monster) => (monster.pos - target).lengthSquared);
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
