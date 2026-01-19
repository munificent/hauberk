import 'package:malison/malison.dart';

import '../../engine.dart';
import '../../hues.dart';
import '../input.dart';
import '../widget/draw.dart';
import '../widget/table.dart';
import 'info_dialog.dart';

class MonsterLoreInfoDialog extends InfoDialog {
  static int _compareGlyph(Breed a, Breed b) {
    var aChar = (a.appearance as Glyph).char;
    var bChar = (b.appearance as Glyph).char;

    bool isUpper(int c) => c >= CharCode.aUpper && c <= CharCode.zUpper;

    // Sort lowercase letters first even though they come later in character
    // code.
    if (isUpper(aChar) && !isUpper(bChar)) return 1;
    if (!isUpper(aChar) && isUpper(bChar)) return -1;

    return aChar.compareTo(bChar);
  }

  static int _compareDepth(Breed a, Breed b) => a.depth.compareTo(b.depth);

  static int _compareName(Breed a, Breed b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  final Table<Breed> _table = Table(
    columns: [
      Column("Name"),
      Column("Depth", width: 5, align: Align.right),
      Column("Seen", width: 5, align: Align.right),
      Column("Slain", width: 5, align: Align.right),
    ],
    orders: [
      RowOrder("appearance", [_compareGlyph, _compareDepth]),
      RowOrder("name", [_compareName]),
      RowOrder("depth", [_compareDepth, _compareName]),
    ],
    filters: [
      RowFilter("all", where: (breed) => true),
      RowFilter("uniques", where: (breed) => breed.flags.unique),
    ],
  );

  MonsterLoreInfoDialog(super.content, super.hero) : super.base() {
    _buildRows();
  }

  @override
  String get name => "Monster Lore";

  @override
  Map<String, String> get extraHelp => _table.extraHelp;

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (_table.keyDown(keyCode, shift: shift, alt: alt)) {
      dirty();
      return true;
    }

    return super.keyDown(keyCode, shift: shift, alt: alt);
  }

  @override
  bool handleInput(Input input) {
    if (_table.handleInput(input)) {
      dirty();
      return true;
    }

    return super.handleInput(input);
  }

  @override
  void drawInfo(Terminal terminal) {
    _table.draw(terminal.rect(0, 1, terminal.width, terminal.height - 16));

    _showMonster(terminal, _table.selectedRow.data);
  }

  void _showMonster(Terminal terminal, Breed breed) {
    terminal = terminal.rect(0, terminal.height - 15, 80, 14);

    var seen = hero.lore.seenBreed(breed);

    Draw.glyphFrame(
      terminal,
      0,
      0,
      terminal.width,
      terminal.height,
      glyph: seen == 0 ? Glyph("?", UIHue.disabled) : breed.appearance as Glyph,
      label: seen == 0 ? "" : breed.name,
    );

    if (seen == 0) {
      terminal.writeAt(
        1,
        3,
        "You have not seen this breed yet.",
        UIHue.disabled,
      );
      return;
    }

    var y = 3;
    // TODO: Remove this check once all breeds have descriptions.
    if (breed.description != "") {
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

  String _describeBreed(Breed breed) {
    var sentences = <String>[];
    var pronoun = breed.pronoun.subjective;
    var lore = hero.lore;

    // TODO: Breed descriptive text.
    // TODO: Multi-color output.

    var noun = "monster";
    if (breed.groups.isNotEmpty) {
      // TODO: Handle more than two groups.
      noun = breed.groups.map((group) => group).join(" ");
    }

    if (breed.flags.unique) {
      if (lore.slain(breed) > 0) {
        sentences.add("You have slain this unique $noun.");
      } else {
        sentences.add("You have seen but not slain this unique $noun.");
      }
    } else {
      sentences.add(
        "You have seen ${lore.seenBreed(breed).fmt()} and slain "
        "${lore.slain(breed).fmt()} of this $noun.",
      );
    }

    sentences.add("$pronoun is worth ${breed.experience.fmt()} experience.");

    if (lore.slain(breed) > 0) {
      sentences.add("$pronoun has ${breed.maxHealth.fmt()} health.");
    }

    // TODO: Other stats, moves, attacks, etc.

    return sentences
        .map(
          (sentence) =>
              sentence.substring(0, 1).toUpperCase() + sentence.substring(1),
        )
        .join(" ");
  }

  void _buildRows() {
    // TODO: Sort mode to show only uniques.
    var breeds = content.breeds.toList();

    _table.rebuild(() sync* {
      for (var index = 0; index < breeds.length; index++) {
        var breed = breeds[index];
        var seen = hero.lore.seenBreed(breed);
        if (seen > 0) {
          yield Row(breed, glyph: breed.appearance as Glyph, [
            Cell(breed.name),
            Cell(breed.depth.fmt()),
            if (breed.flags.unique) ...[
              Cell("Yes"),
              Cell(hero.lore.slain(breed) > 0 ? "Yes" : "No"),
            ] else ...[
              Cell(seen.fmt()),
              Cell(hero.lore.slain(breed).fmt()),
            ],
          ]);
        } else {
          yield Row(breed, [
            Cell("(undiscovered ${index + 1})", enabled: false),
          ]);
        }
      }
    });
  }
}
