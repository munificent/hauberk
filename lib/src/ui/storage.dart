import 'dart:convert';

import 'package:web/web.dart' as web;

import '../engine.dart';

/// The entrypoint for all persisted save data.
class Storage {
  final Content content;
  final List<HeroSave> heroes = <HeroSave>[];

  Storage(this.content) {
    _load();
  }

  /// Add new [hero] to storage.
  void add(HeroSave hero) {
    heroes.add(hero);
    save();
  }

  /// Delete [hero] from storage.
  void remove(HeroSave hero) {
    heroes.removeWhere((existing) => existing.name == hero.name);
    save();
  }

  /// Replace the existing save for the given hero (identified by name) with
  /// [hero].
  void replace(HeroSave hero) {
    var index = heroes.indexWhere((existing) => existing.name == hero.name);
    heroes[index] = hero;
    save();
  }

  void _load() {
    // TODO: For debugging. If the query is "?clear", then ditch saved heroes.
    if (web.window.location.search == '?clear') {
      save();
      return;
    }

    var storage = web.window.localStorage.getItem('heroes');
    if (storage == null) return;

    var data = json.decode(storage) as Map<String, dynamic>;

    // TODO: Check version.

    for (var hero in data['heroes'] as List<dynamic>) {
      try {
        var heroData = hero as Map<String, dynamic>;
        var name = heroData['name'] as String;
        var raceName = hero['race'] as String;
        var race = content.races.firstWhere((race) => race.name == raceName);

        HeroClass heroClass;
        if (heroData['class'] == null) {
          // TODO: Temp for characters before classes.
          heroClass = content.classes[0];
        } else {
          var name = heroData['class'] as String;
          heroClass = content.classes.firstWhere((c) => c.name == name);
        }

        var permadeath = heroData['death'] == 'permanent';

        var inventoryItems = _loadItems(heroData['inventory']);
        var inventory = Inventory(
          ItemLocation.inventory,
          Option.inventoryCapacity,
          inventoryItems,
        );

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
          ItemLocation.crucible,
          Option.crucibleCapacity,
          crucibleItems,
        );

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
        var stats = heroData['stats'] as Map<String, dynamic>;

        var heroSave = HeroSave(
          name,
          race,
          heroClass,
          permadeath,
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
          maxDepth,
          strength: stats['strength'] as int,
          agility: stats['agility'] as int,
          vitality: stats['vitality'] as int,
          intellect: stats['intellect'] as int,
          will: stats['will'] as int,
        );
        heroes.add(heroSave);
      } catch (error, trace) {
        print("Could not load hero. Data:");
        print(json.encode(hero));
        print("Error:\n$error\n$trace");
      }
    }
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

    var prefix = _loadAffix(data['prefix']);
    var suffix = _loadAffix(data['suffix']);
    var intrinsicAffix = _loadAffix(data['intrinsic']);

    return Item(
      type,
      count,
      prefix: prefix,
      suffix: suffix,
      intrinsicAffix: intrinsicAffix,
    );
  }

  Affix? _loadAffix(dynamic data) {
    return switch (data) {
      {'id': String id, 'parameter': int parameter} => Affix(
        content.findAffix(id)!,
        parameter,
      ),
      _ => null,
    };
  }

  Log _loadLog(Object? data) {
    var log = Log();
    if (data is List<dynamic>) {
      for (var messageData in data) {
        var messageMap = messageData as Map<String, dynamic>;
        var type = LogType.values.firstWhere(
          (type) => type.name == messageMap['type'] as String,
        );
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
    var foundAffixes = <AffixType, int>{};
    var createdArtifacts = <ItemType>{};
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
          createdArtifacts.add(content.tryFindItem(name as String)!);
        }
      }
    }

    return Lore.from(
      seenBreeds,
      slain,
      foundItems,
      foundAffixes,
      createdArtifacts,
      usedItems,
    );
  }

  void save() {
    // TODO: Version.
    var data = {
      'heroes': [
        for (var hero in heroes)
          {
            'name': hero.name,
            'race': hero.race.name,
            'stats': {
              'strength': hero.strength.baseValue,
              'agility': hero.agility.baseValue,
              'vitality': hero.vitality.baseValue,
              'intellect': hero.intellect.baseValue,
              'will': hero.will.baseValue,
            },
            'class': hero.heroClass.name,
            'death': hero.permadeath ? 'permanent' : 'dungeon',
            'inventory': _saveItems(hero.inventory),
            'equipment': _saveItems(hero.equipment),
            'home': _saveItems(hero.home),
            'crucible': _saveItems(hero.crucible),
            'shops': {
              for (var MapEntry(key: shop, value: items) in hero.shops.entries)
                shop.name: _saveItems(items),
            },
            'experience': hero.experience,
            'skills': {
              for (var skill in hero.skills.discovered)
                skill.name: {
                  'level': hero.skills.level(skill),
                  'points': hero.skills.points(skill),
                },
            },
            'log': _saveLog(hero.log),
            'lore': _saveLore(hero.lore),
            'gold': hero.gold,
            'maxDepth': hero.maxDepth,
          },
      ],
    };

    var encoded = json.encode(data);
    web.window.localStorage.setItem('heroes', encoded);
    print('Saved.');
  }

  List<dynamic> _saveLog(Log log) {
    return [
      for (var message in log.messages)
        <String, dynamic>{
          'type': message.type.name,
          'text': message.text,
          'count': message.count,
        },
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
    }

    for (var itemType in content.items) {
      if (itemType.isArtifact && lore.createdArtifact(itemType)) {
        createdArtifacts.add(itemType.name);
      }
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

  List<dynamic> _saveItems(Iterable<Item> items) {
    return [
      for (var item in items)
        {
          'type': item.type.name,
          'count': item.count,
          if (item.prefix case var affix?) 'prefix': _saveAffix(affix),
          if (item.suffix case var affix?) 'suffix': _saveAffix(affix),
          if (item.intrinsicAffix case var affix?)
            'intrinsic': _saveAffix(affix),
        },
    ];
  }

  Map<String, dynamic> _saveAffix(Affix affix) {
    return {'id': affix.type.id, 'parameter': affix.parameter};
  }
}
