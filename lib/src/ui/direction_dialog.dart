import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'game_screen.dart';
import 'input.dart';

/// Modal dialog for letting the user select a [Direction] to perform a
/// [DirectionSkill] in.
class DirectionDialog extends Screen<Input> {
  static const _numFrames = 8;
  static const _ticksPerFrame = 5;

  final GameScreen _gameScreen;
  final Game _game;
  final void Function(Direction direction) _onSelect;

  int _animateOffset = 0;

  bool get isTransparent => true;

  DirectionDialog(this._gameScreen, this._game, this._onSelect);

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
      var color = (_animateOffset ~/ _ticksPerFrame == frame)
          ? Color.yellow
          : Color.darkYellow;

      _gameScreen.drawStageGlyph(terminal, _game.hero.pos.x + dir.x,
          _game.hero.pos.y + dir.y, Glyph(char, color));
    }

    // TODO: Let skill filter out valid directions.
    draw(0, Direction.n, "|");
    draw(1, Direction.ne, "/");
    draw(2, Direction.e, "-");
    draw(3, Direction.se, r"\");
    draw(4, Direction.s, "|");
    draw(5, Direction.sw, "/");
    draw(6, Direction.w, "-");
    draw(7, Direction.nw, r"\");
  }

  void _select(Direction dir) {
    _onSelect(dir);
    ui.pop(dir);
  }
}
