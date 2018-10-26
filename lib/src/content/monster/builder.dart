import 'package:malison/malison.dart';

import '../../engine.dart';
import '../action/missive.dart';
import '../elements.dart';
import '../item/drops.dart';
import '../move/amputate.dart';
import '../move/bolt.dart';
import '../move/cone.dart';
import '../move/haste.dart';
import '../move/heal.dart';
import '../move/howl.dart';
import '../move/missive.dart';
import '../move/spawn.dart';
import '../move/teleport.dart';
import 'monsters.dart';

final collapseNewlines = RegExp(r"\n\s*");

/// The last builder that was created. It gets implicitly finished when the
/// next family or breed starts, or at the end of initialization. This way, we
/// don't need an explicit `build()` call at the end of each builder.
_BreedBuilder _builder;

_FamilyBuilder _family = _FamilyBuilder(null);

_FamilyBuilder family(String character,
    {double frequency,
    int meander,
    int speed,
    int dodge,
    int tracking,
    String flags}) {
  finishBreed();

  _family = _FamilyBuilder(frequency);
  _family._character = character;
  _family._meander = meander;
  _family._speed = speed;
  _family._dodge = dodge;
  _family._tracking = tracking;
  _family._flags = flags;

  return _family;
}

void finishBreed() {
  if (_builder == null) return;

  // TODO: Is this tag still needed?
  var tags = <String>[];
  tags.addAll(_family._groups);
  tags.addAll(_builder._groups);

  if (tags.isEmpty) tags.add("monster");

  var breed = _builder.build();

  // TODO: join() here is dumb since Resource then splits it.
  Monsters.breeds.add(breed,
      name: breed.name,
      depth: breed.depth,
      frequency: _builder._frequency ?? _family._frequency,
      tags: tags.join(" "));
  _builder = null;
}

// TODO: Move more named params into builder methods?
_BreedBuilder breed(String name, int depth, Color color, int health,
    {double frequency, int speed = 0, int dodge, int meander}) {
  finishBreed();

  var glyph = Glyph(_family._character, color);
  _builder = _BreedBuilder(name, depth, frequency, glyph, health);
  _builder._speed = speed;
  _builder._meander = meander;
  return _builder;
}

void describe(String description) {
  description = description.replaceAll(collapseNewlines, " ");
  _builder._description = description;
}

class _BaseBuilder {
  final double _frequency;

  int _tracking;

  // Default to walking.
  // TODO: Are there monsters that cannot walk?
  Motility _motility = Motility.walk;

  // TODO: Get this working again.
  SpawnLocation _location;

  /// The default speed for breeds in the current family. If the breed
  /// specifies a speed, it offsets the family's speed.
  int _speed;

  /// The default meander for breeds in the current family. If the breed
  /// specifies a meander, it offset's the family's meander.
  int _meander;

  int _dodge;

  final List<Defense> _defenses = [];
  final List<String> _groups = [];

  // TODO: Make flags strongly typed here too?
  String _flags;

  int _countMin;
  int _countMax;

  TileType _stain;

  int _emanationLevel;

  int _vision;
  int _hearing;

  _BaseBuilder(this._frequency);

  void emanate(int level) {
    _emanationLevel = level;
  }

  void sense({int see, int hear}) {
    _vision = see;
    _hearing = hear;
  }

  void preferWall() {
    _location = SpawnLocation.wall;
  }

  void preferCorner() {
    _location = SpawnLocation.corner;
  }

  void preferOpen() {
    _location = SpawnLocation.open;
  }

  /// How many monsters of this kind are spawned.
  void count(int minOrMax, [int max]) {
    if (max == null) {
      _countMin = 1;
      _countMax = minOrMax;
    } else {
      _countMin = minOrMax;
      _countMax = max;
    }
  }

  void stain(TileType type) {
    _stain = type;
  }

  void fly() {
    _motility |= Motility.fly;
  }

  void swim() {
    _motility |= Motility.swim;
  }

