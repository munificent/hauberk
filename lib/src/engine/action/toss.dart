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

  /// `true` if the item has reached an [Actor] and failed to hit it. When this
  /// happens, the item will keep flying past its target until the end of its
  /// range.
  bool _missed = false;

  int get range => _item.type.tossAttack.range;

  TossLosAction(Vec target, this._item)
      : super(target);

  void onStep(Vec pos) {
    addEvent(EventType.toss, pos: pos, other: _item);
  }

  bool onHitActor(Vec pos, Actor target) {
    var attack = _item.type.tossAttack;

    // TODO: Range should affect strike.
    if (!attack.perform(this, actor, target)) {
      // The item missed, so keep flying.
      _missed = true;
      return false;
    }

    _endThrow(pos);
    return true;
  }

  void onEnd(Vec pos) {
    _endThrow(pos);
  }

  bool onTarget(Vec pos) {
    // If the item failed to make contact with an actor, it's no longer well
    // targeted and just keeps going.
    if (_missed) return false;

    _endThrow(pos);

    // Let the player aim at a specific tile on the ground.
    return true;
  }

  void _endThrow(Vec pos) {
    // See if it breaks.
    if (rng.range(100) < _item.type.breakage) {
      log("{1} breaks!", _item.type.tossAttack.noun);
      return;
    }

    // Drop the item onto the ground.
    _item.pos = pos;
    game.stage.items.add(_item);

    // TODO: Secondary actions: potions explode etc.
  }
}