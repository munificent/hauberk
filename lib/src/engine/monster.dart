library hauberk.engine.monster;

import 'dart:math' as math;

import '../debug.dart';
import '../util.dart';
import 'action_base.dart';
import 'actor.dart';
import 'ai/monster_states.dart';
import 'breed.dart';
import 'energy.dart';
import 'game.dart';
import 'hero/hero.dart';
import 'log.dart';
import 'los.dart';
import 'melee.dart';
import 'option.dart';

class Monster extends Actor {
  /// The number of times the actor has rested. Once this crosses a certain
  /// threshold (based on the Actor's max health), its health will be increased
  /// and this will be lowered.
  int _restCount = 0;

  final Breed breed;

  MonsterState _state;

  /// After performing a [Move] a monster must recharge to regain its cost.
  /// This is how much recharging is left to do before another move can be
  /// performed.
  int _recharge = 0;

  bool get isRecharged => _recharge == 0;

  bool get isAfraid => _state is AfraidState;

  /// How afraid of the hero the monster currently is. If it gets high enough,
  /// the monster will switch to the afraid state and try to flee.
  double _fear = 0.0;

  /// The fear level that will cause the monster to become frightened. This is
  /// randomized every frame so that all monsters don't become frightened at
  /// the same time.
  double _frightenThreshold = 1000.0;

  // TODO: Only used by debug log. Do something better.
  double get fear => _fear;

  get appearance => breed.appearance;

  String get nounText => 'the ${breed.name}';
  Pronoun get pronoun => breed.pronoun;

  /// How much experience a level one [Hero] gains for killing this monster.
  int get experienceCents => breed.experienceCents;

  Monster(Game game, this.breed, int x, int y, int maxHealth)
      : super(game, x, y, maxHealth) {
    Debug.addMonster(this);
    changeState(new AsleepState());
  }

  void spendCharge(int cost) {
    // Add some randomness to the cost. Since monsters very eagerly prefer to
    // use moves, this ensures they don't use them too predictably.
    _recharge += rng.range(cost, cost * 5);
  }

  /// Gets whether or not this monster has a line of sight to [target].
  ///
  /// Does not take into account if there are other [Actor]s between the monster
  /// and the target.
  bool canView(Vec target) {
    // Walk to the target.
    for (final step in new Los(pos, target)) {
      if (step == target) return true;
      if (!game.stage[step].isTransparent) return false;
    }

    throw 'unreachable';
  }

  /// Gets whether or not this monster has a line of sight to [target].
  ///
  /// Does take into account if there are other [Actor]s between the monster
  /// and the target.
  bool canTarget(Vec target) {
    // Walk to the target.
    for (final step in new Los(pos, target)) {
      if (step == target) return true;
      if (game.stage.actorAt(step) != null) return false;
      if (!game.stage[step].isTransparent) return false;
    }

    throw 'unreachable';
  }

  bool get canOpenDoors => breed.flags.contains('open-doors');

  int onGetSpeed() => Energy.NORMAL_SPEED + breed.speed;

  Action onGetAction() {
    // Recharge moves.
    _recharge = math.max(0, _recharge - Option.RECHARGE_RATE);

    // We do the randomization once per turn and not in [_modifyFear] because
    // calling that repeatedly should not increase the chance of a state change.
    _frightenThreshold = rng.range(60, 100).toDouble();

    return _state.getAction();
  }

  /// Modifies fear and then determines if it's has crossed the threshold to
  /// cause a state change.
  void _modifyFear(Action action, double offset) {
    // Don't add effects if the monster already died.
    if (!isAlive) return;

    if (breed.flags.contains("fearless")) return;

    // If it can't run, there's no point in being afraid.
    if (breed.flags.contains("immobile")) return;

    _fear = math.max(0.0, _fear + offset);

    // TODO: Also check for other awake non-afraid states.
    if (_state is AwakeState && _fear > _frightenThreshold) {
      log("{1} is afraid!", this);
      changeState(new AfraidState());
      action.addEvent(new Event(EventType.FEAR, actor: this));
      return;
    }

    if (_state is AfraidState && _fear <= 0.0) {
      // TODO: Should possibly go into other non-afraid states.
      log("{1} grows courageous!", this);
      changeState(new AwakeState());
      action.addEvent(new Event(EventType.COURAGE, actor: this));
    }
  }

  void changeState(MonsterState state) {
    _state = state;
    _state.bind(this);
  }

  Attack getAttack(Actor defender) => rng.item(breed.attacks);

  Attack defend(Attack attack) {
    _state.defend();

    // TODO: Handle resists.
    return attack;
  }

