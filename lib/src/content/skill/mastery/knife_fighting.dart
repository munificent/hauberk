import 'mastery.dart';

class KnifeFighting extends MasterySkill {
  @override
  String get name => "Knife Fighting";

  @override
  String get description =>
      "Small and easily concealed, knives are deadly in the hand of a skilled "
      "practitioner.";

  @override
  String get weaponType => "knife";

  @override
  String levelDescription(int level) {
    // TODO: Should improve backstabbing.
    return "TODO";
  }
}
