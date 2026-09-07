import '../../engine.dart';
import 'skills.dart';

class SpellSchool extends Skill {
  static final SpellSchool conjuring = SpellSchool._("Conjuring");
  static final SpellSchool divination = SpellSchool._("Divination");
  static final SpellSchool sorcery = SpellSchool._("Sorcery");

  @override
  final String name;

  @override
  Domain get domain => Domains.spell;

  @override
  final int baseExperience = 4000;

  SpellSchool._(this.name);

  @override
  String get description => "TODO";

  @override
  String levelDescription(int level) => "TODO";
}
