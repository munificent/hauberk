import 'package:malison/malison.dart';

import '../../engine.dart';
import '../drops.dart';
import '../elements.dart';
import '../move/bolt.dart';
import '../move/cone.dart';
import '../move/haste.dart';
import '../move/heal.dart';
import '../move/howl.dart';
import '../move/insult.dart';
import '../move/spawn.dart';
import '../move/teleport.dart';
import 'monsters.dart';

/// The last builder that was created. It gets implicitly finished when the
/// next family or breed starts, or at the end of initialization. This way, we
/// don't need an explicit `build()` call at the end of each builder.
_BreedBuilder _builder;

_FamilyBuilder _family = new _FamilyBuilder(null);

/// While the breeds are being built, we store their minions as string names
/// to avoid problems with circular references between breeds. Once all breeds
/// are defined, we go back and look up the actual breed object for each name.
Map<Breed, List<_NamedMinion>> _minionNames = {};

_FamilyBuilder family(String character,
    {double frequency,
    int meander,
    int speed,
    int dodge,
    int tracking,
    String flags}) {
  finishBreed();

  _family = new _FamilyBuilder(frequency);
  _family._character = character;
  _family._meander = meander;
  _family._speed = speed;
  _family._dodge = dodge;
  _family._tracking = tracking;
  _family._flags = flags;

  // Default to walking.
  _family._motilities.add(Motility.walk);

  return _family;
}

void finishBreed() {
  if (_builder == null) return;

  // TODO: Is this tag still needed?
  var tags = ["monster"];

  tags.addAll(_builder._places);
  tags.addAll(_family._places);

  // TODO: We probably want to be able to opt out of this for special breeds
  // that should never spawn natural and only appear as minions or in special
  // rooms.
  // Default to spawning in rooms.
  if (_builder._places.isEmpty && _family._places.isEmpty) tags.add("room");

  var breed = _builder.build();
  // TODO: join() here is dumb since Resource then splits it.
  Monsters.breeds
    ..add(breed.name, breed, breed.depth,
        _builder._frequency ?? _family._frequency ?? 1.0, tags.join(" "));
  _builder = null;
}

// TODO: Move more named params into builder methods?
_BreedBuilder breed(String name, int depth, appearance, int health,
    {double frequency, int speed: 0, int dodge, int meander: 0}) {
  finishBreed();

  Glyph glyph;
  if (appearance is Color) {
    glyph = new Glyph(_family._character, appearance);
  } else {
    glyph = appearance(_family._character);
  }

  _builder = new _BreedBuilder(name, depth, frequency, glyph, health);
  _builder._speed = speed;
  _builder._meander = meander;
  return _builder;
}

void linkMinions() {
  _minionNames.forEach((breed, minions) {
    breed.minions.addAll(minions.map((named) => new Minion(
        Monsters.breeds.find(named.breed), named.countMin, named.countMax)));
  });
}

class _BaseBuilder {
  final double _frequency;

  int _tracking;

  final List<Motility> _motilities = [];
  SpawnLocation _location;

  /// Names of places where this breed may spawn.
  final List<String> _places = [];

  /// The default speed for breeds in the current family. If the breed
  /// specifies a speed, it offsets the family's speed.
  int _speed;

  /// The default meander for breeds in the current family. If the breed
  /// specifies a meander, it offset's the family's meander.
  int _meander;

  int _dodge;

  final List<Defense> _defenses = [];

  // TODO: Make flags strongly typed here too?
  String _flags;

  int _countMin;
  int _countMax;

  TileType _stain;

  int _emanationLevel;

  _BaseBuilder(this._frequency);

