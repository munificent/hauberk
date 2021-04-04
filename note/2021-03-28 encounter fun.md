Encounters are the real meat of the game. Fighting monsters is to Hauberk what
driving is to Mario Kart or platforming is to Mario. And it's not very fun or
interesting right now. It feels pretty grindy and non-tactical.

This part must be fun or the rest of the game doesn't matter. I want encounters
to feel:

*   **Satisfying.** Most encounters won't be super high-stakes boss fights. But
    even run of the mill ones should provide a pleasant little hit of
    satisfaction. Think how farming or mining in Minecraft just kind of feels
    good.

    Much of this comes from earning a little XP and getting some loot, but it's
    worth thinking about what else we can do here to give the player a sense of
    progress or accomplishment.

    It may be that completing the encounter and thus continuing to explore the
    dungeon is a big part of this?

*   **Tactical.** Most encounters should involve more than one monster, or at
    least monsters with interesting moves. The local layout of the area should
    affect what the hero does. Cover, dark corners, lighting, and visibility 
    come into play. The positions of various monsters affect what the hero does.
    Simply taking a step to move somewhere else should be an important part of
    combat.

    At the same time, those tactics should be more interesting than Angband's
    perpetual "draw them out of the room and into a corridor". The hero should
    be mindful of not letting themselves get surrounded, but at the same time
    should have to, or be incentivized to take on multiple monsters because that
    makes for much more interesting play.

*   **Powerful.** Players should at least periodically get to mow through a
    bunch of weaker monsters. They should cast spells or use items every now
    and then that are really impressive. They should feel like a superhuman hero
    who is always outmanned but never outgunned.

*   **Perilous.** At the same time, it's not trivially easy. They can't just
    mindlessly mow through everything. They need to always evaluate the threat
    level of a situation. Encounters will have fairly high variance in
    difficulty and they may have to flee some. It should feel high-stakes.

## Multi-turn puzzles

I want playing while in an encounter to feel sort of puzzle-like to really lean
into being turned based. But not so puzzle-like that you feel that you need
perfect play to win. It shouldn't feel like *chess* where you need to make the
optimal move every turn, except in critical boss-like battles.

More like, say, Tetris, where each step counts somewhat, but you can get into a
flow state and make moves somewhat intuitively most of the time. Sort of like
playing chess against a not-very smart opponent.

## A dance of death

In particular, I want it to have that Tetris like feel where each move is also
done in the context of setting up future moves. Each turn should feel connected
in a series of meaningful, escalating steps. Like executing a combo where each
turn accomplishes something, but also builds towards the next one. Otherwise, I
think the gameplay feels too slow and staccato. It's hard to reallly draw
players in if they can't plan several moves ahead and then execute them. Of
course, surprises may force them to reevaluate -- that's part of keeping the
player on their toes -- but often they should feel like they are setting up some
dominoes and then playing them out.

In other words, they should feel that their choices have greater meaning than
just for the next turn. That will make them more satisfying and impactful.

## Suboptimal play

In any given encounter, there's a range of player moves from bad to optimal.
The game should encourage you to be pretty smart so that you don't just melee
grind through everything and get bored. At the same time, it shouldn't always
be lethal to play sub-optimally.

One difficulty now is that an encounter's rewards are pretty black and white.
If you survive the encounter, you can rest so it doesn't matter how much health
you lost. Otherwise, you die and lose everything. Any play style at least good
enough to live is effectively "optimal".

We can encourage smarter play by cranking up the difficulty (and probably should
do that somewhat), but that gets punishing quickly. What's really missing is
some shades of gray in the incentive structure. Ways for the player to get some
incremental benefit if they play a little smarter. Ideas:

