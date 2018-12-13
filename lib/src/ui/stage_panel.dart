import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import '../content/elements.dart';
import '../debug.dart';
import '../engine.dart';
import '../hues.dart';
import 'effect.dart';
import 'game_screen.dart';

/// The main gameplay area of the screen.
class StagePanel {
  static const _dazzleColors = [
    steelGray,
    slate,
    gunsmoke,
    ash,
    sandal,
    persimmon,
    copper,
    garnet,
    buttermilk,
    gold,
    carrot,
    mint,
    mustard,
    lima,
    peaGreen,
    sherwood,
    salmon,
    brickRed,
    maroon,
    lilac,
    violet,
    indigo,
    turquoise,
    cornflower,
    cerulean,
    ultramarine,
  ];

  static const _fireChars = [CharCode.blackUpPointingTriangle, CharCode.caret];
  static const _fireColors = [
    [gold, copper],
    [buttermilk, carrot],
    [persimmon, brickRed],
    [brickRed, garnet]
  ];

  final GameScreen _gameScreen;

  final _effects = <Effect>[];

  bool _hasAnimatedTile = false;

  int _frame = 0;

  Rect _cameraBounds;

  StagePanel(this._gameScreen) {
    _positionCamera();
  }

  /// The portion of the [Stage] currently in view on screen.
  Rect get cameraBounds => _cameraBounds;

  /// Draws [Glyph] at [x], [y] in [Stage] coordinates onto the current view.
  void drawStageGlyph(Terminal terminal, int x, int y, Glyph glyph) {
    terminal.drawGlyph(x - _cameraBounds.x, y - _cameraBounds.y, glyph);
  }

  bool update(Iterable<Event> events) {
    _frame++;

    for (final event in events) addEffects(_effects, event);

    var hadEffects = _effects.isNotEmpty;
    _effects.removeWhere((effect) => !effect.update(_gameScreen.game));

    _positionCamera();

    // TODO: Re-rendering the entire screen when only animated tiles have
    // changed is pretty rough on CPU usage. Maybe optimize to only redraw the
    // animated tiles if that's all that happened in a turn?
    return _hasAnimatedTile ||
        hadEffects ||
        _effects.isNotEmpty ||
        _gameScreen.game.hero.dazzle.isActive;
  }

