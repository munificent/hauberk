import 'package:piecemeal/piecemeal.dart';

import '../actor.dart';
import '../attack.dart';
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
  final Hit _hit;
  final Vec _target;

  TossAction(ItemLocation location, Item item, this._hit, this._target)
      : super(location, item);

  ActionResult onPerform() {
    if (!item.canToss) return fail("{1} can't be thrown.", item);

    Item tossed;
    if (item.count == 1) {
      // Throwing the entire stack.
      tossed = item;
      removeItem();
    } else {
      // Throwing one item from a stack.
      tossed = item.splitStack(1);
      countChanged();
    }

    // Take the item and throw it.
    return alternate(new TossLosAction(_target, tossed, _hit));
  }
}

/// Action for handling the path of a thrown item while it's in flight.
class TossLosAction extends LosAction {
  final Item _item;
  final Hit _hit;

  /// `true` if the item has reached an [Actor] and failed to hit it. When this
  /// happens, the item will keep flying past its target until the end of its
  /// range.
  bool _missed = false;

  int get range => _hit.range;

  TossLosAction(Vec target, this._item, this._hit)
      : super(target);

  void onStep(Vec pos) {
    addEvent(EventType.toss, pos: pos, other: _item);
  }

  bool onHitActor(Vec pos, Actor target) {
    // TODO: Range should affect strike.
    if (!_hit.perform(this, actor, target)) {
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
    // TODO: I think there's a bug here somewhere. Sometimes, when you throw a
    // bottled element at a monster, it seems to only do the toss damage of the
    // bottle itself, and not the effect damage too.
    // See if the item does something when it hits.
    if (_item.toss.use != null) {
      addAction(_item.toss.use(pos));
      return;
    }

    // See if it breaks.
    if (rng.percent(_item.toss.breakage)) {
      log("{1} breaks!", _item);
      return;
    }

    // Drop the item onto the ground.
    game.stage.addItem(_item, pos);
  }
}