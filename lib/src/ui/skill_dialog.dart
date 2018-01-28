import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

// TODO: Allow accessing this outside of the dungeon.
abstract class SkillDialog extends Screen<Input> {
  SkillDialog _nextScreen;

  factory SkillDialog(Content content, Hero hero) {
    var screens = [
      new DisciplineDialog(content, hero),
      new SpellDialog(content, hero),
    ];

    for (var i = 0; i < screens.length; i++) {
      screens[i]._nextScreen = screens[(i + 1) % screens.length];
    }

    return screens.first;
  }

  SkillDialog._();

  String get _name;
}

abstract class SkillTypeDialog<T extends Skill> extends SkillDialog {
  final Content _content;
  final Hero _hero;
  final List<T> _skills = [];

  int _selectedSkill = 0;

  SkillTypeDialog(this._content, this._hero) : super._() {
    for (var skill in _content.skills) {
      if (skill is T) _skills.add(skill);
    }
  }

  String get _extraHelp => null;

  // TODO: Eventually should clone skill set so we can cancel changes on dialog.
  SkillSet get _skillSet => _hero.skills;

  bool keyDown(int keyCode, {bool shift, bool alt}) {
    if (shift || alt) return false;

    if (keyCode == KeyCode.tab) {
      ui.goTo(_nextScreen);
      return true;
    }

    return false;
  }

  bool handleInput(Input input) {
    switch (input) {
      case Input.n:
        _changeSelection(-1);
        return true;
      case Input.s:
        _changeSelection(1);
        return true;

      // TODO: Get this working with spells, tricks, etc. that need to be
      // explicitly raised.
//      case Input.e:
//        if (!_canRaiseSkill) return false;
//        _raiseSkill();
//        return true;

      // TODO: Use OK to confirm changes and cancel to discard them?
      case Input.cancel:
        // TODO: Pass back updated skills for skills that are learned on this
        // screen.
        ui.pop();
        return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    terminal.clear();

    _renderSkillList(terminal);
    _renderSkill(terminal);

    var helpText = '[Esc] Exit, [Tab] View ${_nextScreen._name}';
    if (_extraHelp != null) {
      helpText += ", $_extraHelp";
    }

    terminal.writeAt(0, terminal.height - 1, helpText, slate);
  }

  void _renderSkillList(Terminal terminal) {
    terminal = terminal.rect(0, 0, 40, terminal.height - 1);

    Draw.frame(terminal, 0, 0, terminal.width, terminal.height);
    terminal.writeAt(1, 0, _name, UIHue.text);

    _renderSkillListHeader(terminal);
    terminal.writeAt(2, 2, _rowSeparator, steelGray);

    var i = 0;
    for (var skill in _skills) {
      var y = i * 2 + 3;
      terminal.writeAt(2, y + 1, _rowSeparator, midnight);

      var color = i == _selectedSkill ? UIHue.selection : UIHue.primary;
      terminal.writeAt(2, y, skill.name, color);

      _renderSkillInList(terminal, y, skill);

      i++;
    }

    terminal.drawChar(1, _selectedSkill * 2 + 3,
        CharCode.blackRightPointingPointer, UIHue.selection);
  }

  void _renderSkill(Terminal terminal) {
    terminal = terminal.rect(40, 0, terminal.width - 40, terminal.height - 1);
    Draw.frame(terminal, 0, 0, terminal.width, terminal.height);

    var skill = _skills[_selectedSkill];
    var level = _hero.skills[skill];
    terminal.writeAt(1, 0, skill.name, UIHue.primary);

    writeDescription(int y, String text) {
      for (var line in Log.wordWrap(terminal.width - 2, text)) {
        terminal.writeAt(1, y++, line, UIHue.text);
      }
    }

    writeDescription(2, skill.description);

    if (level > 0) {
      terminal.writeAt(1, 16, "At current level $level:", UIHue.primary);
      writeDescription(18, skill.levelDescription(level));
    }

    if (level < skill.maxLevel) {
      terminal.writeAt(1, 24, "At next level ${level + 1}:", UIHue.primary);
      writeDescription(26, skill.levelDescription(level + 1));
    }

    _renderSkillDetails(terminal, skill);
  }

  void _renderValue(Terminal terminal, int i, String label, Object value) {
    terminal.writeAt(1, 10 + i, "$label:", UIHue.text);
    terminal.writeAt(20, 10 + i, value.toString(), UIHue.primary);
  }

  String get _rowSeparator;

  void _renderSkillListHeader(Terminal terminal);

  void _renderSkillInList(Terminal terminal, int y, T skill);

  void _renderSkillDetails(Terminal terminal, T skill);

  void _changeSelection(int offset) {
    _selectedSkill = (_selectedSkill + offset).clamp(0, _skills.length - 1);
    dirty();
  }
}

class DisciplineDialog extends SkillTypeDialog<Discipline> {
  DisciplineDialog(Content content, Hero hero) : super(content, hero);

  String get _name => "Disciplines";
  String get _rowSeparator => "──────────────────────────── ─── ────";

