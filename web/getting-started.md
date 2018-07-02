# Getting Started

**TODO: This is all horrendously out of date.**

Welcome! I see you have an adventurous spirit! Not because you wish to venture into dungeons filled with beasts and untolds horrors, but because you have the fortitude to try out a game while it's still under development. Well, some of the former too.

A caution for the unwary: **The game is not done, or balanced, or complete, or bug-free.** It may destroy your savefiles or steal your boyfriend!

## Input

Hauberk is played using your keyboard, the fixie of input devices. A lot of input is directional. Arrow keys work for that, but don't support diagonal moves. Instead, you're better off hitting num lock and using the numpad on your keyboard if you have one:

    .---.---.---.          .---.---.---.
    | 7 | 8 | 9 |          | \ | ^ | / |
    |---+---+---|          |---+---+---|
    | 4 | 5 | 6 | maps to: |<- |   | ->|
    |---+---+---|          |---+---+---|
    | 7 | 8 | 9 |          | / | v | \ |
    '---'---'---'          '---'---'---'

If you don't have a numpad, but do have a US layout keyboard, you can also use:

    .---.---.---.          .---.---.---.
    | I | O | P |          | \ | ^ | / |
    '---+---+---+          '---+---+---+
     | K | L | ; | maps to: |<- |   | ->|
     '---+---+---+          '---+---+---+
      | , | . | / |          | / | v | \ |
      '---'---'---'          '---'---'---'

The `5` and `L` buttons in the middle are "stand". They're also used like an "OK" button to accept a selection on menu screens. `Escape` is used to go back in menu screens and exit dialogs.

(Note that all keys are shown uppercase here but are typed lower case. `L` means a lowercase "l". An uppercase one will be `Shift-L`.)

*At some point, I plan to add support for user-defined keybindings, but they aren't there yet.*

## A Hero Awakens

To play, you need avatar in the game world to live (and die!) vicariously through. On the Main Menu Screen, type `N` to create a new hero (or heroine, the game is gender-neutral). Enter a name, or use the default suggested one and hit `Enter`.

*There isn't much to specify at character creation time right now, but eventually you'll pick a class, race, pet peeves, favorite sandwich, etc. Currently, warrior is the only class.*

Your hero is saved in your browser's [local storage][]. This means you can return to the game later and your hero will still be there. If you switch browsers, though, your heroes won't be in the new browser. Heroes are saved every time you leave a level, or exit your home.

[local storage]: https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Storage#localStorage

The game is *not* saved while you're in the middle of a level! If you close your browser in the middle of playing because your boss walked in, your progress in the level will be lost. That's what you get for slacking off at work.

*Because the game is still in active development, new releases may not be savefile compatible with previous ones. Your heroes may get deleted if they don't work with the latest code. Sorry.*

### The hero screen

Once you create or choose a hero, you're taken to the *hero screen*. This is sort of like the "town" in other games. It's the safe place where you can tinker with your gear and enter the game.

### Your home

From the hero screen, press `H` to enter your home. This gives you a place where you can stash loot you don't want to carry around. You can also move items between your *inventory* (stuff you carry in your backpack) and your *equipment* (weapons and armor you are currently wearing or holding).

### The crucible

The most interesting facet of your home is the *crucible*. This is the place where you can *craft*&mdash;make new items from existing ones. You place items into the crucible just like you can your home or inventory. However, it only allows items that are part of a *recipe*.

A recipe is a set of items that can be turned into something else. When you place all of the required items for a recipe in the crucible, it will tell you. Press `Space` and it will magically transmute them into something new.

*The set of recipes is still highly in flux, but try dropping a few healing potions in there.*

## The Dungeon Awaits

Now that your hero is alive and ready, it's time to slay some beasts.

### Areas and levels

Unlike other roguelikes, Hauberk doesn't have a single monolithic dungeon. Instead, there are a number of *areas*. Each area has its own "flavor"&mdash;it's own kinds of monsters, difficulty, appearance, etc. An area is in turn divided into a series of *levels*, each more difficult than the last.

From the hero screen, you can select which area and level you want to play. You can only enter an area if you've beaten at least one level from the previous area. Likewise, you must beat a level to unlock the next one.

