import '../../engine.dart';

class SpellSchool extends Skill {
  @override
  final String name;

  @override
  final int baseExperience = 4000;

  SpellSchool(this.name);

  @override
  String get description => "TODO";

  @override
  String levelDescription(int level) => "TODO";
}
