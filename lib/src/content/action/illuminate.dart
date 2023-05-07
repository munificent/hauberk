import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import 'ray.dart';

/// Creates a swath of emanation that radiates out from a point.
class IlluminateAction extends RayActionBase {
  @override
  final int range;

  IlluminateAction(this.range, Vec center) : super(center, center, 1.0);

  @override
  void reachStartTile(Vec pos) {
    reachTile(pos, 0);
  }

  @override
  void reachTile(Vec pos, num distance) {
    game.stage[pos].maxEmanation(Lighting.emanationForLevel(3));
    game.stage.floorEmanationChanged();
    addEvent(EventType.pause);
  }
}

/// Creates an expanding ring of emanation centered on the [Actor].
///
/// This class mainly exists as an [Action] that [Item]s can use.
class IlluminateSelfAction extends Action {
  final int _range;

  IlluminateSelfAction(this._range);

  @override
  bool get isImmediate => false;

  @override
  ActionResult onPerform() {
    game.stage[actor!.pos].maxEmanation(Lighting.emanationForLevel(3));
    game.stage.floorEmanationChanged();
    addEvent(EventType.pause);

    return alternate(IlluminateAction(_range, actor!.pos));
  }
}
