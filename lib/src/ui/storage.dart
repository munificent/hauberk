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

    var data = json.decode(storage) as Map<String, dynamic>;

    // TODO: Check version.

    for (var hero in data['heroes'] as List<dynamic>) {
      try {
        var heroData = hero as Map<String, dynamic>;
        var name = heroData['name'] as String;
        var race = _loadRace(hero['race'] as Map<String, dynamic>);

        HeroClass heroClass;
        if (heroData['class'] == null) {
          // TODO: Temp for characters before classes.
          heroClass = content.classes[0];
        } else {
          var name = heroData['class'] as String;
          heroClass = content.classes.firstWhere((c) => c.name == name);
        }

        var inventoryItems = _loadItems(heroData['inventory']);
        var inventory = Inventory(
            ItemLocation.inventory, Option.inventoryCapacity, inventoryItems);

        var equipment = Equipment();
        for (var item in _loadItems(heroData['equipment'])) {
          // TODO: If there are multiple slots of the same type, this may
          // shuffle items around.
          equipment.equip(item);
        }

        var homeItems = _loadItems(heroData['home']);
        var home = Inventory(ItemLocation.home, Option.homeCapacity, homeItems);

        var crucibleItems = _loadItems(heroData['crucible']);
        var crucible = Inventory(
            ItemLocation.crucible, Option.crucibleCapacity, crucibleItems);

        // TODO: What if shops are added or changed?
        var shops = <Shop, Inventory>{};
        if (heroData.containsKey('shops')) {
          var shopsData = heroData['shops'] as Map<String, dynamic>;
          content.shops.forEach((name, shop) {
            var shopData = shopsData[name] as List<dynamic>?;
            if (shopData != null) {
              shops[shop] = shop.load(_loadItems(shopData));
            } else {
              print("No data for $name, so regenerating.");
              shops[shop] = shop.create();
            }
          });
        }

        // Clean up legacy heroes before item stacks.
        // TODO: Remove this once we don't need to worry about it anymore.
        inventory.countChanged();
        home.countChanged();
        crucible.countChanged();

        // Defaults are to support legacy saves.

        var experience = heroData['experience'] as int;

        var levels = <Skill, int>{};
        var points = <Skill, int>{};
        var skills = heroData['skills'] as Map<String, dynamic>?;
        if (skills != null) {
          for (var name in skills.keys) {
            var skill = content.findSkill(name);
            // Handle old storage without points.
            // TODO: Remove when no longer needed.
            var skillData = skills[name];
            if (skillData is int) {
              levels[skill] = skillData;
              points[skill] = 0;
            } else {
              skillData as Map<String, dynamic>;
              levels[skill] = skillData['level'] as int;
              points[skill] = skillData['points'] as int;
            }
          }
        }

        var skillSet = SkillSet.from(levels, points);

        var log = _loadLog(heroData['log']);
        var lore = _loadLore(heroData['lore'] as Map<String, dynamic>);

        var gold = heroData['gold'] as int;
        var maxDepth = heroData['maxDepth'] as int? ?? 0;

        var heroSave = HeroSave.load(
            name,
            race,
            heroClass,
            inventory,
            equipment,
            home,
            crucible,
            shops,
            experience,
            skillSet,
            log,
            lore,
            gold,
            maxDepth);
        heroes.add(heroSave);
      } catch (error, trace) {
        print("Could not load hero. Data:");
        print(json.encode(hero));
        print("Error:\n$error\n$trace");
      }
    }
  }

  RaceStats _loadRace(Map<String, dynamic>? data) {
    // TODO: Temp to handle heros from before races.
    if (data == null) {
      return content.races.elementAt(4).rollStats();
    }

    var name = data['name'] as String;
    var race = content.races.firstWhere((race) => race.name == name);

    var statData = data['stats'] as Map<String, dynamic>;
    var stats = <Stat, int>{};

    for (var stat in Stat.all) {
      stats[stat] = statData[stat.name] as int;
    }

    // TODO: 1234 is temp for characters without seed.
    var seed = data['seed'] as int? ?? 1234;

    return RaceStats(race, stats, seed);
  }

  List<Item> _loadItems(List<dynamic> data) {
    var items = <Item>[];
    for (var itemData in data) {
      var item = _loadItem(itemData as Map<String, dynamic>);
      if (item != null) items.add(item);
    }

    return items;
  }

  Item? _loadItem(Map<String, dynamic> data) {
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

    var affixes = <Affix>[];
    if (data.containsKey('affixes')) {
      var affixesData = data['affixes'] as List<dynamic>;

      for (var affixData in affixesData) {
        affixes.add(content.findAffix(affixData as String)!);
      }
    }

    return Item(type, count, affixes);
  }

  Log _loadLog(Object? data) {
    var log = Log();
    if (data is List<dynamic>) {
      for (var messageData in data) {
        var messageMap = messageData as Map<String, dynamic>;
        var type = LogType.values
            .firstWhere((type) => type.name == messageMap['type'] as String);
        var text = messageMap['text'] as String;
        var count = messageMap['count'] as int;
        log.messages.add(Message(type, text, count));
      }
    }

    return log;
  }

  Lore _loadLore(Map<String, dynamic>? data) {
    var seenBreeds = <Breed, int>{};
    var slain = <Breed, int>{};
    var foundItems = <ItemType, int>{};
    var foundAffixes = <Affix, int>{};
    var createdArtifacts = <Affix>{};
    var usedItems = <ItemType, int>{};

    // TODO: Older saves before lore.
    if (data != null) {
      var seenMap = data['seen'] as Map<String, dynamic>?;
      if (seenMap != null) {
        seenMap.forEach((breedName, dynamic count) {
          var breed = content.tryFindBreed(breedName);
          if (breed != null) seenBreeds[breed] = count as int;
        });
      }

      var slainMap = data['slain'] as Map<String, dynamic>?;
      if (slainMap != null) {
        slainMap.forEach((breedName, dynamic count) {
          var breed = content.tryFindBreed(breedName);
          if (breed != null) slain[breed] = count as int;
        });
      }

      var foundItemMap = data['foundItems'] as Map<String, dynamic>?;
      if (foundItemMap != null) {
        foundItemMap.forEach((itemName, dynamic count) {
          var itemType = content.tryFindItem(itemName);
          if (itemType != null) foundItems[itemType] = count as int;
        });
      }

      var foundAffixMap = data['foundAffixes'] as Map<String, dynamic>?;
      if (foundAffixMap != null) {
        foundAffixMap.forEach((affixName, dynamic count) {
          var affix = content.findAffix(affixName);
          if (affix != null) foundAffixes[affix] = count as int;
        });
      }

      var usedItemMap = data['usedItems'] as Map<String, dynamic>?;
      if (usedItemMap != null) {
        usedItemMap.forEach((itemName, dynamic count) {
          var itemType = content.tryFindItem(itemName);
          if (itemType != null) usedItems[itemType] = count as int;
        });
      }

      var createdArtifactsList = data['createdArtifacts'] as List<dynamic>?;
      if (createdArtifactsList != null) {
        for (var name in createdArtifactsList) {
          createdArtifacts.add(content.findAffix(name as String)!);
        }
      }
    }

    return Lore.from(seenBreeds, slain, foundItems, foundAffixes,
        createdArtifacts, usedItems);
  }

  void save() {
    var heroData = <dynamic>[];
    for (var hero in heroes) {
      var raceStats = <String, dynamic>{};
      for (var stat in Stat.all) {
        raceStats[stat.name] = hero.race.max(stat);
      }

      var race = {
        'name': hero.race.name,
        'seed': hero.race.seed,
        'stats': raceStats
      };

      var inventory = _saveItems(hero.inventory);
      var equipment = _saveItems(hero.equipment);
      var home = _saveItems(hero.home);
      var crucible = _saveItems(hero.crucible);

      var shops = <String, dynamic>{};
      hero.shops.forEach((shop, inventory) {
        shops[shop.name] = _saveItems(inventory);
      });

      var skills = <String, dynamic>{};
      for (var skill in hero.skills.discovered) {
        skills[skill.name] = {
          'level': hero.skills.level(skill),
          'points': hero.skills.points(skill)
        };
      }

      heroData.add({
        'name': hero.name,
        'race': race,
        'class': hero.heroClass.name,
        'inventory': inventory,
        'equipment': equipment,
        'home': home,
        'crucible': crucible,
        'shops': shops,
        'experience': hero.experience,
        'skills': skills,
        'log': _saveLog(hero.log),
        'lore': _saveLore(hero.lore),
        'gold': hero.gold,
        'maxDepth': hero.maxDepth
      });
    }

    // TODO: Version.
    var data = {'heroes': heroData};

    html.window.localStorage['heroes'] = json.encode(data);
    print('Saved.');
  }

  List<dynamic> _saveLog(Log log) {
    return [
      for (var message in log.messages)
        <String, dynamic>{
          'type': message.type.name,
          'text': message.text,
          'count': message.count
        }
    ];
  }

  Map<String, dynamic> _saveLore(Lore lore) {
    var seen = <String, dynamic>{};
    var slain = <String, dynamic>{};
    var foundItems = <String, dynamic>{};
    var foundAffixes = <String, dynamic>{};
    var usedItems = <String, dynamic>{};
    var createdArtifacts = <dynamic>[];

    for (var breed in content.breeds) {
      var count = lore.seenBreed(breed);
      if (count != 0) seen[breed.name] = count;

      count = lore.slain(breed);
      if (count != 0) slain[breed.name] = count;
    }

    for (var itemType in content.items) {
      var found = lore.foundItems(itemType);
      if (found != 0) foundItems[itemType.name] = found;

      var used = lore.usedItems(itemType);
      if (used != 0) usedItems[itemType.name] = used;
    }

    for (var affix in content.affixes) {
      var found = lore.foundAffixes(affix);
      if (found != 0) foundAffixes[affix.id] = found;

      if (lore.createdArtifact(affix)) createdArtifacts.add(affix.id);
    }

    return {
      'seen': seen,
      'slain': slain,
      'foundItems': foundItems,
      'foundAffixes': foundAffixes,
      'usedItems': usedItems,
      'createdArtifacts': createdArtifacts,
    };
  }

  List _saveItems(Iterable<Item> items) {
    return <dynamic>[for (var item in items) _saveItem(item)];
  }

  Map<String, dynamic> _saveItem(Item item) {
    return <String, dynamic>{
      'type': item.type.name,
      'count': item.count,
      if (item.affixes.isNotEmpty)
        'affixes': [for (var affix in item.affixes) affix.id]
    };
  }
}
