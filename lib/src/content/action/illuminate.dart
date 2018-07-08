import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'ray.dart';

/// Creates a swath of damage that radiates out from a point.
class IlluminateAction extends RayActionBase {
  final int range;
  final int _emanationLevel;

  IlluminateAction(this.range, this._emanationLevel, Vec center)
      : super(center, center, 1.0);

  void reachStartTile(Vec pos) {
    reachTile(pos, 0);
  }

  void reachTile(Vec pos, num distance) {
    game.stage[pos].addEmanation(Lighting.emanationForLevel(_emanationLevel));
    game.stage.floorEmanationChanged();
    addEvent(EventType.pause);
  }
}

/// Creates an expanding ring of emanation centered on the [Actor].
///
/// This class mainly exists as an [Action] that [Item]s can use.
class IlluminateSelfAction extends Action {
  final int _range;
  final int _emanationLevel;

  IlluminateSelfAction(this._range, this._emanationLevel);

  bool get isImmediate => false;

  ActionResult onPerform() {
    return alternate(IlluminateAction(_range, _emanationLevel, actor.pos));
  }
}
