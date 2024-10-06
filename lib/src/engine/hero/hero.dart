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
  final Set<Monster> _seenMonsters = {};

  Behavior? _behavior;

  /// Damage scale for wielded weapons based on strength, their combined heft,
  /// skills, etc.
  final Property<double> _heftDamageScale = Property();
  double get heftDamageScale => _heftDamageScale.value;

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

  /// How calm and centered the hero is. Mental skills like spells spend focus.
  int get focus => _focus;
  int _focus = 0;

  /// How enraged the hero is.
  ///
  /// Each level increases the damage multiplier for melee damage.
  int get fury => _fury;
  int _fury = 0;

  /// The number of hero turns since they last took a hit that caused them to
  /// lose focus.
  int _turnsSinceLostFocus = 0;

  /// The number of hero turns since they last dealt damage to a monster.
  int _turnsSinceGaveDamage = 100;

  /// How much noise the Hero's last action made.
  double get lastNoise => _lastNoise;
  double _lastNoise = 0.0;

  @override
  String get nounText => 'you';

  @override
  Pronoun get pronoun => Pronoun.you;

  Inventory get inventory => save.inventory;

  Equipment get equipment => save.equipment;

  int get experience => save.experience;

  set experience(int value) => save.experience = value;

  SkillSet get skills => save.skills;

  int get gold => save.gold;

  set gold(int value) => save.gold = value;

  Lore get lore => save.lore;

  @override
  int get maxHealth => fortitude.maxHealth;

  Strength get strength => save.strength;

  Agility get agility => save.agility;

  Fortitude get fortitude => save.fortitude;

  Intellect get intellect => save.intellect;

  Will get will => save.will;

  // TODO: Equipment and items that let the hero swim, fly, etc.
  @override
  Motility get motility => Motility.doorAndWalk;

  @override
  int get emanationLevel => save.emanationLevel;

  Hero(Game game, Vec pos, this.save) : super(game, pos.x, pos.y) {
    // Give the hero energy so they can act before all of the monsters.
    energy.energy = Energy.actionCost;

    refreshProperties();

    // Set the meters now that we know the stats.
    health = maxHealth;
    _focus = intellect.maxFocus;
  }

  // TODO: Hackish.
  @override
  Object get appearance => 'hero';

  @override
  bool get needsInput {
    if (_behavior != null && !_behavior!.canPerform(this)) {
      waitForInput();
    }

    return _behavior == null;
  }

  /// The hero's experience level.
  int get level => _level.value;
  final _level = Property<int>();

  @override
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
          log(skill.gainMessage(level), this);
        } else {
          log(skill.discoverMessage, this);
        }
      }
    }
  }

  @override
  int get baseSpeed => Energy.normalSpeed;

  @override
  int get baseDodge => 20 + agility.dodgeBonus;

  @override
  Iterable<Defense> onGetDefenses() sync* {
    for (var item in equipment) {
      var defense = item.defense;
      if (defense != null) yield defense;
    }

    for (var skill in skills.acquired) {
      var defense = skill.getDefense(this, skills.level(skill));
      if (defense != null) yield defense;
    }

    // TODO: Temporary bonuses, etc.
  }

  @override
  Action onGetAction() => _behavior!.getAction(this);

  @override
  List<Hit> onCreateMeleeHits(Actor? defender) {
    var hits = <Hit>[];

    // See if any melee weapons are equipped.
    var weapons = equipment.weapons.toList();
    for (var i = 0; i < weapons.length; i++) {
      var weapon = weapons[i];
      if (weapon.attack!.isRanged) continue;

      var hit = weapon.attack!.createHit();

      weapon.modifyHit(hit);

      // Take heft and strength into account.
      hit.scaleDamage(_heftDamageScale.value);
      hits.add(hit);
    }

    // If not, punch it.
    if (hits.isEmpty) {
      hits.add(Attack(this, 'punch[es]', Option.heroPunchDamage).createHit());
    }

    for (var hit in hits) {
      hit.addStrike(agility.strikeBonus);

      for (var skill in skills.acquired) {
        skill.modifyAttack(
            this, defender as Monster?, hit, skills.level(skill));
      }

      // Scale damage by fury.
      hit.scaleDamage(strength.furyScale(fury));
    }

    return hits;
  }

  Hit createRangedHit() {
    var weapons = equipment.weapons.toList();
    var i = weapons.indexWhere((weapon) => weapon.attack!.isRanged);
    assert(i != -1, "Should have ranged weapon equipped.");

    var hit = weapons[i].attack!.createHit();

    // Take heft and strength into account.
    hit.scaleDamage(_heftDamageScale.value);

    modifyHit(hit, HitType.ranged);
    return hit;
  }

  /// Applies the hero-specific modifications to [hit].
  @override
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
    }

    // Let armor modify it. We don't worry about weapons here since the weapon
    // modified it when the hit was created. This ensures that when
    // dual-wielding, that one weapon's modifiers don't affect the other.
    for (var item in equipment) {
      if (item.type.weaponType == null) item.modifyHit(hit);
    }

    // TODO: Apply skills.
  }

  // TODO: If class or race can affect this, add it in.
  @override
  int onGetResistance(Element element) => save.equipmentResistance(element);

  @override
  void onGiveDamage(Action action, Actor defender, int damage) {
    // Hitting starts or continues the fury chain.
    _turnsSinceGaveDamage = 0;
  }

  @override
  void onTakeDamage(Action action, Actor? attacker, int damage) {
    // Getting hit loses focus.
    // TODO: Lose less focus for ranged attacks?
    var focus = (damage / maxHealth * will.damageFocusScale).ceil();
    _focus = (_focus - focus).clamp(0, intellect.maxFocus);

    _turnsSinceLostFocus = 0;

    // TODO: Would be better to do skills.discovered, but right now this also
    // discovers BattleHardening.
    for (var skill in game.content.skills) {
      skill.takeDamage(this, damage);
    }
  }

  @override
  void onKilled(Action action, Actor defender) {
    var monster = defender as Monster;

    // Killing starts or continues the fury chain.
    _turnsSinceGaveDamage = 0;

    // It only counts if the hero's seen the monster at least once.
    if (!_seenMonsters.contains(monster)) return;

    lore.slay(monster.breed);

    for (var skill in skills.discovered) {
      skill.killMonster(this, action, monster);
    }

    experience += monster.experience;
    refreshProperties();
  }

  @override
  void onDied(Noun attackNoun) {
    game.log.message("you were slain by {1}.", attackNoun);
  }

  @override
  void onFinishTurn(Action action) {
    // Make some noise.
    _lastNoise = action.noise;

    // Always digesting.
    if (stomach > 0) {
      stomach--;
      if (stomach == 0) game.log.message("You are getting hungry.");
    }

    // Update fury.
    if (_turnsSinceGaveDamage == 0) {
      // Every turn the hero harmed a monster increases fury.
      _fury++;
    } else if (_turnsSinceGaveDamage > 1) {
      // Otherwise, it decays, with a one turn grace period.
      // TODO: Maybe have higher will slow the decay rate.
      _fury -= _turnsSinceGaveDamage - 1;
    }

    _fury = _fury.clamp(0, strength.maxFury);

    _turnsSinceGaveDamage++;
    _turnsSinceLostFocus++;

    // TODO: Passive skills?
  }

  @override
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
        for (var skill in game.content.skills) {
          skill.seeBreed(this, monster.breed);
        }
      }
    }
  }

  /// Spends focus on some useful action.
  ///
  /// Does not reset [_turnsSinceLostFocus].
  void spendFocus(int focus) {
    assert(_focus >= focus);

    _focus -= focus;
  }

  void regenerateFocus(int focus) {
    // The longer the hero goes without losing focus, the more quickly it
    // regenerates.
    var scale = (_turnsSinceLostFocus + 1).clamp(1, 8) / 4;
    _focus = (_focus + focus * scale).ceil().clamp(0, intellect.maxFocus);
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

    // Refresh the heft scales.
    var weapons = equipment.weapons.toList();

    if (weapons.length > 1) {
      // Discover the dual-wield skill.
      // TODO: This is a really specific method to put on Skill. Is there a
      // cleaner way to handle this?
      for (var skill in game.content.skills) {
        skill.dualWield(this);
      }
    }

    var heftModifier = 1.0;
    for (var skill in skills.acquired) {
      heftModifier = skill.modifyHeft(this, skills.level(skill), heftModifier);
    }

    // When dual-wielding, it's as if each weapon has an individual heft that
    // is the total of both of them.
    var totalHeft = 0;
    for (var weapon in weapons) {
      totalHeft += weapon.heft;
    }

    var heftScale = strength.heftScale((totalHeft * heftModifier).round());
    _heftDamageScale.update(heftScale, (previous) {
      // TODO: Reword these if there is no weapon equipped?
      var weaponList = weapons.join(' and ');
      if (heftScale < 1.0 && previous >= 1.0) {
        game.log.error("You are too weak to effectively wield $weaponList.");
      } else if (heftScale >= 1.0 && previous < 1.0) {
        game.log.message("You feel comfortable wielding $weaponList.");
      }
    });

    // See if any skills changed. (Gaining intellect learns spells.)
    _refreshSkills();

    // Keep other stats in bounds.
    health = health.clamp(0, maxHealth);
    _focus = _focus.clamp(0, intellect.maxFocus);
    _fury = _fury.clamp(0, strength.maxFury);
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

  /// Whether the hero can currently perceive [actor].
  ///
  /// Takes into account both visibility and [perception].
  bool canPerceive(Actor actor) {
    if (game.stage[actor.pos].isVisible) return true;
    if (perception.isActive && (pos - actor.pos) < perception.intensity) {
      return true;
    }

    return false;
  }
}

int experienceLevel(int experience) {
  for (var level = 1; level <= Hero.maxLevel; level++) {
    if (experience < experienceLevelCost(level)) return level - 1;
  }

  return Hero.maxLevel;
}

/// Returns how much experience is needed to reach [level].
int experienceLevelCost(int level) {
  if (level > Hero.maxLevel) throw RangeError.value(level, "level");
  return math.pow(level - 1, 3).toInt() * 1000;
}
