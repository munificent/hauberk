library hauberk.ui.close_door_dialog;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'input.dart';

/// Modal dialog for letting the user select an adjacent open door to close it.
class CloseDoorDialog extends Screen {
  final Game game;

  bool get isTransparent => true;

  CloseDoorDialog(this.game);

  bool handleInput(Input input) {
    switch (input) {
      case Input.CANCEL: ui.pop(); break;
      case Input.NW: tryClose(Direction.NW); break;
      case Input.N:  tryClose(Direction.N); break;
      case Input.NE: tryClose(Direction.NE); break;
      case Input.W:  tryClose(Direction.W); break;
      case Input.E:  tryClose(Direction.E); break;
      case Input.SW: tryClose(Direction.SW); break;
      case Input.S:  tryClose(Direction.S); break;
      case Input.SE: tryClose(Direction.SE); break;
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
