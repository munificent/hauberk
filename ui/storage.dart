part of ui;

/// The entrypoint for all persisted save data.
class Storage {
  final Content content;
  final List<HeroSave> heroes = <HeroSave>[];

  Storage(this.content) {
    _load();
  }

  void _load() {
    // TODO(bob): For debugging. If the query is "?clear", then ditch
    // saved heroes.
    if (html.window.location.search == '?clear') {
      save();
      return;
    }

    var storage = html.window.localStorage['heroes'];
    if (storage == null) return;

    var data = json.parse(storage);

    // TODO(bob): Check version.

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

      var skills = new SkillSet(content.skills);
      hero['skills'].forEach((name, level) {
        skills[content.skills[name]] = level;
      });

      var experience = hero['experience'];

      var completedLevels = hero['completedLevels'];

      heroes.add(new HeroSave.load(name, inventory, equipment, home, crucible,
          skills, experience, completedLevels));
    }
  }

  Item _loadItem(data) {
    var type = content.items[data['type']];
    // TODO(bob): Load powers.
    return new Item(type);
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
        if (level != 0) skills[skill.name] = level;
      });

      heroData.add({
        'name': hero.name,
        'inventory': inventory,
        'equipment': equipment,
        'home': home,
        'crucible': crucible,
        'skills': skills,
        'experience': hero.experienceCents,
        'completedLevels': hero.completedLevels
      });
    }

    // TODO(bob): Version.
    var data = {
      'heroes': heroData
    };

    html.window.localStorage['heroes'] = json.stringify(data);
    print('Saved.');
  }

  _saveItem(Item item) {
    // TODO(bob): Save powers.
    return {
      'type': item.type.name
    };
  }
}
