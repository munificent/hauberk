import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../skills.dart';
import 'conjuring.dart';
import 'divination.dart';
import 'sorcery.dart';

abstract final class Spells {
  static final List<Spell> all = [
    ...conjuringSpells(Skills.find("Conjuring")),
    ...divinationSpells(Skills.find("Divination")),
    ...sorcerySpells(Skills.find("Sorcery")),
  ];

  static final Map<String, Spell> _byName = {
    for (var spell in all) spell.name: spell,
  };

  static Spell find(String name) {
    var spell = _byName[name];
    if (spell == null) throw ArgumentError("Unknown spell '$name'.");
    return spell;
  }
}

class SpellSchool extends Skill {
  @override
  int get maxLevel => 10;

  @override
  final String name;

  SpellSchool(this.name);

  @override
  String get description => "TODO";

  @override
  String levelDescription(int level) => "TODO";
}

class ActionSpell extends Spell with ActionAbility {
  @override
  final String name;

  @override
  final String description;

  @override
  final Skill skill;

  @override
  final int spellLevel;

  final int _focusCost;

  final Action Function(ActionSpell spell, Game game, int schoolLevel)
  _getAction;

  ActionSpell(
    this.skill,
    this.name,
    this._getAction, {
    required this.description,
    required this.spellLevel,
    required int focus,
  }) : _focusCost = focus;

  @override
  int focusCost(HeroSave hero, int skillLevel) => _focusCost;

  @override
  Action onGetAction(Game game, int schoolLevel) =>
      _getAction(this, game, schoolLevel);
}

class TargetSpell extends Spell with TargetAbility {
  @override
  final String name;

  @override
  final String description;

  @override
  final Skill skill;

  @override
  final int spellLevel;

  final int _focusCost;

  final int range;

  final Action Function(TargetSpell spell, Game game, int level, Vec target)
  _getAction;

  TargetSpell(
    this.skill,
    this.name,
    this._getAction, {
    required this.description,
    required this.spellLevel,
    required int focus,
    required this.range,
  }) : _focusCost = focus;

  @override
  int focusCost(HeroSave hero, int skillLevel) => _focusCost;

  @override
  Action onGetTargetAction(Game game, int level, Vec target) =>
      _getAction(this, game, level, target);

  @override
  int getRange(Game game) => range;
}
