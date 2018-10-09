import '../../engine.dart';
import '../themes.dart';
import 'builder.dart';
import 'lowercase.dart';
import 'uppercase.dart';

/// Static class containing all of the [Monster] [Breed]s.
class Monsters {
  static final ResourceSet<Breed> breeds = ResourceSet();

  static void initialize() {
    Themes.defineTags(breeds, "monster");

    // Here's approximately the level distributions for the different
    // broad categories on monsters. Monsters are very roughly lumped
    // together so that different depths tend to have a different
    // feel. This doesn't mean that all monsters of a category will
    // fall in that range, just that they tend to. For every family,
    // there will likely be some oddball out of range monsters, like
    // death molds.

    //                   0  10  20  30  40  50  60  70  80  90 100
    // jelly             OOOooo-----
    // bugs              --oooOOOooo-----------
    // animals           ooOOOooooooo------
    // kobolds              --ooOOoo--
    // reptilians               --oooOOOo-
    // humanoids             ----oooooOOOOoooo----
    // plants                  --o--        --oooOoo----
    // orcs                    --ooOOOoo----
    // ogres                        --ooOOOo-
    // undead                            --------oOOOOOoooooo-----
    // trolls                           --ooOOOoooo-------
    // demons                                 -----ooooOOOOooooo--
    // elementals                   --------ooooooooooooo-----
    // golems                                --ooOOOoooo---
    // giants                                     --oooOOOooo-----
    // quylthulgs                                     -----ooooooo
    // mythical beasts                 ----------oooooooOOOOoo----
    // dragons                                  -----oooOOOoo-
    // ancient dragons                               ----ooooOOOOo
    // ancients                                            ---ooOO

    // jelly - unmoving, do interesting things when touched
    // bugs - quick, breed, normal attacks
    // animals - normal normal normal, sometimes groups
    // kobolds - weakest of the "human-like" races that can drop useable stuff
    // reptilians
    // humanoids
    // plants - poison touch, unmoving but very strong
    // orcs
    // ogres
    // undead
    //   zombies - slow, appear in groups, very bad to be touched by
    //   ghosts - quick, bad to be touched by

    // Here's the different letters used for monsters. Letters marked
    // with a * differ from how the letter is used in Angband.

    // a  Arachnid/Scorpion   A  Ancient being
    // b  Giant Bat           B  Bird
    // c  Canine (Dog)        C  Canid (Dog-like humanoid)
    // d  Dragon              D  Ancient Dragon
    // e  Floating Eye        E  Elemental
    // f  Flying Insect       F  Feline (Cat)
    // g  Goblin              G  Golem
    // h  Humanoids           H  Hybrid
    // i  Insect              I  Insubstantial (ghost)
    // j  Jelly/Slime         J  (unused)
    // k  Kobold/Imp/etc      K  Kraken/Land Octopus
    // l  Lizard man          L  Lich
    // m  Mold/Mushroom       M  Multi-Headed Hydra
    // n  Naga                N  Demon
    // o  Orc                 O  Ogre
    // p  Human "person"      P  Giant "person"
    // q  Quadruped           Q  End boss ("quest")
    // r  Rodent/Rabbit       R  Reptile/Amphibian
    // s  Slug                S  Snake
    // t  Troglodyte          T  Troll
    // u  Minor Undead        U  Major Undead
    // v  Vine/Plant          V  Vampire
    // w  Worm or Worm Mass   W  Wight/Wraith
    // x  Skeleton            X  Xorn/Xaren
    // y  Yeek                Y  Yeti
    // z  Zombie/Mummy        Z  Serpent (snake-like dragon)
    // TODO:
    // - Come up with something better than yeeks for "y".

    arachnids();
    bats();
    canines();
    dragons();
    eyes();
    felines();
    goblins();
    humanoids();
    insects();
    jellies();
    kobolds();
    lizardMen();
    mushrooms();
    nagas();
    orcs();
    people();
    quadrupeds();
    rodents();
    slugs();
    troglodytes();
    minorUndead();
    vines();
    worms();
    skeletons();
    // y?
    zombies();

    ancients();
    birds();
    canids();
    greaterDragons();
    elementals();
    faeFolk();
    golems();
    hybrids();
    insubstantials();
    // J?
    krakens();
    lichs();
    hydras();
    demons();
    ogres();
    giants();
    quest();
    reptiles();
    snakes();
    trolls();
    majorUndead();
    vampires();
    wraiths();
    xorns();
    // Y?
    serpents();

    finishBreed();

    // Now that all the breeds are defined, link up the cyclic references.
    BreedRef.resolve(breeds.find);
  }
}
