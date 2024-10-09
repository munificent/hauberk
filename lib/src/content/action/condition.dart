import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../elements.dart';

/// Base class for an [Action] that applies (or extends/intensifies) a
/// [Condition]. It handles cases where the condition is already in effect with
/// possibly a different intensity.
abstract class ConditionAction extends Action {
  /// The [Condition] on the actor that should be affected.
  Condition get condition;

  /// The intensity of the condition to apply.
  int get intensity => 1;

  /// The number of turns the condition should last.
  int get duration;

  @override
  ActionResult onPerform() {
    var intensity = this.intensity;
    var duration = this.duration;

    if (!condition.isActive) {
      condition.activate(duration, intensity);
      onActivate();
      return ActionResult.success;
    }

    if (condition.intensity >= intensity) {
      // Scale down the new duration by how much weaker the new intensity is.
      duration = (duration * intensity) ~/ condition.intensity;

      // Compounding doesn't add as much as the first one.
      duration ~/= 2;
      if (duration == 0) return succeed();

      condition.extend(duration);
      onExtend();
      return ActionResult.success;
    }

    // Scale down the existing duration by how much stronger the new intensity
    // is.
    var oldDuration = (condition.duration * condition.intensity) ~/ intensity;

    condition.activate(oldDuration + duration ~/ 2, intensity);
    onIntensify();
    return ActionResult.success;
  }

  /// Override this to log the message when the condition is first applied.
  void onActivate();

  /// Override this to log the message when the condition is already in effect
  /// and its duration is extended.
  void onExtend();

  /// Override this to log the message when the condition is already in effect
  /// at a weaker intensity and the intensity increases.
  void onIntensify() {}
}

class HasteAction extends ConditionAction {
  final int _speed;
  final int _duration;

  HasteAction(this._speed, this._duration);

  @override
  Condition get condition => actor!.haste;

  @override
  int get intensity => _speed;

  @override
  int get duration => _duration;

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
  int get intensity => 1 + _damage ~/ 40;

  @override
  int get duration => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);

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
  int get intensity => 1 + _damage ~/ 20;

  @override
  int get duration => 1 + rng.triangleInt(_damage * 2, _damage ~/ 2);

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
  int get duration => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);

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
  int get duration => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);

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
  Condition get condition => actor!.resistanceCondition(_element);

  @override
  int get duration => _duration;
  // TODO: Resistances of different intensity.

  @override
  void onActivate() {
    // Poison resistance also immediately cures poison.
    log("{1} [are|is] resistant to $_element.", actor);
    if (actor!.poison.isActive) {
      actor!.poison.cancel();
      log("{1} [are|is] no longer poisoned.", actor);
    }

    // TODO: Same thing for cold? Other conditions?
  }

  @override
  void onExtend() => log("{1} feel[s] the resistance extend.", actor);
}
