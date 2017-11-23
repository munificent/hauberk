import 'dart:collection';

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../hues.dart';
import 'input.dart';

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
      terminal.writeAt(30, 2 + i, _skills[row.skill].toString(), secondary);
    }

    terminal.drawChar(1, 2 + selectedSkill, CharCode.blackRightPointingPointer,
        UIHue.selection);

    terminal.writeAt(2, 0, "Skill points:", UIHue.text);
    terminal.writeAt(30, 0, _hero.skillPoints.toString(), UIHue.primary);

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
      if (!nodeMap.containsKey(skill.prerequisite));

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
