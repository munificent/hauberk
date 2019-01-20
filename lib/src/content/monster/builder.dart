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
import 'spawns.dart';

final collapseNewlines = RegExp(r"\n\s*");

final _elementText = {
  Elements.air: ["the wind", "buffets"],
  Elements.earth: ["the soil", "buries"],
  Elements.fire: ["the flame", "burns"],
  Elements.water: ["the water", "blasts"],
  Elements.acid: ["the acid", "melts"],
  Elements.cold: ["the ice", "freezes"],
  Elements.lightning: ["the lightning", "shocks"],
  Elements.poison: ["the poison", "chokes"],
  Elements.dark: ["the darkness", "crushes"],
  Elements.light: ["the light", "sears"],
  Elements.spirit: ["the spirit", "haunts"],
};

/// The last builder that was created. It gets implicitly finished when the
/// next family or breed starts, or at the end of initialization. This way, we
/// don't need an explicit `build()` call at the end of each builder.
_BreedBuilder _builder;

_FamilyBuilder _family;

_FamilyBuilder family(String character,
    {double frequency,
    int meander,
    int speed,
    int dodge,
    int tracking,
    String flags}) {
  finishBreed();

  _family = _FamilyBuilder(frequency, character);
  _family._meander = meander;
  _family._speed = speed;
  _family._dodge = dodge;
  _family._tracking = tracking;
  _family._flags = flags;

  return _family;
}

void finishBreed() {
  if (_builder == null) return;

  var tags = <String>[];
  tags.addAll(_family._groups);
  tags.addAll(_builder._groups);

  if (tags.isEmpty) tags.add("monster");

  var breed = _builder.build();

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

  void flags(String flags) {
    // TODO: Allow negated flags.
    _flags = flags;
  }

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
  final String _character;

  _FamilyBuilder(double frequency, this._character) : super(frequency);
}

class _BreedBuilder extends _BaseBuilder {
  final String _name;
  final int _depth;
  final Object _appearance;
  final int _health;
  final List<Attack> _attacks = [];
  final List<Move> _moves = [];
  final List<Drop> _drops = [];
  final List<Spawn> _minions = [];
  Pronoun _pronoun;
  String _description;

  _BreedBuilder(
      this._name, this._depth, double frequency, this._appearance, this._health)
      : super(frequency) {}

  void minion(String name, [int minOrMax, int max]) {
    Spawn spawn;
    if (Monsters.breeds.tagExists(name)) {
      spawn = spawnTag(name);
    } else {
      spawn = spawnBreed(name);
    }

    if (max != null) {
      spawn = repeatSpawn(minOrMax, max, spawn);
    } else if (minOrMax != null) {
      spawn = repeatSpawn(1, minOrMax, spawn);
    }

    _minions.add(spawn);
  }

  void attack(String verb, int damage, [Element element, Noun noun]) {
    _attacks.add(Attack(noun, verb, damage, 0, element));
  }

  /// Drops [name], which can be either an item type or tag.
  void drop(String name,
      {int percent = 100,
      int count = 1,
      int depthOffset = 0,
      int affixChance}) {
    var drop = percentDrop(percent, name, _depth + depthOffset, affixChance);
    if (count > 1) drop = repeatDrop(count, drop);
    _drops.add(drop);
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

  void bolt(Element element, {num rate, int damage, int range}) {
    _bolt(_elementText[element][0], _elementText[element][1], element,
        rate: rate, damage: damage, range: range);
  }

  void windBolt({num rate = 5, int damage}) =>
      bolt(Elements.air, rate: rate, damage: damage, range: 8);

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
      bolt(Elements.fire, rate: rate, damage: damage, range: 8);

  void lightningBolt({num rate = 5, int damage}) =>
      bolt(Elements.lightning, rate: rate, damage: damage, range: 10);

  void acidBolt({num rate = 5, int damage, int range = 8}) =>
      bolt(Elements.acid, rate: rate, damage: damage, range: range);

  void darkBolt({num rate = 5, int damage}) =>
      bolt(Elements.dark, rate: rate, damage: damage, range: 10);

  void lightBolt({num rate = 5, int damage}) =>
      bolt(Elements.light, rate: rate, damage: damage, range: 10);

  void poisonBolt({num rate = 5, int damage}) =>
      bolt(Elements.poison, rate: rate, damage: damage, range: 8);

  void cone(Element element, {num rate, int damage, int range}) {
    _cone(_elementText[element][0], _elementText[element][1], element,
        rate: rate, damage: damage, range: range);
  }

  void windCone({num rate, int damage, int range}) =>
      cone(Elements.air, rate: rate, damage: damage, range: range);

  void fireCone({num rate, int damage, int range}) =>
      cone(Elements.fire, rate: rate, damage: damage, range: range);

  void iceCone({num rate, int damage, int range}) =>
      cone(Elements.cold, rate: rate, damage: damage, range: range);

  void lightningCone({num rate, int damage, int range}) =>
      cone(Elements.lightning, rate: rate, damage: damage, range: range);

  void lightCone({num rate, int damage, int range}) =>
      cone(Elements.light, rate: rate, damage: damage, range: range);

  void darkCone({num rate, int damage, int range}) =>
      cone(Elements.dark, rate: rate, damage: damage, range: range);

  void waterCone({num rate, int damage, int range}) =>
      cone(Elements.water, rate: rate, damage: damage, range: range);

  void missive(Missive missive, {num rate = 5}) =>
      _addMove(MissiveMove(missive, rate));

  void howl({num rate = 10, int range = 10, String verb}) =>
      _addMove(HowlMove(rate, range, verb));

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
    rate ??= 5;
    range ??= 10;

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

    Spawn minions;
    if (_minions.length == 1) {
      minions = _minions[0];
    } else if (_minions.length > 1) {
      minions = spawnAll(_minions);
    }

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
        minions: minions,
        stain: _stain ?? _family._stain,
        flags: BreedFlags.fromSet(flags),
        description: _description);

    breed.defenses.addAll(_family._defenses);
    breed.defenses.addAll(_defenses);

    breed.groups.addAll(_family._groups);
    breed.groups.addAll(_groups);

    return breed;
  }
}
