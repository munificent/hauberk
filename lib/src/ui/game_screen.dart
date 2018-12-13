import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

// TODO: Directly importing this is a little hacky.
import '../content/tiles.dart';
import '../debug.dart';
import '../engine.dart';
import '../hues.dart';
import 'direction_dialog.dart';
import 'exit_screen.dart';
import 'forfeit_dialog.dart';
import 'game_over_screen.dart';
import 'hero_info_dialog.dart';
import 'input.dart';
import 'item_dialog.dart';
import 'item_screen.dart';
import 'loading_dialog.dart';
import 'log_panel.dart';
import 'select_depth_screen.dart';
import 'select_skill_dialog.dart';
import 'sidebar_panel.dart';
import 'skill_dialog.dart';
import 'stage_panel.dart';
import 'storage.dart';
import 'target_dialog.dart';
import 'wizard_dialog.dart';

class GameScreen extends Screen<Input> {
  final Game game;

  final HeroSave _storageSave;
  final Storage _storage;
  final LogPanel _logPanel;
  SidebarPanel _sidebarPanel;
  StagePanel _stagePanel;

  /// The number of ticks left to wait before restarting the game loop after
  /// coming back from a dialog where the player chose an action for the hero.
  int _pause = 0;

  // TODO: Move this to StagePanel?
  /// The size of the [Stage] view area.
  final viewSize = Vec(60, 34);

  Actor _targetActor;
  Vec _target;

  UsableSkill _lastSkill;

  /// The portal for the tile the hero is currently standing on.
  ///
  /// When this changes, we know the hero has stepped onto a new one.
  TilePortal _portal;

  void targetActor(Actor value) {
    if (_targetActor != value) dirty();

    _targetActor = value;
    _target = null;
  }

  /// Targets the floor at [pos].
  void targetFloor(Vec pos) {
    if (_targetActor != null || _target != pos) dirty();

    _targetActor = null;
    _target = pos;
  }

  /// Gets the currently targeted position.
  ///
  /// If targeting an actor, gets the actor's position.
  Vec get currentTarget {
    // If we're targeting an actor, use its position.
    if (currentTargetActor != null) return currentTargetActor.pos;

    // Forget the targeted floor if we know the hero can't see it.
    if (_target != null) {
      var tile = game.stage[_target];

      // TODO: Should use isVisible? Can you still target a reachable tile in
      // the dark?
      if (tile.isExplored && (tile.isOccluded || tile.blocksView)) {
        _target = null;
      }
    }

    return _target;
  }

  /// The currently targeted actor, if any.
  Actor get currentTargetActor {
    // Forget the target if it dies or goes offscreen.
    if (_targetActor != null) {
      if (!_targetActor.isAlive || !_targetActor.isVisibleToHero) {
        _targetActor = null;
      }
    }

    if (_targetActor != null) return _targetActor;

    // If we're targeting the floor, see if there is an actor there.
    if (_target != null) {
      return game.stage.actorAt(_target);
    }

    return null;
  }

  GameScreen(this._storage, this.game, this._storageSave)
      : _logPanel = LogPanel(game.log) {
    _sidebarPanel = SidebarPanel(this);
    _stagePanel = StagePanel(this);

    Debug.bindGameScreen(this);
  }

  factory GameScreen.town(Storage storage, Content content, HeroSave save) {
    var game = Game(content, save, 0, width: 60, height: 34);
    for (var _ in game.generate()) {}

    return GameScreen(storage, game, null);
  }

  Rect get cameraBounds => _stagePanel.cameraBounds;

  /// Draws [Glyph] at [x], [y] in [Stage] coordinates onto the stage panel.
  void drawStageGlyph(Terminal terminal, int x, int y, Glyph glyph) {
    _stagePanel.drawStageGlyph(terminal, x, y, glyph);
  }

