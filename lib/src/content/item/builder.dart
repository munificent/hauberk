import 'package:malison/malison.dart';

import '../../engine.dart';
import '../action/condition.dart';
import '../action/detection.dart';
import '../action/eat.dart';
import '../action/flow.dart';
import '../action/heal.dart';
import '../action/illuminate.dart';
import '../action/mapping.dart';
import '../action/ray.dart';
import '../action/teleport.dart';
import '../skill/skills.dart';
import 'affixes.dart';
import 'items.dart';

int _sortIndex = 0;
_CategoryBuilder _category;
_ItemBuilder _item;
String _affixTag;
_AffixBuilder _affix;

_CategoryBuilder category(int glyph, {String verb, int stack}) {
  finishItem();

  _category = _CategoryBuilder();
  _category._glyph = glyph;
  _category._verb = verb;
  _category._maxStack = stack;

  return _category;
}

_ItemBuilder item(String name, Color color, {double frequency, int price}) {
  finishItem();

  _item = _ItemBuilder();
  _item._name = name;
  _item._color = color;
  _item._frequency = frequency ?? 1.0;
  _item._price = price ?? 0;

  return _item;
}

void affixCategory(String tag) {
  finishAffix();
  _affixTag = tag;
}

_AffixBuilder affix(String name, double frequency) {
  finishAffix();

  bool isPrefix;
  if (name.endsWith(" _")) {
    name = name.substring(0, name.length - 2);
    isPrefix = true;
  } else if (name.startsWith("_ ")) {
    name = name.substring(2);
    isPrefix = false;
  } else {
    throw 'Affix "$name" must start or end with "_".';
  }

  return _affix = _AffixBuilder(name, isPrefix, frequency);
}

class _BaseBuilder {
  final List<Skill> _skills = [];
  final Map<Element, int> _destroyChance = {};

  int _maxStack;
  Element _tossElement;
  int _tossDamage;
  int _tossRange;
  TossItemUse _tossUse;
  int _emanation;
  int _fuel;

  /// Percent chance of objects in the current category breaking when thrown.
  int _breakage;

  void stack(int stack) {
    _maxStack = stack;
  }

  /// Makes items in the category throwable.
  void toss({int damage, Element element, int range, int breakage}) {
    _tossDamage = damage;
    _tossElement = element;
    _tossRange = range;
    _breakage = breakage;
  }

  void tossUse(TossItemUse use) {
    _tossUse = use;
  }

  void destroy(Element element, {int chance, int fuel}) {
    _destroyChance[element] = chance;
    // TODO: Per-element fuel.
    _fuel = fuel;
  }

  void skill(String skill) {
    _skills.add(Skills.find(skill));
  }

  void skills(List<String> skills) {
    _skills.addAll(skills.map(Skills.find));
  }
}

class _CategoryBuilder extends _BaseBuilder {
  /// The current glyph's character code. Any items defined will use this.
  int _glyph;

  String _equipSlot;

  String _weaponType;
  String _tag;
  String _verb;
  bool _isTreasure = false;

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
      "boots"
    ];

    if (tags.contains("shield")) {
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
    Affixes.defineItemTag(tagPath);
  }

  void treasure() {
    _isTreasure = true;
  }
}

class _ItemBuilder extends _BaseBuilder {
  Color _color;
  double _frequency;
  int _price;
  ItemUse _use;
  Attack _attack;
  Defense _defense;
  int _weight;
  int _heft;
  int _armor;

  String _name;
  int _minDepth;
  int _maxDepth;

  /// Sets the item's minimum depth to [from]. If [to] is given, then the item
  /// has the given depth range. Otherwise, its max is [Option.maxDepth].
  void depth(int from, {int to}) {
    _minDepth = from;
    _maxDepth = to ?? Option.maxDepth;
  }

  void defense(int amount, String message) {
    assert(_defense == null);
    _defense = Defense(amount, message);
  }

  void armor(int armor, {int weight}) {
    _armor = armor;
    _weight = weight;
  }

