library hauberk.ui.direction_dialog;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'game_screen.dart';
import 'input.dart';

/// Modal dialog for letting the user select a [Direction] to perform a
/// [Command] in.
class DirectionDialog extends Screen {
  static const _numFrames = 8;
  static const _ticksPerFrame = 5;

  final GameScreen _gameScreen;
  final Game _game;

  int _animateOffset = 0;

  /// The selected [Direction].
  Direction _direction = Direction.NONE;

  bool get isTransparent => true;

  DirectionDialog(this._gameScreen, this._game);

  bool handleInput(Input input) {
    switch (input) {
      case Input.ok: ui.pop(_direction); break;
      case Input.cancel: ui.pop(Direction.NONE); break;

      case Input.nw: ui.pop(Direction.NW); break;
      case Input.n: ui.pop(Direction.N); break;
      case Input.ne: ui.pop(Direction.NE); break;
      case Input.w: ui.pop(Direction.W); break;
      case Input.e: ui.pop(Direction.E); break;
      case Input.sw: ui.pop(Direction.SW); break;
      case Input.s: ui.pop(Direction.S); break;
      case Input.se: ui.pop(Direction.SE); break;
    }

    return true;
  }

  void update() {
    _animateOffset = (_animateOffset + 1) % (_numFrames * _ticksPerFrame);
    if (_animateOffset % _ticksPerFrame == 0) dirty();
  }

  void render(Terminal terminal) {
    draw(int frame, Direction dir, String char) {
      var color = (_animateOffset ~/ _ticksPerFrame == frame) ?
          Color.yellow : Color.darkYellow;

      _gameScreen.drawStageGlyph(terminal,
          _game.hero.pos.x + dir.x, _game.hero.pos.y + dir.y,
          new Glyph(char, color));
    }

    // TODO: Let command filter out valid directions.
    draw(0, Direction.N, "|");
    draw(1, Direction.NE, "/");
    draw(2, Direction.E, "-");
    draw(3, Direction.SE, r"\");
    draw(4, Direction.S, "|");
    draw(5, Direction.SW, "/");
    draw(6, Direction.W, "-");
    draw(7, Direction.NW, r"\");
  }
}
