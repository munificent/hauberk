library hauberk.engine.action.toss;

import 'package:piecemeal/piecemeal.dart';

import '../actor.dart';
import '../game.dart';
import '../items/inventory.dart';
import '../items/item.dart';
import 'action.dart';
import 'bolt.dart';
import 'item.dart';

/// [Action] for throwing an [Item].
///
/// This is referred to as "toss" in the code but as "throw" in the user
/// interface. "Toss" is used just to avoid using "throw" in code, which is a
/// reserved word.
class TossAction extends ItemAction {
  final Vec _target;
  Iterator<Vec> _los;

  TossAction(ItemLocation location, int index, this._target)
      : super(location, index);

  ActionResult onPerform() {
    if (!item.canToss) return fail("{1} can't be thrown.", item);

    // Take the item and throw it.
    return alternate(new TossLosAction(_target, removeItem()));
  }
}

/// Action for handling the path of a thrown item while it's in flight.
class TossLosAction extends LosAction {
  final Item _item;

  int get range => _item.type.tossAttack.range;

  TossLosAction(Vec target, this._item)
      : super(target);

  void onStep(Vec pos) {
    addEvent(EventType.TOSS, pos: pos, other: _item);
  }

  void onHitActor(Vec pos, Actor target) {
    var attack = _item.type.tossAttack;

    // Being too close or too far weakens the bolt.
    // TODO: Make this modify strike instead?
    var toTarget = pos - actor.pos;
    if (toTarget > attack.range * 2 / 3) {
      attack = attack.multiplyDamage(0.5);
    }

    attack.perform(this, actor, target, canMiss: false);

    // Drop the item onto the ground.
    _item.pos = pos;
    game.stage.items.add(_item);

    // TODO: Secondary actions: potions explode etc.
  }

  void onEnd(Vec pos) {
    // Drop the item onto the ground.
    _item.pos = pos;
    game.stage.items.add(_item);

    // TODO: Secondary actions: potions explode etc.
  }

  bool onTarget(Vec pos) {
    // Drop the item onto the ground.
    _item.pos = pos;
    game.stage.items.add(_item);

    // TODO: Secondary actions: potions explode etc.

    // Let the player aim at a specific tile on the ground.
    return true;
  }

}