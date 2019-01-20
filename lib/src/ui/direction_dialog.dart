import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'game_screen.dart';
import 'input.dart';

/// Modal dialog for letting the user select a [Direction] to perform a command.
abstract class DirectionDialog extends Screen<Input> {
  static const _numFrames = 8;
  static const _ticksPerFrame = 5;

  final GameScreen _gameScreen;

  int _animateOffset = 0;

  bool get isTransparent => true;

  Game get game => _gameScreen.game;

  String get query;

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
    draw(int frame, Direction dir, String char) {
      var pos = game.hero.pos + dir;
      if (!canTarget(game.stage[pos])) return;

      Glyph glyph;
      if (_animateOffset ~/ _ticksPerFrame == frame) {
        glyph = Glyph(char, gold, brown);
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

        glyph = Glyph.fromCharCode(glyph.char, gold, brown);
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

    Draw.helpKeys(terminal, {"↕↔": helpText, "Esc": "Cancel"}, query);
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

  String get query => "Which direction?";

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

/// Asks the user to select an adjacent tile to close.
class CloseDialog extends DirectionDialog {
  String get query => "Close what?";
  String get helpText => "Choose direction";

  CloseDialog(GameScreen gameScreen) : super(gameScreen);

  bool canTarget(Tile tile) => tile.type.canClose;

  bool tryDirection(Direction direction) {
    var pos = game.hero.pos + direction;
    var tile = game.stage[pos].type;
    if (tile.canClose) {
      game.hero.setNextAction(tile.onClose(pos));
      return true;
    } else {
      game.log.error('There is nothing to close there.');
      return false;
    }
  }
}

/// Asks the user to select an adjacent tile to open.
class OpenDialog extends DirectionDialog {
  String get query => "Open what?";
  String get helpText => "Choose direction";

  OpenDialog(GameScreen gameScreen) : super(gameScreen);

  bool canTarget(Tile tile) => tile.type.canOpen;

  bool tryDirection(Direction direction) {
    var pos = game.hero.pos + direction;
    var tile = game.stage[pos].type;
    if (tile.canOpen) {
      game.hero.setNextAction(tile.onOpen(pos));
      return true;
    } else {
      game.log.error('There is nothing to open there.');
      return false;
    }
  }
}