  void openDoors() {
    _motility |= Motility.door;
  }

  void defense(int amount, String message) {
    _defenses.add(Defense(amount, message));
  }

  void groups(String names) {
    _groups.addAll(names.split(" "));
  }
}

class _FamilyBuilder extends _BaseBuilder {
  /// Character for the current monster.
  String _character;

  _FamilyBuilder(double frequency) : super(frequency);
}

class _BreedBuilder extends _BaseBuilder {
  final String _name;
  final int _depth;
  final Object _appearance;
  final int _health;
  final List<Attack> _attacks = [];
  final List<Move> _moves = [];
  final List<Drop> _drops = [];
  final List<Minion> _minions = [];
  Pronoun _pronoun;
  String _description;

  _BreedBuilder(
      this._name, this._depth, double frequency, this._appearance, this._health)
      : super(frequency) {}

  void minion(String name, [int minOrMax, int max]) {
    if (minOrMax == null) {
      minOrMax = 1;
      max = 1;
    } else if (max == null) {
      max = minOrMax;
      minOrMax = 1;
    }

    _minions.add(Minion(name, minOrMax, max));
  }

  void attack(String verb, int damage, [Element element, Noun noun]) {
    _attacks.add(Attack(noun, verb, damage, 0, element));
  }

  void drop(String name,
      {int percent = 100, int count = 1, int depthOffset = 0}) {
    var drop = percentDrop(percent, name, _depth + depthOffset);
    if (count > 1) drop = repeatDrop(count, drop);
    _drops.add(drop);
  }

  void flags(String flags) {
    // TODO: Allow negated flags.
    _flags = flags;
  }

  void he() {
    _pronoun = Pronoun.he;
  }

  void she() {
    _pronoun = Pronoun.she;
  }

  void heal({num rate = 5, int amount}) => _addMove(HealMove(rate, amount));

  void arrow({num rate = 5, int damage}) =>
      _bolt("the arrow", "hits", Element.none,
          rate: rate, damage: damage, range: 8);

  void whip({num rate = 5, int damage, int range = 2}) =>
      _bolt(null, "whips", Element.none,
          rate: rate, damage: damage, range: range);

  void windBolt({num rate = 5, int damage}) =>
      _bolt("the wind", "blows", Elements.air,
          rate: rate, damage: damage, range: 8);

  void stoneBolt({num rate = 5, int damage}) =>
      _bolt("the stone", "hits", Elements.earth,
          rate: rate, damage: damage, range: 8);

  void waterBolt({num rate = 5, int damage}) =>
      _bolt("the jet", "splashes", Elements.water,
          rate: rate, damage: damage, range: 8);

  void sparkBolt({num rate = 5, int damage, int range = 8}) =>
      _bolt("the spark", "zaps", Elements.lightning,
          rate: rate, damage: damage, range: range);

  void iceBolt({num rate = 5, int damage, int range = 8}) =>
      _bolt("the ice", "freezes", Elements.cold,
          rate: rate, damage: damage, range: range);

  void fireBolt({num rate = 5, int damage}) =>
      _bolt("the flame", "burns", Elements.fire,
          rate: rate, damage: damage, range: 8);

  void lightningBolt({num rate = 5, int damage}) =>
      _bolt("the lightning", "shocks", Elements.lightning,
          rate: rate, damage: damage, range: 10);

  void acidBolt({num rate = 5, int damage, int range = 8}) =>
      _bolt("the acid", "burns", Elements.acid,
          rate: rate, damage: damage, range: range);

  void darkBolt({num rate = 5, int damage}) =>
      _bolt("the darkness", "crushes", Elements.dark,
          rate: rate, damage: damage, range: 10);

  void lightBolt({num rate = 5, int damage}) =>
      _bolt("the light", "sears", Elements.light,
          rate: rate, damage: damage, range: 10);

  void poisonBolt({num rate = 5, int damage}) =>
      _bolt("the poison", "engulfs", Elements.poison,
          rate: rate, damage: damage, range: 8);

