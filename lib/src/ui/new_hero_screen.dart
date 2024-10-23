import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'game_screen.dart';
import 'input.dart';
import 'storage.dart';

// From: http://medieval.stormthecastle.com/medieval-names.htm.
const _defaultNames = [
  "Merek",
  "Carac",
  "Ulric",
  "Tybalt",
  "Borin",
  "Sadon",
  "Terrowin",
  "Rowan",
  "Forthwind",
  "Althalos",
  "Fendrel",
  "Brom",
  "Hadrian",
  "Crewe",
  "Bolbec",
  "Fenwick",
  "Mowbray",
  "Drake",
  "Bryce",
  "Leofrick",
  "Letholdus",
  "Lief",
  "Barda",
  "Rulf",
  "Robin",
  "Gavin",
  "Terrin",
  "Jarin",
  "Cedric",
  "Gavin",
  "Josef",
  "Janshai",
  "Doran",
  "Asher",
  "Quinn",
  "Xalvador",
  "Favian",
  "Destrian",
  "Dain",
  "Millicent",
  "Alys",
  "Ayleth",
  "Anastas",
  "Alianor",
  "Cedany",
  "Ellyn",
  "Helewys",
  "Malkyn",
  "Peronell",
  "Thea",
  "Gloriana",
  "Arabella",
  "Hildegard",
  "Brunhild",
  "Adelaide",
  "Beatrix",
  "Emeline",
  "Mirabelle",
  "Helena",
  "Guinevere",
  "Isolde",
  "Maerwynn",
  "Catrain",
  "Gussalen",
  "Enndolynn",
  "Krea",
  "Dimia",
  "Aleida"
];

// TODO: Update to handle resizable UI.
class NewHeroScreen extends Screen<Input> {
  static const _deaths = ["Stairs", "Permanent"];

  static const _deathDescriptions = [
    "When you die, you lose everything since the last time you went up or "
        "down a set of stairs (or left a shop).",
    "When you die, that's it. Your hero is gone forever. This is the most "
        "challenging way to play, but often the most rewarding as well."
  ];

  final Content _content;
  final Storage _storage;

  /// Index of the control that has focus.
  int _focus = 0;

  final NameControl _name;
  final SelectControl _race;
  final SelectControl _class;
  final SelectControl _death;
  final List<Control> _controls = [];

  NewHeroScreen(this._content, this._storage)
      : _name = NameControl(0, 0, _storage),
        _race = SelectControl(
            0, 4, "Race", _content.races.map((race) => race.name).toList()),
        _class = SelectControl(
            0, 14, "Class", _content.classes.map((cls) => cls.name).toList()),
        _death = SelectControl(0, 28, "Death", _deaths) {
    _controls.addAll([_name, _race, _class, _death]);

    _race.selected = rng.range(_content.races.length);
    _class.selected = rng.range(_content.classes.length);
  }

  @override
  void render(Terminal terminal) {
    Draw.dialog(terminal, 80, 40,
        label: "Out of the forgotten wilderness, a hero appears...",
        (terminal) {
      Draw.hLine(terminal, 0, 3, terminal.width);
      Draw.hLine(terminal, 0, 13, terminal.width);
      Draw.hLine(terminal, 0, 27, terminal.width);

      _renderRace(terminal.rect(0, 4, terminal.width, 8));
      _renderClass(terminal.rect(0, 14, terminal.width, 15));
      _renderDeath(terminal.rect(0, 28, terminal.width, 7));

      for (var i = 0; i < _controls.length; i++) {
        _controls[i].render(terminal, focus: i == _focus);
      }
    }, helpKeys: {
      "Tab": "Next field",
      ..._controls[_focus].helpKeys,
      if (_name._isUnique) "Enter": "Create hero",
      "`": "Cancel"
    });
  }

  void _renderRace(Terminal terminal) {
    var race = _content.races[_race.selected];
    _renderText(terminal, race.description);

    // Show how race affects stats.
    var y = 3;
    for (var stat in Stat.all) {
      terminal.writeAt(0, y, stat.abbreviation, UIHue.secondary);
      Draw.thinMeter(terminal, 4, y, 14, race.stats[stat]!, 45);
      y++;
    }
  }

  void _renderClass(Terminal terminal) {
    var heroClass = _content.classes[_class.selected];
    _renderText(terminal, heroClass.description);

    // TODO: Should show class proficiencies in some way. That's hard right now
    // because they are stored individually for each skill which is way too
    // fine-grained to fit on this little UI.
    //
    // Maybe have some kind of category system for skills?
  }

  void _renderDeath(Terminal terminal) {
    _renderText(terminal, _deathDescriptions[_death.selected]);
  }

  void _renderText(Terminal terminal, String description) {
    var y = 3;
    for (var line in Log.wordWrap(59, description)) {
      terminal.writeAt(19, y, line, UIHue.text);
      y++;
    }
  }

