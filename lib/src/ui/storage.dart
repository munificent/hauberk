import 'dart:convert';
import 'dart:html' as html;

import '../engine.dart';

/// The entrypoint for all persisted save data.
class Storage {
  final Content content;
  final List<HeroSave> heroes = <HeroSave>[];

  Storage(this.content) {
    _load();
  }

  void _load() {
    // TODO: For debugging. If the query is "?clear", then ditch saved heroes.
    if (html.window.location.search == '?clear') {
      save();
      return;
    }

    var storage = html.window.localStorage['heroes'];
    if (storage == null) return;

    var data = json.decode(storage);

    // TODO: Check version.

    for (var hero in data['heroes']) {
      try {
        var name = hero['name'] as String;
        var race = _loadRace(hero['race'] as Map<String, dynamic>);

        HeroClass heroClass;
        if (hero['class'] == null) {
          // TODO: Temp for characters before classes.
          heroClass = content.classes[0];
        } else {
          var name = hero['class'] as String;
          heroClass = content.classes.firstWhere((c) => c.name == name);
        }

        var items = <Item>[];
        for (var itemData in hero['inventory']) {
          var item = _loadItem(itemData as Map<String, dynamic>);
          if (item != null) items.add(item);
        }
        var inventory = Inventory(Option.inventoryCapacity, items);

        var equipment = Equipment();
        for (var itemData in hero['equipment']) {
          var item = _loadItem(itemData as Map<String, dynamic>);
          // TODO: If there are multiple slots of the same type, this may
          // shuffle items around.
          if (item != null) equipment.equip(item);
        }

        items = [];
        for (var itemData in hero['home']) {
          var item = _loadItem(itemData as Map<String, dynamic>);
          if (item != null) items.add(item);
        }
        var home = Inventory(Option.homeCapacity, items);

        items = [];
        for (var itemData in hero['crucible']) {
          var item = _loadItem(itemData as Map<String, dynamic>);
          if (item != null) items.add(item);
        }
        var crucible = Inventory(Option.crucibleCapacity, items);

        // Clean up legacy heroes before item stacks.
        // TODO: Remove this once we don't need to worry about it anymore.
        inventory.countChanged();
        home.countChanged();
        crucible.countChanged();

        // Defaults are to support legacy saves.

        var experience = hero['experience'] as int;
        var skillPoints = hero['skillPoints'] as int ?? 0;

        var skillMap = <Skill, int>{};
        var skills = hero['skills'] as Map<String, dynamic>;
        if (skills != null) {
          for (var name in skills.keys) {
            skillMap[content.findSkill(name)] = skills[name] as int;
          }
        }

        var skillSet = SkillSet(skillMap);

        var lore = _loadLore(hero['lore'] as Map<String, dynamic>);

        var gold = hero['gold'] as int;
        var maxDepth = hero['maxDepth'] as int ?? 0;

        var heroSave = HeroSave.load(
            name,
            race,
            heroClass,
            inventory,
            equipment,
            home,
            crucible,
            experience,
            skillPoints,
            skillSet,
            lore,
            gold,
            maxDepth);
        heroes.add(heroSave);
      } catch (error) {
        print("Could not load hero. Data:");
        print(hero);
        print("Error:\n$error");
      }
    }
  }

  RaceStats _loadRace(Map<String, dynamic> data) {
    // TODO: Temp to handle heros from before races.
    if (data == null) {
      return content.races.elementAt(4).rollStats();
    }

    var name = data['name'] as String;
    var race = content.races.firstWhere((race) => race.name == name);

    var statData = data['stats'];
    var stats = <Stat, int>{};

    for (var stat in Stat.all) {
      stats[stat] = statData[stat.name] as int;
    }

    // TODO: 1234 is temp for characters without seed.
    var seed = data['seed'] as int ?? 1234;

    return RaceStats(race, stats, seed);
  }

