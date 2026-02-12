I'm working on equipment affixes that boost skill levels. An important design
question is how that interacts with skill caps.

## Design questions

There are three related questions:

### Boosting above 20

If a hero's class allows the max skill level for a skill and then they boost it
beyond that with equipment, does that work? Currently, a lot of skills use
lerp for the effects of the skill and going above 20 doesn't actually do
anything useful. If I want to allow skill levels past 20, I'll have to tweak
those expressions.

Or I guess just have players accept that even though they can boost it beyond
that, for some skills there's no point in doing so.

### Boosting from a mid-level cap

Some classes allow learning a skill but not fully maxing it out. For example,
adventurers can learn spellcasting up to level 10. Can equipment boost it past
that?

### Boosting disallowed skills

A warrior can't cast spells at all, so the skill cap for spell schools is zero.
Can equipment boost that above zero and allow them to use otherwise completely
disallowed skills?

## Design goals

*   Obviously, skill boosting equipment shouldn't break or unbalance the game
    completely.

*   The game shouldn't incentivize players to play "against class". For example,
    if you play a warrior, the game shouldn't be easiest to win by then
    immediately equipping a wand and playing like a spellcaster.

    It might be reasonable for players to pick equipment that gives a sort of
    "secondary class" benefit. Skill boosting equipment doesn't necessarily
    need to *only* boost the class's main skills. But it shouldn't completely
    override what the class is good at.

*   I've long planned to have spellcasting characters wield wands and staves as
    weapons. These wouldn't be very useful in melee and would be equipped
    primarily for their affixes. Some of that can be intellect boosting, but
    the main thing is improving spellcasting. So I definitely want equipment
    that can make spellcasters even better spellcasters.

*   Overall, I think skill boost equipment should be a fairly large part of
    building an end game hero.

*   I'm on the fence about whether skill equipment means a player should feel
    less need to spend experience on a given skill. I don't know whether
    equipment should always augment what they are also leveling, or can be a
    substitute to one degree or another. I lean towards feeling like they should
    *both* level the skill and try to boost it even higher.

*   Putting the previous bullet point another way, maybe the highest power in a
    skill you can attain requires committing *both* experience and equipment to
    that skill. Equipment slots are precious, and it seems like a player
    shouldn't be able to free them up by getting the same benefit by burning
    more experience.

## Compared to stats

The last couple of bullet points there are pointing in the direction of allowing
skills to be boosted by equipment beyond their experience-gainable max. That's
consistent with stats, which have a `baseMax` and `modifiedMax` which goes above
it.

That feels like the right approach to me.

## Design

### Boosting above the max

OK, so for the first question, the answer is yes, a skill can be boosted above
20. As with stats, I don't want to allow a skill to be boosted indefinitely, so
I'll probably have a modified max above that, like 30. That way if a player
goes crazy and spends every equipment slot maxing a skill, they don't break the
game.

Perhaps I'll lower the natural max to say 10 and then have 20 be the boosted
max.

### Spell schools

For most skills, it's pretty easy to rework the numbers to fit in any range.
It's mostly a question of how much experience it takes to reach a given power.

But spell schools are more complex. Each skill level there opens up access to
more powerful spells. If there are too many skill levels compared to the amount
of spells, then I risk having skill levels that don't give you anything because
there are no new spells at that level. Too few skill levels and it's hard to
make more powerful spells less attainable.

I have to say, 20 does feel like a lot of levels here. I suspect that would
leave them pretty sparse unless I design a *lot* of spells. So maybe 10 is a
better natural max.

### Equipment-only spells

OK, so each spell has a given level and you need to have that level or higher
in the corresponding school to learn it. Are there spells whose spell level is
above the natural skill max? That would mean the only way to attain the spell
is to both level the skill *and* have equipment that boosts the spell level
even further.

I think I'm OK with that. It helps force magic users to invest their equipment
slots in items that boost spellcasting. There probably won't be a lot of spells
above the natural max, but a few particularly powerful ones up there seems like
a cool idea.

### Boosting above lower maxes

All of the above assumes the hero's max level in a skill is the actual base max.
But what about classes that have some skill but don't allow all levels? I think
letting equipment boost above the class's max makes sense there.

Thematically, it seems coherent to say that the class max is the hero's physical
and mental limits based on their birth and upbringing but magical equipment
shouldn't be beholden to those limits. It's magic.

Mechanically, if a player wants to spend an equipment slot on an item that helps
in a skill, I don't see any reason that shouldn't let it go above the class's
max. It's the simplest mechanic because it means we don't need to special case
skills limited by the class from skills that aren't.

Allowing this gives the player more agency and more variety in how they can
develop a hero.

### Boosting unlearnable skills

So what about skills where the class's max is zero? Can equipment let a warrior
cast spells?

I think all of the logic from the previous section holds here too. If a player
wants to do it, why not let them? They still have to spend equipment slots to
get it which is a very finite resource, so it's not game-breaking.

It allows a greater variety of heros, and it seems like it might be fun to have
a hero with a couple of minor spells or a mage that decides they want to wield
a magical sword.

## Summary

OK, so what I'll try is:

*   Skills have a base max level of 10. This is the number of levels they can
    gain in the skill by spending experience.

*   Classes can restrict the base for some skills to lower than that, including
    zero. Again, this is the limit of how many levels they can earn by spending
    experience.

*   Skill affixes stack on top of the base level. The base max level doesn't
    limit the effect of skill affixes. A mage can go above 10 for spellcasting,
    an adventurer can go above 5 or whatever for it, and a warrior can even
    have levels in spellcasting if they equip the right gear.

*   Skills have a modified absolute max of 20. Even with a ton of equipment, no
    skill can ever go above that.

*   Retune the skills to take the new ranges into account. Most of their range
    is up to 10, but they still need to gracefully handle going up to 20. Spell
    levels will mostly be 10 or lower but some powerful spells may be above.

*   The experience screen will need UI work to separate out the base and
    modified skill levels. Similar to stats.
