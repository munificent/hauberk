import 'dart:collection';

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

// TODO: Do we want to allow importing directly from content?
import '../content/skill/spell.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';

// TODO: Allow accessing this outside of the dungeon.
class SkillDialog extends Screen<Input> {
  final Content _content;
  final SkillSet _skills;
  SkillTree _tree;
  final Hero _hero;

  int selectedSkill = 0;

  SkillDialog(this._content, this._hero) : _skills = _hero.skills.clone() {
    _tree = new SkillTree(_skills, _content.skills);
  }

  bool handleInput(Input input) {
    switch (input) {
      case Input.n:
        _changeSelection(-1);
        return true;
      case Input.s:
        _changeSelection(1);
        return true;

      case Input.e:
        if (!_canRaiseSkill) return false;
        _raiseSkill();
        return true;

      // TODO: Use OK to confirm changes and cancel to discard them?
      case Input.cancel:
        ui.pop(_skills);
        return true;
    }

    return false;
  }

  void render(Terminal terminal) {
    terminal.clear();

    for (var i = 0; i < _tree.length; i++) {
      var row = _tree[i];

      var primary = UIHue.primary;
      var secondary = UIHue.secondary;

      if (!_skills.canGain(row.skill)) {
        primary = UIHue.disabled;
        secondary = UIHue.disabled;
      } else if (i == selectedSkill) {
        primary = UIHue.selection;
        secondary = UIHue.selection;
      }

      terminal.writeAt(2, 2 + i, row.prefix, slate);
      terminal.writeAt(2 + row.prefix.length, 2 + i, row.skill.name, primary);
      terminal.writeAt(
          26, 2 + i, _skills[row.skill].toString().padLeft(2), secondary);
    }

    terminal.drawChar(1, 2 + selectedSkill, CharCode.blackRightPointingPointer,
        UIHue.selection);

    terminal.writeAt(2, 0, "Skills:", UIHue.text);

    terminal.writeAt(2, terminal.height - 3, "Available points:", UIHue.text);
    terminal.writeAt(26, terminal.height - 3,
        _hero.skillPoints.toString().padLeft(2), UIHue.primary);

    var skill = _tree[selectedSkill].skill;
    var level = _skills[skill];

    String error;
    if (_hero.skillPoints == 0) {
      error = "You don't have any skill points to spend.";
    } else if (level == skill.maxLevel) {
      error = "You've maxed out this skill.";
    } else if (skill.prerequisite != null && _skills[skill.prerequisite] == 0) {
      error = "You must learn ${skill.prerequisite.name} first.";
    }

    writeDescription(int y, String text) {
      for (var line in Log.wordWrap(40, text)) {
        terminal.writeAt(30, y++, line, UIHue.text);
      }
    }

    terminal.writeAt(
        30, 2, skill.name, error == null ? UIHue.selection : UIHue.disabled);
    writeDescription(4, skill.description);

    if (skill is SpellSkill) {
      // TODO: Should show this for non-spell skills that also cost focus.
      terminal.writeAt(30, 10, "Focus:", UIHue.text);
      terminal.writeAt(
          50, 10, skill.adjustedFocusCost(_hero).toString(), UIHue.primary);

      terminal.writeAt(30, 11, "Complexity:", UIHue.text);
      terminal.writeAt(50, 11, skill.complexity.toString(), UIHue.primary);

      if (level > 0) {
        // TODO: These values don't take into account changes to hero attributes
        // made while on the skill dialog.

        // TODO: Should only show the one of these that applies to the spell.
        terminal.writeAt(30, 12, "Effectiveness:", UIHue.text);
        terminal.writeAt(
            50, 12, skill.effectiveness(_hero.game).toString(), UIHue.primary);

        terminal.writeAt(30, 13, "Failure:", UIHue.text);
        terminal.writeAt(
            50, 13, "${skill.failureChance(_hero.game)}%", UIHue.primary);
      }
    }

    if (level > 0) {
      terminal.writeAt(30, 16, "At current level $level:", UIHue.primary);
      writeDescription(18, skill.levelDescription(level));
    }

    if (level < skill.maxLevel) {
      terminal.writeAt(30, 24, "At next level ${level + 1}:", UIHue.primary);
      writeDescription(26, skill.levelDescription(level + 1));
    }

    if (error != null) {
      terminal.writeAt(30, 32, error, UIHue.text);
    } else {
      terminal.writeAt(
          30, 32, "Press [→] to raise this skill.", UIHue.helpText);
    }

    var helpText = ['[↕] Change selection'];
    if (_canRaiseSkill) helpText.add('[→] Raise skill');
    helpText.add('[Esc] Exit');
    terminal.writeAt(0, terminal.height - 1, helpText.join(', '), slate);
  }

  void _changeSelection(int offset) {
    selectedSkill = (selectedSkill + offset) % _tree.length;
    dirty();
  }

  bool get _canRaiseSkill {
    if (_hero.skillPoints <= 0) return false;

    return _skills.canGain(_tree[selectedSkill].skill);
  }

  void _raiseSkill() {
    _skills[_tree[selectedSkill].skill]++;
    _hero.skillPoints--;
    dirty();
  }
}

/// Takes the list of skills and organizes them into a tree based on their
/// parents.
class SkillTree extends ListBase<SkillTreeRow> {
  final SkillSet _skills;
  final List<SkillTreeRow> _rows = [];

  SkillTree(this._skills, List<Skill> allSkills) {
    var root = new SkillTreeNode(null);
    var nodeMap = <Skill, SkillTreeNode>{null: root};

    // Note: Assumes the skill list always has prerequisites before the skills
    // that require them.
    for (var skill in allSkills) {
      if (!_skills.isKnown(skill)) continue;

      // If the prerequisite isn't known (transitively), don't show the skill.
      if (!nodeMap.containsKey(skill.prerequisite)) ;

      var node = new SkillTreeNode(skill);
      nodeMap[skill] = node;

      var parent = nodeMap[skill.prerequisite];
      parent.children.add(node);
    }

    root.traverse(_rows);
  }

  int get length => _rows.length;
  set length(int newLength) => throw new UnsupportedError("Can't set length.");

  SkillTreeRow operator [](int index) => _rows[index];

  void operator []=(int index, SkillTreeRow value) => _rows[index] = value;
}

class SkillTreeRow {
  final Skill skill;
  final String prefix;

  SkillTreeRow(this.skill, this.prefix);
}

class SkillTreeNode {
  final Skill skill;
  final List<SkillTreeNode> children = [];

  SkillTreeNode(this.skill);

  void traverse(List<SkillTreeRow> rows, [String prefix = ""]) {
    for (var child in children) {
      var isRoot = child.skill.prerequisite == null;
      var isLast = child == children.last;

      var thisPrefix = isRoot ? "" : isLast ? "└" : "├";
      rows.add(new SkillTreeRow(child.skill, "$prefix$thisPrefix"));

      var childPrefix = isRoot ? "" : isLast ? " " : "│";
      child.traverse(rows, "$prefix$childPrefix");
    }
  }
}
