library hauberk.web.main;

import 'dart:html' as html;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/debug.dart';
import 'package:hauberk/src/ui/input.dart';
import 'package:hauberk/src/ui/main_menu_screen.dart';

const WIDTH = 100;
const HEIGHT = 40;

final terminals = [];
UserInterface ui;

addTerminal(String name, html.Element element,
    RenderableTerminal terminalCallback(html.Element element)) {

  // Make the terminal.
  var terminal = terminalCallback(element);
  terminals.add([name, element, terminal]);

  if (Debug.ENABLED) {
    var debugBox = new html.PreElement();
    debugBox.id = "debug";
    html.document.body.children.add(debugBox);

    var lastPos;
    element.onMouseMove.listen((event) {
      // TODO: This is broken now that maps scroll. :(
      var pixel = new Vec(event.offset.x - 4, event.offset.y - 4);
      var pos = terminal.pixelToChar(pixel);
      var absolute = pixel + new Vec(element.offsetLeft, element.offsetTop);
      if (pos != lastPos) debugHover(debugBox, absolute, pos);
      lastPos = pos;
    });
  }

  // Make a button for it.
  var button = new html.ButtonElement();
  button.innerHtml = name;
  button.onClick.listen((_) {
    for (var i = 0; i < terminals.length; i++) {
      if (terminals[i][0] == name) {
        html.querySelector("#game").append(terminals[i][1]);
      } else {
        terminals[i][1].remove();
      }
    }
    ui.setTerminal(terminal);

    // Remember the preference.
    html.window.localStorage['font'] = name;
  });

  html.querySelector('.button-bar').children.add(button);
}

