import 'dart:html' as html;
import 'dart:js';
import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/debug.dart';
import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/ui/game_screen.dart';
import 'package:hauberk/src/ui/input.dart';
import 'package:hauberk/src/ui/main_menu_screen.dart';

final _fonts = <TerminalFont>[];
UserInterface<Input> _ui;
TerminalFont _font;

final Set<Monster> _debugMonsters = {};

class TerminalFont {
  final String name;
  final html.CanvasElement canvas;
  RenderableTerminal terminal;
  final int charWidth;
  final int charHeight;

  TerminalFont(this.name, this.canvas, this.terminal,
      {this.charWidth, this.charHeight});
}

void main() {
  var content = createContent();

  _addFont("8x8", 8);
  _addFont("8x10", 8, 10);
  _addFont("9x12", 9, 12);
  _addFont("10x12", 10, 12);
  _addFont("16x16", 16);
  _addFont("16x20", 16, 20);

  // Load the user's font preference, if any.
  var fontName = html.window.localStorage["font"];
  _font = _fonts[1];
  for (var thisFont in _fonts) {
    if (thisFont.name == fontName) {
      _font = thisFont;
      break;
    }
  }

  var div = html.querySelector("#game");
  div.append(_font.canvas);

  // Scale the terminal to fit the screen.
  html.window.onResize.listen((_) {
    _resizeTerminal();
  });

  _ui = UserInterface<Input>(_font.terminal);

  // Set up the keyPress.
  _ui.keyPress.bind(Input.ok, KeyCode.enter);
  _ui.keyPress.bind(Input.cancel, KeyCode.escape);
  _ui.keyPress.bind(Input.cancel, KeyCode.backtick);
  _ui.keyPress.bind(Input.forfeit, KeyCode.f, shift: true);
  _ui.keyPress.bind(Input.quit, KeyCode.q);

  _ui.keyPress.bind(Input.open, KeyCode.c, shift: true);
  _ui.keyPress.bind(Input.close, KeyCode.c);
  _ui.keyPress.bind(Input.drop, KeyCode.d);
  _ui.keyPress.bind(Input.use, KeyCode.u);
  _ui.keyPress.bind(Input.pickUp, KeyCode.g);
  _ui.keyPress.bind(Input.swap, KeyCode.x);
  _ui.keyPress.bind(Input.equip, KeyCode.e);
  _ui.keyPress.bind(Input.toss, KeyCode.t);
  _ui.keyPress.bind(Input.selectSkill, KeyCode.s);
  _ui.keyPress.bind(Input.heroInfo, KeyCode.a);
  _ui.keyPress.bind(Input.editSkills, KeyCode.s, shift: true);

  // Laptop directions.
  _ui.keyPress.bind(Input.nw, KeyCode.i);
  _ui.keyPress.bind(Input.n, KeyCode.o);
  _ui.keyPress.bind(Input.ne, KeyCode.p);
  _ui.keyPress.bind(Input.w, KeyCode.k);
  _ui.keyPress.bind(Input.e, KeyCode.semicolon);
  _ui.keyPress.bind(Input.sw, KeyCode.comma);
  _ui.keyPress.bind(Input.s, KeyCode.period);
  _ui.keyPress.bind(Input.se, KeyCode.slash);
  _ui.keyPress.bind(Input.runNW, KeyCode.i, shift: true);
  _ui.keyPress.bind(Input.runN, KeyCode.o, shift: true);
  _ui.keyPress.bind(Input.runNE, KeyCode.p, shift: true);
  _ui.keyPress.bind(Input.runW, KeyCode.k, shift: true);
  _ui.keyPress.bind(Input.runE, KeyCode.semicolon, shift: true);
  _ui.keyPress.bind(Input.runSW, KeyCode.comma, shift: true);
  _ui.keyPress.bind(Input.runS, KeyCode.period, shift: true);
  _ui.keyPress.bind(Input.runSE, KeyCode.slash, shift: true);
  _ui.keyPress.bind(Input.fireNW, KeyCode.i, alt: true);
  _ui.keyPress.bind(Input.fireN, KeyCode.o, alt: true);
  _ui.keyPress.bind(Input.fireNE, KeyCode.p, alt: true);
  _ui.keyPress.bind(Input.fireW, KeyCode.k, alt: true);
  _ui.keyPress.bind(Input.fireE, KeyCode.semicolon, alt: true);
  _ui.keyPress.bind(Input.fireSW, KeyCode.comma, alt: true);
  _ui.keyPress.bind(Input.fireS, KeyCode.period, alt: true);
  _ui.keyPress.bind(Input.fireSE, KeyCode.slash, alt: true);

  _ui.keyPress.bind(Input.ok, KeyCode.l);
  _ui.keyPress.bind(Input.rest, KeyCode.l, shift: true);
  _ui.keyPress.bind(Input.fire, KeyCode.l, alt: true);

  // Arrow keys.
  _ui.keyPress.bind(Input.n, KeyCode.up);
  _ui.keyPress.bind(Input.w, KeyCode.left);
  _ui.keyPress.bind(Input.e, KeyCode.right);
  _ui.keyPress.bind(Input.s, KeyCode.down);
  _ui.keyPress.bind(Input.runN, KeyCode.up, shift: true);
  _ui.keyPress.bind(Input.runW, KeyCode.left, shift: true);
  _ui.keyPress.bind(Input.runE, KeyCode.right, shift: true);
  _ui.keyPress.bind(Input.runS, KeyCode.down, shift: true);
  _ui.keyPress.bind(Input.fireN, KeyCode.up, alt: true);
  _ui.keyPress.bind(Input.fireW, KeyCode.left, alt: true);
  _ui.keyPress.bind(Input.fireE, KeyCode.right, alt: true);
  _ui.keyPress.bind(Input.fireS, KeyCode.down, alt: true);

  // Numeric keypad.
  _ui.keyPress.bind(Input.nw, KeyCode.numpad7);
  _ui.keyPress.bind(Input.n, KeyCode.numpad8);
  _ui.keyPress.bind(Input.ne, KeyCode.numpad9);
  _ui.keyPress.bind(Input.w, KeyCode.numpad4);
  _ui.keyPress.bind(Input.e, KeyCode.numpad6);
  _ui.keyPress.bind(Input.sw, KeyCode.numpad1);
  _ui.keyPress.bind(Input.s, KeyCode.numpad2);
  _ui.keyPress.bind(Input.se, KeyCode.numpad3);
  _ui.keyPress.bind(Input.runNW, KeyCode.numpad7, shift: true);
  _ui.keyPress.bind(Input.runN, KeyCode.numpad8, shift: true);
  _ui.keyPress.bind(Input.runNE, KeyCode.numpad9, shift: true);
  _ui.keyPress.bind(Input.runW, KeyCode.numpad4, shift: true);
  _ui.keyPress.bind(Input.runE, KeyCode.numpad6, shift: true);
  _ui.keyPress.bind(Input.runSW, KeyCode.numpad1, shift: true);
  _ui.keyPress.bind(Input.runS, KeyCode.numpad2, shift: true);
  _ui.keyPress.bind(Input.runSE, KeyCode.numpad3, shift: true);

  _ui.keyPress.bind(Input.ok, KeyCode.numpad5);
  _ui.keyPress.bind(Input.rest, KeyCode.numpad5, shift: true);
  _ui.keyPress.bind(Input.fire, KeyCode.numpad5, alt: true);

  _ui.keyPress.bind(Input.wizard, KeyCode.w, shift: true, alt: true);

  _ui.push(MainMenuScreen(content));

  _ui.handlingInput = true;
  _ui.running = true;

  if (Debug.enabled) {
    html.document.body.onKeyDown.listen((_) {
      _refreshDebugBoxes();
    });
  }
}