Since you just created a hero, you can only play the first level of the Friendly Forest, so just type `L` to enter it. Later, when you unlock stuff, use the directional keys to select an area and level. You can replay a level as many times as you want.

### Quests, victory, and defeat

Every level is randomly generated (of course) and populated with monsters and treasure. Each level also has a *quest*. This is a goal you must fulfill before you're allowed to leave the level. After completing the quest, type `Q` to leave the level and return to the safety of your home. All experience and items gained in the level will be saved henceforth and forever more.

If you *die* in the level, you lose everything you gained while in that level. It isn't quite [permadeath][], but it's pretty damn annoying to lose that experience and whatever hot loot you picked up.

[permadeath]: http://en.wikipedia.org/wiki/Permanent_death

If you want to give up and leave the level before completing the quest, you can *forfeit* by typing `Shift-F`. Like dying, doing this sacrifices anything you've gained since entering the level.

### Navigating the level

Your avatar in the game is represented by a `@`. Floor tiles are usually `.`, and impassible barriers and walls look like `#`, or other hopefully obvious solid looking tiles.

You walk around using the directional keys. Pressing the stand key (`5` or `L`) makes you stand still for a turn. That's useful to let a monster take a step closer so you can attack the next turn.

Hold down `Shift` and press a direction to *run* in that direction. You will repeatedly walk in that direction until *disturbed* by reaching an obstacle, a fork in the path, or seeing a monster. When not in combat, running is the most user-friendly way to get from point A to point B.

Closed doors look like `+`. You can open them (which takes a turn) by simply walking into them. An open door looks like `-`. You can close a door by pressing `C` while standing next to one.

### Combat!

Monsters in the game are represented using letters. You attack by trying to walk into the tile where a monster is standing. On the right side of the screen you can see your health along with some of the nearby monsters. Try to get theirs to zero before yours does!

When you kill a monster, you are granted some *experience points*. Earn enough of those, and your hero will increase in *experience level*. That increases your maximum health and does some other good stuff.

Meanwhile, monsters will be attacking you. You are outnumbered, so try not to let them surround you. Attacking from the safety of a narrow corridor helps.

### Resting

After a skirmish, your hero has likely lost some health. That can be regained by imbibing magic potions, but those are in short supply. Instead, they'll have to rest.

Resting requires *food*, which you automatically discover as you explore the level. Every turn that you stand still consumes a bit of food and regains a point of health. Instead of mashing down the stand key, if you press `Shift-Stand`, you will repeatedly rest until you run out of food, fully regain their health, or are disturbed by a nearby monster.

If you don't have any food, resting accomplishes nothing. To get food, you *must* explore new parts of the level. No resting on your laurels or wandering through familiar passages!

### Loot!

While the ridding the world of an evil beast is its own reward, it's not the *only* reward. Many monsters drop treasure, and you'll find some laying on the ground as well. Different levels and monsters tend to drop different stuff, so explore (and murder) widely.

Items are represented using punctuation characters. Potions are `!`, scrolls are `?`, etc. You can pick up an item off the ground by standing on top of it and pressing `G`, for "get".

*If there are multiple items in the same tile, that picks up the top one. Press `G` repeatedly to pick them all up. Eventually, I'll add a menu to let you pick which one you want.*

Many items can be *used*. Potions can be quaffed, scrolls read, wands... uh... waved around? To use an item, press `U` to bring up the item selection screen. In addition to your inventory and equipment, you can also use items that are laying on the ground under you. You don't have to pick them up first. (And *not* picking them up first saves you a turn. Useful in the heat of battle!) Pressing `Tab` on the item screen cycles through these three views.

Type the letter next to an item to use it. If the item has an active "use" like a potion, this will perform it. "Using" a piece of equipment equips it. Using a piece of equipment that you're already wearing unequips it. Remember that equipment must be worn to get any advantage! Carrying around a sword in your backpack doesn't do you much good.

If you want to discard an item, press `D`, then select the item. It will drop onto the ground. It may gaze back at you forlornly, wondering why it wasn't good enough and why you love the other items in your inventory more.

A more entertaining and often more useful way to rid yourself of an item is to *throw* it, which is done by pressing `T`. Throwing an item at a monster will often harm it, and some items do fun and exciting things like explode when lobbed at an unsuspecting beastie.

**TODO: Warrior skills.**
