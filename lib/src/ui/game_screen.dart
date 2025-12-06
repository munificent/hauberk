import 'dart:math' as math;

import 'package:hauberk/src/ui/item/toss_dialog.dart';
import 'package:hauberk/src/ui/item/use_dialog.dart';
import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

// TODO: Directly importing this is a little hacky.
import '../content/tiles.dart';
import '../debug.dart';
import '../engine.dart';
import '../hues.dart';
import 'direction_dialog.dart';
import 'exit_popup.dart';
import 'experience_dialog.dart';
import 'forfeit_popup.dart';
import 'game_over_screen.dart';
import 'hero_info_dialog.dart';
import 'input.dart';
import 'item/drop_dialog.dart';
import 'item/equip_dialog.dart';
import 'item/item_dialog.dart';
import 'item/pick_up_dialog.dart';
import 'item/town_screen.dart';
import 'loading_dialog.dart';
import 'panel/item_panel.dart';
import 'panel/log_panel.dart';
import 'panel/sidebar_panel.dart';
import 'panel/stage_panel.dart';
import 'select_depth_popup.dart';
import 'select_skill_dialog.dart';
import 'skill_dialog.dart';
import 'storage.dart';
import 'target_dialog.dart';
import 'wizard_dialog.dart';

class GameScreen extends Screen<Input> {
  final Game game;

  /// When the hero is in the dungeon, this is their save state before entering.
  /// If they die or forfeit, their current state is discarded and this one is
  /// used instead.
  final HeroSave _previousSave;

  final Storage _storage;
  final LogPanel _logPanel;
  final ItemPanel itemPanel;
  late final SidebarPanel _sidebarPanel;

  StagePanel get stagePanel => _stagePanel;
  late final StagePanel _stagePanel;

  /// The number of ticks left to wait before restarting the game loop after
  /// coming back from a dialog where the player chose an action for the hero.
  int _pause = 0;

  Actor? _targetActor;
  Vec? _target;

  UsableSkill? _lastSkill;

  /// The portal for the tile the hero is currently standing on.
  ///
  /// When this changes, we know the hero has stepped onto a new one.
  TilePortal? _portal;

  void targetActor(Actor? value) {
    if (_targetActor != value) dirty();

    _targetActor = value;
    _target = null;
  }

  /// Targets the floor at [pos].
  void targetFloor(Vec? pos) {
    if (_targetActor != null || _target != pos) dirty();

    _targetActor = null;
    _target = pos;
  }

  /// Gets the currently targeted position.
  ///
  /// If targeting an actor, gets the actor's position.
  Vec? get currentTarget {
    // If we're targeting an actor, use its position.
    var actor = currentTargetActor;
    return actor?.pos ?? _target;
  }

  /// The currently targeted actor, if any.
  Actor? get currentTargetActor {
    // Forget the target if it dies or goes offscreen.
    var actor = _targetActor;
    if (actor != null) {
      if (!actor.isAlive || !game.heroCanPerceive(actor)) {
        _targetActor = null;
      }
    }

    if (_targetActor != null) return _targetActor;

    // If we're targeting the floor, see if there is an actor there.
    if (_target != null) {
      return game.stage.actorAt(_target!);
    }

    return null;
  }

  Rect get cameraBounds => _stagePanel.cameraBounds;

  Color get heroColor {
    var hero = game.hero;
    if (hero.health < hero.maxHealth / 4) return red;
    if (hero.poison.isActive) return peaGreen;
    if (hero.cold.isActive) return lightBlue;
    if (hero.health < hero.maxHealth / 2) return pink;
    return ash;
  }

  GameScreen(this._storage, this.game)
    : _previousSave = game.hero.save.clone(),
      _logPanel = LogPanel(game.log),
      itemPanel = ItemPanel(game) {
    _sidebarPanel = SidebarPanel(this);
    _stagePanel = StagePanel(this);

    Debug.bindGameScreen(this);
  }

  /// Builds a GameScreen and game with the hero in the town.
  ///
  /// If [newHero] is `true`, then [save] was just created. After creating the
  /// game, grants the hero their starting equipment. We do this here instead
  /// of when creating the [HeroSave] because gaining items can unlock skills,
  /// which adds to the log. The log can only be accessed once the [Hero] is in
  /// a [Game].
  factory GameScreen.town(
    Storage storage,
    Content content,
    HeroSave save, {
    bool newHero = false,
  }) {
    var game = Game(content, 0, save, width: 60, height: 34);

    // Give the hero their starting gear.
    if (newHero) {
      for (var item in content.startingItems(save)) {
        game.hero.inventory.tryAdd(item);
        game.hero.pickUp(game, item);
      }
    }

    for (var _ in game.generate()) {}

    return GameScreen(storage, game);
  }