  /// Inflicting damage decreases fear.
  void onDamage(Action action, Actor defender, int damage) {
    // The greater the power of the hit, the more emboldening it is.
    var fear = 100.0 * damage / game.hero.health.max;

    _modifyFear(action, -fear);
    Debug.logMonster(this, "Hit for ${damage} / ${game.hero.health.max} "
        "decreases fear by ${fear} to $_fear");

    // Nearby monsters may witness it.
    _updateWitnesses((witness) {
      witness._viewHeroDamage(action, damage);
    });
  }

  /// This is called when another monster in sight of this one has damaged the
  /// hero.
  void _viewHeroDamage(Action action, int damage) {
    var fear = 50.0 * damage / health.max;

    _modifyFear(action, -fear);
    Debug.logMonster(this, "Witness ${damage} / ${health.max} "
        "decreases fear by ${fear} to $_fear");
  }

  /// Taking damage increases fear.
  void onDamaged(Action action, Actor attacker, int damage) {
    // The greater the power of the hit, the more frightening it is.
    var fear = 100.0 * damage / health.max;

    if (breed.flags.contains("cowardly")) {
      fear *= 2.0;
    } else if (breed.flags.contains("berzerk")) {
      // Getting hurt enrages it.
      fear *= -3.0;
    }

    _modifyFear(action, fear);
    Debug.logMonster(this, "Hit for ${damage} / ${health.max} "
        "increases fear by ${fear} to $_fear");

    // Nearby monsters may witness it.
    _updateWitnesses((witness) {
      witness._viewMonsterDamage(action, this, damage);
    });
  }

  /// This is called when another monster in sight of this one has taken
  /// damage.
  void _viewMonsterDamage(Action action, Monster monster, int damage) {
    var fear = 50.0 * damage / health.max;

    if (breed.flags.contains("cowardly")) {
      fear *= 2.0;
    } else if (breed.flags.contains("protective") && monster.breed == breed) {
      // Seeing its own kind get hurt enrages it.
      fear *= -2.0;
    } else if (breed.flags.contains("berzerk")) {
      // Seeing any monster get hurt enrages it.
      fear *= -1.0;
    }

    _modifyFear(action, fear);
    Debug.logMonster(this, "Witness ${damage} / ${health.max} "
        "increases fear by ${fear} to $_fear");
  }

  /// Called when this Actor has been killed by [attacker].
  void onDied(Actor attacker) {
    // Handle drops.
    breed.drop.spawnDrop(game, (item) {
      item.pos = pos;
      // TODO: Scatter items a bit?
      log("{1} drop[s] {2}.", this, item);
      game.stage.items.add(item);
    });

    // Tell the quest.
    game.quest.killMonster(game, this);

    game.stage.removeActor(this);
    Debug.removeMonster(this);
  }

  void onFinishTurn(Action action) {
    _decayFear(action);

    // Regenerate health if out of sight.
    if (isVisible) return;

    // TODO: Tune this now that it only applies to monsters.
    var turnsNeeded = math.max(
        Option.REST_MAX_HEALTH_FOR_RATE ~/ health.max, 1);

    if (_restCount++ > turnsNeeded) {
      health.current++;
      _restCount = 0;
    }
  }

  void changePosition(Vec from, Vec to) {
    super.changePosition(from, to);

    // If the monster is (or was) visible, don't let the hero rest through it
    // moving.
    if (game.stage[from].visible || game.stage[to].visible) {
      game.hero.disturb();
    }
  }

  /// Invokes [callback] on all nearby monsters that can see this one.
  void _updateWitnesses(callback(Monster monster)) {
    for (var other in game.stage.actors) {
      if (other == this) continue;
      if (other is! Monster) continue;
      if (other._state is AsleepState) continue;

      var distance = (other.pos - pos).kingLength;
      if (distance > 20) continue;

      if (other.canView(pos)) callback(other);
    }
  }

  /// Fear decays over time, more quickly the farther the monster is from the
  /// hero.
  void _decayFear(Action action) {
    // TODO: Poison should slow the decay of fear.
    var fearDecay = 5.0 + (pos - game.hero.pos).kingLength;

    // Fear decays more quickly if out of sight.
    if (!isVisible) fearDecay = 5.0 + fearDecay * 2.0;

    // The closer the monster is to death, the less quickly it gets over fear.
    fearDecay = 2.0 + fearDecay * health.current / health.max;

    _modifyFear(action, -fearDecay);
    Debug.logMonster(this, "Decay fear by $fearDecay to $_fear");
  }
}
