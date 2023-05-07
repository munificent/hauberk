import 'package:piecemeal/piecemeal.dart';

import 'scenario.dart';

void main() {
  scenario("run in open space to wall", () {
    setUpStage("""##########
                  #........#
                  #@......1#
                  #........#
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });
}
