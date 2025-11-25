In a previous note, I had an idea that you could spend experience to grow the
character: raise stats, learn skills, etc. No more levels.

One gap that leaves is that the player no longer has a clear notion of how "far
along" their character is. Level is a nice sense of progress.

I have also long wanted some kind of subclasses or titles in the game, partially
to encourage specialization, and partially because there are so many evocative
words for various occupations and roles.

Here's a couple ideas for how to solve both problems:

## Classes and subclasses

First, we take classes and subclasses and organize them into something like a
skill tree. Adventurer is at the root, the four basic classes are below that,
and various subclasses like magic school specializations, weaponmasters, etc.
hang off those, with potentially multiple levels of subclass.

In order to gain a class or subclass, the player must already be at the parent
node, and must spend experience to reach the subclass. A character only has one
class or subclass at any point in time, so spending the experience to move to
a subclass means leaving the current class.

We could maybe let you walk back *up* the tree if you wanted. Flexibility is
nice, but forcing the player to make meaningful choices is important too. I
lean towards this being permanent. You can go forward and specialize into
subclasses, but you can't undo.

Mechanically, classes and subclasses mainly exist to make easier to acquire
or use certain skills. This could mean lowering the experience cost to gain the
skill (if you have to spend experience to get it), lowering the cost to use it,
or lowering a stat requirement. I'll have to think about this more.

Purchasing a subclass is sort of like spending XP on a "combo" in that it makes
a whole suite of skills easier/cheaper to attain/use. But since you have to
spend experience to unlock the subclass itself -- and doing so locks you out of
-- other subclasses, it encourages you to commit to a specialization.

You don't *have* to subclass. You can stay at one of the generalizations and
that's also a viable way to win the game.

## Specialization versus power

Subclasses don't always have to represent *specializations* of a class. They can
also represent simply a *more powerful* form of that class. If we want something
that replaces "I'm a level 30 warrior" in terms of getting a basic sense of
character power, then having a deep tree of subclasses to represent "basically
the same kind of class but stronger" is important.

Organizing and navigating that tree might get difficult, though. Let's say we
have a few subclasses of mage that are just more powerful:

- Mage -> Sorceror -> Sage -> Wizard

Then we also have a few subclasses that specialize in different schools:

- Conjurer
- Diviner
- Elementalist

At what mage level do those branch off from? What if you go past that branch
point but then later decide you want to specialize.

Are there more powerful forms of those too?

## Class level and specialization

Maybe I'm trying to cram two things together into one when they are separate.
Let's try a different approach.

### Class level

Let's say that there are four basic classes each with their own kind of skill:

- Warrior and disciplines
- Mage and spells
- Rogue and skills
- Priest and prayers / granted powers

The reason these four are special is because each category of skill has a
separate mechanic for how they work. Disciplines are passively trained, spells
are learned from books, etc.

For each of these, the hero has a level in them. So you can be level 0 at mage,
level 1, etc. We'll come up with a nice title for each level. A hero can level
up multiple of these. You can be a warrior/mage. You spend experience points to
level one up.

You class level caps the skills you can learn under that class. So some spells
might need you to be a level 3 mage before you can learn them. Basically like
instead of having a single "experience level" for the whole character, there
are four independent experience levels for each of the main skill categories.

### Specialization

Then, separate from that, you can spend experience points to purchase a
specialization. These are things like "archer", "necromancer", etc. A 
specialization makes it easier to acquire some skills within a class.

Can you only have one of these?

## What are classes for again?

Maybe I'm getting ahead of myself. I have had these four archetypal classes in
the game for a long time and had an idea that each would have its own kind of
skill mechanic... I never really did figure out what rogue skills are.

### Skill mechanics

Maybe before I get in the weeds around subclasses and titles and stuff, I should
figure out what the fundamentals are. So far I'm pretty happy with the approach
that there are a few flavors of skills that each have their own mechanic which
lends itself towards a play style.

-   I like how warriors and disciplines work.
-   I sort of like how mages and spells work, though I don't have much
    experience with them yet.
-   I'm interested in the piety mechanic, but haven't tried it in practice.

I never really figured out a different mechanic for rogue skills. Maybe rogues
should be considered a subclass of warriors?

### Different skill mechanics in one character?

So I like having a couple of different skill mechanics. The next question is
should a given character only ever have one kind? Or does it make sense for a 
character to have some disciplines, some spells, etc.?

