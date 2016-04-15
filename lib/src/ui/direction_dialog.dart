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
  Direction _direction = Direction.none;

  bool get isTransparent => true;

  DirectionDialog(this._gameScreen, this._game);

  bool handleInput(Input input) {
    switch (input) {
      case Input.ok: ui.pop(_direction); break;
      case Input.cancel: ui.pop(Direction.none); break;

      case Input.nw: ui.pop(Direction.nw); break;
      case Input.n: ui.pop(Direction.n); break;
      case Input.ne: ui.pop(Direction.ne); break;
      case Input.w: ui.pop(Direction.w); break;
      case Input.e: ui.pop(Direction.e); break;
      case Input.sw: ui.pop(Direction.sw); break;
      case Input.s: ui.pop(Direction.s); break;
      case Input.se: ui.pop(Direction.se); break;
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
    draw(0, Direction.n, "|");
    draw(1, Direction.ne, "/");
    draw(2, Direction.e, "-");
    draw(3, Direction.se, r"\");
    draw(4, Direction.s, "|");
    draw(5, Direction.sw, "/");
    draw(6, Direction.w, "-");
    draw(7, Direction.nw, r"\");
  }
}
