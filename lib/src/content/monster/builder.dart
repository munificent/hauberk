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
BreedBuilder? _builder;

late FamilyBuilder _family;

FamilyBuilder family(
  String character,
  String groupPath, {
  double? frequency,
  int? speed,
  int? dodge,
  int? tracking,
  String? flags,
}) {
  finishBreed();

  Monsters.breeds.defineTags("monster/$groupPath");
  var group = groupPath.split("/").last;

  _family = FamilyBuilder(frequency, character, group);
  _family._speed = speed;
  _family._dodge = dodge;
  _family._tracking = tracking;
  if (flags != null) {
    _family._flags.addAll(flags.split(" "));
  }

  return _family;
}

void finishBreed() {
  var builder = _builder;
  if (builder == null) return;

  var tags = [_family._group];

  if (tags.isEmpty) tags.add("monster");

  var breed = builder.build();

  Monsters.breeds.add(
    breed,
    name: breed.name,
    depth: breed.depth,
    frequency: builder._frequency ?? _family._frequency,
    tags: tags.join(" "),
  );
  _builder = null;
}

// TODO: Move more named params into builder methods?
BreedBuilder breed(
  String name,
  int depth,
  Color color,
  int health, {
  double? frequency,
  int speed = 0,
  int? dodge,
}) {
  finishBreed();

  var glyph = Glyph(_family._character, color);
  var builder = BreedBuilder(name, depth, frequency, glyph, health);
  builder._speed = speed;
  builder._dodge = dodge;
  _builder = builder;
  return builder;
}

void describe(String description) {
  description = description.replaceAll(collapseNewlines, " ");
  _builder!._description = description;
}

class _BaseBuilder {
  final double? _frequency;

  int? _tracking;

  // Default to walking.
  // TODO: Are there monsters that cannot walk?
  Motility _motility = Motility.walk;

  // TODO: Get this working again.
  SpawnLocation? _location;

  /// The default speed for breeds in the current family. If the breed
  /// specifies a speed, it offsets the family's speed.
  int? _speed;

  int? _meander;

  int? _dodge;

  final List<Defense> _defenses = [];

  final List<String> _flags = [];

  int? _countMin;
  int? _countMax;

  TileType? _stain;

  int? _emanationLevel;

  int? _vision;
  int? _hearing;

  _BaseBuilder(this._frequency);

  void flags(String flags) {
    // TODO: Allow negated flags.
    _flags.addAll(flags.split(" "));
  }

  void emanate(int level) {
    _emanationLevel = level;
  }

  void meander(int meander) {
    _meander = meander;
  }

