Originally, I was going to have separate classes. Each would have its own
unique mechanics around character development. Something along the lines of:

    Warrior - Disciplines
    - Increase in level
    - Gained automatically by performing certain action
    - Some are passive and have no cost, others require fury or focus

    Mage - Spells
    - No levels, simple yes or no
    - Discovered from scrolls or spell books, intellect requirement to learn
    - Must be explicitly cast, which spends mana or focus

    Priest - Granted powers and prayers
    - Deity at any point in time may randomly grant power to hero, can use after
      that
    - Most granted powers are passive
    - Some ("prayers") are specifically invoked
    - Prayers spend invisible piety stat
    - As piety gets lower, chance of failure increases
    - Gaining new granted power also requires piety, so casting more prayers slows
      rate of gaining granted powers

    Rogue - Skills
    - Skills can be increased in level
    - Player explicitly controls which skills they level up
    - Some skills require certain equipment to be used (i.e. backstabbing
      requires a dagger, etc.)

I killed classes and moved everything to skills. The main motivation was that
it didn't force the player to choose a character type early in the game. They
could incrementally commit to a character style over time based on the kind of
loot they discovered. The idea was that it would make for less useless loot.

Other motivations:

- It also simplifies the game engine. Fewer distinct mechanics to implement,
  user interfaces to build, etc.

- It lets player come up with lots of hybrid character styles that mix different
  skills instead of a hard-coded flat list. Instead of four kinds of characters,
  any combination of skills may be a viable kind, so there's a lot more emergent
  complexity.

I think those are all good things, but there is some loss:

- Having an explicit, detailed character creation process helps the player feel
  connected to their character immediately.

- Different classes are part of the feel of a fantasy game. I was hoping to
  get some of that back using titles, but it's probably not quite the same.

- Some of the different mechanics above actually sound pretty neat. In
  particular, they give each character style a different *play* style. Warriors
  don't have to futz with skills because they will train automatically. Priests
  have a lot more randomness and hope that good things will spontaneously
  happen. Mages carefully select from a long list of spells.

This is a brain dump to see if there's maybe a way to get the best of both
worlds.

One option, of course, would be to dump all of those mechanics in while not
forcing the player to pick only a single subset of them. You could create
characters that have trainings, skills, granted powers, and/or spells. That
kind of sounds like chaos.

A better way, I think is to try to unify them in some way. All of the classes
above have "powers" that the character can gain. They differ in:

1.  Does the power support a range of levels, or only a single one?
    - Warrior training, rogue skills: levels
    - Mage spell: flat
    - Priest granted powers and prayers: not sure

2.  How does the player control which powers are gained or improved?
    - Warrior training: Perform certain in-game action, often with certain item
      equipped
    - Mage spell: Explicitly choose which spells to learn after finding right
      spellbooks/scrolls
    - Priest granted power / prayer: Randomly granted by game
    - Rogue: Similar to spells but more equipment-based

3.  Is the power passive or actively used the player?
    - Warrior training: Some of both
    - Mage spell: Always active
    - Priest: Some of both
    - Rogue: Some of both

I think we can unify 1. by saying all skills may be leveled up but some just
have lower max levels.

It looks like with 3 we basically want to support both passive and active skills
for most classes.

The interesting one is the second question. That's the place where I think the
different mechanics are actually interesting. So one option is to say that each
skill controls how it is improved. Some skills are trained like warriors, others
are randomly granted, others are explicitly chosen by the player.

If we want to let players mix and match those freely, then a single hero will
need to contain all of the stats that control those. So skill/spell points and
piety for gaining them. Focus and fury for using them.

That can be weird though. If you want a warrior character, what do you do with
all those unused spell points?

Here's an idea: make the quantity of them based on *stats*. So you have strenth
points, agility points, intellect points, etc. Raising that stat gives you more
of those points per level that you can spend on skills. Each skill requires a
certain number of the right kind of points.

Hmm, that still interacts weird with warrior skills. They don't need strength
points because they shouldn't be explicitly spending them anyway. Maybe spells
just have a minimum intellect requirement and you have to find the right spell
book or wand to learn it? Likewise rogue skills.

