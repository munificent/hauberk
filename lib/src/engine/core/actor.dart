import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import 'combat.dart';
import 'condition.dart';
import 'element.dart';
import 'energy.dart';
import 'game.dart';
import 'log.dart';
import 'tile.dart';

abstract class Thing implements Noun {
  Vec _pos;

  Thing(this._pos);

  Vec get pos => _pos;
  void set pos(Vec value) {
    if (value != _pos) {
      changePosition(_pos, value);
      _pos = value;
    }
  }

  int get x => pos.x;
  void set x(int value) {
    pos = new Vec(value, y);
  }

  int get y => pos.y;
  void set y(int value) {
    pos = new Vec(x, value);
  }

  /// Called when the actor's position is about to change from [from] to [to].
  void changePosition(Vec from, Vec to) {}

  get appearance;
  String get nounText;
  Pronoun get pronoun => Pronoun.it;

  String toString() => nounText;
}

/// An active entity in the game. Includes monsters and the hero.
abstract class Actor extends Thing {
  final Game game;
  final Stat health;
  final Energy energy = new Energy();

  /// Haste raises speed.
  final Condition haste = new HasteCondition();

  /// Cold lowers speed.
  final Condition cold = new ColdCondition();

  /// Poison inflicts damage each turn.
  final Condition poison = new PoisonCondition();

  /// Makes it hard for the actor to see.
  final Condition blindness = new BlindnessCondition();

  /// Makes it hard for the actor to see.
  final Condition dazzle = new BlindnessCondition();

  // Temporary resistance to elements.
  final resistances = <Element, ResistCondition>{};

  // All [Condition]s for the actor.
  Iterable<Condition> get conditions => <Condition>[
        haste,
        cold,
        poison,
        blindness,
        dazzle
      ]..addAll(resistances.values);

  Actor(this.game, int x, int y, int health)
      : health = new Stat(health),
        super(new Vec(x, y)) {
    for (var element in game.content.elements) {
      resistances[element] = new ResistCondition(element);
    }

    conditions.forEach((condition) => condition.bind(this));
  }

  bool get isAlive => health.current > 0;

  /// Whether or not the actor can be seen by the [Hero].
  bool get isVisible => game.stage[pos].visible;

  /// Whether the actor's vision is currently impaired.
  bool get isBlinded => blindness.isActive || dazzle.isActive;

  bool get needsInput => false;

  MotilitySet get motilities;

  /// Gets the actor's current speed, taking into any account any active
  /// [Condition]s.
  int get speed {
    var speed = onGetSpeed();
    speed += haste.intensity;
    speed -= cold.intensity;
    return speed;
  }

  /// Additional ways the actor can avoid a hit beyond dodging it.
  Iterable<Defense> get defenses sync* {
    var dodge = 20 + onGetDodge();

    // Hard to dodge an attack you can't see coming.
    if (isBlinded) dodge ~/= 2;

    if (dodge != 0) yield new Defense(dodge, "{1} dodge[s] {2}.");

    yield* onGetDefenses();
  }

  /// The amount of protection against damage the actor has.
  int get armor;

  void changePosition(Vec from, Vec to) {
    game.stage.moveActor(from, to);
  }

  int onGetSpeed();

  /// The actor's base dodge ability. This is the percentage chance of a melee
  /// attack missing the actor.
  int onGetDodge();

  Iterable<Defense> onGetDefenses();

  Action getAction() {
    final action = onGetAction();
    if (action != null) action.bind(this, true);
    return action;
  }

  Action onGetAction();

  /// Create a new [Hit] for this [Actor] to attempt to hit some defender.
  Hit createMeleeHit() {
    var hit = onCreateMeleeHit();
    modifyHit(hit, HitType.melee);
    return hit;
  }

  Hit onCreateMeleeHit();

  /// Applies the hit modifications from the actor.
  void modifyHit(Hit hit, HitType type) {
    // Hard to hit an actor you can't see.
    if (isBlinded) {
      switch (type) {
        case HitType.melee:
          hit.scaleStrike(0.5);
          break;
        case HitType.ranged:
          hit.scaleStrike(0.3);
          break;
        case HitType.toss:
          hit.scaleStrike(0.2);
          break;
      }
    }

    // Let the subclass also modify it.
    onModifyHit(hit, type);
  }

  void onModifyHit(Hit hit, HitType type) {}

  /// This is called on the defender when some attacker is attempting to hit it.
  void defend();

  /// The amount of resistance the actor currently has to [element].
  ///
  /// Every level of resist reduces the damage taken by an attack of that
  /// element by 1/(resistance + 1), so that 1 resist is half damange, 2 is
  /// third, etc.
  int resistance(Element element) {
    // TODO: What about negative resists?

    // Get the base resist from the subclass.
    var result = onGetResistance(element);

    // Apply temporary resistance.
    var resistance = resistances[element];
    if (resistance.isActive) {
      result += resistance.intensity;
    }

    return result;
  }

  int onGetResistance(Element element);

  /// Reduces the actor's health by [damage], and handles its death. Returns
  /// `true` if the actor died.
  bool takeDamage(Action action, int damage, Noun attackNoun,
      [Actor attacker]) {
    health.current -= damage;
    onDamaged(action, attacker, damage);

    if (health.current > 0) return false;

    action.addEvent(EventType.die, actor: this);

    action.log("{1} kill[s] {2}.", attackNoun, this);
    if (attacker != null) attacker.onKilled(action, this);

    onDied(attackNoun);

    return true;
  }

  /// Called when this actor has successfully hit this [defender].
  void onDamage(Action action, Actor defender, int damage) {
    // Do nothing.
  }

  /// Called when [attacker] has successfully hit this actor.
  ///
  /// [attacker] may be `null` if the damage is not the direct result of an
  /// attack (for example, poison).
  void onDamaged(Action action, Actor attacker, int damage) {
    // Do nothing.
  }

  /// Called when this Actor has been killed by [attackNoun].
  void onDied(Noun attackNoun) {
    // Do nothing.
  }

  /// Called when this Actor has killed [defender].
  void onKilled(Action action, Actor defender) {
    // Do nothing.
  }

  /// Called when this Actor has completed a turn.
  void onFinishTurn(Action action) {
    // Do nothing.
  }

  bool canOccupy(Vec pos) {
    if (pos.x < 0) return false;
    if (pos.x >= game.stage.width) return false;
    if (pos.y < 0) return false;
    if (pos.y >= game.stage.height) return false;

    var tile = game.stage[pos];
    return tile.canEnterAny(motilities);
  }

  void finishTurn(Action action) {
    energy.spend();

    conditions.forEach((condition) => condition.update(action));

    if (isAlive) onFinishTurn(action);
  }

  /// Logs [message] if the actor is visible to the hero.
  void log(String message, [Noun noun1, Noun noun2, Noun noun3]) {
    if (!isVisible) return;
    game.log.message(message, noun1, noun2, noun3);
  }
}

class Stat {
  int _current;
  int _max;

  int get current => _current;
  void set current(int value) {
    _current = value.clamp(0, _max);
  }

  int get max => _max;
  void set max(int value) {
    _max = value;

    // Make sure current is still in bounds.
    _current = _current.clamp(0, _max);
  }

  bool get isMax => _current == _max;

  Stat(int value)
      : _current = value,
        _max = value;
}