  void weapon(int damage, {int heft, Element element}) {
    _attack = Attack(null, _category._verb, damage, null, element);
    _heft = heft;
  }

  void ranged(String noun, {int heft, int damage, int range}) {
    _attack = Attack(Noun(noun), "pierce[s]", damage, range);
    // TODO: Make this per-item once it does something.
    _heft = heft;
  }

  void use(String description, Action Function() createAction) {
    _use = ItemUse(description, createAction);
  }

  void food(int amount) {
    use("Provides $amount turns of food.", () => EatAction(amount));
  }

  void detection(List<DetectType> types, {int range}) {
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
      description += "up to $range steps away";
    }

    use("$description.", () => DetectAction(types, range));
  }

  void resistSalve(Element element) {
    use("Grantes resistance to $element for 40 turns.",
        () => ResistAction(40, element));
  }

  void mapping(int distance, {bool illuminate}) {
    illuminate ??= false;

    var description =
        "Imparts knowledge of the dungeon up to $distance steps from the hero.";
    if (illuminate) {
      description += " Illuminates the dungeon.";
    }

    use(description, () => MappingAction(distance, illuminate: illuminate));
  }

  void haste(int amount, int duration) {
    use("Raises speed by $amount for $duration turns.",
        () => HasteAction(amount, duration));
  }

  void teleport(int distance) {
    use("Attempts to teleport up to $distance steps away.",
        () => TeleportAction(distance));
  }

  // TODO: Take list of conditions to cure?
  void heal(int amount, {bool curePoison = false}) {
    use("Instantly heals $amount lost health.",
        () => HealAction(amount, curePoison: curePoison));
  }

  /// Sets a use and toss use that creates an expanding ring of elemental
  /// damage.
  void ball(Element element, String noun, String verb, int damage,
      {int range}) {
    range ??= 3;
    var attack = Attack(Noun(noun), verb, damage, range, element);

    use(
        "Unleashes a ball of $element that inflicts $damage damage out to "
        "$range steps from the hero.",
        () => RingSelfAction(attack));
    tossUse((pos) => RingFromAction(attack, pos));
  }

  /// Sets a use and toss use that creates a flow of elemental damage.
  void flow(Element element, String noun, String verb, int damage,
      {int range = 5, bool fly = false}) {
    var attack = Attack(Noun(noun), verb, damage, range, element);

    var motility = Motility.walk;
    if (fly) motility |= Motility.fly;

    use(
        "Unleashes a flow of $element that inflicts $damage damage out to "
        "$range steps from the hero.",
        () => FlowSelfAction(attack, motility));
    tossUse((pos) => FlowFromAction(attack, pos, motility));
  }

  void lightSource({int level, int range}) {
    _emanation = level;

    if (range != null) {
      use("Illuminates out to a range of $range.",
          () => IlluminateSelfAction(range, level + 1));
    }
  }
}

class _AffixBuilder {
  final String _name;
  final bool _isPrefix;
  int _minDepth;
  int _maxDepth;
  final double _frequency;

  double _heftScale;
  int _weightBonus;
  int _strikeBonus;
  double _damageScale;
  int _damageBonus;
  Element _brand;
  int _armor;
  int _priceBonus;
  double _priceScale;

  final Map<Element, int> _resists = {};
  final Map<Stat, int> _statBonuses = {};

  _AffixBuilder(this._name, this._isPrefix, this._frequency);

  /// Sets the affix's minimum depth to [from]. If [to] is given, then the
  /// affix has the given depth range. Otherwise, its max range is
  /// [Option.maxDepth].
  void depth(int from, {int to}) {
    _minDepth = from;
    _maxDepth = to ?? Option.maxDepth;
  }

  void heft(double scale) {
    _heftScale = scale;
  }

  void weight(int bonus) {
    _weightBonus = bonus;
  }

  void strike(int bonus) {
    _strikeBonus = bonus;
  }

  void damage({double scale, int bonus}) {
    _damageScale = scale;
    _damageBonus = bonus;
  }

