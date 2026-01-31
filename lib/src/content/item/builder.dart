import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../action/condition.dart';
import '../action/detection.dart';
import '../action/eat.dart';
import '../action/flow.dart';
import '../action/heal.dart';
import '../action/illuminate.dart';
import '../action/mapping.dart';
import '../action/perception.dart';
import '../action/ray.dart';
import '../action/teleport.dart';
import '../skill/skills.dart';
import 'affixes.dart';
import 'items.dart';

late CategoryBuilder _category;
ItemBuilder? _itemBuilder;
String? _affixTag;
AffixBuilder? _affixBuilder;

CategoryBuilder category(int glyph, {String? verb, int? stack}) {
  finishItem();

  _category = CategoryBuilder(glyph, verb);
  _category._maxStack = stack;

  return _category;
}

ItemBuilder item(String name, Color color, {int price = 0}) {
  finishItem();

  return _itemBuilder = ItemBuilder(name, color, price);
}

void affixCategory(String tag) {
  finishAffix();
  _affixTag = tag;
}

AffixBuilder affix(String nameTemplate, {double frequency = 1.0}) {
  finishAffix();

  var affixSet = nameTemplate.endsWith(" _")
      ? Affixes.prefixes
      : Affixes.suffixes;
  return _affixBuilder = AffixBuilder(nameTemplate, affixSet, frequency);
}

class _BaseBuilder {
  final List<Skill> _skills = [];
  final Map<Element, int> _destroyChance = {};

  int? _maxStack;
  Element? _tossElement;
  int? _tossDamage;
  int? _tossRange;
  TossItemUse? _tossUse;
  int? _emanation;
  int? _fuel;
  double? _frequency;
  bool? _isTwoHanded;

  /// Percent chance of objects in the current category breaking when thrown.
  int? _breakage;

  void frequency(double frequency) {
    _frequency = frequency;
  }

  void stack(int stack) {
    _maxStack = stack;
  }

  /// Makes items in the category throwable.
  void toss({int? damage, Element? element, int? range, int? breakage}) {
    _tossDamage = damage;
    _tossElement = element;
    _tossRange = range;
    _breakage = breakage;
  }

  void tossUse(TossItemUse use) {
    _tossUse = use;
  }

  void destroy(Element element, {required int chance, int? fuel}) {
    _destroyChance[element] = chance;
    // TODO: Per-element fuel.
    _fuel = fuel;
  }

  void twoHanded() {
    _isTwoHanded = true;
  }

  void skill(String skill) {
    _skills.add(Skills.find(skill));
  }

  void skills(List<String> skills) {
    _skills.addAll(skills.map(Skills.find));
  }
}

class CategoryBuilder extends _BaseBuilder {
  /// The current glyph's character code. Any items defined will use this.
  final int _glyph;
  final String? _verb;

  String? _equipSlot;
  String? _weaponType;
  late final String _tag;
  bool _isTreasure = false;

  CategoryBuilder(this._glyph, this._verb);

  void tag(String tagPath) {
    // Define the tag path and store the leaf tag which is what gets used by
    // the item types.
    Items.types.defineTags("item/$tagPath");
    var tags = tagPath.split("/");
    _tag = tags.last;

    const tagEquipSlots = [
      "hand",
      "ring",
      "necklace",
      "body",
      "cloak",
      "helm",
      "gloves",
      "boots",
    ];

    if (tags.contains("shield") || tags.contains("light")) {
      _equipSlot = "hand";
    } else if (tags.contains("weapon")) {
      // TODO: Handle two-handed weapons.
      _equipSlot = "hand";
      _weaponType = tags[tags.indexOf("weapon") + 1];
    } else {
      for (var equipSlot in tagEquipSlots) {
        if (tags.contains(equipSlot)) {
          _equipSlot = equipSlot;
          break;
        }
      }
    }

    // TODO: Hacky. We need a matching tag hiearchy for affixes so that, for
    // example, a "sword" item will match a "weapon" affix.
    Affixes.defineItemTag("item/$tagPath");
  }

  void treasure() {
    _isTreasure = true;
  }
}

class ItemBuilder extends _BaseBuilder {
  static int _sortIndex = 0;

