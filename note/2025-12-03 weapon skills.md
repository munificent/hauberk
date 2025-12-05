OK, so I was working on the plan from the previous doc, but then started having
second thoughts. If I make the weapon special attacks things that all classes
can do all the time, then warriors really start to feel like a subset of
magic-using classes where they just have strictly fewer actions they can
perform.

I think there should be *some* magic-using classes that can also access the
weapon special attacks. But if you're primarily a mage-like class, your melee
abilities should be pretty limited.

## Skills unlock powers

This suggests a different design. As you level up a skill like axe mastery, at
some level it unlocks the axe sweep attack. So maybe skills aren't themselves
actions you can directly perform, but they provide access to those at certain
levels.

Let's call those performable actions "powers". Then the idea is that axe sweep,
club bash, spear stab, etc. are all powers that you can gain by leveling up the
corresponding mastery skill to some point. Probably not a super high level, but
enough that primarily magic-using classes aren't likely to reach it very early
in the game but warriors are.

### Archery

What about ranged weapons? Is shooting a bow a power you have to gain too? In
real life, it is a pretty skillful activity. I'm not opposed to saying you have
to put a level into archery before you can use a bow at all.

### Multiple weapon powers

This mechanism opens the door to potentially having multiple powers for a given
weapon type at different levels. I'm not sure what they would be, but if I come
up with some, it would give warriors more things they can do later in the game
beyond just making numbers go up.

### Spells

If skill levels unlock powers, that suggests that we build spells on the same
mechanic. There is a skill for each spell school. At certain levels, the skill
unlocks the next spell in that school.

## Spell acquisition

Having levels in spell schools unlock specific spells works, but it means
players don't have much control over which spells they earn. They can't choose
to skip a spell they don't care about. I have a few goals around spell
acquisition:

*   Players shouldn't be able to access the strongest spells across all schools.
    There should be some amount of specialization at the highest levels. No
    ultra-mage that can do all the things.

    That rules out using only intellect and complexity to determine which spells
    can be gained because then a high-enough intellect would let you access
    spells across all schools.

*   I'd like a relatively large number of possible spells in the game. More than
    Diablo, certainly. That suggestst that having a spell school skill directly
    grant spells when you level it might get crowded: a school may have more
    spells than there are levels.

*   At the same time, I don't necessarily want players to have access to a huge
    number of spells, even within one or two schools. It might be good to force
    players to make some choices about which spells to have.

    That also suggests that just granting spells when leveling a school isn't
    the right fit.

### Spellcasting

Here's an idea: We have a separate skill "Spellcasting". It determines *how
many* spells the hero has. When you level it up, you get a greater number of
spells you can learn.

Then there is a skill for each spell school. Leveling it up increases the
maximum spell level you can learn for spells in that school and makes spells
in that school more powerful.

If you want to be a "jack of all trades" spellcaster, you can put a lot of
points into spellcasting and have a long list of spells to choose from. But
that means you probably won't have access to the strongest spells since you
haven't leveled up the schools as much. And also, your use of spells will be
weaker because lower school skill levels also mean spell effects are weaker.

If you want to specialize in a narrower set of spells, you can put fewer points
into spellcasting and have more to spend mastering a spell school or two.

I'm not sure if spellcasting should treat all spells as equal when it comes to
learning them or if more powerful spells should cost more "spell points". For
now, probably the simplest choice is the former and then I can refine it later
if that seems to not work well.

So, in total, the mechanics I'm thinking for magic use are:

*   Every spell is in a school, has a level, and focus cost. Stronger spells are
    higher level. Casting a spell spends focus. Stronger spells spend more
    focus.

*   Intellect determines maximum focus, which is how much magic you can dish
    out in a battle before being drained.

*   Spellcasting skill level determines who many spells the hero knows. Leveling
    it up lets them learn more spells.

*   A skill for each spell school determines the maximum spell level for spells
    in that school that the hero can learn. Leveling up the skill also increases
    the power of each spell in that school.

*   Magic equipment can artificially boost skill levels. So wands and staves
    can give bonuses to spellcasting or spell school skills.

I could also imagine a mechanic that lets you lower the focus cost of some or
all spells. But currently no plan for that.