  @override
  bool handleInput(Input input) {
    if (_controls[_focus].handleInput(input)) {
      dirty();
      return true;
    }

    switch (input) {
      case Input.cancel:
        ui.pop();
        return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (_controls[_focus].keyDown(keyCode, shift: shift, alt: alt)) {
      dirty();
      return true;
    }

    if (alt) return false;

    switch (keyCode) {
      // We look for "enter" explicitly and not Input.OK, because typing "l"
      // should enter that letter, not create a hero.
      case KeyCode.enter when _name._isUnique:
        var hero = _content.createHero(_name._name,
            race: _content.races[_race.selected],
            heroClass: _content.classes[_class.selected],
            permadeath: _death.selected == 1);
        _storage.add(hero);
        ui.goTo(GameScreen.town(_storage, _content, hero, newHero: true));
        return true;

      case KeyCode.tab:
        var offset = shift ? _controls.length - 1 : 1;
        _focus = (_focus + offset) % _controls.length;
        dirty();
        return true;
    }

    return false;
  }
}

abstract class Control {
  Map<String, String> get helpKeys;

  bool handleInput(Input input) => false;

  bool keyDown(int keyCode, {required bool shift, required bool alt}) => false;

  void render(Terminal terminal, {required bool focus});
}

class NameControl extends Control {
  static const _maxNameLength = 20;

  final int _x;
  final int _y;

  final Storage _storage;

  String _enteredName = "";

  String _defaultName = rng.item(_defaultNames);

  String get _name => _enteredName.isNotEmpty ? _enteredName : _defaultName;

  bool _isUnique = false;

  NameControl(this._x, this._y, this._storage) {
    _refreshUnique();
  }

  @override
  Map<String, String> get helpKeys => const {"A-Z Del": "Edit name"};

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (alt) return false;

    switch (keyCode) {
      case KeyCode.delete:
        if (_enteredName.isNotEmpty) {
          _enteredName = _enteredName.substring(0, _enteredName.length - 1);

          // Pick a new default name.
          if (_enteredName.isEmpty) {
            _defaultName = rng.item(_defaultNames);
          }
        }

        _refreshUnique();
        return true;

      case KeyCode.space:
        // TODO: Handle modifiers.
        _append(" ");
        return true;

      default:
        var key = keyCode;

        if (key >= KeyCode.a && key <= KeyCode.z) {
          // TODO: Figuring out the char code manually here is lame. Pass it
          // in from the KeyEvent?
          var charCode = key;
          // TODO: Handle other modifiers.
          if (!shift) {
            charCode = 'a'.codeUnits[0] - 'A'.codeUnits[0] + charCode;
          }

          _append(String.fromCharCode(charCode));
          return true;
        } else if (key >= KeyCode.zero && key <= KeyCode.nine) {
          _append(String.fromCharCode(key));
          return true;
        }
    }

    return false;
  }

  void _append(String append) {
    if (_enteredName.length < _maxNameLength) {
      _enteredName += append;
    }

    _refreshUnique();
  }

  /// See if there is already a hero with this name.
  ///
  /// We don't allow heroes to share the same name because when permadeath is
  /// on, we use the name to figure out which hero to delete from storage.
  void _refreshUnique() {
    _isUnique = _storage.heroes.every((hero) => hero.name != _name);
  }

  @override
  void render(Terminal terminal, {required bool focus}) {
    var color = _isUnique ? UIHue.selection : red;

    terminal.writeAt(_x, _y + 1, "Name:", focus ? UIHue.selection : UIHue.text);
    if (focus) {
      Draw.box(terminal, _x + 18, _y, 23, 3, color);
    }

    if (_enteredName.isNotEmpty) {
      terminal.writeAt(_x + 19, _y + 1, _enteredName, UIHue.primary);
      if (focus) {
        terminal.writeAt(
            _x + 19 + _enteredName.length, _y + 1, " ", Color.black, color);
      }
    } else {
      if (focus) {
        terminal.writeAt(_x + 19, _y + 1, _defaultName, Color.black, color);
      } else {
        terminal.writeAt(_x + 19, _y + 1, _defaultName, UIHue.primary);
      }
    }

    if (!_isUnique) {
      terminal.writeAt(42, 1, "Already a hero with that name", red);
    }
  }
}

class SelectControl extends Control {
  final int _x;
  final int _y;
  final String _name;
  final List<String> _options;

  int selected = 0;

  SelectControl(this._x, this._y, this._name, this._options);

  @override
  Map<String, String> get helpKeys => {"◄►": "Select ${_name.toLowerCase()}"};

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.w:
        selected = (selected + _options.length - 1) % _options.length;
        return true;
      case Input.e:
        selected = (selected + 1) % _options.length;
        return true;
    }

    return false;
  }

  @override
  void render(Terminal terminal, {required bool focus}) {
    terminal.writeAt(
        _x, _y + 1, "$_name:", focus ? UIHue.selection : UIHue.text);

    if (focus) {
      var x = _x + 19;
      for (var i = 0; i < _options.length; i++) {
        var option = _options[i];

        if (i == selected) {
          Draw.box(terminal, x - 1, _y, option.length + 2, 3, UIHue.selection);
          terminal.writeAt(x - 1, _y + 1, "◄", UIHue.selection);
          terminal.writeAt(x + option.length, _y + 1, "►", UIHue.selection);
        }

        terminal.writeAt(
            x, _y + 1, option, i == selected ? UIHue.selection : UIHue.primary);
        x += option.length + 2;
      }
    } else {
      terminal.writeAt(_x + 19, _y + 1, _options[selected], UIHue.primary);
    }
  }
}