  void render(
      Terminal terminal, Color heroColor, List<Monster> visibleMonsters) {
    _hasAnimatedTile = false;

    var game = _gameScreen.game;
    var hero = game.hero;

    // Draw the tiles and items.
    for (var pos in _cameraBounds) {
      var tile = game.stage[pos];
      var actor = game.stage.actorAt(pos);

      // Skip the tile if not known.
      if (!tile.isExplored &&
          (!Debug.showMonsterAlertness || actor == null) &&
          !Debug.showHeroVolume) {
        continue;
      }

      // Even if not currently visible, if explored we can see the tile itself.
      var tileGlyph = _tileGlyph(pos, tile);

      var char = tileGlyph.char;
      var fore = tileGlyph.fore;
      var back = tileGlyph.back;
      var isThing = false;

      // Show the item if the tile has been explored, even if not currently
      // visible.
      // TODO: If an item is picked up or destroyed while not visible, the
      // player will see it. Should they?
      var items = game.stage.itemsAt(pos);
      if (items.isNotEmpty) {
        var itemGlyph = items.first.appearance as Glyph;
        char = itemGlyph.char;
        fore = itemGlyph.fore;
        isThing = true;
      }

      // If the tile is currently visible, show any actor on it.
      if (tile.isVisible ||
          pos == game.hero.pos ||
          Debug.showAllMonsters && actor != null) {
        if (tile.substance != 0) {
          if (tile.element == Elements.fire) {
            char = rng.item(_fireChars);
            var color = rng.item(_fireColors);
            fore = color[0];
            back = color[1];

            _hasAnimatedTile = true;
          } else if (tile.element == Elements.poison) {
            var amount = 0.1 + (tile.substance / 255) * 0.9;
            back = back.blend(lima, amount);
          }
        }

        var actor = game.stage.actorAt(pos);
        if (actor != null) {
          var actorGlyph = actor.appearance;
          if (actorGlyph is Glyph) {
            char = actorGlyph.char;
            fore = actorGlyph.fore;
          } else {
            // Hero.
            char = CharCode.at;
            fore = heroColor;
          }

          // If the actor is being targeted, invert its colors.
          if (_gameScreen.currentTargetActor == actor) {
            back = fore;
            fore = midnight;
          }

          if (actor is Monster) visibleMonsters.add(actor);
          isThing = true;
        }
      }

      if (hero.dazzle.isActive) {
        var chance = math.min(90, hero.dazzle.duration * 8);
        if (rng.percent(chance)) {
          char = rng.percent(chance) ? char : CharCode.asterisk;
          fore = rng.item(_dazzleColors);
        }
      }

      // Apply lighting and visibility to the tile.
      if (tile.isVisible) {
        // If we ramp the lighting so that only maximum lighting is fully
        // illuminated, then the dungeon looks much too gloomy. Instead,
        // anything above 50% lit is shown at full brightness. We square the
        // value to ramp things down more quickly below that, and we allow
        // brightness to go a little past 1.0 so that things above 128 have
        // a little more glow.
        var light = (tile.visibility / 128);
        light = (light * light).clamp(0.0, 1.1);

        const shadow = Color(0x04, 0x03, 0xa);

        // Show tiles containing interesting things more brightly.
        if (isThing) {
          fore = shadow.blend(fore, light * 0.3 + 0.7);
        } else {
          fore = shadow.blend(fore, light * 0.7 + 0.3);
        }

        if (back == midnight) {
          // Hackish. If the background color is the default dark color, then
          // boost it *past* its max value to add some extra glow when well
          // lit.
          back = shadow.blend(back, light * 1.1 + 0.2);
        } else {
          back = shadow.blend(back, light * 0.8 + 0.2);
        }
      } else {
        const blueShadow = Color(0x00, 0x00, 0xe);

        // Show tiles containing interesting things more brightly.
        fore = blueShadow.blend(fore, isThing ? 0.7 : 0.2);

        if (back == midnight) {
          // If the background color is the default dark color, then go all
          // the way to black. This makes it easier for the player to tell
          // which tiles are not visible.
          back = Color.black;
        } else {
          back = blueShadow.blend(back, 0.1);
        }
      }

      if (Debug.showHeroVolume) {
        var volume = game.stage.heroVolume(pos);
        if (volume > 0.0) back = back.blend(peaGreen, volume);
      }

      if (Debug.showMonsterAlertness && actor is Monster) {
        back = Color.blue.blend(Color.red, actor.alertness);
      }

      var glyph = Glyph.fromCharCode(char, fore, back);
      drawStageGlyph(terminal, pos.x, pos.y, glyph);
    }

    // Draw the effects.
    for (var effect in _effects) {
      effect.render(game, (x, y, glyph) {
        drawStageGlyph(terminal, x, y, glyph);
      });
    }
  }

  /// Gets the [Glyph] to render for [tile].
  Glyph _tileGlyph(Vec pos, Tile tile) {
    // If the appearance is a single glyph, it's a normal tile.
    if (tile.type.appearance is Glyph) return tile.type.appearance;

    // Otherwise it's an animated tile, like water.
    var glyphs = tile.type.appearance as List<Glyph>;

    // Ping pong back and forth.
    var period = glyphs.length * 2 - 2;

    // Calculate a "random" but consistent phase for each position.
    var phase = hashPoint(pos.x, pos.y);
    var frame = (_frame ~/ 8 + phase) % period;
    if (frame >= glyphs.length) {
      frame = glyphs.length - (frame - glyphs.length) - 1;
    }

    _hasAnimatedTile = true;
    return glyphs[frame];
  }

  /// Determines which portion of the [Stage] should be in view based on the
  /// position of the [Hero].
  void _positionCamera() {
    var game = _gameScreen.game;

    // Handle the stage being smaller than the view.
    var rangeWidth = math.max(0, game.stage.width - _gameScreen.viewSize.x);
    var rangeHeight = math.max(0, game.stage.height - _gameScreen.viewSize.y);

    var cameraRange = Rect(0, 0, rangeWidth, rangeHeight);

    var camera = game.hero.pos - _gameScreen.viewSize ~/ 2;
    camera = cameraRange.clamp(camera);
    _cameraBounds = Rect(
        camera.x,
        camera.y,
        math.min(_gameScreen.viewSize.x, game.stage.width),
        math.min(_gameScreen.viewSize.y, game.stage.height));
  }
}
