import 'package:piecemeal/piecemeal.dart';

import 'scenario.dart';

void main() {
  scenario("run in open space to wall", (s) {
    s.setUpStage("""##########
                  #........#
                  #@......1#
                  #........#
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("run diagonal in open space to wall", (s) {
    s.setUpStage("""##########
                  #....1...#
                  #........#
                  #........#
                  #........#
                  #@.......#
                  #........#
                  ##########""");

    s.heroRun(Direction.ne);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("run along left wall until end", (s) {
    s.setUpStage("""##########
                  #@......1#
                  #........#
                  #........#
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("run along right wall until end", (s) {
    s.setUpStage("""##########
                  #........#
                  #........#
                  #@......1#
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("enter open space and run to wall", (s) {
    s.setUpStage("""##########
                  ##.......#
                  #@......1#
                  ##.......#
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("enter open left wall and run until end", (s) {
    s.setUpStage("""##########
                  #@......1#
                  ##.......#
                  ##.......#
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("enter open right wall and run until end", (s) {
    s.setUpStage("""##########
                  ##.......#
                  ##.......#
                  #@......1#
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("run along left wall until opening", (s) {
    s.setUpStage("""##########
                  ######.###
                  ######.###
                  #@...1...#
                  #........#
                  #........#
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("run along right wall until opening", (s) {
    s.setUpStage("""##########
                  #........#
                  #........#
                  #@...1...#
                  ######.###
                  ######.###
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("run through corridor until T left intersection", (s) {
    s.setUpStage("""##########
                  ######.###
                  ######.###
                  #@...1...#
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("run through corridor until T right intersection", (s) {
    s.setUpStage("""##########
                  #@...1...#
                  ######.###
                  ######.###
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("run through corridor until cross intersection", (s) {
    s.setUpStage("""##########
                  ######.###
                  ######.###
                  #@...1...#
                  ######.###
                  ######.###
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("stop at T", (s) {
    s.setUpStage("""###########
                  #.........#
                  #####1#####
                  #####.#####
                  #####.#####
                  #####@#####
                  ###########""");

    s.heroRun(Direction.n);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("continue straight through T left intersection", (s) {
    s.setUpStage("""##########
                  ####.#####
                  ####.#####
                  #..@....1#
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("continue left through T left intersection", (s) {
    s.setUpStage("""##########
                  ####1#####
                  ####.#####
                  ####.#####
                  ####.#####
                  #..@.....#
                  ##########""");

    s.heroRun(Direction.ne);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("continue straight through T right intersection", (s) {
    s.setUpStage("""##########
                  #..@....1#
                  ####.#####
                  ####.#####
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("continue right through T right intersection", (s) {
    s.setUpStage("""##########
                  #..@.....#
                  ####.#####
                  ####.#####
                  ####.#####
                  ####1#####
                  ##########""");

    s.heroRun(Direction.se);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("continue straight through cross intersection", (s) {
    s.setUpStage("""##########
                  ####.#####
                  ####.#####
                  ####.#####
                  #..@....1#
                  ####.#####
                  ####.#####
                  ####.#####
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("continue left through cross intersection", (s) {
    s.setUpStage("""##########
                  ####1#####
                  ####.#####
                  ####.#####
                  #..@.....#
                  ####.#####
                  ####.#####
                  ####.#####
                  ##########""");

    s.heroRun(Direction.ne);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("continue right through cross intersection", (s) {
    s.setUpStage("""##########
                  ####.#####
                  ####.#####
                  ####.#####
                  #..@.....#
                  ####.#####
                  ####.#####
                  ####1#####
                  ##########""");

    s.heroRun(Direction.se);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("run through right turns", (s) {
    s.setUpStage("""###########
                  #@........#
                  #########.#
                  #1#######.#
                  #.#######.#
                  #.#######.#
                  #.........#
                  ###########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    s.expectHeroAt(1, turns: 21);
  });

  scenario("run through left turns", (s) {
    s.setUpStage("""###########
                  #@#1......#
                  #.#######.#
                  #.#######.#
                  #.#######.#
                  #.#######.#
                  #.........#
                  ###########""");

    s.heroRun(Direction.s);
    s.playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    s.expectHeroAt(1, turns: 21);
  });

  scenario("run through two step zig-zag corridor", (s) {
    s.setUpStage("""###########
                  #@....#####
                  #####.#####
                  #####....1#
                  ###########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    s.expectHeroAt(1, turns: 8);
  });

  scenario("run around wall", (s) {
    s.setUpStage("""#######
                  #@....#
                  #####.#
                  #1....#
                  #######""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    s.expectHeroAt(1, turns: 8);
  });

  scenario("run around buttonhook corner right", (s) {
    s.setUpStage("""#######
                  #@....#
                  #####.#
                  ####..#
                  ####.##
                  ####1##
                  #######""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    s.expectHeroAt(1, turns: 7);
  });

  scenario("run around buttonhook corner left", (s) {
    s.setUpStage("""#######
                  #....@#
                  #.#####
                  #..####
                  ##.####
                  ##1####
                  #######""");

    s.heroRun(Direction.w);
    s.playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    s.expectHeroAt(1, turns: 7);
  });

  scenario("run through one step zig-zag corridor", (s) {
    s.setUpStage("""###########
                  #@....#####
                  #####....1#
                  ###########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    s.expectHeroAt(1, turns: 8);
  });

  scenario("run through one step zig-zag corridor", (s) {
    s.setUpStage("""##########
                  ####....1#
                  #@...#####
                  ##########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();

    // Count turns to make sure the hero cuts the corners diagonally.
    s.expectHeroAt(1, turns: 7);
  });

  scenario("continue through zig-zag corridor", (s) {
    s.setUpStage("""##########
                  ###......#
                  ###.####.#
                  ###.#....#
                  #...#.####
                  #.###.####
                  #@#1..####
                  ##########""");

    s.heroRun(Direction.n);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("stop in wide diagonal corridor", (s) {
    // TODO: It would be good if running could detect this and continue through
    // it but for now it doesn't, so pinning the test to the current behavior.
    s.setUpStage("""#############
                  #######.....#
                  ######..#####
                  #####..######
                  ####..#######
                  #@.1.########
                  #############""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("stop at diagonal branch", (s) {
    s.setUpStage("""###########
                  #######.###
                  ######.####
                  #####.#####
                  #@..1######
                  #####.#####
                  ######.####
                  #######.###
                  ###########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("continue through corridor with 45° left turns", (s) {
    s.setUpStage("""#############
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

    s.heroRun(Direction.sw);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("continue through corridor with 45° right turns", (s) {
    s.setUpStage("""#############
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

    s.heroRun(Direction.se);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("continue through diagonal corridor with 90° left turns", (s) {
    s.setUpStage("""###########
                  ####1#@####
                  ###.###.###
                  ##.#####.##
                  #.#######.#
                  ##.#####.##
                  ###.###.###
                  ####.#.####
                  #####.#####
                  ###########""");

    s.heroRun(Direction.se);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("continue through diagonal corridor with 90° right turns", (s) {
    s.setUpStage("""###########
                  ####@#1####
                  ###.###.###
                  ##.#####.##
                  #.#######.#
                  ##.#####.##
                  ###.###.###
                  ####.#.####
                  #####.#####
                  ###########""");

    s.heroRun(Direction.sw);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  scenario("stop at ambiguous pillar", (s) {
    // Even though both two-step paths end up at the same point, we don't know
    // which to pick, so we pick neither.
    s.setUpStage("""###########
                  #####.#####
                  #@..1#....#
                  #####.#####
                  ###########""");

    s.heroRun(Direction.e);
    s.playUntilNeedsInput();
    s.expectHeroAt(1);
  });

  // TODO: Test that it cuts corners when turning through corridor.
  // TODO: Test that it can handle short zig-zag corridors.
  // TODO: Test stopping next to items and monsters.
  // TODO: Test stopping when a visible monster moves.
}
