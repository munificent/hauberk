library dngn.engine.actor;

import '../util.dart';
import 'action_base.dart';
import 'condition.dart';
import 'energy.dart';
import 'game.dart';
import 'log.dart';
import 'melee.dart';

abstract class Thing implements Noun {
  Vec _pos;

  Thing(this._pos);

  Vec get pos => _pos;
  void set pos(Vec value) {
    if (value != _pos) {
      _pos = changePosition(value);
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

  /// Called when the actor's position is about to change to [pos]. Override
  /// to do stuff when the position changes. Returns the new position.
  Vec changePosition(Vec pos) => pos;

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

  /// Eating food lets the actor slowly regenerate health.
  final Condition food = new FoodCondition();

  final Condition haste = new HasteCondition();

  Actor(this.game, int x, int y, int health)
  : super(new Vec(x, y)),
    health = new Stat(health) {
    food.bind(this);
    haste.bind(this);
  }

  bool get isAlive => health.current > 0;

  /// Whether or not the actor can be seen by the [Hero].
  bool get isVisible => game.stage[pos].visible;

  bool get needsInput => false;

  /// Gets the actor's current speed, taking into any account any active
  /// [Condition]s.
  int get speed {
    var speed = onGetSpeed();
    speed += haste.intensity;
    return speed;
  }

  int onGetSpeed();

  Action getAction() {
    final action = onGetAction();
    if (action != null) action.bind(this, true);
    return action;
  }

  Action onGetAction();

  /// Get an [Attack] for this [Actor] to attempt to hit [defender].
  Attack getAttack(Actor defender);

  /// This is called on the defender when some attacker is attempting to hit it.
  /// The defender can modify the attack or simply return the incoming one.
  Attack defend(Attack attack) => attack;

  /// Called when this actor has successfully hit this [defender].
  void onDamage(Action action, Actor defender, int damage) {
    // Do nothing.
  }

  /// Called when [attacker] has successfully hit this actor.
  void onDamaged(Action action, Actor attacker, int damage) {
    // Do nothing.
  }

  /// Called when this Actor has been killed by [attacker].
  void onDied(Actor attacker) {
    // Do nothing.
  }

  /// Called when this Actor has killed [defender].
  void onKilled(Actor defender) {
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

    return game.stage[pos].isPassable;
  }

  void finishTurn(Action action) {
    energy.spend();

    // TODO: Move food to hero?
    food.update();
    haste.update();

    onFinishTurn(action);
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