  void brand(Element element, {int resist}) {
    _brand = element;

    // By default, branding also grants resistance.
    _resists[element] = resist ?? 1;
  }

  void armor(int armor) {
    _armor = armor;
  }

  void resist(Element element, [int power]) {
    _resists[element] = power ?? 1;
  }

  void strength(int bonus) {
    _statBonuses[Stat.strength] = bonus;
  }

  void agility(int bonus) {
    _statBonuses[Stat.agility] = bonus;
  }

  void fortitude(int bonus) {
    _statBonuses[Stat.fortitude] = bonus;
  }

  void intellect(int bonus) {
    _statBonuses[Stat.intellect] = bonus;
  }

  void will(int bonus) {
    _statBonuses[Stat.will] = bonus;
  }

  void price(int bonus, double scale) {
    _priceBonus = bonus;
    _priceScale = scale;
  }
}

void finishItem() {
  if (_item == null) return;

  var appearance = Glyph.fromCharCode(_category._glyph, _item._color);

  Toss toss;
  var tossDamage = _item._tossDamage ?? _category._tossDamage;
  if (tossDamage != null) {
    var noun = Noun("the ${_item._name.toLowerCase()}");
    var verb = "hits";
    if (_category._verb != null) {
      verb = Log.conjugate(_category._verb, Pronoun.it);
    }

    var range = _item._tossRange ?? _category._tossRange;
    assert(range != null);
    var element = _item._tossElement ?? _category._tossElement ?? Element.none;
    var use = _item._tossUse ?? _category._tossUse;
    var breakage = _category._breakage ?? _item._breakage ?? 0;

    var tossAttack = Attack(noun, verb, tossDamage, range, element);
    toss = Toss(breakage, tossAttack, use);
  }

  var itemType = ItemType(
      _item._name,
      appearance,
      _item._minDepth,
      _sortIndex++,
      _category._equipSlot,
      _category._weaponType,
      _item._use,
      _item._attack,
      toss,
      _item._defense,
      _item._armor ?? 0,
      _item._price,
      _item._maxStack ?? _category._maxStack ?? 1,
      weight: _item._weight ?? 0,
      heft: _item._heft ?? 0,
      emanation: _item._emanation ?? _category._emanation,
      fuel: _item._fuel ?? _category._fuel,
      treasure: _category._isTreasure);

  itemType.destroyChance.addAll(_category._destroyChance);
  itemType.destroyChance.addAll(_item._destroyChance);

  itemType.skills.addAll(_category._skills);
  itemType.skills.addAll(_item._skills);

  Items.types.addRanged(itemType,
      name: itemType.name,
      start: _item._minDepth,
      end: _item._maxDepth,
      startFrequency: _item._frequency,
      tags: _category._tag);

  _item = null;
}

void finishAffix() {
  if (_affix == null) return;

  var affixes = _affix._isPrefix ? Affixes.prefixes : Affixes.suffixes;

  var displayName = _affix._name;
  var fullName = "$displayName ($_affixTag)";
  var index = 1;

  // Generate a unique name for it.
  while (affixes.tryFind(fullName) != null) {
    index++;
    fullName = "$displayName ($_affixTag $index)";
  }

  var affix = Affix(fullName, displayName,
      heftScale: _affix._heftScale,
      weightBonus: _affix._weightBonus,
      strikeBonus: _affix._strikeBonus,
      damageScale: _affix._damageScale,
      damageBonus: _affix._damageBonus,
      brand: _affix._brand,
      armor: _affix._armor,
      priceBonus: _affix._priceBonus,
      priceScale: _affix._priceScale);

  _affix._resists.forEach(affix.resist);
  _affix._statBonuses.forEach(affix.setStatBonus);

  affixes.addRanged(affix,
      name: fullName,
      start: _affix._minDepth,
      end: _affix._maxDepth,
      startFrequency: _affix._frequency,
      endFrequency: _affix._frequency,
      tags: _affixTag);
  _affix = null;
}
