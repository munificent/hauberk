import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../action/bolt.dart';
import '../../elements.dart';
import '../../events.dart';
import '../../skill/arcana.dart';
import 'spell.dart';

class IcicleSpell extends Spell with TargetAbility {
  @override
  String get name => "Icicle";

  @override
  String get description => "A razor-sharp blade of ice flies toward a target.";

  @override
  final List<Arcanum> arcana = [Arcanum.icewinding];

  @override
  int get arcanumLevel => 1;

  @override
  int onGetFocusCost(HeroSave hero) => 12;

  @override
  Action onGetTargetAction(Game game, Vec target) {
    var attack = Attack(
      Prop("icicle"),
      "pierce",
      8 + spellPower(game.hero.save) * 4,
      range: getRange(game),
      element: Elements.cold,
    );
    return BoltAction(target, attack.createHit(), event: Events.icicle);
  }

  @override
  int getRange(Game game) => 10 + spellPower(game.hero.save);
}
