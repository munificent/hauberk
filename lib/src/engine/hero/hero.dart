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
import '../stage/stage.dart';
import '../stage/tile.dart';
import 'behavior.dart';
import 'hero_class.dart';
import 'lore.dart';
import 'race.dart';
import 'skill.dart';
import 'stat.dart';

/// When the player is playing the game inside a dungeon, he is using a [Hero].
/// When outside of the dungeon on the menu screens, though, only a subset of
/// the hero's data persists (for example, there is no position when not in a
/// dungeon). This class stores that state.
class HeroSave {
  final String name;

  final RaceStats race;
  final HeroClass heroClass;

  int get level => experienceLevel(experienceCents);

  Inventory inventory = Inventory(Option.inventoryCapacity);
  Equipment equipment = Equipment();

  /// Items in the hero's home.
  Inventory home = Inventory(Option.homeCapacity);

  /// Items in the hero's crucible.
  Inventory crucible = Inventory(Option.crucibleCapacity);

  int experienceCents = 0;

  SkillSet skills;

  // TODO: Get rid of gold and shops if I'm sure we won't be using it.
  /// How much gold the hero has.
  int gold = Option.heroGoldStart;

  /// The lowest depth that the hero has successfully explored and exited.
  int maxDepth = 0;

  Lore get lore => _lore;
  Lore _lore;

  HeroSave(this.name, Race race, this.heroClass)
      : race = race.rollStats(),
        skills = SkillSet(),
        _lore = Lore();

  HeroSave.load(
      this.name,
      this.race,
      this.heroClass,
      this.inventory,
      this.equipment,
      this.home,
      this.crucible,
      this.experienceCents,
      this.skills,
      this._lore,
      this.gold,
      this.maxDepth);

  /// Copies data from [hero] into this object. This should be called when the
  /// [Hero] has successfully completed a [Stage] and his changes need to be
  /// "saved".
  void copyFrom(Hero hero) {
    inventory = hero.inventory;
    equipment = hero.equipment;
    experienceCents = hero._experienceCents;
    gold = hero.gold;
    skills = hero.skills.clone();
    _lore = hero.lore.clone();
  }
}

