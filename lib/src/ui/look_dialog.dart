import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine/hero/hero.dart';
import '../engine/monster/monster.dart';
import '../hues.dart';
import 'draw.dart';
import 'game_screen.dart';
import 'input.dart';

class LookDialog extends Screen<Input> {
  final GameScreen _gameScreen;

  Vec _lookedPosition = Vec.zero;

  @override
  bool get isTransparent => true;

  Vec get lookedPosition => _gameScreen.game.hero.pos + _lookedPosition;

  LookDialog(this._gameScreen);

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.cancel:
        ui.pop();
        return true;
      case Input.nw:
        moveDirection(Direction.nw);
      case Input.n:
        moveDirection(Direction.n);
      case Input.ne:
        moveDirection(Direction.ne);
      case Input.w:
        moveDirection(Direction.w);
      case Input.ok:
        resetDirection();
      case Input.e:
        moveDirection(Direction.e);
      case Input.sw:
        moveDirection(Direction.sw);
      case Input.s:
        moveDirection(Direction.s);
      case Input.se:
        moveDirection(Direction.se);
    }

    return false;
  }

  void moveDirection(Direction dir) {
    var previousPos = _lookedPosition;
    _lookedPosition += dir;

    var positionTile = _gameScreen.game.stage.tiles[lookedPosition];

    if (!positionTile.isExplored || !positionTile.isVisible) {
      _lookedPosition = previousPos;
    }

    dirty();
  }

  void resetDirection() {
    _gameScreen.game.stage.heroVisibilityChanged();
    _gameScreen.game.stage.refreshView();
    _gameScreen.dirty();

    _lookedPosition = Vec.zero;
  }

  @override
  void render(Terminal terminal) {
    Draw.helpKeys(terminal, {"↕↔": "Look around", "`": "Exit"});

    var leftWidth = 21;
    if (terminal.width > 160) {
      leftWidth = 29;
    } else if (terminal.width > 150) {
      leftWidth = 25;
    }

    print(leftWidth);
    Draw.frame(terminal, 0, terminal.height - 20, leftWidth, 20, color: gold);

    var targetPos = lookedPosition;

    var watchedTile = _gameScreen.game.stage.tiles[targetPos];

    var appearance = watchedTile.type.appearance;
    var glyph = switch (appearance) {
      Glyph() => appearance,
      List<Glyph>() => appearance.first,
      _ => Glyph('?', Color.white),
    };

    var y = terminal.height - 20 + 2;
    terminal.drawGlyph(2, y, glyph);
    terminal.writeAt(4, y, watchedTile.type.name, lightWarmGray);

    var actor = _gameScreen.game.stage.actorAt(targetPos);
    if (actor != null) {
      var glyph = switch (actor) {
        Monster() => actor.appearance as Glyph,
        Hero() => Glyph.fromCharCode(CharCode.at, Color.white),
        _ => Glyph.fromCharCode(CharCode.questionMark, Color.white),
      };

      var name = switch (actor) {
        Monster() => actor.breed.name,
        Hero() => actor.save.name,
        _ => 'Unknown',
      };

      y += 2;
      terminal.drawGlyph(2, y, glyph);
      terminal.writeAt(4, y, name, lightWarmGray);
    }

    var items = _gameScreen.game.stage.itemsAt(targetPos);
    if (items.isNotEmpty) {
      for (var i = 0; i < items.length; i++) {
        var item = items[i];
        var itemGlyph = item.appearance as Glyph;

        y += 2;
        terminal.drawGlyph(2, y, itemGlyph);
        terminal.writeAt(4, y, item.nounText, lightWarmGray);
      }
    }

    // These Color.black could be replaced with "transparent" but this would need a change to malison's Color class.
    _gameScreen.drawStageGlyph(terminal, targetPos.x - 1, targetPos.y, Glyph('-', gold, Color.black));
    _gameScreen.drawStageGlyph(terminal, targetPos.x + 1, targetPos.y, Glyph('-', gold, Color.black));
    _gameScreen.drawStageGlyph(terminal, targetPos.x, targetPos.y - 1, Glyph('|', gold, Color.black));
    _gameScreen.drawStageGlyph(terminal, targetPos.x, targetPos.y + 1, Glyph('|', gold, Color.black));
  }
}
