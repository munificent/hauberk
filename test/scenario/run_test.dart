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

  scenario("run through right turns", () {
    setUpStage("""###########
                  #@........#
                  #########.#
                  #1#######.#
                  #.#######.#
                  #.#######.#
                  #.........#
                  ###########""");

    heroRun(Direction.e);
    playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    expectHeroAt(1, turns: 21);
  });

  scenario("run through left turns", () {
    setUpStage("""###########
                  #@#1......#
                  #.#######.#
                  #.#######.#
                  #.#######.#
                  #.#######.#
                  #.........#
                  ###########""");

    heroRun(Direction.s);
    playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    expectHeroAt(1, turns: 21);
  });

  scenario("run through one step zig-zag corridor", () {
    setUpStage("""###########
                  #@....#####
                  #####....1#
                  ###########""");

    heroRun(Direction.e);
    playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    expectHeroAt(1, turns: 8);
  });

  scenario("run through two step zig-zag corridor", () {
    setUpStage("""###########
                  #@....#####
                  #####.#####
                  #####....1#
                  ###########""");

    heroRun(Direction.e);
    playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    expectHeroAt(1, turns: 8);
  });

  scenario("run around wall", () {
    setUpStage("""#######
                  #@....#
                  #####.#
                  #1....#
                  #######""");

    heroRun(Direction.e);
    playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    expectHeroAt(1, turns: 8);
  });

  scenario("run around buttonhook corner right", () {
    setUpStage("""#######
                  #@....#
                  #####.#
                  ####..#
                  ####.##
                  ####1##
                  #######""");

    heroRun(Direction.e);
    playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    expectHeroAt(1, turns: 7);
  });

  scenario("run around buttonhook corner left", () {
    setUpStage("""#######
                  #....@#
                  #.#####
                  #..####
                  ##.####
                  ##1####
                  #######""");

    heroRun(Direction.w);
    playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    expectHeroAt(1, turns: 7);
  });

  scenario("stop at side branch", () {
    setUpStage("""###########
                  #@..1.....#
                  #####.#####
                  #####.#####
                  ###########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("stop at T", () {
    setUpStage("""###########
                  #.........#
                  #####1#####
                  #####.#####
                  #####.#####
                  #####@#####
                  ###########""");

    heroRun(Direction.n);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("stop at diagonal branch", () {
    setUpStage("""###########
                  #######.###
                  ######.####
                  #####.#####
                  #@..1######
                  #####.#####
                  ######.####
                  #######.###
                  ###########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("stop at ambiguous pillar", () {
    // Even though both two-step paths end up at the same point, we don't know
    // which to pick, so we pick neither.
    setUpStage("""###########
                  #####.#####
                  #@..1#....#
                  #####.#####
                  ###########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });
}
