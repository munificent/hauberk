import '../core/combat.dart';
import '../item/item.dart';
import '../monster/monster.dart';
import 'hero.dart';
import 'hero_save.dart';

/// A capability granted to their hero by their [Race] or [HeroClass].
abstract class Power with Capability {}

/// An attribute of the [Hero] that can affect various game mechanics.
mixin Capability {
  String get name;
  String get description;

  /// Gives the skill a chance to modify the melee [hit] the [hero] is about to
  /// perform on [monster] when using [weapon].
  void modifyHit(Hero hero, Monster? monster, Item? weapon, Hit hit) {}

  /// Gives the skill a chance to modify the ranged [hit] the [hero] is about to
  /// fire using [weapon].
  void modifyRangedHit(Hero hero, Item? weapon, Hit hit) {}

  /// Modifies the hero's base armor.
  int modifyArmor(HeroSave hero, int armor) => armor;

  /// Gives the capability a chance to add new defenses to the hero.
  Iterable<Defense> defenses(Hero hero) => const [];

  /// Gives the capability a chance to adjust the [totalHeft] from the weapons
  /// the hero has equipped.
  double modifyHeft(Hero hero, List<Item> weapons, double totalHeft) =>
      totalHeft;
}
