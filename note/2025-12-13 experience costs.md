OK, I've got skills working and leveling by spending experience. The big
remaining step is to actually tune the experience costs for everything. I wrote
a little hacky script that generates one dungeon at every depth, kills every
monster on it, and calculates the total experience points earned.

It holds pretty steady around: 2,500,000,000.

## Breed experience decay

The experience rewards for monsters aren't exactly well tuned either, but they
are calculated procedurally based on the monsters' attacks and moves and I try
to make that code reasonable.

I've considered having the amount of experience you earn go down over time for
killing more of the same breed. That would prevent players from grinding
indefinitely to max out everything. That's probably the first step.

I don't think I want the experience reward to ever hit *zero* because that feels
sort of like an unfair hard limit. So probably something more like an
exponential decay.

After playing around with some graphs, I like:

```dart
var experience = baseExperience * 50 / (previouslyKilled + 50);
```

So the first kill gives you full experience. Once you've killed 50, you're down
to only getting half experience. By 100, you 1/3. By 200, 1/5. When you get to
450 kills, then you're down to 10% of the original experience. But it never
hits zero.

Testing that with the progression script gives a total experience around
1,300,000,000.

It looks like the most killed breeds top out around a 100 or so except for orc
soldier which always wins and is a few hundred. I'm guessing this is because of
pits and because there aren't as many middle and late game breeds. But overall
those breed counts seem about right to me.

The base experience for the weakest monster (mouse) is currently 14, which is
a little high, so let's scale everything down. Currently the scale factor to
put the calculated experience in range is 1/40. Using 1/100 gives a mouse 6
experience, a cockroach 8, etc.

Let's also make the experience fall-off a little steeper using 20 instead of 50.
With both of those, clearing all dungeons down to 100 nets about 300,000,000
total experience. That seems like a reasonable number to work with.

## Experience costs

I tweaked the experience cost for raising stats. After some poking around, the
total to raise all stats to their max for each race is:

```
Race          Stat XP
--------  -----------
Dwarf     241,171,146
Elf       182,945,913
Fae       197,922,481
Gnome     153,061,549
Human     192,199,632
```

## Skill costs

Then for each class, I calculated how much it costs to max out every skill:

```
Class            Skill XP  Skills  Levels
------------  -----------  ------  ------
Adventurer     14,985,890      11     110
Warrior       113,717,080       8     160
Mage           64,049,575       4      49
```

Those numbers are low because I'll be adding more skills. I'm sure I'll want to
tweak the base experience for some skills too, so the number will go up.

This will need a lot more work, but it's a starting point. The high level goals
are:

*   End-game heroes shouldn't be able to fully max out everything unless the
    player really wants to grind and grind.

*   Heroes shouldn't get stronger too fast so that they end up feeling like they
    have to dive through dungeon levels.

*   Players should earn enough experience to boost a stat or skill at a
    reasonable cadence so that it feels like they get a good sense or reward at
    the right pace.

*   That pace should hold relatively steady through the character progression.
