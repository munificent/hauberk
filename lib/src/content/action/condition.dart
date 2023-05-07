import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../elements.dart';

class HasteAction extends ConditionAction {
  final int _speed;
  final int _duration;

  HasteAction(this._speed, this._duration);

  @override
  Condition get condition => actor!.haste;

  @override
  int getIntensity() => _speed;
  @override
  int getDuration() => _duration;
  @override
  void onActivate() => log("{1} start[s] moving faster.", actor);
  @override
  void onExtend() => log("{1} [feel]s the haste lasting longer.", actor);
  @override
  void onIntensify() => log("{1} move[s] even faster.", actor);
}

class FreezeActorAction extends ConditionAction with DestroyActionMixin {
  final int _damage;

  FreezeActorAction(this._damage);

  @override
  Condition get condition => actor!.cold;

  @override
  ActionResult onPerform() {
    destroyHeldItems(Elements.cold);
    return super.onPerform();
  }

  @override
  int getIntensity() => 1 + _damage ~/ 40;
  @override
  int getDuration() => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  @override
  void onActivate() => log("{1} [are|is] frozen!", actor);
  @override
  void onExtend() => log("{1} feel[s] the cold linger!", actor);
  @override
  void onIntensify() => log("{1} feel[s] the cold intensify!", actor);
}

class PoisonAction extends ConditionAction {
  final int _damage;

  PoisonAction(this._damage);

  @override
  Condition get condition => actor!.poison;

  @override
  int getIntensity() => 1 + _damage ~/ 20;
  @override
  int getDuration() => 1 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  @override
  void onActivate() => log("{1} [are|is] poisoned!", actor);
  @override
  void onExtend() => log("{1} feel[s] the poison linger!", actor);
  @override
  void onIntensify() => log("{1} feel[s] the poison intensify!", actor);
}

class BlindAction extends ConditionAction {
  final int _damage;

  BlindAction(this._damage);

  @override
  Condition get condition => actor!.blindness;

  @override
  int getDuration() => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);

  @override
  void onActivate() {
    log("{1 his} vision dims!", actor);
    game.stage.heroVisibilityChanged();
  }

  @override
  void onExtend() => log("{1 his} vision dims!", actor);
}

class DazzleAction extends ConditionAction {
  final int _damage;

  DazzleAction(this._damage);

  @override
  Condition get condition => actor!.dazzle;

  @override
  int getDuration() => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  @override
  void onActivate() => log("{1} [are|is] dazzled by the light!", actor);
  @override
  void onExtend() => log("{1} [are|is] dazzled by the light!", actor);
}

class ResistAction extends ConditionAction {
  final int _duration;
  final Element _element;

  ResistAction(this._duration, this._element);

  @override
  Condition get condition => actor!.resistances[_element]!;

  @override
  int getDuration() => _duration;
  // TODO: Resistances of different intensity.
  @override
  void onActivate() => log("{1} [are|is] resistant to $_element.", actor);
  @override
  void onExtend() => log("{1} feel[s] the resistance extend.", actor);
}
