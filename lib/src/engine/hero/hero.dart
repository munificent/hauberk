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
  final HeroSave save;

  /// Monsters the hero has already seen. Makes sure we don't double count them.
  final Set<Monster> _seenMonsters = {};

  Behavior? _behavior;

  // TODO: These properties are never actually read. They're only used to log
  // messages when the calculated value changes. Everything else that uses the
  // value gets it directly. This feels weird.

  /// Damage scale for wielded weapons based on strength, their combined heft,
  /// skills, etc.
  final Property<double> _heftDamageScale = Property();

  /// How many spells the hero is able to know, based on intellect.
  final Property<int> _spellCount = Property();

  /// How full the hero is.
  ///
  /// The hero raises this by eating food. It reduces constantly. The hero can
  /// only rest while its non-zero.
  ///
  /// It starts half-full, presumably the hero had a nice meal before heading
  /// off to adventure.
  // TODO: This should be in HeroSave.
  int get stomach => _stomach;

  set stomach(int value) => _stomach = value.clamp(0, Option.heroMaxStomach);
  int _stomach = Option.heroMaxStomach ~/ 2;

  /// How calm and centered the hero is.
  ///
  /// Mental skills like spells spend focus.
  int get focus => _focus;
  int _focus = 0;

  /// How enraged the hero is.
  ///
  /// Physical skills spend this.
  int get fury => _fury;
  int _fury = 0;

  /// The number of hero turns since they were last attacked.
  int _turnsSinceAttack = 1000;

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
  int get maxHealth => vitality.maxHealth;

  Strength get strength => save.strength;

  Agility get agility => save.agility;

  Vitality get vitality => save.vitality;

  Intellect get intellect => save.intellect;

  // TODO: Equipment and items that let the hero swim, fly, etc.
  @override
  Motility get motility => Motility.doorAndWalk;

  @override
  int get emanationLevel => save.emanationLevel;

  Hero(Vec pos, this.save) : super(pos.x, pos.y) {
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
  bool needsInput(Game game) {
    if (_behavior != null && !_behavior!.canPerform(game, this)) {
      waitForInput();
    }

    return _behavior == null;
  }

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
      yield* skill.defenses(this, skills.level(skill));
    }

    // TODO: Temporary bonuses, etc.
  }

  @override
  Action onGetAction(Game game) => _behavior!.getAction(this);

  @override
  List<Hit> onCreateMeleeHits(Actor? defender) {
    var attacks = <(Item?, Attack)>[];

    // Use any equipped melee weapons.
    for (var weapon in equipment.weapons) {
      if (!weapon.attack!.isRanged) attacks.add((weapon, weapon.attack!));
    }

    // If there are none, punch.
    if (attacks.isEmpty) {
      attacks.add((null, Attack(this, 'punch[es]', Option.heroPunchDamage)));
    }

    var hits = <Hit>[];
    for (var (weapon, attack) in attacks) {
      var hit = attack.createHit();
      hits.add(hit);

      hit.addStrike(agility.strikeBonus, 'agility');

      for (var skill in skills.acquired) {
        var level = skills.level(skill);
        skill.modifyHit(this, defender as Monster?, weapon, hit, level);
      }

      if (weapon != null) {
        // Take heft and strength into account.
        hit.scaleDamage(_heftDamageScale.value, 'heft');

        // Let the weapon's affixes have an effect.
        weapon.modifyHit(hit);
      }
    }

    return hits;
  }

  Hit createRangedHit() {
    var weapons = equipment.weapons.toList();
    var i = weapons.indexWhere((weapon) => weapon.attack!.isRanged);
    assert(i != -1, "Should have ranged weapon equipped.");

    var weapon = weapons[i];
    var hit = weapon.attack!.createHit();

    for (var skill in skills.acquired) {
      var level = skills.level(skill);
      skill.modifyRangedHit(this, weapon, hit, level);
    }

    // Take heft and strength into account.
    hit.scaleDamage(_heftDamageScale.value, 'heft');

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
  void onKilled(Action action, Actor defender) {
    var monster = defender as Monster;

    // It only counts if the hero's seen the monster at least once.
    if (!_seenMonsters.contains(monster)) return;

    var slain = lore.slay(monster.breed);

    // Killing more of the same breed gives diminishing returns. This is to
    // discourage players from grinding indefinitely, and reflects that the
    // hero learns less and less each time they kill the same monster.
    var baseExperience = monster.experience;
    var scaled = (baseExperience * 20 / (slain + 19)).ceil();
    experience += scaled;

    refreshProperties();
  }

  @override
  void onDied(Action action, Noun attackNoun) {
    action.show("{1} [were|was] slain by {2}.", this, attackNoun);
  }

  @override
  void onFinishTurn(Action action) {
    // Make some noise.
    _lastNoise = action.noise;

    // Fury decays if the hero is no longer being attacked.
    if (_fury > 0 && _turnsSinceAttack > 1) {
      var decay = ((_turnsSinceAttack - 2) ~/ 2);
      _fury = (_fury - decay).clamp(0, strength.maxFury);
    }

    _turnsSinceAttack++;

    // TODO: Passive skills?
  }

  @override
  void onChangePosition(Game game, Vec from, Vec to) {
    game.stage.heroVisibilityChanged();
  }

  /// Called when an [Actor] is attempting to [hit] the hero.
  ///
  /// Note that this is called even if the hit ultimately misses.
  void receiveAttack(Hit hit) {
    // Don't sleep through being attacked.
    disturb();

    // Being attacked increases fury. We do this on each attack so that if the
    // hero is surrounded, their fury goes up faster. This mitigates some of
    // the negative consequences of being outnumbered.
    _turnsSinceAttack = 0;

    var healthFraction = hit.averageDamage / health;
    var furyIncrease = (healthFraction * 10.0).ceil();
    _fury = (_fury + furyIncrease).clamp(0, strength.maxFury);
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
      save.log.error(
        "You cannot rest while poison courses through your veins!",
      );
      return false;
    }

    if (health == maxHealth) {
      save.log.message("You are fully rested.");
      return false;
    }

    if (stomach == 0) {
      save.log.error("You are too hungry to rest.");
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
    }
  }

  /// Spends focus on some useful action.
  void spendFocus(int focus) {
    assert(_focus >= focus);

    _focus -= focus;
  }

  void regenerateFocus(int focus) {
    _focus = (_focus + focus).clamp(0, intellect.maxFocus);
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
    strength.refresh(save);
    agility.refresh(save);
    vitality.refresh(save);
    intellect.refresh(save);

    // Refresh the heft scales.
    var heftModifier = 1.0;
    for (var skill in skills.acquired) {
      heftModifier = skill.modifyHeft(this, skills.level(skill), heftModifier);
    }

    // When dual-wielding, it's as if each weapon has an individual heft that
    // is the total of both of them.
    var totalHeft = 0;
    var weapons = equipment.weapons.toList();
    for (var weapon in equipment.weapons) {
      totalHeft += weapon.heft;
    }

    var heftScale = strength.heftScale((totalHeft * heftModifier).round());
    _heftDamageScale.update(heftScale, (previous) {
      var description = switch (weapons) {
        // Dual-wielding two of the same weapon.
        [var a, var b] when a.quantifiableName == b.quantifiableName =>
          Log.quantify(a.quantifiableName, 2),
        [var a, var b] => "${a.nounText} and ${b.nounText}",
        [var a] => a.nounText,
        [] => "your fists",
        _ => throw ArgumentError(),
      };

      if (heftScale < 1.0 && previous >= 1.0) {
        save.log.error("You are too weak to effectively wield $description.");
      } else if (heftScale >= 1.0 && previous < 1.0) {
        save.log.message("You feel comfortable wielding $description.");
      }
    });

    var spellCount = intellect.spellCount;
    _spellCount.update(spellCount, (previous) {
      // Let the player know if they lost or regained any previously learned
      // spells.
      var knownBefore = math.min(save.learnedSpells.length, previous);
      var knownAfter = math.min(save.learnedSpells.length, spellCount);
      if (knownAfter < knownBefore) {
        for (var i = knownBefore - 1; i >= knownAfter; i--) {
          var spell = save.learnedSpells[i];
          save.log.error("You can't remember how to cast $spell!");
        }
      } else if (knownAfter > knownBefore) {
        for (var i = knownBefore; i < knownAfter; i++) {
          var spell = save.learnedSpells[i];
          save.log.message("You remember how to cast $spell!");
        }
      }

      // Let the player know if they have room to learn any new spells.
      var availableBefore = math.max(0, previous - save.learnedSpells.length);
      var availableAfter = math.max(0, spellCount - save.learnedSpells.length);
      if (availableBefore != availableAfter) {
        if (availableAfter == 1) {
          save.log.gain("You can learn 1 spell.");
        } else {
          save.log.gain("You can learn $availableAfter spells.");
        }
      }
    });

    // Keep other stats in bounds.
    health = health.clamp(0, maxHealth);
    _focus = _focus.clamp(0, intellect.maxFocus);
    _fury = _fury.clamp(0, strength.maxFury);
  }

  /// Called when the hero holds an item.
  ///
  /// This can be in response to picking it up, or equipping or using it
  /// straight from the ground.
  void pickUp(Game game, Item item) {
    // TODO: If the user repeatedly picks up and drops the same item, it gets
    // counted every time. Maybe want to put a (serialized) flag on items for
    // whether they have been picked up or not.
    lore.findItem(item);
    refreshProperties();
  }
}