*   Lean more heavily on consumables. Crank the difficulty up enough that
    players do have to use healing and other consumables fairly often in
    encounters. Then optimal play means burning fewer of those.

    This only works if consumables have meaningful value. If the player always
    has enough gold to buy them, and enough inventory room to carry a pile, then
    it's just another pointless chore.

    One solution is to move away from gold more towards crafting. If getting
    more healing potions means spending components that could be used for
    crafting other useful items, then playing poorly feels like a greater cost.

    Note that all of this though makes players feel *worse* for playing poorly,
    but doesn't necessarily feel *good* for playing better.

*   Make resting tied to exploration. A while back, I had a mechanic where your
    food counter only recharged by exploring tiles. This meant you had to keep
    moving forward to rest. If you played too poorly and needed to rest too
    much, you were forced into greater and greater danger.

    The mechanic felt artificial and balancing this is very hard. It's easy for
    the player to get into a situation where they are dragged into certain death
    if they dive too fast or get unlucky. But it did put a meaningful cost to
    losing health during encounters.

*   Reward them at the end of the dungeon based on how well they played. The
    less health they lost compared to how many monsters they killed, the better
    the reward. This would also help with session fun by encouraging players to
    clear more of the dungeon. Kind of artificial but could be cool.

*   Make playing near full health feel more fun. Link has a more powerful sword
    attack when at full health which really sucks to lose. We could crank up
    the effects or do other tweaks when the player is at high health. It's
    important though not to make the player get too much weaker as their health
    is lowered because that can lead to a really shitty death spiral. They
    should be able to be heroic even when near death.

*   Mentioned elsewhere, but I think fury can help a lot here. In melee combat,
    that will encourage players to avoid taking damage because it burns fury
    and limits their attacks.

*   Make monsters interact with loot more. If they are more likely to pick up
    or destroy items laying around, then the player is incentivized to get the
    battle over quickly.

Of these, I think making consumables and craft components the sort of "meter"
for the session is good, as is leaning more on fury and focus.

## Ideas

*   Monster behavior should probably more predictable and clockwork like. That
    way players can correctly anticipate their behavior more. It's not really
    necessary for monsters to be smart or erratic to be challenging. There is no
    "smarts" to the cards in a game of solitaire, but the game is still
    interesting and challenging because of the situation and difficulty.

    Of course, they shouldn't be entirely mechanistic. Surprise and randomness
    is also an important part of the roguelike experience. But less random and
    subtle than they are now.

*   I'll start a separate doc on this, but I think re-emphasizing the focus/fury
    system could help make combat feel chained and connected. I'm imagining that
    a warrior does a couple of planned normal melee hits on weaker monsters to
    charge up some fury just in time to unleash it on the boss with a special
    hit.

*   Likewise, mages and archers may spend a couple of turns carefully dodging
    enemies to regain focus in order to unleash some ranged attacks.

*   Different classes may vary how much combat feels continuous like this. I'd
    expect rogue-ish characters to be more staccato and opportunistic where a
    warrior wants to feel like a tank plowing through monsters building to a
    crescendo. Mages feel more tension-release where they seemingly do nothing
    for a while charging up and then unleash.

*   Make monsters interact with each other in more interesting ways. That can
    make combat more tactical. For example, if one monster is healing another,
    then you need to take out the healer first. Or taking out a captain to
    frighten the underlings.

*   More interesting, specific AI behaviors. Using moves more deliberately,
    perhaps. Interacting with the world in interesting ways (starting fires,
    moving obstacles, picking up items, etc.)

*   Rechargeable items. That encourages players to use items more often without
    having to burn consumables. A collection of fairly short-recharge moves the
    player can make gives encounters a more orchestrated richer feel. It means
    each turn feels a little different from the previous because different
    moves may have recharged and become available.    

*   More multiple-turn effects. Instead of spells and items that do one thing
    instantly and leave the next turn a clean slate, more things like poison,
    gaseous clouds, burning wall, buffs, debuffs, etc. that affect future turns.

*   Likewise more monsters moves that affect multiple turns.

So the high level summary here is:

*   Give monsters a wider but more predictable set of things they can do.

*   Make actions and options span multiple turns in interesting ways.