I'd like characters to feel somewhat focused and force the player to really
commit and not just have a character that can do everything. But at the same
time, supporting at least *some* kinds of characters that have multiple skill
categories seems worthwhile.

### Are skill mechanics attached to class?

So far, I've been assuming all disciplines are for warriors, all spells are
for mages, etc. But that's a design choice too. We could say that each class
only has its own set of skills but not necessarily require all skills for a
given class to use the same mechanic.

We could give mages a couple of mage-specific disciplines and warriors a couple
of spells, or at least spell-like things.

I'm leaning towards no. It feels a little confusing and unnecessarily complex.
If we have warrior-specific spells, then calling them "spells" feels confusing
and wrong. But I don't want to have to come up with other terms for "thing like
a spellbook but that a warrior uses" and "thing like a spell but a warrior
casts".

If I really wanted to go in that direction, I'd probably collapse all skills
together into one mechanic more like Diablo.

### Is deity worship a separate class?

A nagging thought I've had for years is that worshipping a deity feels
orthogonal to your secular occupation. Why shouldn't there be warriors or mages
that also worship some deity? That's what some other roguelikes do.

But, thinking about it more, I think it's OK to not allow those to be freely
combined. There's a difference between "some warrior guy who also happens to
believe in this god" and "some acolyte who has devoted so much of their life in
service of this one deity that they have literally been granted divine power and
the attention of the god".

I think it's reasonable to say that only priests, who have sacrificed their
worldly occupation, are able to get the full benefit of a deity.

### A rogue skill mechanic

Here's an idea for rogue skills. We could say that you spend experience directly
to earn them. That could work.

### Four base class levels

OK, so let's say for now that we do have the four main classes and you can
level them up. What do those levels do?

-   Warrior: Lower the training cost to improve disciplines. You're incentivized
    to spend experience growing your warrior level because doing so immediately
    makes your actions more effective at training disciplines.

-   Mage: Increase the maximum spell level you can learn. Instead of having
    spell "complexity" off intelligence, we could say that spells have a level
    and your mage level must be at or above that level to understand the spell.

-   Priest: Maybe priests are the class where class level has the most direct
    affect. It gives you granted powers when you level up. For prayers, we could
    do something like spell level, or maybe we should try to make priests less
    mage-like and just focus on granted powers. That's appealing.

-   Rogue: Lowers the experience cost to learn rogue skills. So investing in
    raising your rogue level makes it easier to do more rogue stuff.

### Mixing class levels

Can you really freely level up in all classes? Some options:

1.  Yes, why not? You would have to grind forever to max them all out and you
    could just not do that. I also have an idea where monsters of a given breed
    could offer diminishing experience returns based on how many you've killed,
    which would effectively start capping total experience.

2.  No, you have to pick one class and you can only level up that one. You'd
    still in theory be able to learn disciplines and rogue skills, just not at
    any kind of discount. Spells and priest granted powers would be off the
    table.

3.  You can pick up to two classes. You can pick zero to be a pure adventurer.
    You can pick one to be a normal single class and only level that class up.
    Or you can dual-class and pick two.

4.  You can pick one and also a secondary class. Like the previous option but
    the second class's level is capped in some way.

### Subclass specializations

OK, I'm not sure about mixing classes yet. Let's try to figure out how
specialized subclasses could work and see if that helps.

-   Warrior subclasses: Lower the training cost for some disciplines but not
    others.

-   Mage subclasses: Increase the maximum spell level of some schools but not
    others. Maybe lower casting cost of spells in a school?

-   Rogue subclasses: Lower the experience cost for some skills but not others.

In other words, each subclass acts sort of like a class level but only for a
subset of the skills in that class.

### Warriors and rogues versus mages and priests

With the class level mechanics above, the non-supernatural classes are pretty
different from the supernatural ones. A mage *needs* to raise their class level
to access stronger spells. Likewise, a priest must level up to get the granted
powers.

But a warrior or rogue could simply never level up their class levels at all.
Warriors can just train disciplines and rogues can buy individual skills. Their
class levels are just soft incentives.

Is that OK? It implies that warriors and rogues might have more experience
available to spend raising stats. It doesn't sound unreasonable to imagine that
a warrior could have more time to improve their body (and mind?).

Maybe that's OK.

### Class branches

