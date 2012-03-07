/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  // TODO(bob): Let user specify.
  final Gender gender = Gender.MALE;

  Hero(Game game, int x, int y) : super(game, x, y);

  Action nextAction;

  bool get needsInput() => nextAction == null;

  void getAction() {
    final action = nextAction;
    nextAction = null;
    return action;
  }

  String get nounText() => 'you';
  int get person() => 2;
}

class Gender {
  // See http://en.wikipedia.org/wiki/English_personal_pronouns.
  static final FEMALE = const Gender('she', 'her', 'her');
  static final MALE   = const Gender('he',  'him', 'his');
  static final NEUTER = const Gender('it',  'it',  'its');

  final String subjective;
  final String objective;
  final String possessive;

  const Gender(this.subjective, this.objective, this.possessive);
}