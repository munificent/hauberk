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

  scenario("run diagonal in open space to wall", () {
    setUpStage("""##########
                  #....1...#
                  #........#
                  #........#
                  #........#
                  #@.......#
                  #........#
                  ##########""");

    heroRun(Direction.ne);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("run along left wall until end", () {
    setUpStage("""##########
                  #@......1#
                  #........#
                  #........#
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("run along right wall until end", () {
    setUpStage("""##########
                  #........#
                  #........#
                  #@......1#
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("enter open space and run to wall", () {
    setUpStage("""##########
                  ##.......#
                  #@......1#
                  ##.......#
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("enter open left wall and run until end", () {
    setUpStage("""##########
                  #@......1#
                  ##.......#
                  ##.......#
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("enter open right wall and run until end", () {
    setUpStage("""##########
                  ##.......#
                  ##.......#
                  #@......1#
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("run along left wall until opening", () {
    setUpStage("""##########
                  ######.###
                  ######.###
                  #@...1...#
                  #........#
                  #........#
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("run along right wall until opening", () {
    setUpStage("""##########
                  #........#
                  #........#
                  #@...1...#
                  ######.###
                  ######.###
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("run through corridor until T left intersection", () {
    setUpStage("""##########
                  ######.###
                  ######.###
                  #@...1...#
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("run through corridor until T right intersection", () {
    setUpStage("""##########
                  #@...1...#
                  ######.###
                  ######.###
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("run through corridor until cross intersection", () {
    setUpStage("""##########
                  ######.###
                  ######.###
                  #@...1...#
                  ######.###
                  ######.###
                  ##########""");

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

  scenario("continue straight through T left intersection", () {
    setUpStage("""##########
                  ####.#####
                  ####.#####
                  #..@....1#
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("continue left through T left intersection", () {
    setUpStage("""##########
                  ####1#####
                  ####.#####
                  ####.#####
                  ####.#####
                  #..@.....#
                  ##########""");

    heroRun(Direction.ne);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("continue straight through T right intersection", () {
    setUpStage("""##########
                  #..@....1#
                  ####.#####
                  ####.#####
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("continue right through T right intersection", () {
    setUpStage("""##########
                  #..@.....#
                  ####.#####
                  ####.#####
                  ####.#####
                  ####1#####
                  ##########""");

    heroRun(Direction.se);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("continue straight through cross intersection", () {
    setUpStage("""##########
                  ####.#####
                  ####.#####
                  ####.#####
                  #..@....1#
                  ####.#####
                  ####.#####
                  ####.#####
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("continue left through cross intersection", () {
    setUpStage("""##########
                  ####1#####
                  ####.#####
                  ####.#####
                  #..@.....#
                  ####.#####
                  ####.#####
                  ####.#####
                  ##########""");

    heroRun(Direction.ne);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("continue right through cross intersection", () {
    setUpStage("""##########
                  ####.#####
                  ####.#####
                  ####.#####
                  #..@.....#
                  ####.#####
                  ####.#####
                  ####1#####
                  ##########""");

    heroRun(Direction.se);
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

  scenario("run through one step zig-zag corridor", () {
    setUpStage("""##########
                  ####....1#
                  #@...#####
                  ##########""");

    heroRun(Direction.e);
    playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    expectHeroAt(1, turns: 7);
  });

  scenario("continue through zig-zag corridor", () {
    setUpStage("""##########
                  ###......#
                  ###.####.#
                  ###.#....#
                  #...#.####
                  #.###.####
                  #@#1..####
                  ##########""");

    heroRun(Direction.n);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("stop in wide diagonal corridor", () {
    // TODO: It would be good if running could detect this and continue through
    // it but for now it doesn't, so pinning the test to the current behavior.
    setUpStage("""#############
                  #######.....#
                  ######..#####
                  #####..######
                  ####..#######
                  #@.1.########
                  #############""");

    heroRun(Direction.e);
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

  scenario("continue through corridor with 45° left turns", () {
    setUpStage("""#############
                  #####@#1#####
                  ####.###.####
                  ###.#####.###
                  ##.#######.##
                  #.#########.#
                  #.#########.#
                  #.#########.#
                  ##.#######.##
                  ###.#####.###
                  ####.###.####
                  #####...#####
                  #############""");

    heroRun(Direction.sw);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("continue through corridor with 45° right turns", () {
    setUpStage("""#############
                  #####1#@#####
                  ####.###.####
                  ###.#####.###
                  ##.#######.##
                  #.#########.#
                  #.#########.#
                  #.#########.#
                  ##.#######.##
                  ###.#####.###
                  ####.###.####
                  #####...#####
                  #############""");

    heroRun(Direction.se);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("continue through diagonal corridor with 90° left turns", () {
    setUpStage("""###########
                  ####1#@####
                  ###.###.###
                  ##.#####.##
                  #.#######.#
                  ##.#####.##
                  ###.###.###
                  ####.#.####
                  #####.#####
                  ###########""");

    heroRun(Direction.se);
    playUntilNeedsInput();
    expectHeroAt(1);
  });

  scenario("continue through diagonal corridor with 90° right turns", () {
    setUpStage("""###########
                  ####@#1####
                  ###.###.###
                  ##.#####.##
                  #.#######.#
                  ##.#####.##
                  ###.###.###
                  ####.#.####
                  #####.#####
                  ###########""");

    heroRun(Direction.sw);
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

  // TODO: Test that it cuts corners when turning through corridor.
  // TODO: Test that it can handle short zig-zag corridors.
  // TODO: Test stopping next to items and monsters.
  // TODO: Test stopping when a visible monster moves.
}