  bool handleInput(Input input) {
    Action action;
    switch (input) {
      case Input.quit:
        var portal = game.stage[game.hero.pos].portal;
        if (portal == TilePortals.exit) {
          ui.push(ExitScreen(_storageSave, game));
        } else {
          game.log.error("You are not standing on an exit.");
          dirty();
        }
        break;

      case Input.forfeit:
        ui.push(ForfeitDialog(isTown: game.depth == 0));
        break;
      case Input.selectSkill:
        ui.push(SelectSkillDialog(game));
        break;
      case Input.editSkills:
        ui.push(SkillDialog(game.hero.save));
        break;
      case Input.heroInfo:
        ui.push(HeroInfoDialog(game.content, game.hero.save));
        break;
      case Input.drop:
        ui.push(ItemDialog.drop(this));
        break;
      case Input.use:
        ui.push(ItemDialog.use(this));
        break;
      case Input.toss:
        ui.push(ItemDialog.toss(this));
        break;

      case Input.rest:
        if (!game.hero.rest()) {
          // Show the message.
          dirty();
        }
        break;

      case Input.open:
        _open();
        break;
      case Input.close:
        _closeDoor();
        break;
      case Input.pickUp:
        _pickUp();
        break;
      case Input.unequip:
        ui.push(ItemDialog.unequip(this));
        break;

      case Input.nw:
        action = WalkAction(Direction.nw);
        break;
      case Input.n:
        action = WalkAction(Direction.n);
        break;
      case Input.ne:
        action = WalkAction(Direction.ne);
        break;
      case Input.w:
        action = WalkAction(Direction.w);
        break;
      case Input.ok:
        action = WalkAction(Direction.none);
        break;
      case Input.e:
        action = WalkAction(Direction.e);
        break;
      case Input.sw:
        action = WalkAction(Direction.sw);
        break;
      case Input.s:
        action = WalkAction(Direction.s);
        break;
      case Input.se:
        action = WalkAction(Direction.se);
        break;

      case Input.runNW:
        game.hero.run(Direction.nw);
        break;
      case Input.runN:
        game.hero.run(Direction.n);
        break;
      case Input.runNE:
        game.hero.run(Direction.ne);
        break;
      case Input.runW:
        game.hero.run(Direction.w);
        break;
      case Input.runE:
        game.hero.run(Direction.e);
        break;
      case Input.runSW:
        game.hero.run(Direction.sw);
        break;
      case Input.runS:
        game.hero.run(Direction.s);
        break;
      case Input.runSE:
        game.hero.run(Direction.se);
        break;

      case Input.fireNW:
        _fireTowards(Direction.nw);
        break;
      case Input.fireN:
        _fireTowards(Direction.n);
        break;
      case Input.fireNE:
        _fireTowards(Direction.ne);
        break;
      case Input.fireW:
        _fireTowards(Direction.w);
        break;
      case Input.fireE:
        _fireTowards(Direction.e);
        break;
      case Input.fireSW:
        _fireTowards(Direction.sw);
        break;
      case Input.fireS:
        _fireTowards(Direction.s);
        break;
      case Input.fireSE:
        _fireTowards(Direction.se);
        break;

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
              actionSkill.getAction(game, game.hero.skills.level(actionSkill)));
        } else {
          game.log.error("No skill selected.");
          dirty();
        }
        break;

      case Input.swap:
        if (game.hero.inventory.lastUnequipped == null) {
          game.log.error("You aren't holding an unequipped item to swap.");
          dirty();
        } else {
          action = EquipAction(
              ItemLocation.inventory, game.hero.inventory.lastUnequipped);
        }
        break;

