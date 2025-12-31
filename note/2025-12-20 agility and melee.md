The game currently has two main hero resources:

*   Health, whose max comes from vitality
*   Focus, whose max comes from intellect

There is also:

*   Fury, whose max comes from strength

Health and focus are pretty fundamental resources. Fury is kind of half-baked
right now.

Since three of the stats have a corresponding resource... should agility have
one too? What would it do?

## Coordination

It makes sense that dexterity and coordination wear out the more you use them.
I could see a "coordination" resource that is used for things like firing
arrows and rogue skills. Similar to focus, it would probably be drained using
skills and regained by resting.

Is it *worth* making this a limited resource? My current plan is that arrows
are unlimited. They aren't powerful enough to really need rate limiting. If we
do limit them, they should probably become more powerful in compensation.

For rogue skills, I didn't plan on having them powerful enough to really need
to be resource limited, but I suppose they could be. Conceptually, this resource
makes sense, but I don't know if it makes the game actually better to play. It's
pretty much just another flavor of focus.

## Dodge

We could have the resource interact with dodging. Some ideas:

*   Attempting to dodge an attack spends it. Or perhaps only successfully
    dodging?

*   Wearing heavier armor lowers or drains it somehow.

*   As the resource gets lower, dodge ability gets worse.

I like the idea of doing something here, because it gives players another way
to make heroes that can survive combat by focusing on dodging attacks (agility,
dodge, and coordination) versus enduring them (vitality, armor, and health).

But I'm worried about a death spiral where a hero uses up their coordination,
their dodge tanks, and then every attack hits them and takes them out.

## Parrying

The challenge with dodging is that currently it's not something an actor chooses
to do. The defender of an attack does it implicitly as part of attack
resolution.

If we have a resource for dodging, it doesn't give the player control over when
to spend or not spend that resource.

We could make "attempt to parry next attack" a thing the player can choose to do
during their turn, but it's not very useful. Even if successful, it leaves them
no better than they were before. They already spent their turn parrying, so they
can't do anything else. Actually worse if they are surrounded by more than one
monster since they spent their entire turn and now multiple monsters get to go.

## Tactical combat

I have long wanted to make combat more tactically interesting. Right now, it's
mostly just "try to stay in a corridor and don't get surrounded" as in Angband
which is not super interesting. It's a drag to spend a lot of time on a dungeon
generator that makes interesting rooms if the player actively avoids being in
them.

The main reason for that is that being surrounded is so devastating for players.
So perhaps there's something I can do here to make combat more technically
interesting, encourage players to go inside rooms, make agility more useful and
rogue heroes more fun to play.

I'll brainstorm some mechanics.

## Different action times

Currently, every action takes the same amount of time and actors just have a
global speed that affects how often they get to do them. Some games give actions
different time costs. I've avoided that because I didn't want to make it too
hard for players to reason about when they will get to act again. In pitched
boss battles, it can be important to know whether the monster will get a move
after you do or not.

But that's a choice and I could choose otherwise. I could make some actions
faster or slower. If I do that symmetrically with monsters, I don't know if it
will make a big difference. If heroes and monsters all spend less energy to
walk then the result is pretty much the same in a chase, it just affects how
moving and attacking interact. Likewise making melee attacks faster.

But I don't think I'd want to change action speeds asymmetrically. If the hero
just always walks faster than monsters do, then it doesn't change the tactics
much. It's just free boots of speed.

### Slower melee

How would it affect mechanics if attack actions were always slower than walking?
That should make attacking feel "heavier". You can dance around the room more,
as can monsters, but choosing to attack would feel more like a commitment. Would
that make the tactics different? I might have to try this out and see.

### Running and endurance

Instead of making walking always faster (or slower), we give the hero the
ability to "run". This is a separate walk action that takes less time but
consumes some resource (perhaps agility-derived). This would let the hero dance
around the field of combat a little bit but not just permanently outrun monsters
all the time.

## Counters