/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  /// The highest level the hero can reach.
  static const maxLevel = 50;

  String get nounText => 'you';
  Pronoun get pronoun => Pronoun.you;

  // TODO: Instead of copying all of these immutable values out of HeroSave,
  // move them to a separate shared object.
  final String name;
  final RaceStats race;
  final HeroClass heroClass;

  final Inventory inventory;
  final Equipment equipment;

  /// Experience is stored internally as hundredths of a point for higher (but
  /// not floating point) precision.
  int _experienceCents = 0;

  final strength = Strength();
  final agility = Agility();
  final fortitude = Fortitude();
  final intellect = Intellect();
  final will = Will();

  /// Damage scale based on the current weapon, equipment, and stats.
  final Property<double> _heftScale = Property();

  final SkillSet skills;

  int gold;

  final Lore lore;

  /// Monsters the hero has already seen. Makes sure we don't double count them.
  final Set<Monster> _seenMonsters = Set();

  Behavior _behavior;

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

  int get maxHealth => fortitude.maxHealth;

  int _focus = 400;
  int get focus => _focus;
  set focus(int value) => _focus = value.clamp(0, intellect.maxFocus);

  /// How much noise the Hero's last action made.
  double get lastNoise => _lastNoise;
  double _lastNoise = 0.0;

  // TODO: Equipment and items that let the hero swim, fly, etc.
  Motility get motility => Motility.doorAndWalk;

  // TODO: Calculate from wielded light source and other equipment.
  int get emanationLevel {
    var level = 0;

    // Find the brightest light source being carried.
    for (var item in inventory) {
      level = math.max(level, item.emanationLevel);
    }

    return level;
  }

  Hero(Game game, Vec pos, HeroSave save)
      : name = save.name,
        race = save.race,
        heroClass = save.heroClass,
        inventory = save.inventory.clone(),
        equipment = save.equipment.clone(),
        _experienceCents = save.experienceCents,
        skills = save.skills.clone(),
        gold = save.gold,
        lore = save.lore.clone(),
        super(game, pos.x, pos.y) {
    // Hero state is cloned above so that if they die in the dungeon, they lose
    // anything they found.
    strength.bindHero(this);
    agility.bindHero(this);
    fortitude.bindHero(this);
    intellect.bindHero(this);
    will.bindHero(this);

    // Give the hero energy so they can act before all of the monsters.
    energy.energy = Energy.actionCost;

    refreshProperties();

    // Set the health now that we know the level, which determines fortitude.
    health = maxHealth;

    // Acquire any skills from the starting items.
    // TODO: Doing this here is hacky. It only really comes into play for
    // starting items.
    for (var item in inventory) {
      gainItemSkills(item);
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

  int get experience => _experienceCents ~/ 100;

  /// The hero's experience level.
  int get level => _level.value;
  final _level = Property<int>();

  int get armor {
    var total = 0;
    for (var item in equipment) {
      total += item.armor;
    }

    for (var skill in skills.acquired) {
      total += skill.modifyArmor(this, skills.level(skill));
    }

    return total;
  }

  /// The total weight of all equipment.
  int get weight {
    var total = 0;
    for (var item in equipment) {
      total += item.weight;
    }

    return total;
  }

  /// Gets the total permament resistance provided by all equipment.
  int equipmentResistance(Element element) {
    // TODO: If class or race can affect this, add it in.
    var resistance = 0;

    for (var item in equipment) {
      resistance += item.resistance(element);
    }

    // TODO: Unify this with onDefend().

    return resistance;
  }

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
  void gainItemSkills(Item item) {
    for (var skill in item.type.skills) {
      if (heroClass.proficiency(skill) != 0.0 && skills.discover(skill)) {
        // See if the hero can immediately use it.
        var level = skill.calculateLevel(this);
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

  void defend() {
    disturb();
  }

  // TODO: If class or race can affect this, add it in.
  int onGetResistance(Element element) => equipmentResistance(element);

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

    _experienceCents += monster.experienceCents;
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
      lore.see(monster.breed);

      // If this is the first time we've seen this breed, see if that unlocks
      // a slaying skill for it.
      if (lore.seen(monster.breed) == 1) {
        for (var group in monster.breed.groups) {
          if (group.slaySkill == null) continue;

          if (heroClass.proficiency(group.slaySkill) == 0.0) continue;

          if (skills.discover(group.slaySkill)) {
            game.log.gain(group.slaySkill.discoverMessage, this);
          }
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
    var level = experienceLevel(_experienceCents);
    _level.update(level, (previous) {
      game.log.gain('You have reached level $level.');
      // TODO: Different message if level went down.
    });

    strength.refresh();
    agility.refresh();
    fortitude.refresh();
    intellect.refresh();
    will.refresh();

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

  /// See if any known skills have leveled up.
  void _refreshSkills() {
    skills.discovered.forEach(refreshSkill);
  }

  void refreshSkill(Skill skill) {
    var level = skill.calculateLevel(this);
    if (skills.gain(skill, level)) {
      game.log.gain(skill.gainMessage(level), this);
    }
  }
}

int experienceLevel(int experienceCents) {
  var experience = experienceCents ~/ 100;

  for (var level = 1; level <= Hero.maxLevel; level++) {
    if (experience < experienceLevelCost(level)) return level - 1;
  }

  return Hero.maxLevel;
}

/// Returns how much experience is needed to reach [level] or `null` if [level]
/// is greater than the maximum level.
int experienceLevelCost(int level) {
  if (level > Hero.maxLevel) return null;
  return math.pow(level - 1, 3).toInt() * 100;
}
