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

    for (final hero in data['heroes']) {
      var name = hero['name'];
      var race = _loadRace(hero['race']);

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
        var item = _loadItem(itemData);
        if (item != null) items.add(item);
      }
      var inventory = new Inventory(Option.inventoryCapacity, items);

      var equipment = new Equipment();
      for (var itemData in hero['equipment']) {
        var item = _loadItem(itemData);
        // TODO: If there are multiple slots of the same type, this may
        // shuffle items around.
        if (item != null) equipment.equip(item);
      }

      items = [];
      for (var itemData in hero['home']) {
        var item = _loadItem(itemData);
        if (item != null) items.add(item);
      }
      var home = new Inventory(Option.homeCapacity, items);

      items = [];
      for (var itemData in hero['crucible']) {
        var item = _loadItem(itemData);
        if (item != null) items.add(item);
      }
      var crucible = new Inventory(Option.crucibleCapacity, items);

      // Clean up legacy heroes before item stacks.
      // TODO: Remove this once we don't need to worry about it anymore.
      inventory.countChanged();
      home.countChanged();
      crucible.countChanged();

      // Defaults are to support legacy saves.

      var experience = hero['experience'];
      var skillPoints = hero['skillPoints'] ?? 0;

      var skillMap = <Skill, int>{};
      var skills = hero['skills'];
      if (skills != null) {
        for (var name in skills.keys) {
          skillMap[content.findSkill(name)] = skills[name];
        }
      }

      var skillSet = new SkillSet(skillMap);

      var lore = _loadLore(hero['lore']);

      var gold = hero['gold'];
      var maxDepth = hero['maxDepth'] ?? 0;

      var heroSave = new HeroSave.load(
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
    }
  }

  RaceStats _loadRace(Map data) {
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
    var seed = data['seed'] ?? 1234;

    return new RaceStats(race, stats, seed);
  }

  Item _loadItem(Map data) {
    var type = content.tryFindItem(data['type']);
    if (type == null) {
      print("Couldn't find item type \"${data['type']}\", discarding item.");
      return null;
    }

    var count = 1;
    // Existing save files don't store count, so allow it to be missing.
    if (data.containsKey('count')) {
      count = data['count'];
    }

    Affix prefix;
    if (data.containsKey('prefix')) {
      // TODO: Older save from back when affixes had types.
      if (data['prefix'] is Map) {
        prefix = content.findAffix(data['prefix']['name']);
      } else {
        prefix = content.findAffix(data['prefix']);
      }
    }

    Affix suffix;
    if (data.containsKey('suffix')) {
      // TODO: Older save from back when affixes had types.
      if (data['suffix'] is Map) {
        suffix = content.findAffix(data['suffix']['name']);
      } else {
        suffix = content.findAffix(data['suffix']);
      }
    }

    return new Item(type, count, prefix, suffix);
  }

  Lore _loadLore(Map data) {
    var slain = <Breed, int>{};
    var seen = <Breed, int>{};
    var kills = <String, int>{};

    // TODO: Older saves before lore.
    if (data != null) {
      var slainMap = data['slain'];
      if (slainMap != null) {
        (slainMap as Map).forEach((breedName, count) {
          var breed = content.tryFindBreed(breedName);
          if (breed != null) slain[breed] = count;
        });
      }

      var seenMap = data['seen'];
      if (seenMap != null) {
        (seenMap as Map).forEach((breedName, count) {
          var breed = content.tryFindBreed(breedName);
          if (breed != null) seen[breed] = count;
        });
      }

      var killMap = data['weapon_kills'];
      if (killMap != null) {
        (killMap as Map).forEach((type, count) {
          kills[type] = count;
        });
      }
    }

    return new Lore.from(seen, slain, kills);
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