  /// Draws [Glyph] at [x], [y] in [Stage] coordinates onto the stage panel.
  void drawStageGlyph(Terminal terminal, int x, int y, Glyph glyph) {
    _stagePanel.drawStageGlyph(terminal, x, y, glyph);
  }

  @override
  bool handleInput(Input input) {
    Action? action;
    switch (input) {
      case Input.quit:
        var portal = game.stage[game.hero.pos].portal;
        if (portal == TilePortals.exit) {
          ui.push(ExitPopup(_previousSave, game));
        } else {
          game.log.error("You are not standing on an exit.");
          dirty();
        }

      case Input.forfeit:
        ui.push(ForfeitPopup(isTown: game.depth == 0));
      case Input.selectSkill:
        ui.push(SelectSkillDialog(this));
      case Input.editSkills:
        ui.push(SkillDialog(game.hero.save));
      case Input.spendExperience:
        ui.push(ExperienceDialog(game.content, game.hero.save));
      case Input.heroInfo:
        ui.push(HeroInfoDialog(game.content, game.hero.save));
      case Input.drop:
        ui.push(DropDialog(this));
      case Input.use:
        ui.push(UseDialog(this));
      case Input.toss:
        ui.push(TossDialog(this));

      case Input.rest:
        if (!game.hero.rest()) {
          // Show the message.
          dirty();
        }

      case Input.operate:
        _operate();
      case Input.pickUp:
        _pickUp();
      case Input.equip:
        ui.push(EquipDialog(this));

      case Input.nw:
        action = WalkAction(Direction.nw);
      case Input.n:
        action = WalkAction(Direction.n);
      case Input.ne:
        action = WalkAction(Direction.ne);
      case Input.w:
        action = WalkAction(Direction.w);
      case Input.ok:
        action = WalkAction(Direction.none);
      case Input.e:
        action = WalkAction(Direction.e);
      case Input.sw:
        action = WalkAction(Direction.sw);
      case Input.s:
        action = WalkAction(Direction.s);
      case Input.se:
        action = WalkAction(Direction.se);

      case Input.runNW:
        game.hero.run(Direction.nw);
      case Input.runN:
        game.hero.run(Direction.n);
      case Input.runNE:
        game.hero.run(Direction.ne);
      case Input.runW:
        game.hero.run(Direction.w);
      case Input.runE:
        game.hero.run(Direction.e);
      case Input.runSW:
        game.hero.run(Direction.sw);
      case Input.runS:
        game.hero.run(Direction.s);
      case Input.runSE:
        game.hero.run(Direction.se);

      case Input.fireNW:
        _fireTowards(Direction.nw);
      case Input.fireN:
        _fireTowards(Direction.n);
      case Input.fireNE:
        _fireTowards(Direction.ne);
      case Input.fireW:
        _fireTowards(Direction.w);
      case Input.fireE:
        _fireTowards(Direction.e);
      case Input.fireSW:
        _fireTowards(Direction.sw);
      case Input.fireS:
        _fireTowards(Direction.s);
      case Input.fireSE:
        _fireTowards(Direction.se);

      case Input.fire:
        if (_lastSkill is TargetSkill) {
          var targetSkill = _lastSkill as TargetSkill;
          if (currentTargetActor != null) {
            // If we still have a visible target, use it.
            _fireAtTarget(_lastSkill as TargetSkill);
          } else {
            // No current target, so ask for one.
            _openTargetDialog(targetSkill);
          }
        } else if (_lastSkill is DirectionSkill) {
          // Ask user to pick a direction.
          ui.push(SkillDirectionDialog(this, _fireTowards));
        } else if (_lastSkill is ActionSkill) {
          var actionSkill = _lastSkill as ActionSkill;
          game.hero.setNextAction(
            actionSkill.getAction(game, game.hero.skills.level(actionSkill)),
          );
        } else {
          game.log.error("No skill selected.");
          dirty();
        }

      case Input.swap:
        var unequipped = game.hero.inventory.lastUnequipped;
        if (unequipped == null) {
          game.log.error("You aren't holding an unequipped item to swap.");
          dirty();
        } else {
          action = EquipAction(ItemLocation.inventory, unequipped);
        }

      case Input.wizard:
        if (Debug.enabled) {
          ui.push(WizardDialog(game));
        }
    }

    if (action != null) game.hero.setNextAction(action);

    return true;
  }

