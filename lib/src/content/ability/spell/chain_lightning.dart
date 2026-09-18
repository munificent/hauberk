import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';
import '../../elements.dart';
import '../../events.dart';
import '../../skill/arcana.dart';
import 'spell.dart';

class ChainLightningSpell extends Spell with ActionAbility {
  @override
  String get name => "Chain Lightning";

  @override
  String get description =>
      "Electricity arcs from your fingers to surrounding foes.";

  @override
  final List<Arcanum> arcana = [Arcanum.arcing];

  @override
  int get arcanumLevel => 6;

  @override
  int onGetFocusCost(HeroSave hero) => 24;

  @override
  Action onGetAction(Game game) => ChainLightningAction();
}

class ChainLightningAction extends Action with GeneratorActionMixin {
  static const _arcRange = 4;

  final Set<Actor> _reachedActors = {};
  final List<_Bolt> _bolts = [];

  @override
  Iterable<ActionResult> onGenerate() sync* {
    var attack = Attack(
      Prop("lightning"),
      "shock",
      // TODO: Take spell power into account.
      12,
      range: _arcRange,
      element: Elements.lightning,
    );

    var attacker = actor!;

    // Don't circle back to the one who cast it.
    _reachedActors.add(attacker);

    // Arc to the initial nearby actors.
    _chainFrom(game, attacker.pos);

    if (_bolts.isEmpty) {
      yield fail("There is nothing close enough to strike.");
      return;
    }

    while (_bolts.isNotEmpty) {
      _bolts.retainWhere((bolt) {
        // TODO: Better event type.
        addEvent(
          Events.bolt,
          pos: bolt.steps[bolt.index],
          element: Elements.lightning,
        );

        bolt.index++;
        if (bolt.index < bolt.steps.length) return true;

        // Hit the target.
        var hit = attack.createHit();
        hit.perform(this, actor, bolt.target, canMiss: false);

        // Chain from the end of this bolt.
        // TODO: Damage should fall off as it chains.
        _chainFrom(game, bolt.steps.last);
        // TODO: Concurrent mod here.
        return false;
      });

      yield waitOne();
    }
  }

  void _chainFrom(Game game, Vec from) {
    for (var actor in _actorsNear(game, from)) {
      if (_reachedActors.contains(actor)) continue;
      var steps = <Vec>[];
      for (var pos in Line(from, actor.pos)) {
        steps.add(pos);
        if (pos == actor.pos) break;

        // If we hit anything else before the actor, then don't arc to it.
        if (game.stage.actorAt(pos) != null || game.stage[pos].blocksView) {
          steps.clear();
          break;
        }
      }

      if (steps.isNotEmpty) _bolts.add(_Bolt(actor, steps));
      _reachedActors.add(actor);
    }
  }

  /// Gets all actors near enough to arc from [pos].
  List<Actor> _actorsNear(Game game, Vec pos) => [
    for (var actor in game.stage.actors)
      if (actor.pos - pos <= _arcRange && !_reachedActors.contains(actor))
        actor,
  ];
}

class _Bolt {
  final Actor target;
  final List<Vec> steps;
  int index = 0;

  _Bolt(this.target, this.steps);
}