---

I like the general approach, but the above doesn't quite work out. Here's
another sketch:

## Actions

An action is a specific thing a hero can do that the player can perform. In
addition to the base actions like walking and fighting, certain abilities may
expose more actions.

## Abilities

There are a few kinds of gainable abilities, and secondary stats related to
them:

- Disciplines. These are the "warrior skills". Each has a level. The level is
  increased by training -- performing certain in-game actions. For example,
  using a sword improves sword skill. Most disciplines provide passive benefit,
  but some expose actions (sweep attacks, etc.).

  The inner stats for these are the number of times certain actions have been
  performed -- using weapons of different types, taking damage, etc.

  The intended playstyle is that the player can just make the hero do what they
  want the hero to do and they will naturally get better at that.

- Spells. These are the "mage skills". They can be learned by finding the right
  spellbook or spell scroll and having a high enough intellect. They are
  explicitly used by the player. Using them consumes focus which is also lost
  when hit and regained when resting.

  The intent is that mages have access to a large number of relatively flat
  actions they can perform. The play style is to micromanage -- choosing just
  the right action at each turn. Also, to have a "collector's" mindset of trying
  to find and learn all the spells.

- Skills. These are the "rogue skills". They can be learned and leveled by
  choosing to spend gold on them. Gold is found in the dungeon and dropped by
  some monsters.

  Similar to mages, acquisitiveness is a big part of this play style. But with
  rogues, they have to be more deliberate about *spending* to acquire skills.
  Having chosen to spend, most of the skills tend to be passive. So they are
  focused more on growing the character when outside of combat, but tactically,
  they play more directly.

- Granted powers and prayers. These are the "priest skills". For each God,
  there is a hidden piety score which reflects how much the hero is satisfying
  that God. If the score gets high enough, the game may randomly choose to
  spend some of it by granting a power or new prayer. Powers, once granted, are
  either passive or can be used freely. Prayers consume some amount of piety
  and may fail if piety is too low.

  Piety is gained by doing things the God likes and lost when displeasing the
  God.

  The high randomness means priests cater towards players who are willing to
  take risks. It also relieves players of the burden of making lots of specific
  character growth choices. They can instead just make a go at it and let the
  RNG develop their character for them.

## Classes

I want the game to have different kinds of characters with different play styles
and focused on different kinds of abilities. Some of that emerges by focusing
on different stats. A hero that doesn't have much intellect will have few
spells. A hero with low strength won't be able to use many weapons well.

But classes more directly tailor the abilities. The various kinds of abilities
have costs that determine when new passive boosts and actions are granted. Each
class tunes those costs. Some classes specialize within a subclass of certain
abilities too.

A few examples:

- Adventurer. Moderate in all.
- Warrior. Low training cost. High focus, gold, and piety cost.
- Mage. Low focus cost. High training, gold, and piety cost.
- Rogue. Low gold cost. High training, focus, and piety cost.
- Priest. Low piety cost. High training, focus, and gold cost.
- Paladin. Low training and piety cost. Very high focus and gold cost.
- Archer. Low training in archery. Moderate other training cost. Moderate gold
  cost. High focus and piety.
- Sorceror. Very low focus cost in sorcery spells. Moderate cost in other
  spells. High cost in everything else.
- Witch. Low-moderate spell cost. Moderate gold cost.

You get the idea.

## Races

Moving away from "skills for everything" also means we don't have skills for
raising stats. Instead, every time the hero gains a level, they may gain points
in stats. The hero's race determines the rate that various stats are increased.

Races also provide some variation in game difficulty. In addition to varying
*which* stats the hero improves, some races may overall gain more or less
points in stats. Races that improve stats more quickly lead to an easier game.

Some races may also give passive bonuses -- better detection, infravision, etc.
A few examples:

- Dwarf. High strength, fortitude, will. Low intellect and agility.
- Elf. High intellect, agility.
- Fairy. High agility, intellect, will. Low strength and fortitude. Fly?
- Gnome. High intellect and will.
- Human. Even amounts of all.