  final String _name;
  final Color _color;
  final int _price;
  ItemUse? _use;
  Attack? _attack;
  Defense? _defense;
  int? _weight;
  int? _heft;
  int? _armor;
  bool _isArtifact = false;

  AffixType? _instrinsicAffix;

  // TODO: Instead of late final, initialize these in item() instead of depth().
  late final int _minDepth;
  late final int _maxDepth;

  ItemBuilder(this._name, this._color, this._price);

  /// Sets the item's minimum depth to [from]. If [to] is given, then the item
  /// has the given depth range. Otherwise, its max is [Stage.maxDepth].
  void depth(int from, {int? to}) {
    _minDepth = from;
    _maxDepth = to ?? Stage.maxDepth;
  }

  /// Marks this item type as an artifact with an intrisic affix populated by
  /// calling [buildAffix].
  void artifact(void Function(AffixBuilder affixBuilder)? buildAffix) {
    _isArtifact = true;
    if (buildAffix != null) {
      instrinsicAffix(buildAffix);
    }
  }

  /// Give this item type an intrinsic affix populated by calling [buildAffix].
  void instrinsicAffix(void Function(AffixBuilder affixBuilder) buildAffix) {
    assert(_instrinsicAffix == null);

    var builder = AffixBuilder("$_name intrinsic affix");
    buildAffix(builder);
    _instrinsicAffix = builder._build();
  }

  void defense(int amount, String message) {
    assert(_defense == null);
    _defense = Defense(amount, message);
  }

  void armor(int armor, {int? weight}) {
    _armor = armor;
    _weight = weight;
  }

  void weapon(int damage, {required int heft, Element? element}) {
    _attack = Attack(null, _category._verb!, damage, null, element);
    _heft = heft;
  }

  void ranged(
    String prop, {
    required int heft,
    required int damage,
    required int range,
  }) {
    _attack = Attack(Prop(prop), "pierce[s]", damage, range);
    // TODO: Make this per-item once it does something.
    _heft = heft;
  }

  void use(String description, Action Function() createAction) {
    _use = ItemUse(description, createAction);
  }

  void food(int amount) {
    use("Provides $amount turns of food.", () => EatAction(amount));
  }

  void detection(List<DetectType> types, {int? range}) {
    // TODO: Hokey. Do something more general if more DetectTypes are added.
    var typeDescription = "exits and items";
    if (types.length == 1) {
      if (types[0] == DetectType.exit) {
        typeDescription = "exits";
      } else {
        typeDescription = "items";
      }
    }

    var description = "Detects $typeDescription";
    if (range != null) {
      description += " up to $range steps away";
    }

    use("$description.", () => DetectAction(types, range));
  }

  void perception({int duration = 5, int distance = 16}) {
    use(
      "Perceives the location of monsters, even those that are otherwise "
      "hidden.",
      () => PerceiveAction(duration, distance),
    );
  }

  void resistSalve(Element element) {
    use(
      "Grantes resistance to $element for 40 turns.",
      () => ResistAction(40, element),
    );
  }

  void mapping(int distance, {bool illuminate = false}) {
    var description =
        "Imparts knowledge of the dungeon up to $distance steps from the hero.";
    if (illuminate) {
      description += " Illuminates the dungeon.";
    }

    use(description, () => MappingAction(distance, illuminate: illuminate));
  }

  void haste(int amount, int duration) {
    use(
      "Raises speed by $amount for $duration turns.",
      () => HasteAction(amount, duration),
    );
  }

  void teleport(int distance) {
    use(
      "Attempts to teleport up to $distance steps away.",
      () => TeleportAction(distance),
    );
  }

  // TODO: Take list of conditions to cure?
  void heal(int amount, {bool curePoison = false}) {
    use(
      "Instantly heals $amount lost health.",
      () => HealAction(amount, curePoison: curePoison),
    );
  }

  /// Sets a use and toss use that creates an expanding ring of elemental
  /// damage.
  void ball(
    Element element,
    String prop,
    String verb,
    int damage, {
    int? range,
  }) {
    range ??= 3;
    var attack = Attack(Prop(prop), verb, damage, range, element);

    use(
      "Unleashes a ball of $element that inflicts $damage damage out to "
      "$range steps from the hero.",
      () => RingSelfAction(attack),
    );
    tossUse((pos) => RingFromAction(attack, pos));
  }

