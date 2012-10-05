class MainMenuScreen extends Screen {
  final Content        content;
  final List<HeroSave> heroes;
  int selectedHero = 0;

  MainMenuScreen(Content content)
    : content = content,
      heroes = [] {
    _loadHeroes();
  }

  bool handleInput(Keyboard keyboard) {
    switch (keyboard.lastPressed) {
    case KeyCode.O:
      _changeSelection(-1);
      break;

    case KeyCode.PERIOD:
      _changeSelection(1);
      break;

    case KeyCode.L:
      if (selectedHero < heroes.length) {
        ui.push(new SelectLevelScreen(content, heroes[selectedHero],
            _saveHeroes));
      }
      break;

    case KeyCode.D:
      if (selectedHero < heroes.length) {
        ui.push(new ConfirmDialog(
            "Are you sure you want to delete this hero?", 'delete'));
      }
      break;

    case KeyCode.N:
      heroes.add(content.createHero());
      _saveHeroes();
      ui.push(new SelectLevelScreen(content, heroes[heroes.length - 1],
          _saveHeroes));
      break;
    }

    return true;
  }

  void activate(Screen screen, result) {
    if (screen is ConfirmDialog && result == 'delete') {
      heroes.removeRange(selectedHero, 1);
      if (selectedHero >= heroes.length) selectedHero--;
      _saveHeroes();
      dirty();
    }
  }

  void render(Terminal terminal) {
    if (!isTopScreen) return;

    terminal.clear();

    terminal.writeAt(0, 0,
        'Which hero shall you play?');
    terminal.writeAt(0, terminal.height - 1,
        '[L] Select a hero, [O]/[.] Change selection, [N] Create a new hero, [D] Delete hero',
        Color.GRAY);

    if (heroes.length == 0) {
      terminal.writeAt(0, 2, '(No heroes. Please create a new one.)',
          Color.GRAY);
    }

    for (var i = 0; i < heroes.length; i++) {
      var fore = Color.WHITE;
      var back = Color.BLACK;
      if (i == selectedHero) {
        fore = Color.BLACK;
        back = Color.YELLOW;
      }

      // TODO(bob): Show hero name and useful stats (level?).
      terminal.writeAt(0, 2 + i, "Hero", fore, back);
    }
  }

  void _changeSelection(int offset) {
    selectedHero = (selectedHero + offset) % heroes.length;
    dirty();
  }

  void _loadHeroes() {
    // TODO(bob): For debugging. If the query is "?clear", then ditch
    // saved heroes.
    if (html.window.location.search == '?clear') {
      _saveHeroes();
      return;
    }

    final storage = html.window.localStorage['heroes'];
    if (storage == null) return;

    final data = JSON.parse(storage);

    // TODO(bob): Check version.

    for (final hero in data['heroes']) {
      final inventory = new Inventory(Option.INVENTORY_CAPACITY);
      for (final itemData in hero['inventory']) {
        final item = _loadItem(itemData);
        inventory.tryAdd(item);
      }

      final equipment = new Equipment();
      for (final itemData in hero['equipment']) {
        final item = _loadItem(itemData);
        // TODO(bob): If there are multiple slots of the same type, this may
        // shuffle items around.
        equipment.equip(item);
      }

      final home = new Inventory(Option.HOME_CAPACITY);
      for (final itemData in hero['home']) {
        final item = _loadItem(itemData);
        home.tryAdd(item);
      }

      final crucible = new Inventory(Option.CRUCIBLE_CAPACITY);
      for (final itemData in hero['crucible']) {
        final item = _loadItem(itemData);
        crucible.tryAdd(item);
      }

      final skills = new SkillSet(content.skills);
      hero['skills'].forEach((name, level) {
        skills[content.skills[name]] = level;
      });

      final experience = hero['experience'];
      heroes.add(new HeroSave.load(inventory, equipment, home, crucible,
          skills, experience));
    }

    _saveHeroes();
  }

  Item _loadItem(data) {
    final type = content.items[data['type']];
    // TODO(bob): Load powers.
    return new Item(type, Vec.ZERO, null, null);
  }

  void _saveHeroes() {
    final heroData = [];
    for (final hero in heroes) {
      final inventory = [];
      for (final item in hero.inventory) {
        inventory.add(_saveItem(item));
      }

      final equipment = [];
      for (final item in hero.equipment) {
        equipment.add(_saveItem(item));
      }

      final home = [];
      for (final item in hero.home) {
        home.add(_saveItem(item));
      }

      final crucible = [];
      for (final item in hero.crucible) {
        crucible.add(_saveItem(item));
      }

      final skills = {};
      hero.skills.forEach((skill, level) {
        if (level != 0) skills[skill.name] = level;
      });

      heroData.add({
        'inventory': inventory,
        'equipment': equipment,
        'home': home,
        'crucible': crucible,
        'skills': skills,
        'experience': hero.experienceCents
      });
    }

    // TODO(bob): Version.
    final data = {
      'heroes': heroData
    };

    html.window.localStorage['heroes'] = JSON.stringify(data);
    print('Saved.');
  }

  _saveItem(Item item) {
    // TODO(bob): Save powers.
    return {
      'type': item.type.name
    };
  }
}
