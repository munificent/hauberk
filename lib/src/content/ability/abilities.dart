import '../../engine.dart';
import 'spell/conjuring.dart';
import 'spell/divination.dart';
import 'spell/sorcery.dart';
import 'weapon/axe_sweep.dart';
import 'weapon/club_bash.dart';
import 'weapon/spear_stab.dart';
import 'weapon/whip_crack.dart';

class Abilities {
  /// All of the abilities in the game.
  static final List<Ability> all = [
    AxeSweepAbility(),
    ClubBashAbility(),
    SpearStabAbility(),
    WhipCrackAbility(),
    ...conjuringSpells(),
    ...divinationSpells(),
    ...sorcerySpells(),
  ];
}
