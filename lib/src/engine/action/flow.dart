import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../ai/flow.dart';
import '../attack.dart';
import '../element.dart';
import '../game.dart';
import 'action.dart';
import 'element.dart';

/// Creates a swath of damage that flows out from a point through reachable
/// tiles.
class FlowAction extends Action with DestroyItemMixin {
  /// The centerpoint that the flow is radiating from.
  final Vec _from;
  final Hit _hit;

  Flow _flow;
  List<Vec> _tiles;

  /// Whether the flow should go over obstacles.
  final bool _fly;

  FlowAction(this._from, this._hit, {bool fly})
      : _fly = fly ?? false;

  ActionResult onPerform() {
    if (_tiles == null) {
      // TODO: Should water open doors? Should fire burn them?
      _flow = new Flow(game.stage, _from, ignoreActors: true, canFly: _fly);

      var count = (math.PI * _hit.range * _hit.range).ceil();
      _tiles = _flow.allByDistance.take(count).toList();
    }

    // Hit all tiles at the same distance.
    var distance = _flow.getDistance(_tiles.first);
    int end;
    for (end = 0; end < _tiles.length; end++) {
      if (_flow.getDistance(_tiles[end]) != distance) break;
    }

    for (var pos in _tiles.sublist(0, end)) {
      addEvent(EventType.cone, element: _hit.element, pos: pos);

      // See if there is an actor there.
      var target = game.stage.actorAt(pos);
      if (target != null && target != actor) {
        // TODO: Modify damage based on range?
        _hit.perform(this, actor, target, canMiss: false);
      }

      // Hit stuff on the floor too.
      _hitFloor(pos);
    }

    _tiles = _tiles.sublist(end);
    if (_tiles.isEmpty) return ActionResult.success;

    return ActionResult.notDone;
  }

  // TODO: Copied from ray.dart. Unify.
  /// Applies element-specific effects to items on the floor.
  void _hitFloor(Vec pos) {
    switch (_hit.element) {
      case Element.none:
        // No effect.
        break;

      case Element.air:
        // TODO: Teleport items.
        break;

      case Element.earth:
        break;

      case Element.fire:
        _destroyFloorItems(pos, 3, "flammable", "burns up");
        break;

      case Element.water:
        // TODO: Move items.
        break;

      case Element.acid:
        // TODO: Destroy items.
        break;

      case Element.cold:
        _destroyFloorItems(pos, 6, "freezable", "shatters");
        break;

      case Element.lightning:
        // TODO: Break glass. Recharge some items?
        break;

      case Element.poison:
        break;

      case Element.dark:
        // TODO: Blind.
        break;

      case Element.light:
        break;

      case Element.spirit:
        break;
    }

    return null;
  }

  void _destroyFloorItems(Vec pos, int chance, String flag, String message) {
    var destroyed = destroyItems(
        game.stage.itemsAt(pos), chance, flag, message);
    for (var item in destroyed) {
      game.stage.removeItem(item, pos);
    }
  }
}

/// Creates an expanding ring of damage centered on the [Actor].
///
/// This class mainly exists as an [Action] that [Item]s can use.
class FlowSelfAction extends Action {
  final Attack _attack;
  final bool _fly;

  FlowSelfAction(this._attack, {bool fly = false})
      : _fly = fly;

  ActionResult onPerform() {
    return alternate(new FlowAction(actor.pos, _attack.createHit(), fly: _fly));
  }
}

class FlowFromAction extends Action {
  final Attack _attack;
  final Vec _pos;
  final bool _fly;

  FlowFromAction(this._attack, this._pos, {bool fly = false})
      : _fly = fly;

  ActionResult onPerform() {
    return alternate(new FlowAction(_pos, _attack.createHit(), fly: _fly));
  }
}