Here's an idea for how to involve specializations. We could say that the classes
level up for a while but beyond a certain level, the *only* way to level up is
into a specialized branch, like:

```
          Mage
            |
        Sorceror
            |
         Wizard
            |
    .------- --------.
    |                |
Occultist       Illusionist
    |                |
Necromancer       Conjurer
```

The idea then is that you can't max out an *entire* class. For mages in
particular, this would imply that you can only reach the highest level spells
in a single school.

The shapes of these skill trees could be different for the different classes.
Mages would probably be pretty deep and maybe branch near the end.

For priests, it doesn't make sense to have a "generalist" priest. You can't
worship them all! So its skill tree would probably immediately be split like:

```
Acolyte   Mystic   Shaman
  |         |         |
Monk      Sage      Witch
  |         |
Priest    Prophet
  |
Abbot
```

Maybe warrior and rogue wouldn't branch much at all. Maybe the way to think
about this is there's one big tree for all of the classes that works sort of
like a skill tree where you have to unlock a parent node before you can go into
the branches.

No, that gets weird for priests. You definitely shouldn't be able to go down
multiple priest diety paths at the same time.

### How the main class playstyles should work

Taking a step back, when I think about playing the game in general and the four
main classes or player archetypes, how do I vaguely expect them to work?

#### Warriors

Character creation should be fairly simple. Then players mostly run around
beating stuff up and getting better. They spend experience leveling up stats
and making the player stronger.

I could see having the player pick a subclass at creation time. Or I could see
the game letting them make that choice later. It could be reasonable to only
let them choose one and be done.

#### Mages

Character creation is again fairly simple. But they spend a decent amount of
time thinking about what spells they want to gain and working towards unlocking
more powerful spells.

(One way to contrast mages with warriors is that warriors unlock greater power
through gear while mages unlock it through spells.)

Again I could see subclass happening at creation time or later. One vote in
favor of later is that it lets a player specialize in the spell book they
happen to find. (Alternatively, I could get rid of spellbooks as a mechanic
and rely on spending experience and maybe class levels to access spells.)

#### Priests

A priest has to pick a deity at creation time and that's it for the duration.
I don't think it makes sense to have specialization within deities, so that's
kind of it.

They want to get new granted powers at some reasonable cadence using whatever
mechanic exposes them.

#### Rogues

More than any, rogues probably start off unformed and specialize over time
based on what opportunities arise as the hero explores.

## Idea: Class pairings

Let's say we have a fairly long list of classes and subclasses. The player can
buy one by spending experience. But there are some constraints:

1.  They can only have a total of two. So there's two slots.
2.  Some require you to already have another one in the other slot. These are
    specialized subclasses. So if you want to be a Necromancer, you have to
    commit to being a Mage + Necromancer.
3.  Some pairs are disallowed. You can't have two deities.

Feels weird and pretty arbitrary.

## Idea: Subclasses and dual classes

A player can pick zero, one, or two main classes. So you can be an adventurer
(no classes), mage, or warrior-priest.

If you pick priest, you have to pick a deity subclass immediately.

You can level up each of the classes independently. And at some point, you can
choose to purchase a specialized subclass for either or both of them.

## Back to the original goals

Oof, this note is just wandering all over the place. The original problems I'm
trying to work through are:

-   Allowing the player to buy stat points whose cost is determined by the race
    is a nice mechanic for making races useful while giving the player more
    control over stats.

-   That in turn means treating experience like a currency instead of it just
    leading to leveling up. But that leaves a hole where character level used
    to give the player a sense of progression.

-   We could maybe fill that hole with class levels that the player can
    purchase.

-   Separately, there is the problem of how classes and skills interact and to
    what degree players can specialize their characters and access skills across
    the main skill categories.

    Currently, class just determines "profiency" in each skill category. It
    makes some skills harder or impossible to learn. It feels sort of simple
    and half-baked.

While solving those problems, I have some aspirations:

-   I like the idea of some amount of player-controlled class *combinations*.
    It's not necessary, but it could really open up replayability.

-   If not actual class combinations, at least some way to access some skills
    from different categories would be good. Seems like it should be possible
    to have a character that can both learn disciplines and a couple of spells.

-   At the same time, I don't want a player to be able to max out everything in
    a character, and I like the idea of each character having a well-defined
    punchy identity. "Gnome sorcerer-thief" works for that. "Fae that is level
    3 conjurer, level 2 rogue, level 4 archer, level 1 druid" not so much.