void _addFont(String name, int charWidth, [int charHeight]) {
  charHeight ??= charWidth;

  var canvas = html.CanvasElement();
  canvas.onDoubleClick.listen((_) {
    _fullscreen();
  });

  var terminal = _makeTerminal(canvas, charWidth, charHeight);
  _fonts.add(TerminalFont(name, canvas, terminal,
      charWidth: charWidth, charHeight: charHeight));

  if (Debug.enabled) {
    // Clicking a monster toggles its debug pane.
    canvas.onClick.listen((event) {
      var gameScreen = Debug.gameScreen as GameScreen;
      if (gameScreen == null) return;

      var pixel = Vec(event.offset.x.toInt(), event.offset.y.toInt());
      var pos = terminal.pixelToChar(pixel);

      var absolute = pos + gameScreen.cameraBounds.topLeft;
      if (!gameScreen.cameraBounds.contains(absolute)) return;

      var actor = gameScreen.game.stage.actorAt(absolute);
      if (actor is Monster) {
        if (_debugMonsters.contains(actor)) {
          _debugMonsters.remove(actor);
        } else {
          _debugMonsters.add(actor);
        }

        _refreshDebugBoxes();
      }
    });
  }

  // Make a button for it.
  var button = html.ButtonElement();
  button.innerHtml = name;
  button.onClick.listen((_) {
    for (var i = 0; i < _fonts.length; i++) {
      if (_fonts[i].name == name) {
        _font = _fonts[i];
        html.querySelector("#game").append(_font.canvas);
      } else {
        _fonts[i].canvas.remove();
      }
    }

    _resizeTerminal();

    if (Debug.enabled) _refreshDebugBoxes();

    // Remember the preference.
    html.window.localStorage['font'] = name;
  });

  html.querySelector('.button-bar').children.add(button);
}

