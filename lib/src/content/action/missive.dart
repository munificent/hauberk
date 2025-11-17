import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

enum Missive { clumsy, insult, screech, hiss }

const _messages = {
  Missive.clumsy: [
    "{1} forget[s] what {1 he} was doing.",
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
  ],
  Missive.screech: [
    "{1} screech[es] at {2}!",
    "{1} taunt[s] {2}!",
    "{1} cackle[s] at {2}!",
  ],
  Missive.hiss: ["{1} hiss[es] at {2}!", "{1} spit[s] at {2}!"],
};

class MissiveAction extends Action {
  final Actor target;
  final Missive missive;

  /// Missives make noise.
  @override
  double get noise => Sound.attackNoise;

  MissiveAction(this.target, this.missive);

  @override
  ActionResult onPerform() {
    var message = rng.item(_messages[missive]!);

    return succeed(message, actor, target);
  }
}
