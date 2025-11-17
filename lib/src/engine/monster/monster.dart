import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../../debug.dart';
import '../action/action.dart';
import '../core/actor.dart';
import '../core/combat.dart';
import '../core/element.dart';
import '../core/energy.dart';
import '../core/game.dart';
import '../core/log.dart';
import '../core/math.dart';
import '../hero/hero.dart';
import '../stage/tile.dart';
import 'breed.dart';
import 'monster_states.dart';
import 'move.dart';

class Monster extends Actor {
  static const _maxAlertness = 1.0;

  Breed _breed;

  Breed get breed => _breed;

  set breed(Breed value) {
    _breed = value;

    // Keep the health in bounds.
    health = health.clamp(0, value.maxHealth);

    // The new breed may have different moves.
    _recharges.clear();
    _resetCharges();
  }

  /// The monster's generation.
  ///
  /// Monsters created directly in the level are one. Monsters that are spawned
  /// or summoned by another monster have a generation one greater than that
  /// monster.
  ///
  /// When a monster spawns another, its generation increases too so that it
  /// also spawns less frequently over time.
  int generation;

  MonsterState _state = AsleepState();

  /// After performing a [Move] a monster must recharge to limit the rate that
  /// it can be performed. This tracks how much recharging is left to do for
  /// each move.
  ///
  /// When a move is performed, its rate is added to this. It then reduces over
  /// time. When it reaches zero, the move can be performed again.
  final _recharges = <Move, num>{};

  bool get isAfraid => _state is AfraidState;

  bool get isAsleep => _state is AsleepState;

  bool get isAwake => _state is AwakeState;

  @override
  Motility get motility => breed.motility;

  /// Whether the monster wanted to melee or do a ranged attack the last time
  /// it took a step.
  bool wantsToMelee = true;

  double _alertness = 0.0;

  double get alertness => _alertness;

  /// How afraid of the hero the monster currently is. If it gets high enough,
  /// the monster will switch to the afraid state and try to flee.
  double _fear = 0.0;

  /// The fear level that will cause the monster to become frightened.
  ///
  /// Give this some random variation within monsters of the same breed so
  /// they don't all become frightened at the same time.
  double _frightenThreshold = rng.range(60, 200).toDouble();

  double get fear => _fear;

  @override
  Object get appearance => breed.appearance;

  @override
  String get nounText => breed.hasProperName ? breed.name : "the ${breed.name}";

  @override
  Pronoun get pronoun => breed.pronoun;

  /// How much experience the [Hero] gains for killing this monster.
  int get experience => breed.experience;

  @override
  int get maxHealth => breed.maxHealth;

  /// Instead of armor, we just scale up the health for different breeds to
  /// accomplish the same thing.
  @override
  int get armor => 0;

  @override
  int get emanationLevel => breed.emanationLevel;

  /// How much the monster relies on sight to sense the hero, from 0.0 to 1.0.
  double get sightReliance {
    var senses = breed.vision + breed.hearing;
    if (senses == 0) return 0.0;
    return breed.vision / senses;
  }

  Monster(this._breed, super.x, super.y, this.generation) {
    health = maxHealth;

    _state.bind(this);

    if (breed.flags.cowardly) _frightenThreshold *= 0.7;

    // Initialize the recharges. These will be set to real values when the
    // monster wakes up.
    for (var move in breed.moves) {
      _recharges[move] = 0.0;
    }
  }

  void useMove(Move move) {
    // Add some randomness to the rate. Since monsters very eagerly prefer to
    // use moves, this ensures they don't use them too predictably.
    // TODO: Make rate and experience be double instead of num? If so, get rid
    // of this toDouble().
    _recharges[move] =
        _recharges[move]! + rng.float(move.rate.toDouble(), move.rate * 1.3);
  }

  /// Returns `true` if [move] is recharged.
  bool canUse(Move move) => _recharges[move] == 0.0;

  @override
  int get baseSpeed => Energy.normalSpeed + breed.speed;

  @override
  int get baseDodge => breed.dodge;

  @override
  Iterable<Defense> onGetDefenses() => breed.defenses;