  @override
  void activate(Screen popped, Object? result) {
    if (!game.hero.needsInput(game)) {
      // The player is coming back from a screen where they selected an action
      // for the hero. Give them a bit to visually reorient themselves before
      // kicking off the action.
      _pause = 10;
    }

    if (popped is ExitPopup) {
      // TODO: Hero should start next to dungeon entrance.

      // Update shops.
      game.hero.save.shops.forEach((shop, inventory) {
        shop.update(inventory);
      });

      _storage.save();
      ui.goTo(GameScreen.town(_storage, game.content, game.hero.save));
    } else if (popped is SelectDepthPopup && result is int) {
      // Enter the dungeon.
      _storage.save();
      ui.push(LoadingDialog(game.hero.save, game.content, result));
    } else if (popped is LoadingDialog) {
      ui.goTo(GameScreen(_storage, result as Game));
    } else if (popped is ForfeitPopup && result == true) {
      if (game.depth > 0) {
        // Forfeiting, so return to the town and discard the current hero.
        // TODO: Hero should start next to dungeon entrance.
        ui.goTo(GameScreen.town(_storage, game.content, _previousSave));
      } else {
        // Leaving the town. Save just to be safe.
        _storage.save();
        ui.pop();
      }
    } else if (popped is TownScreen) {
      // Always save when leaving home or a shop.
      _storage.save();
    } else if (popped is ItemDialog) {
      // Save after changing items in the town.
      if (game.depth == 0) _storage.save();
    } else if (popped is SkillDialog) {
      // TODO: Once skills can be learned on the SkillDialog again, make this
      // work.
      // game.hero.updateSkills(result);
    } else if (popped is SelectSkillDialog && result != null) {
      if (result is TargetSkill) {
        _openTargetDialog(result);
      } else if (result is DirectionSkill) {
        ui.push(
          SkillDirectionDialog(this, (dir) {
            _lastSkill = result;
            _fireTowards(dir);
          }),
        );
      } else if (result is ActionSkill) {
        _lastSkill = result;
        game.hero.setNextAction(
          result.getAction(game, game.hero.skills.level(result)),
        );
      }
    }
  }

  @override
  void update() {
    if (_enterPortal()) return;

    if (_pause > 0) {
      _pause--;
      return;
    }

    var result = game.update();

    // See if the hero died.
    if (!game.hero.isAlive) {
      ui.goTo(GameOverScreen(_storage, game.hero.save, _previousSave));
      return;
    }

    if (_stagePanel.update(result.events)) dirty();

    if (result.needsRefresh) dirty();
  }

  @override
  void resize(Vec size) {
    var leftWidth = 21;

    if (size > 160) {
      leftWidth = 29;
    } else if (size > 150) {
      leftWidth = 25;
    }

    var centerWidth = size.x - leftWidth;

    itemPanel.hide();
    if (size.x >= 80) {
      var width = math.min(50, 20 + (size.x - 80) ~/ 2);
      itemPanel.show(Rect(size.x - width, 0, width, size.y));
      centerWidth = size.x - leftWidth - width;
    }

    _sidebarPanel.show(Rect(0, 0, leftWidth, size.y));

    var logHeight = 3 + (size.y - 30) ~/ 2;
    logHeight = math.min(logHeight, 10);

    _logPanel.show(Rect(leftWidth, 0, centerWidth, logHeight));
    stagePanel.show(
      Rect(leftWidth, logHeight, centerWidth, size.y - logHeight),
    );
  }

  @override
  void render(Terminal terminal) {
    terminal.clear();

    _stagePanel.render(terminal);
    _logPanel.render(terminal);
    // Note, this must be rendered after the stage panel so that the visible
    // monsters are correctly calculated first.
    _sidebarPanel.render(terminal);
    itemPanel.render(terminal);
  }