  void emanate(int level) {
    _emanationLevel = level;
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

  void placeIn(String place1, [String place2]) {
    // TODO: Don't stringly-type place names?
    _places.add(place1);
    if (place2 != null) _places.add(place2);
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
    _motilities.add(Motility.fly);
  }

  void swim() {
    _motilities.add(Motility.swim);
  }

  void openDoors() {
    _motilities.add(Motility.door);
  }

  void defense(int amount, String message) {
    _defenses.add(new Defense(amount, message));
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
  final List<_NamedMinion> _minions = [];
  Pronoun _pronoun;

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

    _minions.add(new _NamedMinion(name, minOrMax, max));
  }

  void attack(String verb, int damage, [Element element, Noun noun]) {
    _attacks.add(new Attack(noun, verb, damage, 0, element));
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

  void heal({num rate: 5, int amount}) => _addMove(new HealMove(rate, amount));

  void arrow({num rate: 5, int damage}) =>
      _bolt("the arrow", "hits", Element.none, damage, rate, 8);

  void windBolt({num rate: 5, int damage}) =>
      _bolt("the wind", "blows", Elements.air, damage, rate, 8);

  void stoneBolt({num rate: 5, int damage}) =>
      _bolt("the stone", "hits", Elements.earth, damage, rate, 8);

  void waterBolt({num rate: 5, int damage}) =>
      _bolt("the jet", "splashes", Elements.water, damage, rate, 8);

  void sparkBolt({num rate: 5, int damage, int range: 8}) =>
      _bolt("the spark", "zaps", Elements.lightning, damage, rate, range);

  void iceBolt({num rate: 5, int damage, int range: 8}) =>
      _bolt("the ice", "freezes", Elements.cold, damage, rate, range);

  void fireBolt({num rate: 5, int damage}) =>
      _bolt("the flame", "burns", Elements.fire, damage, rate, 8);

  void lightningBolt({num rate: 5, int damage}) =>
      _bolt("the lightning", "shocks", Elements.lightning, damage, rate, 10);

  void acidBolt({num rate: 5, int damage, int range: 8}) =>
      _bolt("the acid", "burns", Elements.acid, damage, rate, range);

  void darkBolt({num rate: 5, int damage}) =>
      _bolt("the darkness", "crushes", Elements.dark, damage, rate, 10);

  void lightBolt({num rate: 5, int damage}) =>
      _bolt("the light", "sears", Elements.light, damage, rate, 10);

  void poisonBolt({num rate: 5, int damage}) =>
      _bolt("the poison", "engulfs", Elements.poison, damage, rate, 8);

  void windCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the wind", "buffets", Elements.air, rate, damage, range);

  void fireCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the flame", "burns", Elements.fire, rate, damage, range);

  void iceCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the ice", "freezes", Elements.cold, rate, damage, range);

  void lightningCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the lightning", "shocks", Elements.lightning, rate, damage, range);

  void lightCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the light", "sears", Elements.light, rate, damage, range);

  void darkCone({num rate: 5, int damage, int range: 10}) =>
      _cone("the darkness", "crushes", Elements.dark, rate, damage, range);

  void insult({num rate: 5}) => _addMove(new InsultMove(rate));

  void howl({num rate: 10, int range: 10}) =>
      _addMove(new HowlMove(rate, range));

  void haste({num rate: 5, int duration: 10, int speed: 1}) =>
      _addMove(new HasteMove(rate, duration, speed));

  void teleport({num rate: 5, int range: 10}) =>
      _addMove(new TeleportMove(rate, range));

  void spawn({num rate: 10}) => _addMove(new SpawnMove(rate));

  void _bolt(String noun, String verb, Element element, num rate, int damage,
      int range) {
    _addMove(new BoltMove(
        rate, new Attack(new Noun(noun), verb, damage, range, element)));
  }

  void _cone(String noun, String verb, Element element, num rate, int damage,
      int range) {
    _addMove(new ConeMove(
        rate, new Attack(new Noun(noun), verb, damage, range, element)));
  }

  void _addMove(Move move) {
    _moves.add(move);
  }

  Breed build() {
    var flags = new Set<String>();
    if (_family._flags != null) flags.addAll(_family._flags.split(" "));
    if (_flags != null) flags.addAll(_flags.split(" "));

    var motilities = new MotilitySet(_family._motilities);
    motilities.addAll(_motilities);

    var dodge = _dodge ?? _family._dodge;
    if (flags.contains("immobile")) dodge = 0;

    var breed = new Breed(
        _name,
        _pronoun ?? Pronoun.it,
        _appearance,
        _attacks,
        _moves,
        dropAllOf(_drops),
        _location ?? _family._location ?? SpawnLocation.anywhere,
        motilities,
        depth: _depth,
        maxHealth: _health,
        tracking: (_tracking ?? 0) + (_family._tracking ?? 10),
        meander: (_meander ?? 0) + (_family._meander ?? 0),
        speed: (_speed ?? 0) + (_family._speed ?? 0),
        dodge: dodge,
        emanationLevel: _family._emanationLevel ?? _emanationLevel,
        countMin: _countMin ?? _family._countMin ?? 1,
        countMax: _countMax ?? _family._countMax ?? 1,
        stain: _stain ?? _family._stain,
        flags: new BreedFlags.fromSet(flags));

    breed.defenses.addAll(_family._defenses);
    breed.defenses.addAll(_defenses);

    _minionNames[breed] = _minions;

    return breed;
  }
}

class _NamedMinion {
  final String breed;
  final int countMin;
  final int countMax;

  _NamedMinion(this.breed, this.countMin, this.countMax);
}