-   I like the idea of something class-level like for unlocking spells instead
    of hanging it off intellect.

-   Priests need to be locked into one deity.

-   Mages should support some kind of specialized schools.

-   I think it might be a good thing to not force the player to fully lock in
    their character's specialization or subclass at character creation time.
    Another design problem is that the game doesn't really have any big
    milestones to mark player progress since there's no story. I'm hoping that
    I can use "unlock a subclass" as one of those milestones.

All of these may not be attainable. Overall, the design space is feeling a
little over-constrained here.

## Skills

Taking classes completely off the table, let's just think about the kinds of
skills and actions in the game, and their mechanics.

-   Disciplines. These are passive skills that get better automatically by
    doing some relevant action. Aside from masteries, they mostly don't give
    the hero any new actions, they just make basic actions more effective.

    I'm pretty OK with these and how they work. I will say that because they are
    so automatic and passive, it doesn't feel like a particularly strong reward
    when one levels up. They're just sort of there.

    It might be worth separating out the masteries from these because those
    do give the player a new action.

-   Spells. Each one is a concrete new action the hero can perform. They drain
    focus. The intent is for there to be a fairly long list of them, organized
    into some set of spell schools. To acquire them, you have to find
    spellbooks.

    Some of these can be quite powerful, so we have to limit the hero's access
    to them. Currently, this is by having an intellect requirement to learn them
    and then draining focus when using.

    A general mage hero might learn spells from a variety of spellbooks, and
    I'd also like to support heroes that specialize in a certain area. I could
    see requiring specialization for the strongest spells.

-   Deities and granted powers. The hero worships a single deity. Periodically
    they are given a new supernatural ability they can do. The hero has to pick
    a single deity and stick with it.

    Maybe some sort of piety system where the player must restrict their
    behavior in some ways to please their god or they start losing powers.

-   Deities and prayers. I don't have these fully figured out yet, but basically
    sort of like spells for priests but that consume piety instead of focus.
    Not sure if these hold together or merge with granted powers. (I.e. are
    some granted powers just limited by spending piety?)

-   Rogue skills. Don't really have these figured out at all.

### Adding classes

Given those, how might they map to some concrete classes?

-   Warrior: Obviously focused entirely on disciplines. Depending on how rogue
    skills work, maybe some of those.

-   Mage: Obviously focused on spells. It seems reasonable to maybe have some
    disciplines, just trained very slowly.

-   Rogue: Honestly not really sure how this differs from a warrior.

-   Ranger or warlock: Some kind of "battle mage" that can do some spells but
    also pretty good in combat.

-   Druid: A priest-like class that worships some sort of nature god. Can maybe
    transform into an animal. Some combat abilities but more limited than a
    ranger. Plays like a magic-user with nature-oriented spells.

-   Paladin: A warrior-like worshipping some deity of purity and justice. Strong
    combat but also some divine blessings. Some of those could be passive
    granted powers like being able to sense evil. But I imagine most would be
    spell-like in that they are directly invoked. They need to be rate-limited
    in some way to avoid being too powerful.

-   Barbarian: A warrior-like class focusing mostly on weapons and not armor.
    Maybe a dash of some kind of supernatural nature magic.

-   Alchemist: A magic user that focuses on creating, mixing, and transforming
    objects.

-   Necromancer: A magic user that focuses on death-related spells.
    Alternatively, a sort of religious occultist that derives power from demons.
    I suppose when supernatural beings really do exist, the line between
    religion and magic-using is pretty blurry.

What I'm seeing here is:

-   Many classes don't seem to strictly bucket into one flavor of skill.

-   The line between prayers and spells is pretty damn blurry.

-   Priests and rogues don't stand out as meaningful archetypes as much as
    warriors and mages do. It seems like there's really more a continuum between
    warriors which are physical and material to magic users which are mental
    and supernatural.

-   Having said that, there is still maybe something around granted powers for
    priests which is differently from spells which must always be specifically
    invoked and drain focus. Also, if there's a piety mechanic that forces
    priests to restrict their behavior in some way, that's mechanically pretty
    distinct.

## Tabling for now

OK, I think the high level take-away is that I don't have a good enough handle
on what I want rogues and priests to be able to do in order to sort out how
subclasses, classes, skills, etc. should behave.
