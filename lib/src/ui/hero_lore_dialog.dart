import 'package:malison/malison.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';
import 'hero_info_dialog.dart';

class HeroLoreDialog extends HeroInfoDialog {
  static const _rowCount = 11;

  final List<Breed> _breeds = [];
  _Sort _sort = _Sort.appearance;
  int _selection = 0;
  int _scroll = 0;

  HeroLoreDialog(Hero hero) : super.base(hero) {
    _listBreeds();
  }

  String get name => "Monster Lore";
  String get extraHelp => "[↕] Scroll, [S] ${_sort.next.helpText}";

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    if (keyCode == KeyCode.s) {
      _sort = _sort.next;
      _listBreeds();
      dirty();
      return true;
    }

    return super.keyDown(keyCode, shift: shift, alt: alt);
  }

  bool handleInput(Input input) {
    switch (input) {
      case Input.n:
        _select(-1);
        return true;

      case Input.s:
        _select(1);
        return true;

      case Input.runN:
        _select(-(_rowCount - 1));
        return true;

      case Input.runS:
        _select(_rowCount - 1);
        return true;
    }

    return super.handleInput(input);
  }

  void render(Terminal terminal) {
    super.render(terminal);

    writeLine(int y, Color color) {
      terminal.writeAt(
          2,
          y,
          "──────────────────────────────────────────────────────────── ───── "
          "───── ─────",
          color);
    }

    terminal.writeAt(2, 1, "Monsters", gold);
    terminal.writeAt(20, 1, "(${_sort.description})".padLeft(42), steelGray);
    terminal.writeAt(63, 1, "Depth Seen Slain", slate);

    for (var i = 0; i < _rowCount; i++) {
      var y = i * 2 + 3;
      writeLine(y + 1, midnight);

      var index = _scroll + i;
      if (index >= _breeds.length) continue;
      var breed = _breeds[index];

      var fore = UIHue.text;
      if (index == _selection) {
        fore = UIHue.selection;
        terminal.writeAt(1, y, "►", fore);
      }

      var seen = hero.lore.seen(breed);
      var slain = hero.lore.slain(breed);
      if (seen > 0) {
        terminal.drawGlyph(0, y, breed.appearance as Glyph);
        terminal.writeAt(2, y, breed.name, fore);

        terminal.writeAt(63, y, breed.depth.toString().padLeft(5), fore);
        if (breed.flags.unique) {
          terminal.writeAt(69, y, "Yes".padLeft(5), fore);
          terminal.writeAt(75, y, (slain > 0 ? "Yes" : "No").padLeft(5), fore);
        } else {
          terminal.writeAt(69, y, seen.toString().padLeft(5), fore);
          terminal.writeAt(75, y, slain.toString().padLeft(5), fore);
        }
      } else {
        terminal.writeAt(
            2, y, "(undiscovered ${_scroll + i + 1})", UIHue.disabled);
      }
    }

    writeLine(2, steelGray);

    _showMonster(terminal, _breeds[_selection]);
  }

  void _showMonster(Terminal terminal, Breed breed) {
    terminal = terminal.rect(0, terminal.height - 15, terminal.width, 14);

    Draw.frame(terminal, 0, 1, 80, terminal.height - 1);
    terminal.writeAt(1, 0, "┌─┐", steelGray);
    terminal.writeAt(1, 1, "╡ ╞", steelGray);
    terminal.writeAt(1, 2, "└─┘", steelGray);

    var seen = hero.lore.seen(breed);
    if (seen == 0) {
      terminal.writeAt(
          1, 3, "You have not seen this breed yet.", UIHue.disabled);
      return;
    }

    terminal.drawGlyph(2, 1, breed.appearance as Glyph);
    terminal.writeAt(4, 1, breed.name, UIHue.selection);

    var y = 3;
    if (breed.description != null) {
      for (var line in Log.wordWrap(terminal.width - 2, breed.description)) {
        terminal.writeAt(1, y, line, UIHue.text);
        y++;
      }

      y++;
    }

    var description = _describeBreed(breed);
    for (var line in Log.wordWrap(terminal.width - 2, description)) {
      terminal.writeAt(1, y, line, UIHue.text);
      y++;
    }
  }

  void _select(int offset) {
    _selection = (_selection + offset).clamp(0, _breeds.length - 1);

    // Keep the selected row on screen.
    _scroll = _scroll.clamp(_selection - _rowCount + 1, _selection);
    dirty();
  }

  String _describeBreed(Breed breed) {
    var sentences = <String>[];
    var pronoun = breed.pronoun.subjective;
    var lore = hero.lore;

    // TODO: Breed descriptive text.
    // TODO: Multi-color output.

    var noun = "monster";
    if (breed.groups.isNotEmpty) {
      // TODO: Handle more than two groups.
      noun = breed.groups.map((group) => group.name).join(" ");
    }

    if (breed.flags.unique) {
      if (lore.slain(breed) > 0) {
        sentences.add("You have slain this unique $noun.");
      } else {
        sentences.add("You have seen but not slain this unique $noun.");
      }
    } else {
      sentences.add("You have seen ${lore.seen(breed)} and slain "
          "${lore.slain(breed)} of this ${noun}.");
    }

    var experience = (breed.experienceCents / 100).toStringAsFixed(2);
    sentences.add("$pronoun is worth $experience experience.");

    if (lore.slain(breed) > 0) {
      sentences.add("$pronoun has ${breed.maxHealth} health.");
    }

    // TODO: Other stats, moves, attacks, etc.

    return sentences
        .map((sentence) =>
            sentence.substring(0, 1).toUpperCase() + sentence.substring(1))
        .join(" ");
  }

  void _listBreeds() {
    // Try to keep the current breed selected, if there is one.
    Breed selectedBreed;
    if (_breeds.isNotEmpty) {
      selectedBreed = _breeds[_selection];
    }

    _breeds.clear();

    if (_sort == _Sort.uniques) {
      _breeds.addAll(
          hero.game.content.breeds.where((breed) => breed.flags.unique));
    } else {
      _breeds.addAll(hero.game.content.breeds);
    }

    compareGlyph(Breed a, Breed b) {
      var aChar = (a.appearance as Glyph).char;
      var bChar = (b.appearance as Glyph).char;

      isUpper(int c) => c >= CharCode.aUpper && c <= CharCode.zUpper;

      // Sort lowercase letters first even though they come later in character
      // code.
      if (isUpper(aChar) && !isUpper(bChar)) return 1;
      if (!isUpper(aChar) && isUpper(bChar)) return -1;

      return aChar.compareTo(bChar);
    }

    compareDepth(Breed a, Breed b) {
      return a.depth.compareTo(b.depth);
    }

    var comparisons = <int Function(Breed, Breed)>[];
    switch (_sort) {
      case _Sort.appearance:
        comparisons = [compareGlyph, compareDepth];
        break;

      case _Sort.name:
        // No other comparisons.
        break;

      case _Sort.depth:
        comparisons = [compareDepth];
        break;

      case _Sort.uniques:
        comparisons = [compareDepth];
        break;
    }

    _breeds.sort((a, b) {
      for (var comparison in comparisons) {
        var compare = comparison(a, b);
        if (compare != 0) return compare;
      }

      // Otherwise, sort by name.
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    _selection = 0;
    if (selectedBreed != null) {
      _selection = _breeds.indexOf(selectedBreed);

      // It may not be found since the unique page doesn't show all breeds.
      if (_selection == -1) _selection = 0;
    }
    _select(0);
  }
}

class _Sort {
  /// The default order they are created in in the content.
  static const appearance =
      _Sort("ordered by appearance", "Sort by appearance");

  /// Sort by depth.
  static const depth = _Sort("ordered by depth", "Sort by depth");

  /// Sort alphabetically by name.
  static const name = _Sort("ordered by name", "Sort by name");

  /// Show only uniques.
  static const uniques = _Sort("uniques", "Show only uniques");

  static const all = [appearance, depth, name, uniques];

  final String description;
  final String helpText;

  const _Sort(this.description, this.helpText);

  _Sort get next => all[(all.indexOf(this) + 1) % all.length];
}