  @override
  Action onGetAction(Game game) {
    // Recharge moves.
    for (var move in breed.moves) {
      _recharges[move] = math.max(0.0, _recharges[move]! - 1.0);
    }

    // Use the monster's senses to update its mood.
    var awareness = 0.0;
    awareness += _seeHero(game);
    awareness += _hearHero(game);
    // TODO: Smell?

    // Persist some of the awareness. Note that the historical and current
    // awareness don't sum to 1.0. This is so that alertness gradually fades.
    // TODO: The ratio here could be tuned by breeds where some have longer
    // memories than others.
    _alertness = _alertness * 0.75 + awareness * 0.2;
    _alertness = _alertness.clamp(0.0, _maxAlertness);

    _decayFear(game);
    _fear = _fear.clamp(0.0, _frightenThreshold);

    var notice = math.max(awareness, _alertness);

    Debug.monsterStat(this, "aware", awareness);
    Debug.monsterStat(this, "alert", _alertness);
    Debug.monsterStat(this, "notice", notice);
    Debug.monsterStat(this, "fear", _fear / _frightenThreshold);

    // TODO: If standing in substance, should try to get out if harmful.

    // See if we want to change state.
    switch (_state) {
      case AsleepState() when _fear > _frightenThreshold:
        _resetCharges();
        return ChangeMonsterStateAction("{1} is afraid!", AfraidState(),
            event: EventType.frighten);

      case AsleepState() when rng.percent(_awakenPercent(notice)):
        _alertness = _maxAlertness;
        _resetCharges();

        // TODO: Probably shouldn't add event if monster woke up because they
        // were hit.
        return ChangeMonsterStateAction("{1} wakes up!", AwakeState(),
            event: EventType.awaken);

      case AwakeState() when _fear > _frightenThreshold:
        return ChangeMonsterStateAction("{1} is afraid!", AfraidState(),
            event: EventType.frighten);

      case AwakeState() when notice < 0.01:
        _alertness = 0.0;
        return ChangeMonsterStateAction("{1} falls asleep.", AsleepState());

      case AfraidState() when _fear <= 0.0:
        return ChangeMonsterStateAction(
            "{1} find[s] {1 his} courage.", AwakeState());

      default:
        // Keep the current state.
        return _state.getAction(game);
    }
  }

  /// The percent chance of waking up at [notice].
  int _awakenPercent(double notice) {
    // At boundaries, either always or never wake up.
    if (notice < 0.1) return 0;
    if (notice > 0.8) return 100;

    // Between them, gradually increasing chance of waking up.
    var normal = lerpDouble(notice, 0.1, 0.8, 0.0, 1.0);
    return lerpDouble(normal * normal * normal, 0.0, 1.0, 5.0, 100.0).round();
  }

  double _seeHero(Game game) {
    if (breed.vision == 0) {
      Debug.monsterStat(this, "see", 0.0, "sightless");
      return 0.0;
    }

    var heroPos = game.hero.pos;
    if (!game.stage.canView(this, heroPos)) {
      Debug.monsterStat(this, "see", 0.0, "out of sight");
      return 0.0;
    }

    // TODO: Don't check illumination for breeds that see in the dark.
    var illumination = game.stage[heroPos].illumination;
    if (illumination == 0) {
      Debug.monsterStat(this, "see", 0.0, "hero in dark");
      return 0.0;
    }

    var distance = (heroPos - pos).kingLength;
    if (distance >= breed.vision) {
      Debug.monsterStat(this, "see", 0.0, "too far");
      return 0.0;
    }

    var visibility = (breed.vision - distance) / breed.vision;
    Debug.monsterStat(this, "see", illumination * visibility);
    return (illumination / 64) * visibility;

    // TODO: Can the monster see other changes? Other monsters moving?
  }

  double _hearHero(Game game) {
    if (breed.hearing == 0) {
      Debug.monsterStat(this, "hear", 0.0, "deaf");
      return 0.0;
    }

    // TODO: Hear other monsters?
    // Hearing is simply the amount of noise the hero made, scaled by the
    // hero's volume level from here and the breed's normalized hearing ability.
    var volume =
        game.stage.heroVolume(pos) * game.hero.lastNoise * breed.hearing / 10;
    Debug.monsterStat(
        this, "hear", volume, "noise ${game.hero.lastNoise}, volume $volume");
    return volume;
  }

  /// Modifies fear and then determines if it has crossed the threshold to
  /// cause a state change.
  void _modifyFear(double offset) {
    // Don't add effects if the monster already died.
    if (!isAlive) return;

    if (breed.flags.fearless) return;

    // If it doesn't flee, there's no point in being afraid.
    if (breed.flags.immobile) return;

    _fear = math.max(0.0, _fear + offset);
  }

  /// Adds an audible signal at [volume] to the monster's alertness.
  void hear(double volume) {
    _alertness += volume * breed.hearing;
    _alertness = _alertness.clamp(0.0, _maxAlertness);
  }

  MonsterState awaken() {
    var state = AwakeState();
    _changeState(state);
    return state;
  }

  void _changeState(MonsterState state) {
    _state = state;
    _state.bind(this);
  }

  @override
  List<Hit> onCreateMeleeHits(Actor? defender) =>
      [rng.item(breed.attacks).createHit()];

  // TODO: Breed resistances.
  @override
  int onGetResistance(Element element) => 0;

