library hauberk.engine.actor;

import 'package:piecemeal/piecemeal.dart';

import 'action/action.dart';
import 'attack.dart';
import 'condition.dart';
import 'element.dart';
import 'energy.dart';
import 'game.dart';
import 'log.dart';

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
  Pronoun get pronoun => Pronoun.IT;

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
  final Condition dazzle = new DazzleCondition();

  // Temporary resistance to elements.
  final resistances = <Element, ResistCondition>{};

  // All [Condition]s for the actor.
  Iterable<Condition> get conditions => <Condition>[
    haste,
    cold,
    poison,
    dazzle
  ]..addAll(resistances.values);

  Actor(this.game, int x, int y, int health)
      : health = new Stat(health),
        super(new Vec(x, y)) {
    for (var element in Element.ALL) {
      resistances[element] = new ResistCondition(element);
    }

    conditions.forEach((condition) => condition.bind(this));
  }

  bool get isAlive => health.current > 0;

  /// Whether or not the actor can be seen by the [Hero].
  bool get isVisible => game.stage[pos].visible;

  bool get needsInput => false;

  bool get canOpenDoors => true;

  /// Gets the actor's current speed, taking into any account any active
  /// [Condition]s.
  int get speed {
    var speed = onGetSpeed();
    speed += haste.intensity;
    speed -= cold.intensity;
    return speed;
  }

  /// The actor's dodge ability. This is the percentage chance of a melee
  /// attack missing the actor.
  int get dodge {
    var dodge = 15;

    // Hard to block an attack you can't see coming.
    if (dazzle.isActive) dodge -= 5;

    return dodge;
  }

  void changePosition(Vec from, Vec to) {
    game.stage.moveActor(from, to);
  }

  int onGetSpeed();

  Action getAction() {
    final action = onGetAction();
    if (action != null) action.bind(this, true);
    return action;
  }

  Action onGetAction();

  /// Get an [Attack] for this [Actor] to attempt to hit [defender].
  Attack getAttack(Actor defender) {
    var attack = onGetAttack(defender);

    // Hard to hit an actor you can't see.
    if (dazzle.isActive) attack = attack.addStrike(-5);

    return attack;
  }

  /// Get an [Attack] for this [Actor] to attempt to hit [defender].
  Attack onGetAttack(Actor defender);

  /// This is called on the defender when some attacker is attempting to hit it.
  /// The defender can modify the attack or simply return the incoming one.
  Attack defend(Attack attack) {
    // Apply temporary resistance.
    var resistance = resistances[attack.element];
    if (resistance.isActive) {
      attack = attack.addResistance(resistance.intensity);
    }

    return attack;
  }

  /// Reduces the actor's health by [damage], and handles its death. Returns
  /// `true` if the actor died.
  bool takeDamage(Action action, int damage, Noun attackNoun,
                  [Actor attacker]) {
    health.current -= damage;
    onDamaged(action, attacker, damage);

    if (health.current > 0) return false;

    action.addEvent(EventType.DIE, actor: this);

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

    if (game.stage[pos].isPassable) return true;
    return game.stage[pos].isTraversable && canOpenDoors;
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
    _current = clamp(0, value, _max);
  }

  int get max => _max;
  void set max(int value) {
    _max = value;

    // Make sure current is still in bounds.
    _current = clamp(0, _current, _max);
  }

  bool get isMax => _current == _max;

  Stat(int value)
  : _current = value,
    _max = value;
}
