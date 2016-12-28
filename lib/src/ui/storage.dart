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

      var inventory = new Inventory(Option.inventoryCapacity);
      for (var itemData in hero['inventory']) {
        var item = _loadItem(itemData);
        if (item != null) inventory.tryAdd(item);
      }

      var equipment = new Equipment();
      for (var itemData in hero['equipment']) {
        var item = _loadItem(itemData);
        // TODO(bob): If there are multiple slots of the same type, this may
        // shuffle items around.
        if (item != null) equipment.equip(item);
      }

      var home = new Inventory(Option.homeCapacity);
      for (var itemData in hero['home']) {
        var item = _loadItem(itemData);
        if (item != null) home.tryAdd(item);
      }

      var crucible = new Inventory(Option.crucibleCapacity);
      for (var itemData in hero['crucible']) {
        var item = _loadItem(itemData);
        if (item != null) crucible.tryAdd(item);
      }

      var experience = hero['experience'];

      var gold = hero['gold'];

      var maxDepth = hero['maxDepth'];
      // Older saves don't have this.
      if (maxDepth == null) maxDepth = 0;

      var heroClass;
      switch (hero['class']['name']) {
        case 'warrior': heroClass = _loadWarrior(hero['class']); break;
        default:
          throw 'Unknown hero class "${hero['class']['name']}".';
      }

      var heroSave = new HeroSave.load(name, heroClass, inventory, equipment,
          home, crucible, experience, gold, maxDepth);
      heroes.add(heroSave);
    }
  }

  Item _loadItem(Map data) {
    var type = content.findItem(data['type']);
    if (type == null) {
      print("Couldn't find item type '${data['type']}, discarding item.");
      return null;
    }

    var prefix;
    if (data.containsKey('prefix')) {
      prefix = _loadAffix(data['prefix']);
    }

    var suffix;
    if (data.containsKey('suffix')) {
      suffix = _loadAffix(data['suffix']);
    }

    return new Item(type, prefix, suffix);
  }

  HeroClass _loadWarrior(Map data) {
    return new Warrior.load(
        fighting: data['fighting'],
        combat: data['combat'],
        toughness: data['toughness'],
        masteries: data['masteries'] as Map<String, int>);
  }

  Affix _loadAffix(Map data) {
    var attack;

    var attackData = data['attack'];
    if (attackData != null) {
      attack = new Attack("", 0);
      if (attackData['element'] != null) {
        attack = attack.brand(Element.fromName(attackData['element']));
      }

      if (attackData['damageBonus'] != null) {
        attack = attack.addDamage(attackData['damageBonus']);
      }

      if (attackData['strikeBonus'] != null) {
        attack = attack.addStrike(attackData['strikeBonus']);
      }

      if (attackData['damageScale'] != null) {
        attack = attack.multiplyDamage(attackData['damageScale']);
      }
    }

    return new Affix(data['name'], attack);
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
        'gold': hero.gold,
        'maxDepth': hero.maxDepth
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
    var itemData = <String, dynamic>{
      'type': item.type.name
    };

    if (item.prefix != null) {
      itemData['prefix'] = _saveAffix(item.prefix);
    }

    if (item.suffix != null) {
      itemData['suffix'] = _saveAffix(item.suffix);
    }

    return itemData;
  }

  Map _saveAffix(Affix affix) {
    var affixData = <String, dynamic>{
      'name': affix.name
    };

    if (affix.attack != null) {
      var attackData = {};
      affixData['attack'] = attackData;

      if (affix.attack.element != Element.none) {
        attackData['element'] = affix.attack.element.name;
      }

      if (affix.attack.damageBonus != 0) {
        attackData['damageBonus'] = affix.attack.damageBonus;
      }

      if (affix.attack.strikeBonus != 0) {
        attackData['strikeBonus'] = affix.attack.strikeBonus;
      }

      if (affix.attack.damageScale != 1.0) {
        attackData['damageScale'] = affix.attack.damageScale;
      }
    }

    return affixData;
  }

  void _saveWarrior(Warrior warrior, Map data) {
    data['fighting'] = warrior.fighting.count;
    data['combat'] = warrior.combat.count;
    data['toughness'] = warrior.toughness.count;

    var masteries = {};
    warrior.masteries.forEach((name, stat) {
      masteries[name] = stat.count;
    });

    data['masteries'] = masteries;
  }
}