RetroTerminal _makeTerminal(
    html.CanvasElement canvas, int charWidth, int charHeight) {
  var width = (html.document.body.clientWidth - 20) ~/ charWidth;
  var height = (html.document.body.clientHeight - 30) ~/ charHeight;

  width = math.max(width, 80);
  height = math.max(height, 40);

  var scale = html.window.devicePixelRatio.toInt();
  var canvasWidth = charWidth * width;
  var canvasHeight = charHeight * height;
  canvas.width = canvasWidth * scale;
  canvas.height = canvasHeight * scale;
  canvas.style.width = "${canvasWidth}px";
  canvas.style.height = "${canvasHeight}px";

  // Make the terminal.
  var file = "font_$charWidth";
  if (charWidth != charHeight) file += "_$charHeight";
  return RetroTerminal(width, height, "$file.png",
      canvas: canvas, charWidth: charWidth, charHeight: charHeight);
}

/// Updates the character dimensions of the current terminal to fit the screen
/// size.
void _resizeTerminal() {
  var terminal = _makeTerminal(_font.canvas, _font.charWidth, _font.charHeight);

  _font.terminal = terminal;
  _ui.setTerminal(terminal);
}

/// See: https://stackoverflow.com/a/29715395/9457
void _fullscreen() {
  var div = html.querySelector("#game");
  var jsElement = JsObject.fromBrowserObject(div);

  var methods = [
    "requestFullscreen",
    "mozRequestFullScreen",
    "webkitRequestFullscreen",
    "msRequestFullscreen"
  ];
  for (var method in methods) {
    if (jsElement.hasProperty(method)) {
      jsElement.callMethod(method);
      return;
    }
  }
}

void _refreshDebugBoxes() async {
  // Hack: Give the engine a chance to update.
  await html.window.animationFrame;

  for (var debugBox in html.querySelectorAll(".debug")) {
    html.document.body.children.remove(debugBox);
  }

  var gameScreen = Debug.gameScreen as GameScreen;

  _debugMonsters.removeWhere((monster) => !monster.isAlive);
  for (var monster in _debugMonsters) {
    if (gameScreen.cameraBounds.contains(monster.pos)) {
      var screenPos = monster.pos - gameScreen.cameraBounds.topLeft;

      var info = Debug.monsterInfo(monster);
      if (info == null) continue;

      var debugBox = html.PreElement();
      debugBox.className = "debug";
      debugBox.style.display = "inline-block";

      var x = (screenPos.x + 1) * _font.charWidth +
          _font.canvas.offset.left.toInt() +
          4;
      var y = (screenPos.y) * _font.charHeight +
          _font.canvas.offset.top.toInt() +
          2;
      debugBox.style.left = x.toString();
      debugBox.style.top = y.toString();
      debugBox.text = info;

      html.document.body.children.add(debugBox);
    }
  }
}
