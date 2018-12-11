import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/actor.dart';
import '../core/combat.dart';
import '../core/element.dart';
import '../core/energy.dart';
import '../core/game.dart';
import '../core/log.dart';
import '../core/option.dart';
import '../items/equipment.dart';
import '../items/inventory.dart';
import '../items/item.dart';
import '../monster/monster.dart';
import '../stage/tile.dart';
import 'behavior.dart';
import 'hero_save.dart';
import 'lore.dart';
import 'skill.dart';
import 'stat.dart';

/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  /// The highest level the hero can reach.
  static const maxLevel = 50;

  final HeroSave save;

  /// Monsters the hero has already seen. Makes sure we don't double count them.
  final Set<Monster> _seenMonsters = Set();

  Behavior _behavior;

  /// Damage scale based on the current weapon, equipment, and stats.
  final Property<double> _heftScale = Property();

  /// How full the hero is.
  ///
  /// The hero raises this by eating food. It reduces constantly. The hero can
  /// only rest while its non-zero.
  ///
  /// It starts half-full, presumably the hero had a nice meal before heading
  /// off to adventure.
  int get stomach => _stomach;

  set stomach(int value) => _stomach = value.clamp(0, Option.heroMaxStomach);
  int _stomach = Option.heroMaxStomach ~/ 2;

  int _focus = 400;

  int get focus => _focus;

  set focus(int value) => _focus = value.clamp(0, intellect.maxFocus);

  /// How much noise the Hero's last action made.
  double get lastNoise => _lastNoise;
  double _lastNoise = 0.0;

  String get nounText => 'you';

  Pronoun get pronoun => Pronoun.you;

  Inventory get inventory => save.inventory;

  Equipment get equipment => save.equipment;

  int get experience => save.experience;

  set experience(int value) => save.experience = value;

  SkillSet get skills => save.skills;

  int get gold => save.gold;

  set gold(int value) => save.gold = value;

  Lore get lore => save.lore;

  int get maxHealth => fortitude.maxHealth;

  Strength get strength => save.strength;
  Agility get agility => save.agility;
  Fortitude get fortitude => save.fortitude;
  Intellect get intellect => save.intellect;
  Will get will => save.will;

  // TODO: Equipment and items that let the hero swim, fly, etc.
  Motility get motility => Motility.doorAndWalk;

  int get emanationLevel => save.emanationLevel;

  Hero(Game game, Vec pos, this.save)
      : super(game, pos.x, pos.y) {
    // Give the hero energy so they can act before all of the monsters.
    energy.energy = Energy.actionCost;

    refreshProperties();

    // Set the health now that we know the level, which determines fortitude.
    health = maxHealth;

    // Acquire any skills from the starting items.
    // TODO: Doing this here is hacky. It only really comes into play for
    // starting items.
    for (var item in inventory) {
      _gainItemSkills(item);
    }
  }

  // TODO: Hackish.
  get appearance => 'hero';

  bool get needsInput {
    if (_behavior != null && !_behavior.canPerform(this)) {
      waitForInput();
    }

    return _behavior == null;
  }

  /// The hero's experience level.
  int get level => _level.value;
  final _level = Property<int>();

  int get armor => save.armor;

  /// The total weight of all equipment.
  int get weight => save.weight;

  // TODO: Not currently used since skills are not explicitly learned in the
  // UI. Re-enable when we add rogue skills?
  /*
  /// Updates the hero's skill levels to [skills] and apply any other changes
  /// caused by that.
  void updateSkills(SkillSet skills) {
    // Update anything affected.
    this.skills.update(skills);
  }
  */

  // TODO: The set of skills discovered from items should probably be stored in
  // lore. Then the skill levels can be stored using Property and refreshed
  // like other properties.
  /// Discover or acquire any skills associated with [item].
  void _gainItemSkills(Item item) {
    for (var skill in item.type.skills) {
      if (save.heroClass.proficiency(skill) != 0.0 && skills.discover(skill)) {
        // See if the hero can immediately use it.
        var level = skill.calculateLevel(save);
        if (skills.gain(skill, level)) {
          game.log.gain(skill.gainMessage(level), this);
        } else {
          game.log.gain(skill.discoverMessage, this);
        }
      }
    }
  }

  int get baseSpeed => Energy.normalSpeed;

  int get baseDodge => 20 + agility.dodgeBonus;

  // TODO: Shields, temporary bonuses, etc.
  Iterable<Defense> onGetDefenses() sync* {
    for (var skill in skills.acquired) {
      var defense = skill.getDefense(this, skills.level(skill));
      if (defense != null) yield defense;
    }
  }

  Action onGetAction() => _behavior.getAction(this);

  Hit onCreateMeleeHit(Actor defender) {
    // See if a melee weapon is equipped.
    var weapon = equipment.weapon;

    Hit hit;
    if (weapon != null && !weapon.attack.isRanged) {
      hit = weapon.attack.createHit();

      // Take heft and strength into account.
      hit.scaleDamage(_heftScale.value);
    } else {
      hit = Attack(this, 'punch[es]', Option.heroPunchDamage).createHit();
    }

    hit.addStrike(agility.strikeBonus);

    for (var skill in skills.acquired) {
      skill.modifyAttack(this, defender as Monster, hit, skills.level(skill));
    }

    return hit;
  }

  Hit createRangedHit() {
    var weapon = equipment.weapon;

    // This should only be called when we know the hero has a ranged weapon
    // equipped.
    assert(weapon != null && weapon.attack.isRanged);

    var hit = weapon.attack.createHit();

    // Take heft and strength into account.
    hit.scaleDamage(_heftScale.value);

    modifyHit(hit, HitType.ranged);
    return hit;
  }

  /// Applies the hero-specific modifications to [hit].
  void onModifyHit(Hit hit, HitType type) {
    // TODO: Use agility to affect strike.

    switch (type) {
      case HitType.melee:
        break;

      case HitType.ranged:
        // TODO: Use strength to affect range.
        // TODO: Take heft into account.
        break;

      case HitType.toss:
        hit.scaleRange(strength.tossRangeScale);
        break;
    }

    // Let equipment modify it.
    for (var item in equipment) {
      item.modifyHit(hit);
    }

    // TODO: Apply skills.
  }

  // TODO: If class or race can affect this, add it in.
  int onGetResistance(Element element) => save.equipmentResistance(element);

  void onTakeDamage(Action action, Actor attacker, int damage) {
    // Getting hit loses focus.
    // TODO: Should the hero lose focus if they dodge the attack? Seems like it
    // would still break their attention. Maybe lose a fraction of the focus?
    // TODO: Scale based on will.
    focus -= intellect.maxFocus * damage * 2 ~/ maxHealth;

    // TODO: Would be better to do skills.discovered, but right now this also
    // discovers BattleHardening.
    for (var skill in game.content.skills) {
      skill.takeDamage(this, damage);
    }
  }

  void onKilled(Action action, Actor defender) {
    var monster = defender as Monster;

    // It only counts if the hero's seen the monster at least once.
    if (!_seenMonsters.contains(monster)) return;

    lore.slay(monster.breed);

    for (var skill in skills.discovered) {
      skill.killMonster(this, action, monster);
    }

    experience += monster.experience;
    refreshProperties();
  }

  void onDied(Noun attackNoun) {
    game.log.message("you were slain by {1}.", attackNoun);
  }

  void onFinishTurn(Action action) {
    // Make some noise.
    _lastNoise = action.noise;

    // Always digesting.
    if (stomach > 0) {
      stomach--;
      if (stomach == 0) game.log.message("You are getting hungry.");
    }

    // TODO: Passive skills?
  }

  void changePosition(Vec from, Vec to) {
    super.changePosition(from, to);
    game.stage.heroVisibilityChanged();
  }

  void waitForInput() {
    _behavior = null;
  }

  void setNextAction(Action action) {
    _behavior = ActionBehavior(action);
  }

  /// Starts resting, if the hero has eaten and is able to regenerate.
  bool rest() {
    if (poison.isActive) {
      game.log
          .error("You cannot rest while poison courses through your veins!");
      return false;
    }

    if (health == maxHealth) {
      game.log.message("You are fully rested.");
      return false;
    }

    if (stomach == 0) {
      game.log.error("You are too hungry to rest.");
      return false;
    }

    _behavior = RestBehavior();
    return true;
  }

  void run(Direction direction) {
    _behavior = RunBehavior(direction);
  }

  void disturb() {
    if (_behavior is! ActionBehavior) waitForInput();
  }

  void seeMonster(Monster monster) {
    // TODO: Blindness and dazzle.

    if (_seenMonsters.add(monster)) {
      // TODO: If we want to give the hero experience for seeing a monster too,
      // (so that sneak play-style still lets the player gain levels), do that
      // here.
      lore.seeBreed(monster.breed);

      // If this is the first time we've seen this breed, see if that unlocks
      // a slaying skill for it.
      if (lore.seenBreed(monster.breed) == 1) {
        // TODO: Would be better to do skills.discovered, but right now this also
        // discovers BattleHardening.
        for (var skill in game.content.skills) {
          skill.seeBreed(this, monster.breed);
        }
      }
    }
  }

  /// Refreshes all hero state whose change should be logged.
  ///
  /// For example, if the hero equips a helm that increases intellect, we want
  /// to log that. Likewise, if they level up and their strength increases. Or
  /// maybe a ghost drains their experience, which lowers their level, which
  /// reduces dexterity.
  ///
  /// To track that, any calculated property whose change should be noted is
  /// wrapped in a [Property] and updated here. Note that order that these are
  /// updated matters. Properties must be updated after the properties they
  /// depend on.
  void refreshProperties() {
    var level = experienceLevel(experience);
    _level.update(level, (previous) {
      game.log.gain('You have reached level $level.');
      // TODO: Different message if level went down.
    });

    strength.refresh(game);
    agility.refresh(game);
    fortitude.refresh(game);
    intellect.refresh(game);
    will.refresh(game);

    var heft = strength.heftScale(equipment.weapon?.heft ?? 0);
    _heftScale.update(heft, (previous) {
      // TODO: Reword these if there is no weapon equipped?
      if (heft < 1.0 && previous >= 1.0) {
        game.log.error("You are too weak to effectively wield your weapon.");
      } else if (heft >= 1.0 && previous < 1.0) {
        game.log.message("You feel comfortable wielding your weapon.");
      }
    });

    // See if any skills changed. (Gaining intellect learns spells.)
    _refreshSkills();
  }

  /// Called when the hero holds an item.
  ///
  /// This can be in response to picking it up, or equipping or using it
  /// straight from the ground.
  void pickUp(Item item) {
    // TODO: If the user repeatedly picks up and drops the same item, it gets
    // counted every time. Maybe want to put a (serialized) flag on items for
    // whether they have been picked up or not.
    lore.findItem(item);

    _gainItemSkills(item);
    refreshProperties();
  }

  /// See if any known skills have leveled up.
  void _refreshSkills() {
    skills.discovered.forEach(refreshSkill);
  }

  /// Ensures the hero has discovered [skill] and logs if it is the first time
  /// it's been seen.
  void discoverSkill(Skill skill) {
    if (save.heroClass.proficiency(skill) == 0.0) return;

    if (!skills.discover(skill)) return;

    game.log.gain(skill.discoverMessage, this);
  }

  void refreshSkill(Skill skill) {
    var level = skill.calculateLevel(save);
    if (skills.gain(skill, level)) {
      game.log.gain(skill.gainMessage(level), this);
    }
  }
}

int experienceLevel(int experience) {
  for (var level = 1; level <= Hero.maxLevel; level++) {
    if (experience < experienceLevelCost(level)) return level - 1;
  }

  return Hero.maxLevel;
}

/// Returns how much experience is needed to reach [level] or `null` if [level]
/// is greater than the maximum level.
int experienceLevelCost(int level) {
  if (level > Hero.maxLevel) return null;
  return math.pow(level - 1, 3).toInt() * 1000;
}
