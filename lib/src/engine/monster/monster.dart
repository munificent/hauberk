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
import '../stage/lighting.dart';
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

  MonsterState _state;

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
  double _frightenThreshold;

  double get fear => _fear;

  Object get appearance => breed.appearance;

  String get nounText => 'the ${breed.name}';

  Pronoun get pronoun => breed.pronoun;

  /// How much experience the [Hero] gains for killing this monster.
  int get experience => breed.experience;

  int get maxHealth => breed.maxHealth;

  /// Instead of armor, we just scale up the health for different breeds to
  /// accomplish the same thing.
  int get armor => 0;

  int get emanationLevel => breed.emanationLevel;

  /// How much the monster relies on sight to sense the hero, from 0.0 to 1.0.
  double get sightReliance {
    var senses = breed.vision + breed.hearing;
    if (senses == 0) return 0.0;
    return breed.vision / senses;
  }

  Monster(Game game, this._breed, int x, int y, this.generation)
      : super(game, x, y) {
    health = maxHealth;

    _changeState(AsleepState());

    /// Give this some random variation within monsters of the same breed so
    /// they don't all become frightened at the same time.
    _frightenThreshold = rng.range(60, 200).toDouble();
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
    _recharges[move] += rng.float(move.rate, move.rate * 1.3);
  }

  /// Returns `true` if [move] is recharged.
  bool canUse(Move move) => _recharges[move] == 0.0;

  /// Gets whether or not this monster has a line of sight to [target].
  ///
  /// Does not take into account if there are other [Actor]s between the monster
  /// and the target.
  bool canView(Vec target) {
    // Walk to the target.
    for (var step in Line(pos, target)) {
      if (step == target) return true;
      if (game.stage[step].blocksView) return false;
    }

    throw 'unreachable';
  }

  /// Gets whether or not this monster has a line of sight to [target].
  ///
  /// Does take into account if there are other [Actor]s between the monster
  /// and the target.
  bool canTarget(Vec target) {
    // Walk to the target.
    for (var step in Line(pos, target)) {
      if (step == target) return true;
      if (game.stage.actorAt(step) != null) return false;
      if (game.stage[step].blocksView) return false;
    }

    throw 'unreachable';
  }

  int get baseSpeed => Energy.normalSpeed + breed.speed;

  int get baseDodge => breed.dodge;

  Iterable<Defense> onGetDefenses() => breed.defenses;

  Action onGetAction() {
    // Recharge moves.
    for (var move in breed.moves) {
      _recharges[move] = math.max(0.0, _recharges[move] - 1.0);
    }

    // Use the monster's senses to update its mood.
    var awareness = 0.0;
    awareness += _seeHero();
    awareness += _hearHero();
    // TODO: Smell?

    // Persist some of the awareness. Note that the historical and current
    // awareness don't sum to 1.0. This is so that alertness gradually fades.
    // TODO: The ratio here could be tuned by breeds where some have longer
    // memories than others.
    _alertness = _alertness * 0.75 + awareness * 0.2;
    _alertness = _alertness.clamp(0.0, _maxAlertness);

    _decayFear();
    _fear = _fear.clamp(0.0, _frightenThreshold);

    var notice = math.max(awareness, _alertness);

    Debug.monsterStat(this, "aware", awareness);
    Debug.monsterStat(this, "alert", _alertness);
    Debug.monsterStat(this, "notice", notice);
    Debug.monsterStat(this, "fear", _fear / _frightenThreshold);

    // TODO: If standing in substance, should try to get out if harmful.

    _updateState(notice);
    return _state.getAction();
  }

  void _updateState(double notice) {
    // See if we want to change state.
    if (isAsleep) {
      if (_fear > _frightenThreshold) {
        log("{1} is afraid!", this);
        game.addEvent(EventType.frighten, actor: this);

        _resetCharges();
        _changeState(AfraidState());
      } else if (rng.percent(_awakenPercent(notice))) {
        log("{1} wakes up!", this);

        // TODO: Probably shouldn't add event if monster woke up because they
        // were hit.
        game.addEvent(EventType.awaken, actor: this);

        _alertness = _maxAlertness;
        _resetCharges();
        _changeState(AwakeState());
      }
    } else if (isAwake) {
      if (_fear > _frightenThreshold) {
        log("{1} is afraid!", this);
        game.addEvent(EventType.frighten, actor: this);
        _changeState(AfraidState());
      } else if (notice < 0.01) {
        log("{1} falls asleep!", this);

        _alertness = 0.0;
        _changeState(AsleepState());
      }
    } else if (isAfraid) {
      if (_fear <= 0.0) {
        log("{1} grows courageous!", this);
        _changeState(AwakeState());
      }
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

  double _seeHero() {
    if (breed.vision == 0) {
      Debug.monsterStat(this, "see", 0.0, "sightless");
      return 0.0;
    }

    var heroPos = game.hero.pos;
    if (!canView(heroPos)) {
      Debug.monsterStat(this, "see", 0.0, "out of sight");
      return 0.0;
    }

    // TODO: Don't check illumination for breeds that see in the dark.
    var illumination = game.stage[heroPos].illumination / Lighting.max;
    if (illumination == 0.0) {
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
    return illumination * visibility;

    // TODO: Can the monster see other changes? Other monsters moving?
  }

  double _hearHero() {
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

  List<Hit> onCreateMeleeHits(Actor defender) =>
      [rng.item(breed.attacks).createHit()];

  // TODO: Breed resistances.
  int onGetResistance(Element element) => 0;

  /// Inflicting damage decreases fear.
  void onGiveDamage(Action action, Actor defender, int damage) {
    // The greater the power of the hit, the more emboldening it is.
    var fear = 100.0 * damage / game.hero.maxHealth;

    _modifyFear(-fear);
    Debug.monsterReason(this, "fear",
        "hit for $damage/${game.hero.maxHealth} decrease by $fear");

    // Nearby monsters may witness it.
    _updateWitnesses((witness) {
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
  void onTakeDamage(Action action, Actor attacker, int damage) {
    _alertness = _maxAlertness;

    // The greater the power of the hit, the more frightening it is.
    var fear = 100.0 * damage / maxHealth;

    // Getting hurt enrages it.
    if (breed.flags.berzerk) fear *= -3.0;

    _modifyFear(fear);
    Debug.monsterReason(
        this, "fear", "hit for $damage/$maxHealth increases by $fear");

    // Nearby monsters may witness it.
    _updateWitnesses((witness) {
      witness._viewMonsterDamage(action, this, damage);
    });

    // See if the monster does anything when hit.
    var moves = breed.moves
        .where((move) => move.shouldUseOnDamage(this, damage))
        .toList();
    if (moves.isNotEmpty) {
      action.addAction(rng.item(moves).getAction(this), this);
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
  void onDied(Noun attackNoun) {
    // TODO: Is using the breed's motility correct? We probably don't want
    // drops going through doors.
    var items = game.stage.placeDrops(pos, breed.motility, breed.drop);
    for (var item in items) {
      log("{1} drop[s] {2}.", this, item);
    }

    game.stage.removeActor(this);
  }

  void changePosition(Vec from, Vec to) {
    super.changePosition(from, to);

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
  void _updateWitnesses(void Function(Monster monster) callback) {
    for (var other in game.stage.actors) {
      if (other == this) continue;

      if (other is! Monster) continue;
      var monster = other as Monster;

      // TODO: Take breed vision into account.
      var distance = (monster.pos - pos).kingLength;
      if (distance > 20) continue;

      if (monster.canView(pos)) callback(monster);
    }
  }

  /// Fear decays over time, more quickly the farther the monster is from the
  /// hero.
  void _decayFear() {
    // TODO: Poison should slow the decay of fear.
    var fearDecay = 5.0 + (pos - game.hero.pos).kingLength;

    // Fear decays more quickly if out of sight.
    if (!isVisibleToHero) fearDecay = 5.0 + fearDecay * 2.0;

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