  /// Inflicting damage decreases fear.
  @override
  void onGiveDamage(Action action, Actor defender, int damage) {
    // The greater the power of the hit, the more emboldening it is.
    var fear = 100.0 * damage / action.game.hero.maxHealth;

    _modifyFear(-fear);
    Debug.monsterReason(this, "fear",
        "hit for $damage/${action.game.hero.maxHealth} decrease by $fear");

    // Nearby monsters may witness it.
    _updateWitnesses(action.game, (witness) {
      witness._viewHeroDamage(action, damage);
    });
  }

  /// This is called when another monster in sight of this one has damaged the
  /// hero.
  void _viewHeroDamage(Action action, int damage) {
    if (isAsleep) return;

    var fear = 50.0 * damage / maxHealth;

    _modifyFear(-fear);
    Debug.monsterReason(
        this, "fear", "witness $damage/$maxHealth decrease by $fear");
  }

  /// Taking damage increases fear.
  @override
  void onTakeDamage(Action action, Actor? attacker, int damage) {
    _alertness = _maxAlertness;

    // The greater the power of the hit, the more frightening it is.
    var fear = 100.0 * damage / maxHealth;

    // Getting hurt enrages it.
    if (breed.flags.berzerk) fear *= -3.0;

    _modifyFear(fear);
    Debug.monsterReason(
        this, "fear", "hit for $damage/$maxHealth increases by $fear");

    // Nearby monsters may witness it.
    _updateWitnesses(action.game, (witness) {
      witness._viewMonsterDamage(action, this, damage);
    });

    // See if the monster does anything when hit.
    var moves = breed.moves
        .where((move) => move.shouldUseOnDamage(this, damage))
        .toList();
    if (moves.isNotEmpty) {
      action.addAction(rng.item(moves).getAction(action.game, this), this);
    }
  }

  /// This is called when another monster in sight of this one has taken
  /// damage.
  void _viewMonsterDamage(Action action, Monster monster, int damage) {
    if (isAsleep) return;

    var fear = 50.0 * damage / maxHealth;

    if (breed.flags.protective && monster.breed == breed) {
      // Seeing its own kind get hurt enrages it.
      fear *= -2.0;
    } else if (breed.flags.berzerk) {
      // Seeing any monster get hurt enrages it.
      fear *= -1.0;
    }

    _modifyFear(fear);
    Debug.monsterReason(
        this, "fear", "witness $damage/$maxHealth increase by $fear");
  }

  /// Called when this Actor has been killed by [attackNoun].
  @override
  void onDied(Action action, Noun attackNoun) {
    var items =
        action.game.stage.placeDrops(pos, breed.drop, depth: breed.depth);
    for (var item in items) {
      action.show("{1} drop[s] {2}.", this, item);
    }

    action.game.stage.removeActor(this);
  }

  @override
  void onChangePosition(Game game, Vec from, Vec to) {
    // If the monster is (or was) visible, don't let the hero rest through it
    // moving.
    if (game.stage[from].isVisible || game.stage[to].isVisible) {
      game.hero.disturb();
    }

    // If the monster came into view, make sure the hero has seen it.
    if (!game.stage[from].isVisible && game.stage[to].isVisible) {
      game.hero.seeMonster(this);
    }
  }

  /// Invokes [callback] on all nearby monsters that can see this one.
  void _updateWitnesses(Game game, void Function(Monster monster) callback) {
    for (var other in game.stage.actors) {
      if (other == this) continue;
      if (other is! Monster) continue;

      // TODO: Take breed vision into account.
      var distance = (other.pos - pos).kingLength;
      if (distance > 20) continue;

      if (game.stage.canView(other, pos)) callback(other);
    }
  }

  /// Fear decays over time, more quickly the farther the monster is from the
  /// hero.
  void _decayFear(Game game) {
    // TODO: Poison should slow the decay of fear.
    var fearDecay = 5.0 + (pos - game.hero.pos).kingLength;

    // Fear decays more quickly if out of sight.
    if (!game.stage.isVisibleToHero(this)) fearDecay = 5.0 + fearDecay * 2.0;

    // The closer the monster is to death, the less quickly it gets over fear.
    fearDecay = 2.0 + fearDecay * health / maxHealth;

    _modifyFear(-fearDecay);
  }

  /// Randomizes the monster's charges.
  ///
  /// Ensures the monster doesn't immediately unload everything on the hero
  /// when first spotted.
  void _resetCharges() {
    for (var move in breed.moves) {
      _recharges[move] = rng.float(move.rate / 2);
    }
  }
}

/// Action that changes a monster to a given state and then performs that
/// state's action.
class ChangeMonsterStateAction extends Action {
  final String _message;
  final MonsterState _state;
  final EventType? _event;

  ChangeMonsterStateAction(this._message, this._state, {EventType? event})
      : _event = event;

  @override
  ActionResult onPerform() {
    // Let the player know the monster changed.
    show(_message, actor);

    if (_event case var event?) {
      addEvent(event, actor: actor);
    }

    monster._changeState(_state);

    // Now let the new state decide what the monster does.
    return alternate(monster._state.getAction(game));
  }
}
