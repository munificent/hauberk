import 'dart:math';

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart';
import 'confirm_popup.dart';
import 'draw.dart';
import 'game_screen.dart';
import 'input.dart';
import 'new_hero_screen.dart';
import 'storage.dart';

const _chars = [
  r"_____ _____                 ____                     ____",
  r"\ . / \  ./                 \ .|                     \  |",
  r" | |   |.|                   | |                      |.|",
  r" |.|___| |  ____  ____ ____  |.| __     ____  ___  __ | |  ___",
  r" |::___::|  \:::\ \::| \::|  |:|/::\   /::::\ \::|/::\|:| /::/",
  r" |x|   |x|  __ \x| |x|  |x|  |x|  \x\ |x|__)x| |x| \x||x|/x/",
  r" |x|   |x| /xx\|x| |x|  |x|  |x|   |x||x|\xxx| |x|    |xxxx\",
  r" |X|   |X||X(__|X| |X\__|X|  |X|__/XX||X|____  |X|    |X| \X\",
  r" |X|   |X| \XXX/\X\ \XX/|XX\/XX/\XXX/  \XXXX/ /XXX\  /XXX\ \X\",
  r" |X|   |X|",
  r"_|X|   |X|_",
  r"\XX|   |XX/",
  r" \X|   |X/",
  r"  \|   |/",
];

const _charColors = [
  r"LLLLL LLLLL                 LLLL                     LLLL",
  r"ERRRE ERRRE                 ERRE                     ERRE",
  r" ERE   ERE                   ERE                      ERE",
  r" ERELLLERE  LLLL  LLLL LLLL  ERE LL     LLLL  LLL  LL ERE  LLL",
  r" ERREEERRE  ERRRE ERRE ERRE  EREERRL   LRRRRL ERRLLRRLERE LRRE",
  r" EOE   EOE  LL EOE EOE  EOE  EOE  EOL EOELLEOE EOE EOEEOELOE",
  r" EGE   EGE LGGEEGE EGE  EGE  EGE   EGEEGEEGGGE EGE    EGGGGL",
  r" EYE   EYEEYELLEYE EYLLLEYE  EYELLLYYEEYELLLL  EYE    EYE EYL",
  r" EYE   EYE EYYYEEYL EYYEEYYLLYYEEYYYE  EYYYYE LYYYL  LYYYL EYL",
  r" EYE   EYE",
  r"EEYE   EYEE",
  r"EYYE   EYYE",
  r" EYE   EYE",
  r"  EE   EE",
];

const _colors = {
  "L": lightWarmGray,
  "E": warmGray,
  "R": red,
  "O": carrot,
  "G": gold,
  "Y": yellow,
};

class MainMenuScreen extends Screen<Input> {
  /// The number of heroes shown in the list at one time.
  static const _listHeight = 8;

  final Content content;
  final Storage storage;
  int selectedHero = 0;

  Game? _game;
  Iterator<String>? _generator;
  bool _lightDungeon = false;

  /// After dungeon is done being generated, how many frames to wait before
  /// making a new one.
  int _regenerateDelay = 0;

  /// Whether there are any screens above this one.
  ///
  /// We only want to update when you're actually on the main menu.
  // TODO: This seems like something malison should be able to handle directly.
  bool _isActive = true;

  /// How far down in the list of heroes the user has scrolled.
  int _scroll = 0;

  MainMenuScreen(this.content) : storage = Storage(content);

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.n when selectedHero > 0:
        selectedHero--;
        _refreshScroll();
        dirty();
        return true;

      case Input.s when selectedHero < storage.heroes.length - 1:
        selectedHero++;
        _refreshScroll();
        dirty();
        return true;

