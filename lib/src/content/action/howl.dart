import '../../engine.dart';

/// Alert nearby sleeping monsters.
class HowlAction extends Action {
  final int _range;

  HowlAction(this._range);

  ActionResult onPerform() {
    log("{1} howls!", actor);
    addEvent(EventType.howl, actor: actor);

    for (var other in monster.game.stage.actors) {
      if (other != actor &&
          other is Monster &&
          (other.pos - monster.pos) <= _range) {
        // TODO: Take range into account when attenuating volume?
        other.hear(game.stage.volumeBetween(actor.pos, other.pos));
      }
    }

    return ActionResult.success;
  }
}
