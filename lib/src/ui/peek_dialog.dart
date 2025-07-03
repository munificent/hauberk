import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../hues.dart';
import 'draw.dart';
import 'game_screen.dart';
import 'input.dart';

class PeekDialog extends Screen<Input> {
  final GameScreen _gameScreen;

  Vec _peekedPosition = Vec.zero;

  @override
  bool get isTransparent => true;

  PeekDialog(this._gameScreen);

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.cancel:
        peekDirection(Direction.none);
        ui.pop();
        return true;
      case Input.nw:
        peekDirection(Direction.nw);
      case Input.n:
        peekDirection(Direction.n);
      case Input.ne:
        peekDirection(Direction.ne);
      case Input.w:
        peekDirection(Direction.w);
      case Input.ok:
        resetDirection();
      case Input.e:
        peekDirection(Direction.e);
      case Input.sw:
        peekDirection(Direction.sw);
      case Input.s:
        peekDirection(Direction.s);
      case Input.se:
        peekDirection(Direction.se);
    }

    return false;
  }

  void peekDirection(Direction dir) {
    var hero = _gameScreen.game.hero;
    var previousPos = hero.pos;
    var pos = previousPos + dir;

    if (_gameScreen.game.stage.canOccupy(pos, hero.motility)) {
      hero.setPosition(_gameScreen.game, pos);
      _gameScreen.game.stage.heroVisibilityChanged();
      _gameScreen.game.stage.refreshView();
      _gameScreen.dirty();
      _peekedPosition = pos;
      hero.setPosition(_gameScreen.game, previousPos);
    } else {
      resetDirection();
    }
  }

  void resetDirection() {
    _gameScreen.game.stage.heroVisibilityChanged();
    _gameScreen.game.stage.refreshView();
    _gameScreen.dirty();

    _peekedPosition = Vec.zero;
  }

  @override
  void render(Terminal terminal) {
    if (_peekedPosition != Vec.zero) {
      _gameScreen.drawStageGlyph(terminal, _peekedPosition.x, _peekedPosition.y, Glyph.fromCharCode(CharCode.at, warmGray, brown));
    }

    Draw.helpKeys(terminal, {
      "↕↔": "Peek over direction",
      "``": "Exit"
    });
  }
}