  void _renderSkillListHeader(Terminal terminal) {
    terminal.writeAt(31, 1, "Lev Next", UIHue.helpText);
  }

  void _renderSkillInList(Terminal terminal, int y, Discipline skill) {
    var level = _skillSet[skill].toString().padLeft(3);
    terminal.writeAt(31, y, level, UIHue.text);

    var percent = skill.percentUntilNext(_hero.lore);
    terminal.writeAt(
        35, y, percent == null ? "  --" : "$percent%".padLeft(4), UIHue.text);
  }

  void _renderSkillDetails(Terminal terminal, Discipline skill) {
    var trained = skill.trained(_hero.lore);
    _renderValue(terminal, 0, "Trained", trained);

    var percent = skill.percentUntilNext(_hero.lore);
    if (percent != null) {
      var next = skill.trainingNeeded(_skillSet[skill] + 1);
      _renderValue(terminal, 1, "Next", "$next ($percent%)");
    } else {
      _renderValue(terminal, 1, "Next", "(at max)");
    }
  }
}

class SpellDialog extends SkillTypeDialog<Spell> {
  String get _name => "Spells";
  String get _rowSeparator => "─────────────────────────────────────";

  SpellDialog(Content content, Hero hero) : super(content, hero);

  // TODO: Show whether or not the spell is known, etc.
  void _renderSkillListHeader(Terminal terminal) {}

  void _renderSkillInList(Terminal terminal, int y, Spell skill) {}

