library dngn.content.powers;

import '../engine.dart';
import '../util.dart';
import 'item_group.dart';

/// Randomly chooses prefix and suffix [Power]s for an item of type [itemType]
/// that is located in the item hierarchy at [itemPath].
///
/// The [level] is the level where the item is being generated, and [itemLevel]
/// is the level where the item type normally appears.
///
/// Returns a list of two powers, prefix and suffix. Either may be `null` (and
/// most often are).
List<Power> choosePowers(ItemGroup group, ItemType itemType) {
  // TODO: Make "depth" affect odds and bonus.
  var prefix = null;
  var suffix = null;

  // TODO: This is all kind of temp code, but it's a start.
  if (group.isWithin("weapon")) {
    if (rng.oneIn(20)) {
      var bonus = rng.taper(1, 3);
      var name;
      if (bonus < 5) name = "of Harming";
      else if (bonus < 9) name = "of Wounding";
      else if (bonus < 13) name = "of Maiming";
      else if (bonus < 17) name = "of Slaying";
      else name = "of Ruin";
      suffix = new AddDamagePower(name, bonus);
    }

    if (rng.oneIn(20)) {
      var brands = {
        "Glimmering": [Element.LIGHT, 3, 12],
        "Shining": [Element.LIGHT, 5, 14],
        "Radiant": [Element.LIGHT, 8, 16],
        "Dim": [Element.DARK, 4, 13],
        "Dark": [Element.DARK, 6, 15],
        "Black": [Element.DARK, 9, 17],
      };

      // TODO: Other elements.

      var brand = rng.item(brands.keys.toList());
      var element = brands[brand][0];
      var bonus = rng.taper(brands[brand][1], 4);
      var multiplier = rng.taper(brands[brand][2], 4) / 10;
      prefix = new BrandPower(brand, element, bonus, multiplier);
    }
  }

  return [prefix, suffix];
}

class AddDamagePower extends Power {
  final String name;

  final num _damage;

  AddDamagePower(this.name, this._damage);

  Attack modifyAttack(Attack attack) => attack.addDamage(_damage);
}

class BrandPower extends Power {
  final String name;

  final Element _element;
  final num _bonus;
  final num _multiplier;

  BrandPower(this.name, this._element, this._bonus, this._multiplier);

  Attack modifyAttack(Attack attack) =>
      attack.brand(_element).addDamage(_bonus).multiplyDamage(_multiplier);
}
