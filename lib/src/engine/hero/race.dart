import 'stat.dart';

/// The hero's species.
class Race {
  final String name;

  final String description;

  final Map<Stat, double> _statScales;

  /// How much this race emphasizes [stat].
  ///
  /// A value of 1.0 is "normal". Values less than that mean the race is weaker
  /// in that stat, and values higher are stronger.
  double statScale(Stat stat) => _statScales[stat]!;

  Race(this.name, this.description, this._statScales);
}