Currently, when attacked, the defender can dodge, but that's it. Some games
have "counters" where the defender gets to attack in return. The nice thing
about that for the hero is that it scales up with the number of attackers. That
could partially nullify the problems with being surrounded.

Of course, we shouldn't *totally* nullify those. Part of the strategy is
managing not getting overwhelmed by a bunch of monsters. You shouldn't be
rewarded for just plowing into a crowd.

## Sidestep attacks

Another challenge with the current turn-based system is that each turn, the
hero has to decide whether to reposition or to attack because each spends a
turn. That makes it hard for combat to feel like the hero can dance around
enemies unless they are actually significantly faster.

One idea is to have moves that combine both an attack and a move. We could do a
"sidestep left" and "sidestep right" ability. Each takes a target direction
towards an adjacent monster. Sidestep left attacks that monster, and then takes
one step diagonally to the left of it. Likewise for sidestep right.

For example, a sidestep left going north does, in one turn:

```
.....     .....     .....
.....     .....     .....
..M..     ..|..     .@M..
..@..     ..@..     .....
.....     .....     .....
Before   Attack N   Move NW
```

I don't think I'd want a general move that lets you melee and then take a step
in any random direction. If we have that, then the player can just spam that
by attacking and taking a step back every turn to let the monster chase them
around without ever getting a chance to attack, sort of like pillar dancing.

This could be an ability that consumes some sort of agility-based resource too,
if it's too powerful otherwise.

## Haste / alacrity

A simpler mechanic that covers much of the same territory is to give the hero an
ability to haste themselves. This would temporarily raise their speed but
consume some agility-derived resource. Probably it would be a mode they could
switch on and off. When on, their speed is raised but they are burning that
resource every turn. When off, they're at normal speed and don't use that
resource.

The resource would be regained by resting.

Having this be agility-derived I think would work really well with archers,
rogues, and other hero styles that are based more on dexterity and sneaking in
and out than brute force.

One concern I have is that speed is *so* powerful that basically all players of
all styles would want to make good use of this. You'd be incentivized to min-max
this ability for basically every encounter.

So as with the earlier section, maybe it's better to restrict this to some
actions like walking.

## Haste skill

Instead of or maybe in addition to being an agility-limited ability, maybe being
able to move around faster should be a skill you have to deliberately invest in.
Warriors and tank characters wouldn't put as much into it, so it would be less
of an issue of all characters being incentivized to use it all the time.

This could help differentiate rogues from warriors.

## Fury

Right now, the game has a fury resource. It works sort of like a combo meter. It
increases when the hero dishes out damage and fades as turns pass where they
give no damage. It applies a scale to damage the hero does so the higher the
fury, the higher the damage multiplier.

Because it's raised by the hero doing damage, it doesn't encourage them to wade
into melee and get surrounded. The optimal strategy is still to hide in
corridors.

Instead, I have two ideas:

### Incoming damage

First, it gets raised by *receiving* damage. Also, if a monster attempts to hit
the hero but misses, fury still goes up as if it had hit. And it should probably
be based on the pre-armor damage amount. (That way, the hero isn't penalized for
getting better armor or better at dodging.)

The point here is that if the hero is surrounded, their fury goes up faster.
It is regained at the rate that monsters damage the hero, not vice versa. This
encourages the hero go wade into a group of monsters because it means their
fury will raise faster.

### Fury skills

Then we treat it like focus where some skills spend fury. Probably take the
weapon mastery skills and make them much more powerful but spend fury. Also
probably try to make more of those skills do area effect damage in some way.
Combined, this means that as the hero gets surrounded, the rate of incoming
fury increases and the rate that they can respond by burning fury on powerful
skills increases too.

Then some above the previous sections here could likely become skills that spend
fury, like:

*   Battle frenzy: Temporarily increases speed. Or maybe just reduces energy
    cost of attack actions?

*   Sidestep: See above.

*   Roar: Pushes back and frightens all adjacent monsters.

*   Hurdle: Swaps places with adjacent monster.
