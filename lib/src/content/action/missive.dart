import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

enum Missive { clumsy, insult }

final _messages = {
  Missive.clumsy: [
    "{1} forget[s] what {1 his} was doing.",
    "{1} lurch[es] around.",
    "{1} stumble[s] awkwardly.",
    "{1} trip[s] over {1 his} own feet!",
  ],
  Missive.insult: [
    "{1} insult[s] {2 his} mother!",
    "{1} jeer[s] at {2}!",
    "{1} mock[s] {2} mercilessly!",
    "{1} make[s] faces at {2}!",
    "{1} laugh[s] at {2}!",
    "{1} sneer[s] at {2}!",
  ]
};

class MissiveAction extends Action {
  final Actor target;
  final Missive missive;

  MissiveAction(this.target, this.missive);

  ActionResult onPerform() {
    var message = rng.item(_messages[missive]);

    return succeed(message, actor, target);
  }
}
