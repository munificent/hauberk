# Hauberk Player's Guide

Welcome! I see you have an adventurous spirit! Not because you wish to venture into dungeons filled with beasts and untolds horrors, but because you have the fortitude to try out a game while it's still under development. Well, some of the former too.

A caution for the unwary: **The game is not done, or balanced, or complete, or bug-free.** You can help!

## Input

Hauberk is played using your keyboard. It's optimized for a Mac laptop keyboard with US layout. That's what I use. Keybindings are not currently configurable, but I would like it to work well for as many users as possible. If you have suggestions on how to handle other platforms/languages, let me know.

Most user input is directional, and the eight cardinal directions use these keys:

    .---.---.---.
    | I | O | [ |
    |---+---+---|
    | K | L | ; |
    |---+---+---|
    | , | . | / |
    '---'---'---'

This is used for navigating in the game, and also on menu screens. `L` is also the "OK button": use it to select menu items. You'll spend most of the game with your right middle finger sitting comfortably on `L`.

`Escape` is used to go back in menu screens and exit dialogs.

(Note that all keys are shown uppercase here but are typed lower case. `L` means a lowercase "l". An uppercase one will be `Shift-L`.)

## A Hero Awakens

To start playing, first you need to create a character. On the Main Menu Screen, type `N` to create a new hero. Enter a name (or use the default suggested one) and hit `Enter`.

*There isn't much to specify at character creation time, but eventually you'll pick a class, race, and maybe some other stuff. Currently, warrior is the only class.*

Your hero is saved in your browser's [local storage][]. This means you can return to the game later and your hero will still be there. If you switch browsers, though, your heroes won't be in the new browser. Heroes are saved every time you leave a level, or exit your home.

[local storage]: https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Storage#localStorage

### The hero screen

Once you create or choose a hero, you're taken to the *hero screen*. This is sort of like the "town" in other games. It's the safe place where you can tinker with your hero and enter the game.

### Your home

From the hero screen, press `H` to enter your home. This gives you a place where you can stash loot you don't want to carry around. You can also move items between your *inventory* (stuff you carry in your backpack) and your *equipment* (weapons and armor you are currently wearing or holding).

### The Crucible

The most interesting facet of your home is the *Crucible*. This is the place where you can *craft*&mdash;make new items from existing ones. You can place items into the Crucible just like you can your home or inventory.

However, it only allows items that are part of a *recipe*. A recipe is a set of items that can be turned into something else. When you place all of the required items for a recipe in the crucible, it will tell you. Press `Space` and it will magically transmute them into something new.

The set of recipes is still highly in flux, but try dropping a few handfuls of berries in there and see what happens.

## The Dungeon Awaits

Now that your hero is alive and ready, it's time to slay some beasts.

### Areas and levels

Unlike other roguelikes, Hauberk doesn't have a single monolithic dungeon. Instead, there are a number of *areas*. Each area has its own "flavor"&mdash;it's own kind of monsters, difficulty, appearance, etc. Each area is in turn divided into a series of *levels*, each more difficult than the last.

From the hero screen, you can select which area and level you want to play. You can only choose an area if you've beaten at least one level from the previous area. Likewise, you much beat a level to unlock the next one.

Since you just created a hero, you can only play the first level of the Training Grounds, so just type `L` to enter it. Later, when you unlock stuff, use the directional keys to select an area and level. You can replay a level as many times as you want.

### Quests, victory, and defeat

Every level is randomly generated (of course) and populated with monsters and treasure. Each level has a *quest*. This is a goal you must fulfill before you're allowed to leave the level. After completing the quest, type `Q` to leave the level and return to the safety of your home. All experience and items gained in the level will be saved henceforth forever more.

If you *die* in the level, you lose everything you gained while in that level. It isn't quite permadeath, but it's pretty damn annoying to lose that experience and whatever hot loot you picked up.

**TODO: Combat. Choosing skills.**