main() {
  var content = createContent();

  addTerminal('Courier', new html.CanvasElement(),
      (element) => new CanvasTerminal(WIDTH, HEIGHT,
          new Font('"Courier New"', size: 12, w: 8, h: 14, x: 1, y: 11),
          element));

  addTerminal('Menlo', new html.CanvasElement(),
      (element) => new CanvasTerminal(WIDTH, HEIGHT,
          new Font('Menlo', size: 12, w: 8, h: 13, x: 1, y: 11), element));

  addTerminal('DOS', new html.CanvasElement(),
      (element) => new RetroTerminal.dos(WIDTH, HEIGHT, element));

  addTerminal('DOS Short', new html.CanvasElement(),
      (element) => new RetroTerminal.shortDos(WIDTH, HEIGHT, element));

  // Load the user's font preference, if any.
  var font = html.window.localStorage['font'];
  var fontIndex = 3;
  for (var i = 0; i < terminals.length; i++) {
    if (terminals[i][0] == font) {
      fontIndex = i;
      break;
    }
  }

  html.querySelector("#game").append(terminals[fontIndex][1]);

  ui = new UserInterface(terminals[fontIndex][2]);

  // Set up the keyPress.
  ui.keyPress.bind(Input.OK, KeyCode.enter);
  ui.keyPress.bind(Input.CANCEL, KeyCode.escape);
  ui.keyPress.bind(Input.FORFEIT, KeyCode.f, shift: true);
  ui.keyPress.bind(Input.QUIT, KeyCode.q);

  ui.keyPress.bind(Input.CLOSE_DOOR, KeyCode.c);
  ui.keyPress.bind(Input.DROP, KeyCode.d);
  ui.keyPress.bind(Input.USE, KeyCode.u);
  ui.keyPress.bind(Input.PICK_UP, KeyCode.g);
  ui.keyPress.bind(Input.SWAP, KeyCode.x);
  ui.keyPress.bind(Input.TOSS, KeyCode.t);
  ui.keyPress.bind(Input.SELECT_COMMAND, KeyCode.s);

  // Laptop directions.
  ui.keyPress.bind(Input.NW, KeyCode.i);
  ui.keyPress.bind(Input.N, KeyCode.o);
  ui.keyPress.bind(Input.NE, KeyCode.p);
  ui.keyPress.bind(Input.W, KeyCode.k);
  ui.keyPress.bind(Input.E, KeyCode.semicolon);
  ui.keyPress.bind(Input.SW, KeyCode.comma);
  ui.keyPress.bind(Input.S, KeyCode.period);
  ui.keyPress.bind(Input.SE, KeyCode.slash);
  ui.keyPress.bind(Input.RUN_NW, KeyCode.i, shift: true);
  ui.keyPress.bind(Input.RUN_N, KeyCode.o, shift: true);
  ui.keyPress.bind(Input.RUN_NE, KeyCode.p, shift: true);
  ui.keyPress.bind(Input.RUN_W, KeyCode.k, shift: true);
  ui.keyPress.bind(Input.RUN_E, KeyCode.semicolon, shift: true);
  ui.keyPress.bind(Input.RUN_SW, KeyCode.comma, shift: true);
  ui.keyPress.bind(Input.RUN_S, KeyCode.period, shift: true);
  ui.keyPress.bind(Input.RUN_SE, KeyCode.slash, shift: true);
  ui.keyPress.bind(Input.FIRE_NW, KeyCode.i, alt: true);
  ui.keyPress.bind(Input.FIRE_N, KeyCode.o, alt: true);
  ui.keyPress.bind(Input.FIRE_NE, KeyCode.p, alt: true);
  ui.keyPress.bind(Input.FIRE_W, KeyCode.k, alt: true);
  ui.keyPress.bind(Input.FIRE_E, KeyCode.semicolon, alt: true);
  ui.keyPress.bind(Input.FIRE_SW, KeyCode.comma, alt: true);
  ui.keyPress.bind(Input.FIRE_S, KeyCode.period, alt: true);
  ui.keyPress.bind(Input.FIRE_SE, KeyCode.slash, alt: true);

  ui.keyPress.bind(Input.OK, KeyCode.l);
  ui.keyPress.bind(Input.REST, KeyCode.l, shift: true);
  ui.keyPress.bind(Input.FIRE, KeyCode.l, alt: true);

  // Arrow keys.
  ui.keyPress.bind(Input.N, KeyCode.up);
  ui.keyPress.bind(Input.W, KeyCode.left);
  ui.keyPress.bind(Input.E, KeyCode.right);
  ui.keyPress.bind(Input.S, KeyCode.down);
  ui.keyPress.bind(Input.RUN_N, KeyCode.up, shift: true);
  ui.keyPress.bind(Input.RUN_W, KeyCode.left, shift: true);
  ui.keyPress.bind(Input.RUN_E, KeyCode.right, shift: true);
  ui.keyPress.bind(Input.RUN_S, KeyCode.down, shift: true);
  ui.keyPress.bind(Input.FIRE_N, KeyCode.up, alt: true);
  ui.keyPress.bind(Input.FIRE_W, KeyCode.left, alt: true);
  ui.keyPress.bind(Input.FIRE_E, KeyCode.right, alt: true);
  ui.keyPress.bind(Input.FIRE_S, KeyCode.down, alt: true);

  // Numeric keypad.
  ui.keyPress.bind(Input.NW, KeyCode.numpad7);
  ui.keyPress.bind(Input.N, KeyCode.numpad8);
  ui.keyPress.bind(Input.NE, KeyCode.numpad9);
  ui.keyPress.bind(Input.W, KeyCode.numpad4);
  ui.keyPress.bind(Input.E, KeyCode.numpad6);
  ui.keyPress.bind(Input.SW, KeyCode.numpad1);
  ui.keyPress.bind(Input.S, KeyCode.numpad2);
  ui.keyPress.bind(Input.SE, KeyCode.numpad3);
  ui.keyPress.bind(Input.RUN_NW, KeyCode.numpad7, shift: true);
  ui.keyPress.bind(Input.RUN_N, KeyCode.numpad8, shift: true);
  ui.keyPress.bind(Input.RUN_NE, KeyCode.numpad9, shift: true);
  ui.keyPress.bind(Input.RUN_W, KeyCode.numpad4, shift: true);
  ui.keyPress.bind(Input.RUN_E, KeyCode.numpad6, shift: true);
  ui.keyPress.bind(Input.RUN_SW, KeyCode.numpad1, shift: true);
  ui.keyPress.bind(Input.RUN_S, KeyCode.numpad2, shift: true);
  ui.keyPress.bind(Input.RUN_SE, KeyCode.numpad3, shift: true);

  ui.keyPress.bind(Input.OK, KeyCode.numpad5);
  ui.keyPress.bind(Input.REST, KeyCode.numpad5, shift: true);
  ui.keyPress.bind(Input.FIRE, KeyCode.numpad5, alt: true);

  ui.push(new MainMenuScreen(content));

  ui.handlingInput = true;
  ui.running = true;
}

void debugHover(html.Element debugBox, Vec pixel, Vec pos) {
  var info = Debug.getMonsterInfoAt(pos);
  if (info == null) {
    debugBox.style.display = "none";
    return;
  }

  debugBox.style.display = "inline-block";
  debugBox.style.left = "${pixel.x + 10}";
  debugBox.style.top = "${pixel.y}";
  debugBox.text = info;
}