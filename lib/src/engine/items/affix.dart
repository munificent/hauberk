import '../core/element.dart';
import '../hero/stat.dart';
import 'item.dart';

/// A modifier that can be applied to an [Item] to change its capabilities.
/// For example, in a "Dagger of Wounding", the "of Wounding" part is an affix.
///
/// Each affix has a base [AffixType] which determines its names and effects.
/// But some of those effects may depend on a single randomly chosen
/// *parameter*. When the affix is first applied to an item, a random parameter
/// value is chosen. This way, every item with an affix of a certain type isn't
/// exactly identical.
class Affix {
  /// The type of affix.
  final AffixType type;

  /// The parameter value rolled for the affix.
  ///
  /// If not zero, this is used to modify the affix's stats. This way, every
  /// item with an affix of a certain type isn't exactly identical.
  final int parameter;

  Affix(this.type, this.parameter);

  int get sortIndex => type.sortIndex;

  double get heftScale => type._heftScale(parameter);

  int get weightBonus => type._weightBonus(parameter);

  int get strikeBonus => type._strikeBonus(parameter);
  double get damageScale => type._damageScale(parameter);
  int get damageBonus => type._damageBonus(parameter);
  int get armorBonus => type._armorBonus(parameter);

  Element get brand => type.brand;

  int resistance(Element element) {
    var resist = type._resists[element];
    if (resist == null) return 0;

    return resist(parameter);
  }

  int statBonus(Stat stat) {
    var bonus = type._statBonuses[stat];
    if (bonus == null) return 0;

    return bonus(parameter);
  }

  int get priceBonus => type._priceBonus(parameter);
  double get priceScale => type._priceScale(parameter);

  @override
  String toString() => "${type.id} $parameter";
}

/// A kind of affix that can be applied to an [Item].
class AffixType {
  /// The unique identifier for the affix.
  ///
  /// It's possible for different affixes to have the same display name but
  /// different modifiers or applying to different equipment. For storage, we
  /// need to know which one it actually is, which this distinguishes.
  final String id;

  /// The name of the affix.
  final String name;

  /// True if the affix name goes before the item name and false if it goes
  /// after.
  final bool isPrefix;

  final int sortIndex;

  /// If the affix is parameterized, then this rolls the parameter value.
  final RollParameter? _rollParameter;

  final ParameterizeDouble _heftScale;
  final ParameterizeInt _weightBonus;
  final ParameterizeInt _strikeBonus;
  final ParameterizeDouble _damageScale;
  final ParameterizeInt _damageBonus;
  final ParameterizeInt _armorBonus;

  final Element brand;

  final Map<Element, ParameterizeInt> _resists = {};
  final Map<Stat, ParameterizeInt> _statBonuses = {};

  final ParameterizeInt _priceBonus;
  final ParameterizeDouble _priceScale;

  AffixType(
    this.id,
    this.name,
    this.sortIndex, {
    required bool prefix,
    RollParameter? rollParameter,
    required ParameterizeDouble? heftScale,
    required ParameterizeInt? weightBonus,
    required ParameterizeInt? strikeBonus,
    required ParameterizeDouble? damageScale,
    required ParameterizeInt? damageBonus,
    ParameterizeInt? armorBonus,
    Element? brand,
    ParameterizeDouble? priceScale,
    ParameterizeInt? priceBonus,
  }) : isPrefix = prefix,
       _rollParameter = rollParameter,
       _heftScale = heftScale ?? _noScale,
       _weightBonus = weightBonus ?? _noBonus,
       _strikeBonus = strikeBonus ?? _noBonus,
       _damageScale = damageScale ?? _noScale,
       _damageBonus = damageBonus ?? _noBonus,
       _armorBonus = armorBonus ?? _noBonus,
       brand = brand ?? Element.none,
       _priceScale = priceScale ?? _noScale,
       _priceBonus = priceBonus ?? _noBonus;

  /// Creates a new affix with this affix type, rolling a random parameter for
  /// it as needed.
  Affix spawn() => Affix(this, _rollParameter?.call() ?? 0);

  void setResist(Element element, ParameterizeInt power) {
    _resists[element] = power;
  }

  void setStatBonus(Stat stat, ParameterizeInt bonus) {
    _statBonuses[stat] = bonus;
  }

  @override
  String toString() => id;
}

double _noScale(int parameter) => 1.0;
int _noBonus(int parameter) => 0;

typedef RollParameter = int Function();
typedef ParameterizeDouble = double Function(int parameter);
typedef ParameterizeInt = int Function(int parameter);