  /// Handle the hero stepping onto a portal tile.
  bool _enterPortal() {
    var portal = game.stage[game.hero.pos].portal;
    if (portal == _portal) return false;
    _portal = portal;

    switch (portal) {
      case TilePortals.dungeon:
        ui.push(SelectDepthPopup(game.content, game.hero.save));
      case TilePortals.home:
        ui.push(TownScreen.home(this));
      case TilePortals.shop1:
        _enterShop(0);
      case TilePortals.shop2:
        _enterShop(1);
      case TilePortals.shop3:
        _enterShop(2);
      case TilePortals.shop4:
        _enterShop(3);
      case TilePortals.shop5:
        _enterShop(4);
      case TilePortals.shop6:
        _enterShop(5);
      case TilePortals.shop7:
        _enterShop(6);
      case TilePortals.shop8:
        _enterShop(7);
      case TilePortals.shop9:
        _enterShop(8);
    }

    return true;
  }

  void _operate() {
    // See how many adjacent operable tiles there are.
    var operable = <Vec>[];
    for (var pos in game.hero.pos.neighbors) {
      if (game.stage[pos].type.canOperate) {
        operable.add(pos);
      }
    }

    if (operable.isEmpty) {
      game.log.error('You are not next to anything to operate.');
      dirty();
    } else if (operable.length == 1) {
      var pos = operable.first;
      // TODO: This leaks information if the hero is next to unexplored tiles.
      game.hero.setNextAction(game.stage[pos].type.onOperate!(pos));
    } else {
      ui.push(OperateDialog(this));
    }
  }

  void _pickUp() {
    var items = game.stage.itemsAt(game.hero.pos);
    if (items.length > 1) {
      // Show item dialog if there are multiple things to pick up.
      ui.push(PickUpDialog(this));
    } else if (items.length == 1) {
      // Otherwise attempt to pick the one item.
      game.hero.setNextAction(PickUpAction(items.first));
    } else {
      game.log.error('There is nothing here.');
      dirty();
    }
  }

  void _openTargetDialog(TargetSkill skill) {
    ui.push(
      TargetDialog(this, skill.getRange(game), (_) => _fireAtTarget(skill)),
    );
  }

  void _fireAtTarget(TargetSkill skill) {
    if (currentTarget == game.hero.pos && !skill.canTargetSelf) {
      game.log.error("You can't target yourself.");
      dirty();
      return;
    }

    _lastSkill = skill;
    // TODO: It's kind of annoying that we force the player to select a target
    // or direction for skills that spend focus/fury even when they won't be
    // able to perform it. Should do an early check first.
    game.hero.setNextAction(
      skill.getTargetAction(
        game,
        game.hero.skills.level(skill),
        currentTarget!,
      ),
    );
  }

  void _fireTowards(Direction dir) {
    // If the user canceled, don't fire.
    if (dir == Direction.none) return;

    if (_lastSkill is DirectionSkill) {
      var directionSkill = _lastSkill as DirectionSkill;
      game.hero.setNextAction(
        directionSkill.getDirectionAction(
          game,
          game.hero.skills.level(directionSkill),
          dir,
        ),
      );
    } else if (_lastSkill is TargetSkill) {
      var targetSkill = _lastSkill as TargetSkill;
      var pos = game.hero.pos + dir;

      // Target the monster that is in the fired direction, if any.
      late Vec previous;
      for (var step in Line(game.hero.pos, pos)) {
        // If we reached an actor, target it.
        var actor = game.stage.actorAt(step);
        if (actor != null) {
          targetActor(actor);
          break;
        }

        // If we hit a wall, target the floor tile before it.
        if (game.stage[step].blocksView) {
          targetFloor(previous);
          break;
        }

        // If we hit the end of the range, target the floor there.
        if ((step - game.hero.pos) >= targetSkill.getRange(game)) {
          targetFloor(step);
          break;
        }

        previous = step;
      }

      if (currentTarget != null) {
        game.hero.setNextAction(
          targetSkill.getTargetAction(
            game,
            game.hero.skills.level(targetSkill),
            currentTarget!,
          ),
        );
      } else {
        var tile = game.stage[game.hero.pos + dir].type.name;
        game.log.error("There is a $tile in the way.");
        dirty();
      }
    } else if (_lastSkill is ActionSkill) {
      game.log.error("${_lastSkill!.useName} does not take a direction.");
      dirty();
    } else {
      // TODO: Better error message.
      game.log.error("No skill selected.");
      dirty();
    }
  }

  void _enterShop(int index) {
    var shops = game.hero.save.shops.keys.toList();
    if (index >= shops.length) return;

    ui.push(TownScreen.shop(this, game.hero.save.shops[shops[index]]!));
  }
}