  Item _loadItem(Map<String, dynamic> data) {
    var type = content.tryFindItem(data['type'] as String);
    if (type == null) {
      print("Couldn't find item type \"${data['type']}\", discarding item.");
      return null;
    }

    var count = 1;
    // Existing save files don't store count, so allow it to be missing.
    if (data.containsKey('count')) {
      count = data['count'] as int;
    }

    Affix prefix;
    if (data.containsKey('prefix')) {
      // TODO: Older save from back when affixes had types.
      if (data['prefix'] is Map) {
        prefix = content.findAffix(data['prefix']['name'] as String);
      } else {
        prefix = content.findAffix(data['prefix'] as String);
      }
    }

    Affix suffix;
    if (data.containsKey('suffix')) {
      // TODO: Older save from back when affixes had types.
      if (data['suffix'] is Map) {
        suffix = content.findAffix(data['suffix']['name'] as String);
      } else {
        suffix = content.findAffix(data['suffix'] as String);
      }
    }

    return Item(type, count, prefix, suffix);
  }

  Lore _loadLore(Map<String, dynamic> data) {
    var slain = <Breed, int>{};
    var seen = <Breed, int>{};
    var kills = <String, int>{};

    // TODO: Older saves before lore.
    if (data != null) {
      var slainMap = data['slain'] as Map<String, dynamic>;
      if (slainMap != null) {
        slainMap.forEach((breedName, count) {
          var breed = content.tryFindBreed(breedName);
          if (breed != null) slain[breed] = count as int;
        });
      }

      var seenMap = data['seen'] as Map<String, dynamic>;
      if (seenMap != null) {
        seenMap.forEach((breedName, count) {
          var breed = content.tryFindBreed(breedName);
          if (breed != null) seen[breed] = count as int;
        });
      }

      var killMap = data['weapon_kills'] as Map<String, dynamic>;
      if (killMap != null) {
        killMap.forEach((type, count) {
          kills[type] = count as int;
        });
      }
    }

    return Lore.from(seen, slain, kills);
  }

  void save() {
    var heroData = [];
    for (var hero in heroes) {
      var raceStats = {};
      for (var stat in Stat.all) {
        raceStats[stat.name] = hero.race.max(stat);
      }
      var race = {'name': hero.race.name, 'stats': raceStats};

      var inventory = [];
      for (var item in hero.inventory) {
        inventory.add(_saveItem(item));
      }

      var equipment = [];
      for (var item in hero.equipment) {
        equipment.add(_saveItem(item));
      }

      var home = [];
      for (var item in hero.home) {
        home.add(_saveItem(item));
      }

      var crucible = [];
      for (var item in hero.crucible) {
        crucible.add(_saveItem(item));
      }

      var skills = {};
      for (var skill in hero.skills.discovered) {
        skills[skill.name] = hero.skills[skill];
      }

      var seen = {};
      var slain = {};
      var lore = {
        'seen': seen,
        'slain': slain,
        'weapon_kills': hero.lore.killsByWeapon
      };
      for (var breed in content.breeds) {
        var count = hero.lore.seen(breed);
        if (count != 0) seen[breed.name] = count;

        count = hero.lore.slain(breed);
        if (count != 0) slain[breed.name] = count;
      }

      heroData.add({
        'name': hero.name,
        'race': race,
        'class': hero.heroClass.name,
        'inventory': inventory,
        'equipment': equipment,
        'home': home,
        'crucible': crucible,
        'experience': hero.experienceCents,
        'skillPoints': hero.skillPoints,
        'skills': skills,
        'lore': lore,
        'gold': hero.gold,
        'maxDepth': hero.maxDepth
      });
    }

    // TODO: Version.
    var data = {'heroes': heroData};

    html.window.localStorage['heroes'] = json.encode(data);
    print('Saved.');
  }

  Map _saveItem(Item item) {
    var itemData = <String, dynamic>{
      'type': item.type.name,
      'count': item.count
    };

    if (item.prefix != null) {
      itemData['prefix'] = item.prefix.name;
    }

    if (item.suffix != null) {
      itemData['suffix'] = item.suffix.name;
    }

    return itemData;
  }
}