  void sense({int? see, int? hear}) {
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
  void count(int minOrMax, [int? max]) {
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
}

class FamilyBuilder extends _BaseBuilder {
  /// Character for the current monster.
  final String _character;

  final String _group;

  FamilyBuilder(super.frequency, this._character, this._group);
}

class BreedBuilder extends _BaseBuilder {
  final String _name;
  bool _hasProperName = false;
  final int _depth;
  final Object _appearance;
  final int _health;
  final List<Attack> _attacks = [];
  final List<Move> _moves = [];
  final List<Drop> _drops = [];
  final List<Spawn> _minions = [];
  Pronoun? _pronoun;
  String? _description;

  BreedBuilder(
    this._name,
    this._depth,
    double? frequency,
    this._appearance,
    this._health,
  ) : super(frequency);

  void minionTag(String name, [int? minOrMax, int? max]) {
    _minion(spawnTag(name), minOrMax, max);
  }

  void minionBreed(String name, [int? minOrMax, int? max]) {
    _minion(spawnBreed(name), minOrMax, max);
  }

  void _minion(Spawn spawn, [int? minOrMax, int? max]) {
    if (max != null) {
      spawn = repeatSpawn(minOrMax!, max, spawn);
    } else if (minOrMax != null) {
      spawn = repeatSpawn(1, minOrMax, spawn);
    }

    _minions.add(spawn);
  }

  void attack(String verb, int damage, [Element? element, Noun? noun]) {
    _attacks.add(Attack(noun, verb, damage, 0, element));
  }

  /// Drops [name], which can be either an item type or tag.
  void drop(
    String name, {
    int percent = 100,
    int count = 1,
    int depthOffset = 0,
  }) {
    var drop = percentDrop(percent, name, depth: _depth + depthOffset);
    if (count > 1) drop = repeatDrop(count, drop);
    _drops.add(drop);
  }

  /// Drops [name], which can be either an item type or tag.
  void dropGood(
    String name, {
    int percent = 100,
    int count = 1,
    int depthOffset = 0,
  }) {
    var drop = percentDrop(
      percent,
      name,
      depth: _depth + depthOffset,
      quality: ItemQuality.good,
    );
    if (count > 1) drop = repeatDrop(count, drop);
    _drops.add(drop);
  }

  /// Drops [name], which can be either an item type or tag.
  void dropGreat(
    String name, {
    int percent = 100,
    int count = 1,
    int depthOffset = 0,
  }) {
    var drop = percentDrop(
      percent,
      name,
      depth: _depth + depthOffset,
      quality: ItemQuality.great,
    );
    if (count > 1) drop = repeatDrop(count, drop);
    _drops.add(drop);
  }

  void unique({Pronoun? pronoun, bool properName = true}) {
    _flags.add("unique");
    _pronoun = pronoun;
    _hasProperName = properName;
  }

  // TODO: Figure out some strategy for which of these parameters have defaults
  // and which don't.

  void heal({num rate = 5, required int amount}) =>
      _addMove(HealMove(rate, amount));

  void arrow({num rate = 5, required int damage}) => _bolt(
    "the arrow",
    "hits",
    Element.none,
    rate: rate,
    damage: damage,
    range: 8,
  );

  void whip({num rate = 5, required int damage, int range = 2}) => _bolt(
    null,
    "whips",
    Element.none,
    rate: rate,
    damage: damage,
    range: range,
  );

  void bolt(
    Element element, {
    required num rate,
    required int damage,
    required int range,
  }) {
    _bolt(
      _elementText[element]![0],
      _elementText[element]![1],
      element,
      rate: rate,
      damage: damage,
      range: range,
    );
  }

  void windBolt({num rate = 5, required int damage}) =>
      bolt(Elements.air, rate: rate, damage: damage, range: 8);

  void stoneBolt({num rate = 5, required int damage}) => _bolt(
    "the stone",
    "hits",
    Elements.earth,
    rate: rate,
    damage: damage,
    range: 8,
  );

  void waterBolt({num rate = 5, required int damage}) => _bolt(
    "the jet",
    "splashes",
    Elements.water,
    rate: rate,
    damage: damage,
    range: 8,
  );

  void sparkBolt({required num rate, required int damage, int range = 6}) =>
      _bolt(
        "the spark",
        "zaps",
        Elements.lightning,
        rate: rate,
        damage: damage,
        range: range,
      );

  void iceBolt({num rate = 5, required int damage, int range = 8}) => _bolt(
    "the ice",
    "freezes",
    Elements.cold,
    rate: rate,
    damage: damage,
    range: range,
  );

  void fireBolt({num rate = 5, required int damage}) =>
      bolt(Elements.fire, rate: rate, damage: damage, range: 8);

  void lightningBolt({num rate = 5, required int damage}) =>
      bolt(Elements.lightning, rate: rate, damage: damage, range: 10);

  void acidBolt({num rate = 5, required int damage, int range = 8}) =>
      bolt(Elements.acid, rate: rate, damage: damage, range: range);

  void darkBolt({num rate = 5, required int damage}) =>
      bolt(Elements.dark, rate: rate, damage: damage, range: 10);

  void lightBolt({num rate = 5, required int damage}) =>
      bolt(Elements.light, rate: rate, damage: damage, range: 10);

  void poisonBolt({num rate = 5, required int damage}) =>
      bolt(Elements.poison, rate: rate, damage: damage, range: 8);

  void cone(Element element, {num? rate, required int damage, int? range}) {
    _cone(
      _elementText[element]![0],
      _elementText[element]![1],
      element,
      rate: rate,
      damage: damage,
      range: range,
    );
  }

  void windCone({required num rate, required int damage, int? range}) =>
      cone(Elements.air, rate: rate, damage: damage, range: range);

  void fireCone({required num rate, required int damage, int? range}) =>
      cone(Elements.fire, rate: rate, damage: damage, range: range);

  void iceCone({required num rate, required int damage, int? range}) =>
      cone(Elements.cold, rate: rate, damage: damage, range: range);

  void lightningCone({required num rate, required int damage, int? range}) =>
      cone(Elements.lightning, rate: rate, damage: damage, range: range);

  void lightCone({required num rate, required int damage, int? range}) =>
      cone(Elements.light, rate: rate, damage: damage, range: range);

  void darkCone({required num rate, required int damage, int? range}) =>
      cone(Elements.dark, rate: rate, damage: damage, range: range);

  void waterCone({required num rate, required int damage, int? range}) =>
      cone(Elements.water, rate: rate, damage: damage, range: range);

  void missive(Missive missive, {num rate = 5}) =>
      _addMove(MissiveMove(missive, rate));

  void howl({num rate = 10, int range = 10, String? verb}) =>
      _addMove(HowlMove(rate, range, verb));

  void haste({num rate = 5, int duration = 10, int speed = 1}) =>
      _addMove(HasteMove(rate, duration, speed));

  void teleport({num rate = 10, int range = 10}) =>
      _addMove(TeleportMove(rate, range));

  void spawn({num rate = 10, bool? preferStraight}) =>
      _addMove(SpawnMove(rate, preferStraight: preferStraight));

  void amputate(String body, String part, String message) =>
      _addMove(AmputateMove(BreedRef(body), BreedRef(part), message));

  void _bolt(
    String? noun,
    String verb,
    Element element, {
    required num rate,
    required int damage,
    required int range,
  }) {
    var nounObject = noun != null ? Noun(noun) : null;
    _addMove(BoltMove(rate, Attack(nounObject, verb, damage, range, element)));
  }

  void _cone(
    String noun,
    String verb,
    Element element, {
    num? rate,
    required int damage,
    int? range,
  }) {
    rate ??= 5;
    range ??= 10;

    _addMove(ConeMove(rate, Attack(Noun(noun), verb, damage, range, element)));
  }

  void _addMove(Move move) {
    _moves.add(move);
  }

  Breed build() {
    var flags = {..._family._flags, ..._flags};
    var dodge = _dodge ?? _family._dodge;
    if (flags.contains("immobile")) dodge = 0;

    Spawn? minions;
    if (_minions.length == 1) {
      minions = _minions[0];
    } else if (_minions.length > 1) {
      minions = spawnAll(_minions);
    }

    var breed = Breed(
      _name,
      _pronoun ?? Pronoun.it,
      hasProperName: _hasProperName,
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
      countMin: _countMin ?? _family._countMin,
      countMax: _countMax ?? _family._countMax,
      minions: minions,
      stain: _stain ?? _family._stain,
      flags: BreedFlags.fromSet(flags),
      description: _description,
    );

    breed.defenses.addAll(_family._defenses);
    breed.defenses.addAll(_defenses);

    breed.groups.add(_family._group);

    return breed;
  }
}
