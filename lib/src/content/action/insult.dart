import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

class InsultAction extends Action {
  final Actor target;

  InsultAction(this.target);

  ActionResult onPerform() {
    var message = rng.item(const [
      "{1} insult[s] {2 his} mother!",
      "{1} jeer[s] at {2}!",
      "{1} mock[s] {2} mercilessly!",
      "{1} make[s] faces at {2}!",
      "{1} laugh[s] at {2}!",
      "{1} sneer[s] at {2}!",
    ]);

    return succeed(message, actor, target);
  }
}
