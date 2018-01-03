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
import '../hero/hero.dart';
import '../stage/lighting.dart';
import '../stage/tile.dart';
import 'breed.dart';
import 'monster_states.dart';
import 'move.dart';

class Monster extends Actor {
  static const _maxAlertness = 1.0;

  final Breed breed;

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

  MotilitySet get motilities => breed.motilities;

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

  get appearance => breed.appearance;

  String get nounText => 'the ${breed.name}';
  Pronoun get pronoun => breed.pronoun;

  /// How much experience a level one [Hero] gains for killing this monster.
  int get experienceCents => breed.experienceCents;

  /// Instead of armor, we just scale up the health for different breeds to
  /// accomplish the same thing.
  int get armor => 0;

  // TODO: Allow breeds to affect this.
  int get emanationLevel => 0;

  Monster(Game game, this.breed, int x, int y, int maxHealth, this.generation)
      : super(game, x, y, maxHealth) {
    Debug.addMonster(this);
    changeState(new AsleepState());

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
    for (final step in new Line(pos, target)) {
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
    for (final step in new Line(pos, target)) {
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

    var notice = awareness + _alertness * 0.2;

    // Persist some of the awareness.
    // TODO: The ratio here could be tuned by breeds where some have longer
    // memories than others.
    _alertness = _alertness * 0.8 + awareness * 0.2;
    _alertness = _alertness.clamp(0.0, _maxAlertness);

    _decayFear();
    _fear = _fear.clamp(0.0, _frightenThreshold);

    _updateState(notice);
    return _state.getAction();
  }

  void _updateState(double notice) {
    // See if we want to change state.
    if (isAsleep) {
      if (_fear > _frightenThreshold) {
        log("{1} is afraid!", this);

        _resetCharges();
        changeState(new AfraidState());
      } else if (rng.float(1.4) <= notice) {
        if (isVisibleToHero) {
          log("{1} wakes up!", this);
        } else {
          log("Something stirs in the darkness.");
        }

        _alertness = _maxAlertness;
        _resetCharges();
        changeState(new AwakeState());
      }
    } else if (isAwake) {
      if (_fear > _frightenThreshold) {
        log("{1} is afraid!", this);
        changeState(new AfraidState());
      } else if (_alertness < 0.01) {
        if (isVisibleToHero) {
          log("{1} falls asleep!", this);
        }

        _alertness = 0.0;
        changeState(new AsleepState());
      }
    } else if (isAfraid) {
      if (_fear <= 0.0) {
        log("{1} grows courageous!", this);
        changeState(new AwakeState());
      }
    }
  }

  double _seeHero() {
    if (breed.vision == 0) return 0.0;

    var heroPos = game.hero.pos;
    if (!canView(heroPos)) return 0.0;

    // TODO: Don't check illumination for breeds that see in the dark.
    var illumination = game.stage[heroPos].illumination / Lighting.max;
    if (illumination == 0.0) return 0.0;

    var distance = (heroPos - pos).kingLength;
    if (distance >= breed.vision) return 0.0;

    var visibility = (breed.vision - distance) / breed.vision;
    return illumination * visibility;

    // TODO: Can the monster see other changes? Other monsters moving?
  }

  double _hearHero() {
    if (breed.hearing == 0) return 0.0;

    // TODO: Hear other monsters?
    var distance = game.stage.heroAuditoryDistance(pos);
    if (distance >= breed.hearing) return 0.0;

    var audibility = (breed.hearing - distance) / breed.hearing;
    return game.hero.lastNoise * audibility;
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

  /// Changes the monster to its awake state on its next turn, if sleeping.
  void wakeUp() {
    _alertness = _maxAlertness;
  }

  void changeState(MonsterState state) {
    _state = state;
    _state.bind(this);
  }

  Hit onCreateMeleeHit() => rng.item(breed.attacks).createHit();

  // TODO: Breed resistances.
  int onGetResistance(Element element) => 0;

  /// Inflicting damage decreases fear.
  void onGiveDamage(Action action, Actor defender, int damage) {
    // The greater the power of the hit, the more emboldening it is.
    var fear = 100.0 * damage / game.hero.health.max;

    _modifyFear(-fear);
    Debug.logMonster(
        this,
        "Hit for ${damage} / ${game.hero.health.max} "
        "decreases fear by ${fear} to $_fear");

    // Nearby monsters may witness it.
    _updateWitnesses((witness) {
      witness._viewHeroDamage(action, damage);
    });
  }

  /// This is called when another monster in sight of this one has damaged the
  /// hero.
  void _viewHeroDamage(Action action, int damage) {
    if (isAsleep) return;

    var fear = 50.0 * damage / health.max;

    _modifyFear(-fear);
    Debug.logMonster(
        this,
        "Witness ${damage} / ${health.max} "
        "decreases fear by ${fear} to $_fear");
  }

  /// Taking damage increases fear.
  void onTakeDamage(Action action, Actor attacker, int damage) {
    _alertness = _maxAlertness;

    // The greater the power of the hit, the more frightening it is.
    var fear = 100.0 * damage / health.max;

    // Getting hurt enrages it.
    if (breed.flags.berzerk) fear *= -3.0;

    _modifyFear(fear);
    Debug.logMonster(
        this,
        "Hit for ${damage} / ${health.max} "
        "increases fear by ${fear} to $_fear");

    // Nearby monsters may witness it.
    _updateWitnesses((witness) {
      witness._viewMonsterDamage(action, this, damage);
    });
  }

  /// This is called when another monster in sight of this one has taken
  /// damage.
  void _viewMonsterDamage(Action action, Monster monster, int damage) {
    if (isAsleep) return;

    var fear = 50.0 * damage / health.max;

    if (breed.flags.protective && monster.breed == breed) {
      // Seeing its own kind get hurt enrages it.
      fear *= -2.0;
    } else if (breed.flags.berzerk) {
      // Seeing any monster get hurt enrages it.
      fear *= -1.0;
    }

    _modifyFear(fear);
    Debug.logMonster(
        this,
        "Witness ${damage} / ${health.max} "
        "increases fear by ${fear} to $_fear");
  }

  /// Called when this Actor has been killed by [attackNoun].
  void onDied(Noun attackNoun) {
    var items = game.stage.placeDrops(pos, breed.motilities, breed.drop);
    for (var item in items) {
      log("{1} drop[s] {2}.", this, item);
    }

    game.stage.removeActor(this);
    Debug.removeMonster(this);
  }

  void changePosition(Vec from, Vec to) {
    super.changePosition(from, to);

    // If the monster is (or was) visible, don't let the hero rest through it
    // moving.
    if (game.stage[from].isVisible || game.stage[to].isVisible) {
      game.hero.disturb();
    }

    // If the monster just entered an explored tile, make sure the hero has
    // seen it.
    if (!game.stage[from].isExplored && game.stage[to].isExplored) {
      game.hero.seeMonster(this);
    }
  }

  /// Invokes [callback] on all nearby monsters that can see this one.
  void _updateWitnesses(callback(Monster monster)) {
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
    fearDecay = 2.0 + fearDecay * health.current / health.max;

    _modifyFear(-fearDecay);
    Debug.logMonster(this, "Decay fear by $fearDecay to $_fear");
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
