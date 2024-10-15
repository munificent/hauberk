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

  final Condition perception = PerceiveCondition();

  // TODO: Wrap this in a method that returns a non-nullable result.
  // Temporary resistance to elements.
  final _resistances = <Element, ResistCondition>{};

  // All [Condition]s for the actor.
  Iterable<Condition> get conditions => [
        haste,
        cold,
        poison,
        blindness,
        dazzle,
        perception,
        ..._resistances.values
      ];

  /// Where the actor is on the [Stage].
  Vec get pos => _pos;
  Vec _pos;

  int _health = 0;

  int get health => _health;

  set health(int value) {
    _health = value.clamp(0, maxHealth);
  }

  Actor(this.game, int x, int y) : _pos = Vec(x, y) {
    for (var element in game.content.elements) {
      _resistances[element] = ResistCondition(element);
    }

    for (var condition in conditions) {
      condition.bind(this);
    }
  }

  Object get appearance;

  @override
  String get nounText;

  @override
  Pronoun get pronoun => Pronoun.it;

  bool get isAlive => health > 0;

  /// Whether or not the actor can be seen by the hero.
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

  int get baseSpeed;

  /// The actor's base dodge ability. This is the percentage chance of a melee
  /// attack missing the actor.
  int get baseDodge;

  /// Changes the actor's position to [to].
  ///
  /// This should generally not be called directly because the [Stage] needs to
  /// track the location of every actor. Instead, prefer calling
  /// [Action.moveActor()].
  void setPosition(Game game, Vec to) {
    if (_pos == to) return;

    var from = _pos;

    if (emanationLevel > 0) game.stage.actorEmanationChanged();

    onChangePosition(game, from, to);
    game.stage.moveActor(from, to);
    _pos = to;
  }

  /// Called when the actor's position is about to change from [from] to [to].
  void onChangePosition(Game game, Vec from, Vec to) {}

  Iterable<Defense> onGetDefenses();

  Action getAction() {
    var action = onGetAction();
    action.bind(this);
    return action;
  }

  Action onGetAction();

  /// Create a new [Hit] for this [Actor] to attempt to hit [defender].
  ///
  /// Note that [defender] may be null if this hit is being created for
  /// something like a bolt attack or whether the targeted actor isn't known.
  List<Hit> createMeleeHits(Actor? defender) {
    var hits = onCreateMeleeHits(defender);
    for (var hit in hits) {
      modifyHit(hit, HitType.melee);
    }
    return hits;
  }

  List<Hit> onCreateMeleeHits(Actor? defender);

  /// Applies the hit modifications from the actor.
  void modifyHit(Hit hit, HitType type) {
    // Hard to hit an actor you can't see.
    if (isBlinded) {
      hit.scaleStrike(switch (type) {
        HitType.melee => 0.5,
        HitType.ranged => 0.3,
        HitType.toss => 0.2,
      });
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
    var resistance = resistanceCondition(element);
    if (resistance.isActive) {
      result += resistance.intensity;
    }

    return result;
  }

  int onGetResistance(Element element);

  /// Temporary resistance to elements.
  ResistCondition resistanceCondition(Element element) =>
      _resistances[element]!;

  /// Reduces the actor's health by [damage], and handles its death. Returns
  /// `true` if the actor died.
  bool takeDamage(Action action, int damage, Noun attackNoun,
      [Actor? attacker]) {
    health -= damage;
    onTakeDamage(action, attacker, damage);

    if (isAlive) return false;

    action.addEvent(EventType.die, actor: this);

    // TODO: Different verb for unliving monsters.
    action.log("{1} kill[s] {2}.", attackNoun, this);
    if (attacker != null) attacker.onKilled(action, this);

    onDied(action, attackNoun);

    return true;
  }

  /// Called when this actor has successfully hit [defender].
  void onGiveDamage(Action action, Actor defender, int damage) {
    // Do nothing.
  }

  /// Called when [attacker] has successfully hit this actor.
  ///
  /// [attacker] may be `null` if the damage is not the direct result of an
  /// attack (for example, poison).
  void onTakeDamage(Action action, Actor? attacker, int damage) {
    // Do nothing.
  }

  /// Called when this Actor has been killed by [attackNoun].
  void onDied(Action action, Noun attackNoun) {
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

  void finishTurn(Action action) {
    energy.spend();

    for (var condition in conditions) {
      condition.update(action);
    }

    if (isAlive) onFinishTurn(action);
  }

  @override
  String toString() => nounText;
}
