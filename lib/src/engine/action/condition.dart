import 'package:piecemeal/piecemeal.dart';

import '../condition.dart';
import '../element.dart';
import 'action.dart';
import 'element.dart';

/// Base class for an [Action] that applies (or extends/intensifies) a
/// [Condition]. It handles cases where the condition is already in effect with
/// possibly a different intensity.
abstract class ConditionAction extends Action {
  /// The [Condition] on the actor that should be affected.
  Condition get condition;

  /// The intensity of the condition to apply.
  int getIntensity() => 1;

  /// The number of turns the condition should last.
  int getDuration();

  /// Override this to log the message when the condition is first applied.
  void logApply();

  /// Override this to log the message when the condition is already in effect
  /// and its duration is extended.
  void logExtend();

  /// Override this to log the message when the condition is already in effect
  /// at a weaker intensity and the intensity increases.
  void logIntensify() {}

  ActionResult onPerform() {
    var intensity = getIntensity();
    var duration = getDuration();

    // TODO: Apply resistance to duration and bail if zero duration.
    // TODO: Don't lower intensity by resistance here (we want to handle that
    // each turn in case it changes), but do see if resistance will lower the
    // intensity to zero. If so, bail.

    if (!condition.isActive) {
      condition.activate(duration, intensity);
      logApply();
      return ActionResult.success;
    }

    if (condition.intensity >= intensity) {
      // Scale down the new duration by how much weaker the new intensity is.
      duration = (duration * intensity) ~/ condition.intensity;

      // Compounding doesn't add as much as the first one.
      duration ~/= 2;
      if (duration == 0) return succeed();

      condition.extend(duration);
      logExtend();
      return ActionResult.success;
    }

    // Scale down the existing duration by how much stronger the new intensity
    // is.
    var oldDuration = (condition.duration * condition.intensity) ~/ intensity;

    condition.activate(oldDuration + duration ~/ 2, intensity);
    logIntensify();
    return ActionResult.success;
  }
}

class HasteAction extends ConditionAction {
  final int _duration;
  final int _speed;

  HasteAction(this._duration, this._speed);

  Condition get condition => actor.haste;

  int getIntensity() => _speed;
  int getDuration() => _duration;
  void logApply() => log("{1} start[s] moving faster.", actor);
  void logExtend() => log("{1} [feel]s the haste lasting longer.", actor);
  void logIntensify() => log("{1} move[s] even faster.", actor);
}

class FreezeAction extends ConditionAction with DestroyItemsMixin {
  final int _damage;
  final int resistance;

  FreezeAction(this._damage, this.resistance);

  Condition get condition => actor.cold;

  ActionResult onPerform() {
    destroyItems(8, "freezable", "shatters");
    return super.onPerform();
  }

  int getIntensity() => 1 + _damage ~/ 40;
  int getDuration() => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  void logApply() => log("{1} [are|is] frozen!", actor);
  void logExtend() => log("{1} feel[s] the cold linger!", actor);
  void logIntensify() => log("{1} feel[s] the cold intensify!", actor);
}

class PoisonAction extends ConditionAction {
  final int _damage;

  PoisonAction(this._damage);

  Condition get condition => actor.poison;

  int getIntensity() => 1 + _damage ~/ 20;
  int getDuration() => 1 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  void logApply() => log("{1} [are|is] poisoned!", actor);
  void logExtend() => log("{1} feel[s] the poison linger!", actor);
  void logIntensify() => log("{1} feel[s] the poison intensify!", actor);
}

class DazzleAction extends ConditionAction {
  final int _damage;

  DazzleAction(this._damage);

  Condition get condition => actor.dazzle;

  int getDuration() => 3 + rng.triangleInt(_damage * 2, _damage ~/ 2);
  void logApply() => log("{1} [are|is] dazzled by the light!", actor);
  void logExtend() => log("{1} [are|is] dazzled by the light!", actor);
}

class ResistAction extends ConditionAction {
  final int _duration;
  final Element _element;

  ResistAction(this._duration, this._element);

  Condition get condition => actor.resistances[_element];

  int getDuration() => _duration;
  // TODO: Resistances of different intensity.
  void logApply() => log("{1} [are|is] resistant to $_element.", actor);
  void logExtend() => log("{1} feel[s] the resistance extend.", actor);
}
