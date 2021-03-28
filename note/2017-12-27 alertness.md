Awareness is how much the monster has noticed the hero in this current turn.
It's the combination of sight and sound.

Sight is how much visual sensory input the monster is getting in the current
turn about the hero. Sound is the same for auditory.

Alertness is how sensitive to noticing the hero the monster is. Higher
alertness means it takes less sensory input for the monster to notice the hero
and wake up.

Each turn when the monster is sleeping, we:

Calculate sight input.

  Breed has "vision" stat that determines number of tiles of distance monster
  can see hero from when fully illuminated. Max is 16. (Rationale: The screen
  is 34 tiles tall, and monsters shouldn't be able to see the hero if the
  player can't see the monster.)

  Every sixteen units of darkness acts like another tile's worth of vision. So
  if a monster has 8 vision, it can only just barely see a fully illuminated
  hero 8 units away, or one with 240 illumination 7 steps away, etc.

  If monster doesn't have LOS, sight is zero. (TODO: infravision.)

    sight = math.max(0, vision - distance - illumination / 8)

  Hero stealth reduces sight input. Hero invisiblity makes it zero.

Calculate sound input.

  Works like vision except there is no LOS and "distance" is based on sound
  flow. Stealth could lower this too, or we could have separate sound and sight
  based stealth skills ("move quietly").

  (TODO: Backstabbing should be much quieter than a normal attack.)

Add those up to determine awareness. Modify it by alertness (TODO: how?). That
determines the chance of the monster noticing the hero this turn. Roll and see
if it passes. If so, the monster wakes up. Max out alertness.

If it fails, take some fraction of the awareness and add it to the current
alertness. Also, decay alertness some each turn. Maybe we say something like:

    alertness = alertness * 0.9 + awareness * 0.1;


TODO: Need to figure out the math for the probability roll on awareness and
alertness. Goals:

- A monster who has never perceived the hero should never wake up.
- A monster who has not perceived the hero in X turns should definitely go to
  sleep.
- If the hero is very near the monster, there is a chance of waking up even if
  the hero is just resting.
- If the hero is out of sight but in earshot and resting, the monster should be
  unlikely to wake up.
- If the hero is in LOS but distant, some chance of waking up. It's pretty hard
  to walk up to a visible monster without it noticing you unless you have
  stealth.
- Monsters behind closed doors usually only wake up if the hero is making a
  racket for a while. Most of the time, the hero should not open the door to a
  crowd of monsters.
- When a hero first sees a monster, it should often wake up. TODO: Should we
  special case this? Unless the hero is focused on stealth, most of the time
  they should *not* get in the first hit on a sleeping monster.
- Breeds should vary in how alert they are. Some should be harder to sneak up
  on than others.
- The math should ideally be simple and concrete enough for players to reason
  about it. For example, knowing a monster cannot see you *at all* if you're at
  least 8 tiles away makes for a more reliable play strategy than a sight curve
  that extends to infinity but tapers down.

Stats that come into play:

- Breed vision sensitivity
- Breed hearing sensitivity
- Hero stealth
- Hero noise


