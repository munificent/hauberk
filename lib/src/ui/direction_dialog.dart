import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart';
import 'game_screen.dart';
import 'input.dart';

/// Modal dialog for letting the user select a [Direction] to perform a
/// [DirectionSkill] in.
abstract class DirectionDialog extends Screen<Input> {
  static const _numFrames = 8;
  static const _ticksPerFrame = 5;

  final GameScreen _gameScreen;

  int _animateOffset = 0;

  bool get isTransparent => true;

  Game get game => _gameScreen.game;

  String get question;

  String get helpText;

  DirectionDialog(this._gameScreen);

  bool handleInput(Input input) {
    switch (input) {
      case Input.cancel:
        _select(Direction.none);
        break;

      case Input.nw:
        _select(Direction.nw);
        break;
      case Input.n:
        _select(Direction.n);
        break;
      case Input.ne:
        _select(Direction.ne);
        break;
      case Input.w:
        _select(Direction.w);
        break;
      case Input.e:
        _select(Direction.e);
        break;
      case Input.sw:
        _select(Direction.sw);
        break;
      case Input.s:
        _select(Direction.s);
        break;
      case Input.se:
        _select(Direction.se);
        break;
    }

    return true;
  }

  void update() {
    _animateOffset = (_animateOffset + 1) % (_numFrames * _ticksPerFrame);
    if (_animateOffset % _ticksPerFrame == 0) dirty();
  }

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, question, UIHue.text);

    draw(int frame, Direction dir, String char) {
      var pos = game.hero.pos + dir;
      if (!canTarget(game.stage[pos])) return;

      Glyph glyph;
      if (_animateOffset ~/ _ticksPerFrame == frame) {
        glyph = Glyph(char, gold, garnet);
      } else {
        // TODO: TargetDialog and GameScreen have similar code. Unify?
        var actor = game.stage.actorAt(pos);
        if (actor != null) {
          glyph = actor.appearance as Glyph;
        } else {
          var items = game.stage.itemsAt(pos);
          if (items.isNotEmpty) {
            glyph = items.first.appearance as Glyph;
          } else {
            var tile = game.stage[pos];
            if (tile.isExplored) {
              glyph = tile.type.appearance as Glyph;
            } else {
              // Since the hero doesn't know what's on the tile, show it as a
              // blank highlighted tile.
              glyph = Glyph.fromCharCode(CharCode.space);
            }

            glyph = game.stage[pos].type.appearance as Glyph;
          }
        }

        glyph = Glyph.fromCharCode(glyph.char, gold, garnet);
      }

      _gameScreen.drawStageGlyph(terminal, pos.x, pos.y, glyph);
    }

    draw(0, Direction.n, "|");
    draw(1, Direction.ne, "/");
    draw(2, Direction.e, "-");
    draw(3, Direction.se, r"\");
    draw(4, Direction.s, "|");
    draw(5, Direction.sw, "/");
    draw(6, Direction.w, "-");
    draw(7, Direction.nw, r"\");

    terminal.writeAt(
        0, terminal.height - 1, "[↕↔] $helpText, [Esc] Cancel", UIHue.helpText);
  }

  void _select(Direction dir) {
    if (tryDirection(dir)) {
      ui.pop(dir);
    } else {
      ui.pop(Direction.none);
    }
  }

  bool canTarget(Tile tile);

  bool tryDirection(Direction dir);
}

/// Asks the user to select a direction for a [DirectionSkill].
class SkillDirectionDialog extends DirectionDialog {
  final void Function(Direction direction) _onSelect;

  String get question => "Which direction?";

  String get helpText => "Choose direction";

  SkillDirectionDialog(GameScreen gameScreen, this._onSelect)
      : super(gameScreen);

  // TODO: Let skill filter out invalid directions.
  bool canTarget(Tile tile) => true;

  bool tryDirection(Direction direction) {
    _onSelect(direction);
    return true;
  }
}

/// Asks the user to select an adjacent open door to close.
class CloseDoorDialog extends DirectionDialog {
  String get question => "Close which door?";
  String get helpText => "Choose door";

  CloseDoorDialog(GameScreen gameScreen) : super(gameScreen);

  bool canTarget(Tile tile) => tile.type.closesTo != null;

  bool tryDirection(Direction direction) {
    var pos = game.hero.pos + direction;
    if (game.stage[pos].type.closesTo != null) {
      game.hero.setNextAction(CloseDoorAction(pos));
      return true;
    } else {
      game.log.error('There is no open door there.');
      return false;
    }
  }
}

/// Asks the user to select an adjacent close door or other openable tile to
/// open it.
class OpenDialog extends DirectionDialog {
  String get question => "Open what?";
  String get helpText => "Choose direction";

  OpenDialog(GameScreen gameScreen) : super(gameScreen);

  // TODO: Handle chests.
  bool canTarget(Tile tile) => tile.type.opensTo != null;

  bool tryDirection(Direction direction) {
    var pos = game.hero.pos + direction;
    if (game.stage[pos].type.opensTo != null) {
      game.hero.setNextAction(OpenDoorAction(pos));
      return true;
    } else {
      game.log.error('There is nothing to open there.');
      return false;
    }
  }
}