      case Input.ok:
        if (selectedHero < storage.heroes.length) {
          var save = storage.heroes[selectedHero];
          _isActive = false;
          ui.push(GameScreen.town(storage, content, save));
        }
        return true;
    }

    return false;
  }

  void _refreshScroll() {
    // Keep it in bounds.
    _scroll = _scroll.clamp(0, max(storage.heroes.length - _listHeight, 0));

    // Show the selected hero.
    if (selectedHero < _scroll) {
      _scroll = selectedHero;
    } else if (selectedHero >= _scroll + _listHeight) {
      _scroll = selectedHero - _listHeight + 1;
    }
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.d:
        if (selectedHero < storage.heroes.length) {
          var name = storage.heroes[selectedHero].name;
          _isActive = false;
          ui.push(
            ConfirmPopup("Are you sure you want to delete $name?", 'delete'),
          );
        }
        return true;

      case KeyCode.n:
        _isActive = false;
        ui.push(NewHeroScreen(content, storage));
        return true;
    }

    return false;
  }

  @override
  void activate(Screen popped, Object? result) {
    _isActive = true;

    if (popped is ConfirmPopup && result == "delete") {
      storage.heroes.remove(storage.heroes[selectedHero]);

      // If they deleted the last hero, keep the selection in bounds.
      if (selectedHero > 0 && selectedHero >= storage.heroes.length) {
        selectedHero--;
      }

      _refreshScroll();
      dirty();
    }
  }

  @override
  void resize(Vec size) {
    // Clear the dungeon so we generate a new one at the new size.
    _game = null;
    _generator = null;
  }

  @override
  void update() {
    if (!_isActive) return;

    if (_regenerateDelay > 0) {
      _regenerateDelay--;

      if (_regenerateDelay == 0) {
        // Kick off a new dungeon generation.
        _game = null;
        dirty();
      }

      return;
    }

    if (_generator case var generator?) {
      if (!generator.moveNext()) {
        _generator = null;

        // Wait ten seconds before regenerating.
        _regenerateDelay = 60 * 5;
        return;
      }

      if (generator.current == "Ready to decorate") _lightDungeon = true;
      if (_lightDungeon) {
        _game!.stage.tileOpacityChanged();
        _game!.stage.refreshView();
      }
      dirty();
    }
  }

  @override
  void render(Terminal terminal) {
    if (_game case var game?) {
      _renderDungeon(terminal, game);
    } else {
      var save = content.createHero("Temporary");
      var game = _game = Game(
        content,
        rng.inclusive(1, Option.maxDepth),
        save,
        width: terminal.width,
        height: terminal.height,
      );

      _generator = game.generate().iterator;
      _lightDungeon = false;
      _renderDungeon(terminal, game);
    }

    // Center the content.
    var centerTerminal = terminal.rect(
      (terminal.width - 68) ~/ 2,
      (terminal.height - 34) ~/ 2,
      68,
      34,
    );

    centerTerminal.clear();
    Draw.doubleBox(
      centerTerminal,
      0,
      0,
      centerTerminal.width,
      centerTerminal.height,
    );

    for (var y = 0; y < _chars.length; y++) {
      for (var x = 0; x < _chars[y].length; x++) {
        var color = _colors[_charColors[y][x]];
        centerTerminal.writeAt(x + 3, y + 2, _chars[y][x], color);
      }
    }

    centerTerminal.writeAt(3, 18, 'Which hero shall you play?', UIHue.text);

    Draw.hLine(centerTerminal, 3, 20, centerTerminal.width - 6);
    Draw.hLine(centerTerminal, 3, 29, centerTerminal.width - 6);

    if (storage.heroes.isEmpty) {
      centerTerminal.writeAt(
        3,
        21,
        '(No heroes. Please create a new one.)',
        UIHue.disabled,
      );
    } else {
      if (_scroll > 0) {
        centerTerminal.writeAt(
          centerTerminal.width ~/ 2,
          20,
          "▲",
          UIHue.selection,
        );
      }

      if (_scroll < storage.heroes.length - _listHeight) {
        centerTerminal.writeAt(
          centerTerminal.width ~/ 2,
          29,
          "▼",
          UIHue.selection,
        );
      }

      for (var i = 0; i < _listHeight; i++) {
        var heroIndex = i + _scroll;
        if (heroIndex >= storage.heroes.length) break;

        var hero = storage.heroes[heroIndex];

        var primary = UIHue.primary;
        var secondary = UIHue.secondary;
        if (heroIndex == selectedHero) {
          primary = UIHue.selection;
          secondary = UIHue.selection;

          centerTerminal.drawChar(
            2,
            21 + i,
            CharCode.blackRightPointingPointer,
            UIHue.selection,
          );
        }

        centerTerminal.writeAt(3, 21 + i, hero.name, primary);
        centerTerminal.writeAt(25, 21 + i, "Level ${hero.level}", secondary);
        centerTerminal.writeAt(34, 21 + i, hero.race.name, secondary);
        centerTerminal.writeAt(42, 21 + i, hero.heroClass.name, secondary);
        if (hero.permadeath) {
          centerTerminal.writeAt(55, 21 + i, "Permadeath", secondary);
        }
      }
    }

    Draw.helpKeys(terminal, {
      "OK": "Play",
      "↕": "Change selection",
      "N": "Create a new hero",
      "D": "Delete hero",
    });
  }

  void _renderDungeon(Terminal terminal, Game game) {
    var stage = game.stage;

    for (var y = 0; y < stage.height; y++) {
      for (var x = 0; x < stage.width; x++) {
        var pos = Vec(x, y);
        _renderTile(terminal, game, pos);
      }
    }
  }

  void _renderTile(Terminal terminal, Game game, Vec pos) {
    var tile = game.stage[pos];

    var tileGlyph = switch (tile.type.appearance) {
      Glyph glyph => glyph,
      List<Glyph> glyphs =>
        // Calculate a "random" but consistent phase for each position.
        glyphs[hashPoint(pos.x, pos.y) % glyphs.length],
      _ => Glyph.clear,
    };

    var char = tileGlyph.char;
    var fore = tileGlyph.fore;
    var back = tileGlyph.back;
    var lightFore = true;
    var lightBack = true;

    // Show the item if the tile has been explored, even if not currently
    // visible.
    var items = game.stage.itemsAt(pos);
    if (items.isNotEmpty) {
      var itemGlyph = items.first.appearance as Glyph;
      char = itemGlyph.char;
      fore = itemGlyph.fore;
      lightFore = false;
    }

    // Show any actor on it.
    if (game.stage.actorAt(pos)?.appearance case Glyph actor) {
      char = actor.char;
      fore = actor.fore;
      lightFore = false;
    }

    Color multiply(Color a, Color b) {
      return Color(a.r * b.r ~/ 255, a.g * b.g ~/ 255, a.b * b.b ~/ 255);
    }

    // TODO: This could be cached if needed.
    var foreShadow = multiply(fore, const Color(80, 80, 95));
    var backShadow = multiply(back, const Color(20, 20, 35));

    // Apply lighting and visibility to the tile.
    Color applyLighting(Color color, Color shadow) {
      // Apply a slight brightness curve to either end of the range of
      // floor illumination. We keep most of the middle of the range flat
      // so that there is still a visible ramp down at the dark end and
      // just a small bloom around lights at the bright end.
      var visibility = tile.floorIllumination;
      if (visibility < 128) {
        color = color.blend(shadow, lerpDouble(visibility, 0, 127, 1.0, 0.0));
      } else if (visibility > 128) {
        color = color.add(ash, lerpDouble(visibility, 128, 255, 0.0, 0.2));
      }

      if (tile.actorIllumination > 0) {
        const glow = Color(200, 130, 0);
        color = color.add(
          glow,
          lerpDouble(tile.actorIllumination, 0, 255, 0.05, 0.1),
        );
      }

      return color;
    }

    if (lightFore) fore = applyLighting(fore, foreShadow);
    if (lightBack) back = applyLighting(back, backShadow);

    var glyph = Glyph.fromCharCode(char, fore, back);
    terminal.drawGlyph(pos.x, pos.y, glyph);
  }
}