  void windCone({num rate = 5, int damage, int range = 10}) =>
      _cone("the wind", "buffets", Elements.air,
          rate: rate, damage: damage, range: range);

  void fireCone({num rate = 5, int damage, int range = 10}) =>
      _cone("the flame", "burns", Elements.fire,
          rate: rate, damage: damage, range: range);

  void iceCone({num rate = 5, int damage, int range = 10}) =>
      _cone("the ice", "freezes", Elements.cold,
          rate: rate, damage: damage, range: range);

  void lightningCone({num rate = 5, int damage, int range = 10}) =>
      _cone("the lightning", "shocks", Elements.lightning,
          rate: rate, damage: damage, range: range);

  void lightCone({num rate = 5, int damage, int range = 10}) =>
      _cone("the light", "sears", Elements.light,
          rate: rate, damage: damage, range: range);

  void darkCone({num rate = 5, int damage, int range = 10}) =>
      _cone("the darkness", "crushes", Elements.dark,
          rate: rate, damage: damage, range: range);

  void waterCone({num rate = 5, int damage, int range = 10}) =>
      _cone("the water", "blasts", Elements.water,
          rate: rate, damage: damage, range: range);

  void missive(Missive missive, {num rate = 5}) =>
      _addMove(MissiveMove(missive, rate));

  void howl({num rate = 10, int range = 10}) => _addMove(HowlMove(rate, range));

  void haste({num rate = 5, int duration = 10, int speed = 1}) =>
      _addMove(HasteMove(rate, duration, speed));

  void teleport({num rate = 5, int range = 10}) =>
      _addMove(TeleportMove(rate, range));

  void spawn({num rate = 10, bool preferStraight}) =>
      _addMove(SpawnMove(rate, preferStraight: preferStraight));

  void amputate(String body, String part, String message) =>
      _addMove(AmputateMove(BreedRef(body), BreedRef(part), message));

  void _bolt(String noun, String verb, Element element,
      {num rate, int damage, int range}) {
    var nounObject = noun != null ? Noun(noun) : null;
    _addMove(BoltMove(rate, Attack(nounObject, verb, damage, range, element)));
  }

  void _cone(String noun, String verb, Element element,
      {num rate, int damage, int range}) {
    _addMove(ConeMove(rate, Attack(Noun(noun), verb, damage, range, element)));
  }

  void _addMove(Move move) {
    _moves.add(move);
  }

  Breed build() {
    var flags = Set<String>();
    if (_family._flags != null) flags.addAll(_family._flags.split(" "));
    if (_flags != null) flags.addAll(_flags.split(" "));

    var dodge = _dodge ?? _family._dodge;
    if (flags.contains("immobile")) dodge = 0;

    var breed = Breed(
        _name,
        _pronoun ?? Pronoun.it,
        _appearance,
        _attacks,
        _moves,
        dropAllOf(_drops),
        _location ?? _family._location ?? SpawnLocation.anywhere,
        _family._motility | _motility,
        depth: _depth,
        maxHealth: _health,
        tracking: (_tracking ?? 0) + (_family._tracking ?? 10),
        vision: _vision ?? _family._vision,
        hearing: _hearing ?? _family._hearing,
        meander: _meander ?? _family._meander ?? 0,
        speed: (_speed ?? 0) + (_family._speed ?? 0),
        dodge: dodge,
        emanationLevel: _family._emanationLevel ?? _emanationLevel,
        countMin: _countMin ?? _family._countMin ?? 1,
        countMax: _countMax ?? _family._countMax ?? 1,
        stain: _stain ?? _family._stain,
        flags: BreedFlags.fromSet(flags),
        description: _description);

    breed.defenses.addAll(_family._defenses);
    breed.defenses.addAll(_defenses);

    breed.groups.addAll(_family._groups);
    breed.groups.addAll(_groups);

    breed.minions.addAll(_minions);

    return breed;
  }
}
