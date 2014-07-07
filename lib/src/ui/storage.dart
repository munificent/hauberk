library hauberk.ui.storage;

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

    var data = JSON.decode(storage);

    // TODO: Check version.

    for (final hero in data['heroes']) {
      var name = hero['name'];

      var inventory = new Inventory(Option.INVENTORY_CAPACITY);
      for (final itemData in hero['inventory']) {
        var item = _loadItem(itemData);
        inventory.tryAdd(item);
      }

      var equipment = new Equipment();
      for (final itemData in hero['equipment']) {
        var item = _loadItem(itemData);
        // TODO(bob): If there are multiple slots of the same type, this may
        // shuffle items around.
        equipment.equip(item);
      }

      var home = new Inventory(Option.HOME_CAPACITY);
      for (final itemData in hero['home']) {
        var item = _loadItem(itemData);
        home.tryAdd(item);
      }

      var crucible = new Inventory(Option.CRUCIBLE_CAPACITY);
      for (final itemData in hero['crucible']) {
        var item = _loadItem(itemData);
        crucible.tryAdd(item);
      }

      var experience = hero['experience'];

      var completedLevels = hero['completedLevels'];

      var heroClass;
      switch (hero['class']['name']) {
        case 'warrior': heroClass = _loadWarrior(hero['class']); break;
        default:
          throw 'Unknown hero class "${hero['class']['name']}".';
      }

      var heroSave = new HeroSave.load(name, heroClass, inventory, equipment,
          home, crucible, experience, completedLevels);
      heroes.add(heroSave);
    }
  }

  Item _loadItem(data) {
    var type = content.items[data['type']];
    // TODO(bob): Load powers.
    return new Item(type);
  }

  HeroClass _loadWarrior(Map data) {

    return new Warrior.load(
        fighting: data['fighting'],
        combat: data['combat'],
        toughness: data['toughness'],
        masteries: data['masteries']);
  }

  void save() {
    var heroData = [];
    for (var hero in heroes) {
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

      var heroClass = {};
      if (hero.heroClass is Warrior) {
        heroClass['name'] = 'warrior';
        _saveWarrior(hero.heroClass, heroClass);
      }

      heroData.add({
        'name': hero.name,
        'class': heroClass,
        'inventory': inventory,
        'equipment': equipment,
        'home': home,
        'crucible': crucible,
        'experience': hero.experienceCents,
        'completedLevels': hero.completedLevels
      });
    }

    // TODO: Version.
    var data = {
      'heroes': heroData
    };

    html.window.localStorage['heroes'] = JSON.encode(data);
    print('Saved.');
  }

  Map _saveItem(Item item) {
    // TODO: Save powers.
    return {
      'type': item.type.name
    };
  }

  void _saveWarrior(Warrior warrior, Map data) {
    data['fighting'] = warrior.fighting.count;
    data['combat'] = warrior.combat.count;
    data['toughness'] = warrior.toughness.count;

    var masteries = {};
    warrior.masteries.forEach((category, stat) {
      masteries[category] = stat.count;
    });

    data['masteries'] = masteries;
  }
}