  /// Sets a use and toss use that creates a flow of elemental damage.
  void flow(
    Element element,
    String prop,
    String verb,
    int damage, {
    int range = 5,
    bool fly = false,
  }) {
    var attack = Attack(Prop(prop), verb, damage, range, element);

    var motility = Motility.walk;
    if (fly) motility |= Motility.fly;

    use(
      "Unleashes a flow of $element that inflicts $damage damage out to "
      "$range steps from the hero.",
      () => FlowSelfAction(attack, motility),
    );
    tossUse((pos) => FlowFromAction(attack, pos, motility));
  }

  void lightSource({required int level, int? range}) {
    _emanation = level;

    if (range != null) {
      use(
        "Illuminates out to a range of $range.",
        () => IlluminateSelfAction(range),
      );
    }
  }

  ItemType _build() {
    var appearance = Glyph.fromCharCode(_category._glyph, _color);

    Toss? toss;
    if (_tossDamage ?? _category._tossDamage case var tossDamage?) {
      var tossAttack = Attack(
        Prop(_name.toLowerCase()),
        switch (_category._verb) {
          var verb? => Log.conjugate(verb, Pronoun.it),
          _ => "hits",
        },
        tossDamage,
        _tossRange ?? _category._tossRange,
        _tossElement ?? _category._tossElement ?? Element.none,
      );
      toss = Toss(
        _category._breakage ?? _breakage ?? 0,
        tossAttack,
        _tossUse ?? _category._tossUse,
      );
    }

    var itemType = ItemType(
      NounBuilder(
        _name,
        // TODO: Support artifacts with definite names.
        category: _isArtifact ? NounCategory.proper : NounCategory.normal,
      ),
      appearance,
      _minDepth,
      _sortIndex++,
      _category._equipSlot,
      _category._weaponType,
      _use,
      _attack,
      toss,
      _defense,
      _armor ?? 0,
      _price,
      _maxStack ?? _category._maxStack ?? 1,
      _instrinsicAffix,
      weight: _weight ?? 0,
      heft: _heft ?? 0,
      emanation: _emanation ?? _category._emanation,
      fuel: _fuel ?? _category._fuel,
      treasure: _category._isTreasure,
      twoHanded: _category._isTwoHanded ?? _isTwoHanded ?? false,
      isArtifact: _isArtifact,
    );

    itemType.destroyChance.addAll(_category._destroyChance);
    itemType.destroyChance.addAll(_destroyChance);

    itemType.skills.addAll(_category._skills);
    itemType.skills.addAll(_skills);

    return itemType;
  }
}

class AffixBuilder {
  static int _sortIndex = 0;

  final String _nameTemplate;

  /// The kind of affixes this affix will be a member of.
  final ResourceSet<AffixType>? _affixSet;

  int? _minDepth;
  int? _maxDepth;
  final double _frequency;

  RollParameter? _rollParameter;
  ParameterizeDouble? _heftScale;
  ParameterizeInt? _weightBonus;
  ParameterizeInt? _strikeBonus;
  ParameterizeDouble? _damageScale;
  ParameterizeInt? _damageBonus;
  Element? _brand;
  ParameterizeInt? _armorBonus;
  ParameterizeInt? _priceBonus;
  ParameterizeDouble? _priceScale;

  final Map<Element, ParameterizeInt> _resists = {};
  final Map<Stat, ParameterizeInt> _statBonuses = {};

  AffixBuilder(this._nameTemplate, [this._affixSet, this._frequency = 0.0]);

  /// Sets the affix's minimum depth to [from]. If [to] is given, then the
  /// affix has the given depth range. Otherwise, its max range is
  /// [Stage.maxDepth].
  void depth(int from, {int? to}) {
    _minDepth = from;
    _maxDepth = to ?? Stage.maxDepth;
  }

  void price(int bonus, double scale) {
    priceP((_) => bonus, (_) => scale);
  }

  void priceP(ParameterizeInt bonus, ParameterizeDouble scale) {
    _priceBonus = bonus;
    _priceScale = scale;
  }

