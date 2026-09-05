import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../skill/spell_school.dart';

abstract class Spell extends Ability {
  SpellSchool get school;

  /// How difficult the spell is to cast.
  int get spellLevel;

  @override
  List<Requirement> get requirements => [
    SkillLevelRequirement(school, spellLevel),
  ];
}

class ActionSpell extends Spell with ActionAbility {
  @override
  final String name;

  @override
  final String description;

  @override
  final int spellLevel;

  @override
  final SpellSchool school;

  final int _focusCost;

  final Action Function(ActionSpell spell, Game game) _getAction;

  ActionSpell(
    this.name,
    this.school,
    this._getAction, {
    required this.description,
    required this.spellLevel,
    required int focus,
  }) : _focusCost = focus;

  @override
  int focusCost(HeroSave hero) => _focusCost;

  @override
  Action onGetAction(Game game) => _getAction(this, game);
}

class TargetSpell extends Spell with TargetAbility {
  @override
  final String name;

  @override
  final String description;

  @override
  final int spellLevel;

  @override
  final SpellSchool school;

  final int _focusCost;

  final int range;

  final Action Function(TargetSpell spell, Game game, Vec target) _getAction;

  TargetSpell(
    this.name,
    this.school,
    this._getAction, {
    required this.description,
    required this.spellLevel,
    required int focus,
    required this.range,
  }) : _focusCost = focus;

  @override
  int focusCost(HeroSave hero) => _focusCost;

  @override
  Action onGetTargetAction(Game game, Vec target) =>
      _getAction(this, game, target);

  @override
  int getRange(Game game) => range;
}
