The UI is pretty big and is getting kind of ad hoc and messy. Some of that is
and was fine for exploring new UI ideas, but I'd like to start consolidating
and making it cleaner and more coherent.

In particular, I want to:

- Reuse more code across screens for similar UI elements like scrolling lists,
  item inspectors, etc.
- Have a consistent design language for kinds of screens and UI elements.
- Have a complete strategy for how the entire UI handles different screen sizes.

## UI code

Here are all of the Screen subclasses currently in the game, organized by
inheritance:

- AbilityDialog - selects ability to perform
- DirectionDialog - select direction, hovers over GameScreen
- ExperienceDialog - "store" to spend experience
- ItemDialog - modal for selecting an item to perform operation on
  - DropDialog
  - EquipDialog
  - PickUpDialog
  - PutDialog - put in home or crucible
  - SellDialog
  - TossDialog
  - UseDialog
- TownScreen - shop or home
- Popup - centered modal dialog
  - ConfirmPopup - yes/no for deleting hero
  - ExitPopup - shown when leaving dungeon
  - ForfeitPopup - confirm aborting dungeon
  - SelectDepthPopup
- GameOverScreen - shown when hero dies
- GameScreen
- HeroInfoDialog - base class for all "tabs" on hero info screen
  - HeroEquipmentDialog - hero info screen showing equipment
  - HeroItemLoreDialog - known items
  - HeroMonsterLoreDialog - known breeds
  - HeroResistancesDialog - equipment resistances
  - (eventually should add another screen for stats and their effects)
- LoadingDialog - shown while generating dungeon, should probably be Popup?
- MainMenuScreen
- NewHeroScreen
- SpellDialog - select and learn spells
- TargetDialog - pick target for action

There is also some shared code for rendering UI stuff:

- ItemInspector
- `renderItems()` - renders list of items in frame
- Panel - region of GameScreen
  - ItemPanel
  - LogPanel
  - SidebarPanel
  - StagePanel
- The Draw class

## Kinds of screens

Looking over that, I think there are roughly a few kinds of screens (and the
game is somewhat organized this way already):

### Game screen

- GameScreen

Of course, the main game screen is its own thing.

### Action object popups

There are a bunch of popups where the player wants the hero to perform an
action but the game needs some more information to complete it. They are:

#### Item operation popups

- ItemDialog - modal for selecting an item to perform operation on
  - DropDialog
  - EquipDialog
  - PickUpDialog
  - PutDialog - put in home or crucible
  - SellDialog
  - TossDialog
  - UseDialog

These let a user select an item from their equipment, inventory, or ground in
order to do something with it. The user has selected a verb and now they need
an object for it.

These overlap the corresponding item list panels to be minimally disruptive.
They also show the rest of the game since the player wants that context when
deciding what to do.

A floating inspector lets them drill in to get more information before making a
choice.

These are working pretty good. They use `renderItems()` to reuse code for
drawing a list of items. But I don't think there's a lot of reuse of input
handling.

The get and sell dialogs are here too. They use the same code as item dialogs,
but are semantically a little different in that buying and selling actually
actually actions that take game time.

#### AbilityDialog

- AbilityDialog - selects ability to perform

This is sort of like the item dialogs in that the hero is about to perform an
action and we need to know the "object" (ability or spell) to do.

It's visually similar: a drop-down list on the right side of the screen. But
since it's showing abilities/spells and not items, it has its own code. It
might be possible to reuse some code with ItemDialog, but I'm not sure if it's
worth it.

This one could really benefit from an inspector to show more details about the
ability or spell being performed.

### Shop and home screens

- TownScreen - shop or home

These are somewhat unique screens because the shop, crucible, and home are sort
of like "places" but aren't actually spatial. They show up as lists in the stage
area. They also need to make room to show items the hero has because many
operations here are transferring to and from.

This reuses `renderItems()`. It would be good to reuse some input handling code.

These and ItemDialogs both sometimes need the player to specify how many items
in a stack to do something with, and they have their own independent code for
that. It should be unified.

#### Action targeting

- DirectionDialog - select direction, hovers over GameScreen
- TargetDialog - pick target for action

Some actions need to know a direction or target square. These popups let the
user pick one. These almost feel like a modal part of GameScreen itself. They
are super frequently used, so they are designed to be minimally disruptive to
the UI and game flow.

### Info/lore screens

- HeroInfoDialog - base class for all "tabs" on hero info screen
  - HeroEquipmentDialog - hero info screen showing equipment
  - HeroItemLoreDialog - known items
  - HeroMonsterLoreDialog - known breeds
  - HeroResistancesDialog - equipment resistances
  - (eventually should add another screen for stats and their effects)

These are all full screen so that the player can see a lot of information. Most
of them have a scrolling table so you can select one thing (breed, item type)
and get more details on it.

The player doesn't *change* anything about the hero on these screens. They're
strictly read only. There also isn't much info here that's super urgent. They
might want details about their current equipment when pondering changing gear,
but that info is usually available from the inspectors on the various popups
where they change things. These screens just give them a better holistic view
of their entire equipment setup.



### Other popups and modal dialogs

There are a handful of random popup modal dialogs:

- Popup - centered modal dialog
  - ConfirmPopup - yes/no for deleting hero
  - ExitPopup - shown when leaving dungeon
  - ForfeitPopup - confirm aborting dungeon
  - SelectDepthPopup
- GameOverScreen - shown when hero dies
- LoadingDialog - shown while generating dungeon, should probably be Popup?
- MainMenuScreen
- NewHeroScreen

The simple popups share code already. The rest are unique enough to be fine.
Many of them are kind of half-baked because I'm focusing on the core gameplay
experience, but that's fine now.

### Acquisition screens

- ExperienceDialog - "store" to spend experience
- SpellDialog - select and learn spells

These are the two new ones that inspired this doc. Experience now works like a
currency where you spend it. Likewise, spells are gained by spending a number
of spell slots. So I need a UI where users can explore those parts of the hero
and make choices.

These are different from the lore screens because they aren't read-only. The
player is making irrevocable decisions. They're different from the town screens
because they aren't focused on items and don't interact with inventory or
equipment.

Some UX design questions:

- Are they grouped with the lore dialogs or not? Do you get to them by pressing
  Shift-A and then they show up as tabs there?

- Or do you get to the spell acquisition dialog from the spell selection popup?
  If so, how do you get to stat/skill acquisition?

- Is there a screen for skill lore separate from the screen for gaining skills?

My gut tells me that acquisition feels different from lore. And there's room
on the keyboard for another key to get to those screens, so I think I'll make
them another pair of tabbed screens for acquiring stats, skills, and spells.

## To dos

- Turn `renderItems()` into something more like a "widget" that renders and also
  has some shared input handling and help keys code.

- Add an ability inspector to AbilityDialog.

- Add another HeroInfoDialog for stats.

- Come up with a consistent look and feel for inspectors (item, ability, breed),
  and reuse code for them.

- Make the lore dialogs look like popups if the screen is bigger.

- Unify how count selection works for town screens and item dialogs.
