import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../stage/tile.dart';
import 'combat.dart';
import 'condition.dart';
import 'element.dart';
import 'energy.dart';
import 'game.dart';
import 'log.dart';

/// An active entity in the game. Includes monsters and the hero.
abstract class Actor implements Noun {
  final Game game;
  final Energy energy = Energy();

  /// Haste raises speed.
  final Condition haste = HasteCondition();

  /// Cold lowers speed.
  final Condition cold = ColdCondition();

  /// Poison inflicts damage each turn.
  final Condition poison = PoisonCondition();

  /// Makes it hard for the actor to see.
  final Condition blindness = BlindnessCondition();

  /// Makes it hard for the actor to see.
  final Condition dazzle = BlindnessCondition();

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

  Vec _pos;

  Vec get pos => _pos;

  void set pos(Vec value) {
    if (value != _pos) {
      changePosition(_pos, value);
      _pos = value;
    }
  }

  int get x => pos.x;

  void set x(int value) {
    pos = Vec(value, y);
  }

  int get y => pos.y;

  void set y(int value) {
    pos = Vec(x, value);
  }

  int _health;

  int get health => _health;

  void set health(int value) {
    _health = value.clamp(0, maxHealth);
  }

  Actor(this.game, int x, int y) : _pos = Vec(x, y) {
    for (var element in game.content.elements) {
      resistances[element] = ResistCondition(element);
    }

    conditions.forEach((condition) => condition.bind(this));
  }

  Object get appearance;

  String get nounText;

  Pronoun get pronoun => Pronoun.it;

  bool get isAlive => health > 0;

  /// Whether or not the actor can be seen by the [Hero].
  bool get isVisibleToHero => game.stage[pos].isVisible;

  /// Whether the actor's vision is currently impaired.
  bool get isBlinded => blindness.isActive || dazzle.isActive;

  bool get needsInput => false;

  Motility get motility;

  int get maxHealth;

  /// Gets the actor's current speed, taking into any account any active
  /// [Condition]s.
  int get speed {
    var speed = baseSpeed;
    speed += haste.intensity;
    speed -= cold.intensity;
    return speed;
  }

  /// Additional ways the actor can avoid a hit beyond dodging it.
  Iterable<Defense> get defenses sync* {
    var dodge = baseDodge;

    // Hard to dodge an attack you can't see coming.
    if (isBlinded) dodge ~/= 2;

    if (dodge != 0) yield Defense(dodge, "{1} dodge[s] {2}.");

    yield* onGetDefenses();
  }

  /// The amount of protection against damage the actor has.
  int get armor;

  /// The amount of light emanating from this actor.
  ///
  /// This is not a raw emanation value, but a "level" to be passed to
  /// [Lighting.emanationForLevel()].
  int get emanationLevel;

  /// Called when the actor's position is about to change from [from] to [to].
  void changePosition(Vec from, Vec to) {
    game.stage.moveActor(from, to);

    if (emanationLevel > 0) game.stage.actorEmanationChanged();
  }

  int get baseSpeed;

  /// The actor's base dodge ability. This is the percentage chance of a melee
  /// attack missing the actor.
  int get baseDodge;

  Iterable<Defense> onGetDefenses();

  Action getAction() {
    final action = onGetAction();
    if (action != null) action.bind(this);
    return action;
  }

  Action onGetAction();

  /// Create a new [Hit] for this [Actor] to attempt to hit [defender].
  ///
  /// Note that [defender] may be null if this hit is being created for
  /// something like a bolt attack or whether the targeted actor isn't known.
  Hit createMeleeHit(Actor defender) {
    var hit = onCreateMeleeHit(defender);
    modifyHit(hit, HitType.melee);
    return hit;
  }

  Hit onCreateMeleeHit(Actor defender);

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
    health -= damage;
    onTakeDamage(action, attacker, damage);

    if (isAlive) return false;

    action.addEvent(EventType.die, actor: this);

    // TODO: Different verb for unliving monsters.
    action.log("{1} kill[s] {2}.", attackNoun, this);
    if (attacker != null) attacker.onKilled(action, this);

    onDied(attackNoun);

    return true;
  }

  /// Called when this actor has successfully hit this [defender].
  void onGiveDamage(Action action, Actor defender, int damage) {
    // Do nothing.
  }

  /// Called when [attacker] has successfully hit this actor.
  ///
  /// [attacker] may be `null` if the damage is not the direct result of an
  /// attack (for example, poison).
  void onTakeDamage(Action action, Actor attacker, int damage) {
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

  /// Whether it's possible for the actor to ever be on the tile at [pos].
  bool canOccupy(Vec pos) {
    if (pos.x < 0) return false;
    if (pos.x >= game.stage.width) return false;
    if (pos.y < 0) return false;
    if (pos.y >= game.stage.height) return false;

    var tile = game.stage[pos];
    return tile.canEnter(motility);
  }

  /// Whether the actor ever desires to be on the tile at [pos].
  ///
  /// Takes into account that actors do not want to step into burning tiles,
  /// but does not care if the tile is occupied.
  bool willOccupy(Vec pos) => canOccupy(pos) && game.stage[pos].substance == 0;

  /// Whether the actor can enter the tile at [pos] right now.
  ///
  /// This is true if the actor can occupy [pos] and no other actor already is.
  bool canEnter(Vec pos) => canOccupy(pos) && game.stage.actorAt(pos) == null;

  /// Whether the actor desires to enter the tile at [pos].
  ///
  /// Takes into account that actors do not want to step into burning tiles.
  bool willEnter(Vec pos) => canEnter(pos) && game.stage[pos].substance == 0;

  // TODO: Take resistance and immunities into account.

  void finishTurn(Action action) {
    energy.spend();

    conditions.forEach((condition) => condition.update(action));

    if (isAlive) onFinishTurn(action);
  }

  /// Logs [message] if the actor is visible to the hero.
  void log(String message, [Noun noun1, Noun noun2, Noun noun3]) {
    if (!isVisibleToHero) return;
    game.log.message(message, noun1, noun2, noun3);
  }

  String toString() => nounText;
}
