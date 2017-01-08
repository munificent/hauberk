import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'input.dart';

/// Modal dialog for letting the user select an adjacent open door to close it.
class CloseDoorDialog extends Screen<Input> {
  final Game game;

  bool get isTransparent => true;

  CloseDoorDialog(this.game);

  bool handleInput(Input input) {
    switch (input) {
      case Input.cancel: ui.pop(); break;
      case Input.nw: tryClose(Direction.nw); break;
      case Input.n:  tryClose(Direction.n); break;
      case Input.ne: tryClose(Direction.ne); break;
      case Input.w:  tryClose(Direction.w); break;
      case Input.e:  tryClose(Direction.e); break;
      case Input.sw: tryClose(Direction.sw); break;
      case Input.s:  tryClose(Direction.s); break;
      case Input.se: tryClose(Direction.se); break;
    }

    return true;
  }

  bool update() => false;

  void render(Terminal terminal) {
    terminal.writeAt(0, 0, 'Close which door?');
  }

  void tryClose(Direction direction) {
    final pos = game.hero.pos + direction;
    if (game.stage[pos].type.closesTo != null) {
      game.hero.setNextAction(new CloseDoorAction(pos));
      ui.pop();
    } else {
      game.log.error('There is not an open door there.');
      dirty();
    }
  }
}