      case Input.wizard:
        if (Debug.enabled) {
          ui.push(WizardDialog(game));
        } else {
          game.log.cheat("No cheating in non-debug builds. Cheater.");
          dirty();
        }
        break;
    }

    if (action != null) game.hero.setNextAction(action);

    return true;
  }

  void activate(Screen popped, result) {
    if (!game.hero.needsInput) {
      // The player is coming back from a screen where they selected an action
      // for the hero. Give them a bit to visually reorient themselves before
      // kicking off the action.
      _pause = 10;
    }

    if (popped is ExitScreen) {
      // TODO: Hero should start next to dungeon entrance.
      _storageSave.takeFrom(game.hero);
      ui.goTo(GameScreen.town(_storage, game.content, _storageSave));
    } else if (popped is SelectDepthScreen && result is int) {
      // Enter the dungeon.
      // TODO: Make this a transparent dialog?
      _storage.save();
      ui.goTo(LoadingDialog(_storage, game.hero.save, game.content, result));
    } else if (popped is ForfeitDialog && result == true) {
      if (game.depth > 0) {
        // Forfeiting, so return to the town and discard the current hero.
        // TODO: Hero should start next to dungeon entrance.
        ui.goTo(GameScreen.town(_storage, game.content, _storageSave));
      } else {
        // Leaving the town. Save just to be safe.
        _storage.save();
        ui.pop();
      }
    } else if (popped is ItemScreen) {
      // Always save when leaving home or a shop.
      _storage.save();
    } else if (popped is ItemDialog) {
      // Save after changing items in the town.
      if (game.depth == 0) _storage.save();
    } else if (popped is SkillDialog) {
      // TODO: Once skills can be learned on the SkillDialog again, make this
      // work.
//      game.hero.updateSkills(result);
    } else if (popped is SelectSkillDialog && result != null) {
      if (result is TargetSkill) {
        _openTargetDialog(result);
      } else if (result is DirectionSkill) {
        ui.push(SkillDirectionDialog(this, (dir) {
          _lastSkill = result;
          _fireTowards(dir);
        }));
      } else if (result is ActionSkill) {
        _lastSkill = result;
        game.hero.setNextAction(
            result.getAction(game, game.hero.skills.level(result)));
      }
    }
  }

  void update() {
    if (_enterPortal()) return;

    if (_pause > 0) {
      _pause--;
      return;
    }

    var result = game.update();

    // See if the hero died.
    if (!game.hero.isAlive) {
      ui.goTo(GameOverScreen(game.log));
      return;
    }

    if (_stagePanel.update(result.events)) dirty();

    if (result.needsRefresh) dirty();
  }

  void render(Terminal terminal) {
    terminal.clear();

    var bar = Glyph.fromCharCode(CharCode.boxDrawingsLightVertical, steelGray);
    for (var y = 0; y < terminal.height; y++) {
      terminal.drawGlyph(60, y, bar);
    }

    var hero = game.hero;
    var heroColor = ash;
    if (hero.health < hero.maxHealth / 4) {
      heroColor = brickRed;
    } else if (hero.poison.isActive) {
      heroColor = peaGreen;
    } else if (hero.cold.isActive) {
      heroColor = cornflower;
    } else if (hero.health < hero.maxHealth / 2) {
      heroColor = salmon;
    } else if (hero.stomach == 0 && hero.health < hero.maxHealth) {
      heroColor = sandal;
    }

    var visibleMonsters = <Monster>[];

    _stagePanel.render(terminal.rect(0, 0, viewSize.x, viewSize.y), heroColor,
        visibleMonsters);

    _logPanel.render(terminal.rect(0, 34, 60, 6));
    _sidebarPanel.render(
        terminal.rect(61, 0, 20, 40), heroColor, visibleMonsters);
  }

  /// Handle the hero stepping onto a portal tile.
  bool _enterPortal() {
    var portal = game.stage[game.hero.pos].portal;
    if (portal == _portal) return false;
    _portal = portal;

    switch (portal) {
      case TilePortals.dungeon:
        ui.push(SelectDepthScreen(game.content, game.hero.save));
        break;
      case TilePortals.home:
        ui.push(ItemScreen.home(game.hero.save));
        break;
      case TilePortals.shop1:
        _enterShop(0);
        break;
      case TilePortals.shop2:
        _enterShop(1);
        break;
      case TilePortals.shop3:
        _enterShop(2);
        break;
      case TilePortals.shop4:
        _enterShop(3);
        break;
      case TilePortals.shop5:
        _enterShop(4);
        break;
      case TilePortals.shop6:
        _enterShop(5);
        break;
      case TilePortals.shop7:
        _enterShop(6);
        break;
      case TilePortals.shop8:
        _enterShop(7);
        break;
      case TilePortals.shop9:
        _enterShop(8);
        break;
    // TODO: No crucible right now.
//        ui.push(new ItemScreen.crucible(content, save));
    }

    return true;
  }

  void _open() {
    // See how many adjacent closed doors there are.
    // TODO: Handle chests.
    var openable = <Vec>[];
    for (var pos in game.hero.pos.neighbors) {
      if (game.stage[pos].type.canOpen) {
        openable.add(pos);
      }
    }

    if (openable.isEmpty) {
      game.log.error('You are not next to anything to open.');
      dirty();
    } else if (openable.length == 1) {
      var pos = openable.first;
      // TODO: This leaks information if the hero is next to unexplored tiles.
      game.hero.setNextAction(game.stage[pos].type.onOpen(pos));
    } else {
      ui.push(OpenDialog(this));
    }
  }

  void _closeDoor() {
    // See how many adjacent open doors there are.
    var closeable = <Vec>[];
    for (var pos in game.hero.pos.neighbors) {
      if (game.stage[pos].type.canClose) {
        closeable.add(pos);
      }
    }

    if (closeable.isEmpty) {
      game.log.error('You are not next to an open door.');
      dirty();
    } else if (closeable.length == 1) {
      var pos = closeable.first;
      // TODO: This leaks information if the hero is next to unexplored tiles.
      game.hero.setNextAction(game.stage[pos].type.onClose(pos));
    } else {
      ui.push(CloseDialog(this));
    }
  }

  void _pickUp() {
    var items = game.stage.itemsAt(game.hero.pos);
    if (items.length > 1) {
      // Show item dialog if there are multiple things to pick up.
      ui.push(ItemDialog.pickUp(this));
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
        TargetDialog(this, skill.getRange(game), (_) => _fireAtTarget(skill)));
  }

  void _fireAtTarget(TargetSkill skill) {
    if (currentTarget == game.hero.pos && !skill.canTargetSelf) {
      game.log.error("You can't target yourself.");
      dirty();
      return;
    }

    _lastSkill = skill;
    game.hero.setNextAction(skill.getTargetAction(
        game, game.hero.skills.level(skill), currentTarget));
  }

  void _fireTowards(Direction dir) {
    // If the user canceled, don't fire.
    if (dir == Direction.none) return;

    if (_lastSkill is DirectionSkill) {
      var directionSkill = _lastSkill as DirectionSkill;
      game.hero.setNextAction(directionSkill.getDirectionAction(
          game, game.hero.skills.level(directionSkill), dir));
    } else if (_lastSkill is TargetSkill) {
      var targetSkill = _lastSkill as TargetSkill;
      var pos = game.hero.pos + dir;

      // Target the monster that is in the fired direction, if any.
      Vec previous;
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
        game.hero.setNextAction(targetSkill.getTargetAction(
            game, game.hero.skills.level(targetSkill), currentTarget));
      } else {
        var tile = game.stage[game.hero.pos + dir].type.name;
        game.log.error("There is a ${tile} in the way.");
        dirty();
      }
    } else if (_lastSkill is ActionSkill) {
      game.log.error("${_lastSkill.useName} does not take a direction.");
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

    ui.push(
        ItemScreen.shop(game.hero.save, game.hero.save.shops[shops[index]]));
  }
}
