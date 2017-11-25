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

      var skillSet = new SkillSet();
      var skills = hero['skills'];
      if (skills != null) {
        for (var name in skills.keys) {
          skillSet[content.findSkill(name)] = skills[name];
        }
      }

      var gold = hero['gold'];
      var maxDepth = hero['maxDepth'] ?? 0;

      var heroSave = new HeroSave.load(name, inventory, equipment, home,
          crucible, experience, skillPoints, skillSet, gold, maxDepth);
      heroes.add(heroSave);
    }
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

      var skills = {};
      hero.skills.forEach((skill, level) {
        skills[skill.name] = level;
      });

      heroData.add({
        'name': hero.name,
        'inventory': inventory,
        'equipment': equipment,
        'home': home,
        'crucible': crucible,
        'experience': hero.experienceCents,
        'skillPoints': hero.skillPoints,
        'skills': skills,
        'gold': hero.gold,
        'maxDepth': hero.maxDepth
      });
    }

    // TODO: Version.
    var data = {'heroes': heroData};

    html.window.localStorage['heroes'] = JSON.encode(data);
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
