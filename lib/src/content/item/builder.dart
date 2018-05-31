import 'package:malison/malison.dart';

import '../../engine.dart';
import '../action/condition.dart';
import '../action/detection.dart';
import '../action/flow.dart';
import '../action/heal.dart';
import '../action/mapping.dart';
import '../action/ray.dart';
import '../skill/skills.dart';
import 'affixes.dart';
import 'items.dart';

int _sortIndex = 0;
_CategoryBuilder _category;
_ItemBuilder _builder;

_CategoryBuilder category(int glyph, {String verb, String flags, int stack}) {
  finishItem();

  _category = new _CategoryBuilder();
  _category._glyph = glyph;
  _category._verb = verb;
  _category._maxStack = stack;

  if (flags != null) {
    _category.flags(flags);
  }

  return _category;
}

_ItemBuilder item(String name, int depth, double frequency, Color color) {
  finishItem();

  _builder = new _ItemBuilder();
  _builder._name = name;
  _builder._depth = depth;
  _builder._frequency = frequency;
  _builder._color = color;

  return _builder;
}

class _BaseBuilder {
  final List<String> _flags = [];
  final List<Skill> _skills = [];

  int _maxStack;
  Element _tossElement;
  int _tossDamage;
  int _tossRange;
  TossItemUse _tossUse;
  int _emanation;

  /// Percent chance of objects in the current category breaking when thrown.
  int _breakage;

  void stack(int stack) {
    _maxStack = stack;
  }

  void flags(String flags) {
    if (flags == null) return;
    _flags.addAll(flags.split(" "));
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

  void light(int level) {
    _emanation = level;
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

  void tag(String tagPath) {
    // Define the tag path and store the leaf tag which is what gets used by
    // the item types.
    Items.types.defineTags("item/$tagPath");
    var tags = tagPath.split("/");
    _tag = tags.last;

    const tagEquipSlots = const [
      'weapon',
      'ring',
      'necklace',
      'body',
      'cloak',
      'shield',
      'helm',
      'gloves',
      'boots'
    ];

    for (var equipSlot in tagEquipSlots) {
      if (tags.contains(equipSlot)) {
        _equipSlot = equipSlot;
        break;
      }
    }

    if (tags.contains("weapon")) {
      _weaponType = tags[tags.indexOf("weapon") + 1];
    }

    // TODO: Hacky. We need a matching tag hiearchy for affixes so that, for
    // example, a "sword" item will match a "weapon" affix.
    Affixes.defineItemTag(tagPath);
  }
}

class _ItemBuilder extends _BaseBuilder {
  // category too.
  Color _color;
  double _frequency;
  ItemUse _use;
  Attack _attack;
  int _weight;
  int _heft;
  int _armor;

  String _name;
  int _depth;

  void armor(int armor, {int weight}) {
    _armor = armor;
    _weight = weight;
  }

  void weapon(int damage, {int heft, Element element}) {
    _attack = new Attack(null, _category._verb, damage, null, element);
    _heft = heft;
  }

  void ranged(String noun, {int damage, int range}) {
    _attack = new Attack(new Noun(noun), "pierce[s]", damage, range);
    // TODO: Make this per-item once it does something.
    _heft = 1;
  }

  void use(ItemUse use) {
    _use = use;
  }

  void detection(List<DetectType> types, {int range}) {
    use(() => new DetectAction(types, range));
  }

  void resistSalve(Element element) {
    use(() => new ResistAction(40, element));
  }

  void mapping(int distance, {bool illuminate}) {
    use(() => new MappingAction(distance, illuminate: illuminate));
  }

  // TODO: Take list of conditions to cure?
  void heal(int amount, {bool curePoison: false}) {
    use(() => new HealAction(amount, curePoison: curePoison));
  }

  /// Sets a use and toss use that creates an expanding ring of elemental
  /// damage.
  void ball(Element element, String noun, String verb, int damage,
      {int range}) {
    var attack = new Attack(new Noun(noun), verb, damage, range ?? 3, element);

    use(() => new RingSelfAction(attack));
    tossUse((pos) => new RingFromAction(attack, pos));
  }

  /// Sets a use and toss use that creates an flow of elemental damage.
  void flow(Element element, String noun, String verb, int damage,
      {int range = 3, bool fly = false}) {
    var attack = new Attack(new Noun(noun), verb, damage, range, element);

    var motilities = new MotilitySet([Motility.walk]);
    if (fly) motilities.add(Motility.fly);

    use(() => new FlowSelfAction(attack, motilities));
    tossUse((pos) => new FlowFromAction(attack, pos, motilities));
  }
}

void finishItem() {
  if (_builder == null) return;

  var appearance = new Glyph.fromCharCode(_category._glyph, _builder._color);

  Toss toss;
  var tossDamage = _builder._tossDamage ?? _category._tossDamage;
  if (tossDamage != null) {
    var noun = new Noun("the ${_builder._name.toLowerCase()}");
    var verb = "hits";
    if (_category._verb != null) {
      verb = Log.conjugate(_category._verb, Pronoun.it);
    }

    var range = _builder._tossRange ?? _category._tossRange;
    assert(range != null);
    var element =
        _builder._tossElement ?? _category._tossElement ?? Element.none;
    var use = _builder._tossUse ?? _category._tossUse;
    var breakage = _category._breakage ?? _builder._breakage ?? 0;

    var tossAttack = new Attack(noun, verb, tossDamage, range, element);
    toss = new Toss(breakage, tossAttack, use);
  }

  var itemType = new ItemType(
      _builder._name,
      appearance,
      _builder._depth,
      _sortIndex++,
      _category._equipSlot,
      _category._weaponType,
      _builder._use,
      _builder._attack,
      toss,
      _builder._armor ?? 0,
      0,
      _builder._maxStack ?? _category._maxStack ?? 1,
      weight: _builder._weight ?? 0,
      heft: _builder._heft ?? 0,
      emanation: _builder._emanation ?? _category._emanation);

  // Use the tags (if any) to figure out which slot it can be equipped in.
  itemType.flags.addAll(_category._flags);
  if (_builder._flags != null) {
    for (var flag in _builder._flags) {
      if (flag.startsWith("-")) {
        itemType.flags.remove(flag.substring(1));
      } else {
        itemType.flags.add(flag);
      }
    }
  }

  itemType.skills.addAll(_category._skills);
  itemType.skills.addAll(_builder._skills);

  Items.types.add(itemType.name, itemType, itemType.depth, _builder._frequency,
      _category._tag);

  _builder = null;
}