  void _renderSkillDetails(Terminal terminal, Spell skill) {
    // TODO: Should show this for non-spell skills that also cost focus.
    _renderValue(terminal, 0, "Focus", skill.adjustedFocusCost(_hero));

    // TODO: Should show relative to Intellect too.
    _renderValue(terminal, 1, "Complexity", skill.complexity);

    var level = _skillSet[skill];
    if (level > 0) {
      // TODO: Should only show the one of these that applies to the spell.
      _renderValue(
          terminal, 2, "Effectiveness", skill.effectiveness(_hero.game));
      _renderValue(
          terminal, 3, "Failure", "${skill.failureChance(_hero.game)}%");
    }
  }
}

// TODO: Remove all of this once everything is moved to the new approach to
// skills.
//class OldSkillDialog extends Screen<Input> {
//  final Content _content;
//  final SkillSet _skills;
//  SkillTree _tree;
//  final Hero _hero;
//
//  int selectedSkill = 0;
//
//  OldSkillDialog(this._content, this._hero) : _skills = _hero.skills.clone() {
//    _tree = new SkillTree(_skills, _content.skills);
//  }
//
//  bool handleInput(Input input) {
//    switch (input) {
//      case Input.n:
//        _changeSelection(-1);
//        return true;
//      case Input.s:
//        _changeSelection(1);
//        return true;
//
//      case Input.e:
//        if (!_canRaiseSkill) return false;
//        _raiseSkill();
//        return true;
//
//      // TODO: Use OK to confirm changes and cancel to discard them?
//      case Input.cancel:
//        ui.pop(_skills);
//        return true;
//    }
//
//    return false;
//  }
//
//  void render(Terminal terminal) {
//    terminal.clear();
//
//    // TODO: Show trained skills more explicitly.
//
//    for (var i = 0; i < _tree.length; i++) {
//      var row = _tree[i];
//
//      var primary = UIHue.primary;
//      var secondary = UIHue.secondary;
//
//      if (!_skills.canGain(row.skill)) {
//        primary = UIHue.disabled;
//        secondary = UIHue.disabled;
//      } else if (i == selectedSkill) {
//        primary = UIHue.selection;
//        secondary = UIHue.selection;
//      }
//
//      terminal.writeAt(2, 2 + i, row.prefix, slate);
//      terminal.writeAt(2 + row.prefix.length, 2 + i, row.skill.name, primary);
//      terminal.writeAt(
//          26, 2 + i, _skills[row.skill].toString().padLeft(2), secondary);
//    }
//
//    terminal.drawChar(1, 2 + selectedSkill, CharCode.blackRightPointingPointer,
//        UIHue.selection);
//
//    terminal.writeAt(2, 0, "Skills:", UIHue.text);
//
//    terminal.writeAt(2, terminal.height - 3, "Available points:", UIHue.text);
//    terminal.writeAt(26, terminal.height - 3,
//        _hero.skillPoints.toString().padLeft(2), UIHue.primary);
//
//    var skill = _tree[selectedSkill].skill;
//    var level = _skills[skill];
//
//    String error;
//    if (_hero.skillPoints == 0) {
//      error = "You don't have any skill points to spend.";
//    } else if (level == skill.maxLevel) {
//      error = "You've maxed out this skill.";
//    } else if (skill.prerequisite != null && _skills[skill.prerequisite] == 0) {
//      error = "You must learn ${skill.prerequisite.name} first.";
//    }
//
//    writeDescription(int y, String text) {
//      for (var line in Log.wordWrap(40, text)) {
//        terminal.writeAt(30, y++, line, UIHue.text);
//      }
//    }
//
//    terminal.writeAt(
//        30, 2, skill.name, error == null ? UIHue.selection : UIHue.disabled);
//    writeDescription(4, skill.description);
//
//    if (skill is Spell) {
//      // TODO: Should show this for non-spell skills that also cost focus.
//      terminal.writeAt(30, 10, "Focus:", UIHue.text);
//      terminal.writeAt(
//          50, 10, skill.adjustedFocusCost(_hero).toString(), UIHue.primary);
//
//      terminal.writeAt(30, 11, "Complexity:", UIHue.text);
//      terminal.writeAt(50, 11, skill.complexity.toString(), UIHue.primary);
//
//      if (level > 0) {
//        // TODO: Should only show the one of these that applies to the spell.
//        terminal.writeAt(30, 12, "Effectiveness:", UIHue.text);
//        terminal.writeAt(
//            50, 12, skill.effectiveness(_hero.game).toString(), UIHue.primary);
//
//        terminal.writeAt(30, 13, "Failure:", UIHue.text);
//        terminal.writeAt(
//            50, 13, "${skill.failureChance(_hero.game)}%", UIHue.primary);
//      }
//    }
//
//    if (level > 0) {
//      terminal.writeAt(30, 16, "At current level $level:", UIHue.primary);
//      writeDescription(18, skill.levelDescription(level));
//    }
//
//    if (level < skill.maxLevel) {
//      terminal.writeAt(30, 24, "At next level ${level + 1}:", UIHue.primary);
//      writeDescription(26, skill.levelDescription(level + 1));
//    }
//
//    if (error != null) {
//      terminal.writeAt(30, 32, error, UIHue.text);
//    } else if (skill is Discipline) {
//      // TODO: More useful description that explains how to train it.
//      // TODO: Show how much training is needed to reach the next level.
//      terminal.writeAt(30, 32, "This skill is trained.", UIHue.helpText);
//    } else {
//      terminal.writeAt(
//          30, 32, "Press [→] to raise this skill.", UIHue.helpText);
//    }
//
//    var helpText = ['[↕] Change selection'];
//    if (_canRaiseSkill) helpText.add('[→] Raise skill');
//    helpText.add('[Esc] Exit');
//    terminal.writeAt(0, terminal.height - 1, helpText.join(', '), slate);
//  }
//
//  void _changeSelection(int offset) {
//    selectedSkill = (selectedSkill + offset) % _tree.length;
//    dirty();
//  }
//
//  bool get _canRaiseSkill {
//    if (_hero.skillPoints <= 0) return false;
//
//    var skill = _tree[selectedSkill].skill;
//    if (skill is Discipline) return false;
//
//    return _skills.canGain(skill);
//  }
//
//  void _raiseSkill() {
//    _skills[_tree[selectedSkill].skill]++;
//    _hero.skillPoints--;
//    dirty();
//  }
//}
//
///// Takes the list of skills and organizes them into a tree based on their
///// parents.
//class SkillTree extends ListBase<SkillTreeRow> {
//  final SkillSet _skills;
//  final List<SkillTreeRow> _rows = [];
//
//  SkillTree(this._skills, List<Skill> allSkills) {
//    var root = new SkillTreeNode(null);
//    var nodeMap = <Skill, SkillTreeNode>{null: root};
//
//    // Note: Assumes the skill list always has prerequisites before the skills
//    // that require them.
//    for (var skill in allSkills) {
//      if (!_skills.isDiscovered(skill)) continue;
//
//      // If the prerequisite isn't known (transitively), don't show the skill.
//      if (!nodeMap.containsKey(skill.prerequisite)) ;
//
//      var node = new SkillTreeNode(skill);
//      nodeMap[skill] = node;
//
//      var parent = nodeMap[skill.prerequisite];
//      parent.children.add(node);
//    }
//
//    root.traverse(_rows);
//  }
//
//  int get length => _rows.length;
//  set length(int newLength) => throw new UnsupportedError("Can't set length.");
//
//  SkillTreeRow operator [](int index) => _rows[index];
//
//  void operator []=(int index, SkillTreeRow value) => _rows[index] = value;
//}
//
//class SkillTreeRow {
//  final Skill skill;
//  final String prefix;
//
//  SkillTreeRow(this.skill, this.prefix);
//}
//
//class SkillTreeNode {
//  final Skill skill;
//  final List<SkillTreeNode> children = [];
//
//  SkillTreeNode(this.skill);
//
//  void traverse(List<SkillTreeRow> rows, [String prefix = ""]) {
//    for (var child in children) {
//      var isRoot = child.skill.prerequisite == null;
//      var isLast = child == children.last;
//
//      var thisPrefix = isRoot ? "" : isLast ? "└" : "├";
//      rows.add(new SkillTreeRow(child.skill, "$prefix$thisPrefix"));
//
//      var childPrefix = isRoot ? "" : isLast ? " " : "│";
//      child.traverse(rows, "$prefix$childPrefix");
//    }
//  }
//}