  void parameter(int min, {int? max, int? boostOneIn}) {
    max ??= min;

    _rollParameter = () {
      var value = rng.inclusive(min, max);

      if (boostOneIn != null) {
        var boosted = 0;
        while (boosted++ < 10 && rng.oneIn(boostOneIn)) {
          value++;
        }
      }

      return value;
    };
  }

  void heft(double scale) {
    _heftScale = (_) => scale;
  }

  void weight(int bonus) {
    _weightBonus = (_) => bonus;
  }

  void strike(int bonus) {
    _strikeBonus = (_) => bonus;
  }

  void damage({ParameterizeDouble? scale, ParameterizeInt? bonus}) {
    if (scale != null) _damageScale = scale;
    if (bonus != null) _damageBonus = bonus;
  }

  void brand(Element element, {int? resist}) {
    _brand = element;

    // By default, branding also grants resistance.
    _resists[element] = (_) => resist ?? 1;
  }

  void armor(ParameterizeInt armor) {
    _armorBonus = armor;
  }

  void resist(Element element, [ParameterizeInt? power]) {
    if (power != null) {
      _resists[element] = power;
    } else {
      _resists[element] = (_) => 1;
    }
  }

  void strength(ParameterizeInt bonus) => _statBonus(Stat.strength, bonus);
  void agility(ParameterizeInt bonus) => _statBonus(Stat.agility, bonus);
  void vitality(ParameterizeInt bonus) => _statBonus(Stat.vitality, bonus);
  void intellect(ParameterizeInt bonus) => _statBonus(Stat.intellect, bonus);

  /// Gives the affix a [bonus] to [stat].
  void _statBonus(Stat stat, ParameterizeInt bonus) {
    _statBonuses[stat] = bonus;
  }

  AffixType _build() {
    var id = _nameTemplate;

    var affixSet = _affixSet;
    if (affixSet != null) {
      // If the affix is going into a resource set, make sure it has a unique
      // ID. (If it's an intrinsic affix on an ItemType, it doesn't matter if
      // there is a name collision.)
      var idBase = _nameTemplate.replaceAll("_", "[$_affixTag]");
      id = idBase;
      var index = 1;

      while (affixSet.tryFind(id) != null) {
        index++;
        id = "$idBase ($index)";
      }
    }

    var isPrefix = _nameTemplate.endsWith(" _");
    var name = _nameTemplate.replaceAll("_", "").trim();

    var affix = AffixType(
      id,
      name,
      prefix: isPrefix,
      _sortIndex++,
      rollParameter: _rollParameter,
      heftScale: _heftScale,
      weightBonus: _weightBonus,
      strikeBonus: _strikeBonus,
      damageScale: _damageScale,
      damageBonus: _damageBonus,
      brand: _brand,
      armorBonus: _armorBonus,
      priceBonus: _priceBonus,
      priceScale: _priceScale,
    );

    _resists.forEach(affix.setResist);
    _statBonuses.forEach(affix.setStatBonus);

    return affix;
  }
}

/// Ignores the parameter and yields a fixed value.
T Function(int) fixed<T>(T value) =>
    (_) => value;

/// Uses the parameter value as an int.
final ParameterizeInt equalsParam = _intIdentity;

int _intIdentity(int value) => value;

/// Converts the parameter to a double scale value by taking [base] and adding
/// [scale] times the parameter to it.
ParameterizeDouble scaleParam({double base = 1.0, double scale = 0.1}) =>
    (int parameter) => base + parameter * scale;

void finishItem() {
  var builder = _itemBuilder;
  if (builder == null) return;

  var itemType = builder._build();

  Items.types.addRanged(
    itemType,
    name: itemType.name,
    start: builder._minDepth,
    end: builder._maxDepth,
    startFrequency: builder._frequency ?? _category._frequency ?? 1.0,
    tags: _category._tag,
  );

  _itemBuilder = null;
}

void finishAffix() {
  var builder = _affixBuilder;
  if (builder == null) return;

  var affix = builder._build();

  builder._affixSet!.addRanged(
    affix,
    name: affix.id,
    start: builder._minDepth,
    end: builder._maxDepth,
    startFrequency: builder._frequency,
    tags: _affixTag,
  );

  _affixBuilder = null;
}
