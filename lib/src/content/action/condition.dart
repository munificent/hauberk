import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../elements.dart';

class HasteAction extends ConditionAction {
  final int _duration;
  final int _speed;

  HasteAction(this._duration, this._speed);

  Condition get condition => actor.haste;

  int getIntensity() => _speed;
  int getDuration() => _duration;
  void onActivate() => log("{1} start[s] moving faster.", actor);
  void onExtend() => log("{1} [feel]s the haste lasting longer.", actor);
  void onIntensify() => log("{1} move[s] even faster.", actor);
}

class FreezeActorAction extends ConditionAction with DestroyActionMixin {
  final int _damage;

  FreezeActorAction(this._damage);

  Condition get condition => actor.cold;

  ActionResult onPerform() {
    destroyHeldItems(Elements.cold);
    return super.onPerform();
  }

  int getIntensity() => 1 + _damage ~/ 40;
  int getDuration() => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  void onActivate() => log("{1} [are|is] frozen!", actor);
  void onExtend() => log("{1} feel[s] the cold linger!", actor);
  void onIntensify() => log("{1} feel[s] the cold intensify!", actor);
}

class PoisonAction extends ConditionAction {
  final int _damage;

  PoisonAction(this._damage);

  Condition get condition => actor.poison;

  int getIntensity() => 1 + _damage ~/ 20;
  int getDuration() => 1 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  void onActivate() => log("{1} [are|is] poisoned!", actor);
  void onExtend() => log("{1} feel[s] the poison linger!", actor);
  void onIntensify() => log("{1} feel[s] the poison intensify!", actor);
}

class BlindAction extends ConditionAction {
  final int _damage;

  BlindAction(this._damage);

  Condition get condition => actor.blindness;

  int getDuration() => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);

  void onActivate() {
    log("{1 his} vision dims!", actor);
    game.stage.heroVisibilityChanged();
  }

  void onExtend() => log("{1 his} vision dims!", actor);
}

class DazzleAction extends ConditionAction {
  final int _damage;

  DazzleAction(this._damage);

  Condition get condition => actor.dazzle;

  int getDuration() => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  void onActivate() => log("{1} [are|is] dazzled by the light!", actor);
  void onExtend() => log("{1} [are|is] dazzled by the light!", actor);
}

class ResistAction extends ConditionAction {
  final int _duration;
  final Element _element;

  ResistAction(this._duration, this._element);

  Condition get condition => actor.resistances[_element];

  int getDuration() => _duration;
  // TODO: Resistances of different intensity.
  void onActivate() => log("{1} [are|is] resistant to $_element.", actor);
  void onExtend() => log("{1} feel[s] the resistance extend.", actor);
}
