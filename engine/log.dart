/// The message log.
class Log {
  static String makeVerbsAgree(String text, int person) {
    final optionalSuffix = const RegExp(@'\[(\w+?)\]');
    final irregular = const RegExp(@"\[([^|]+)\|([^\]]+)\]");

    // Handle verbs with optional suffixes like `close[s]`.
    while (true) {
      final match = optionalSuffix.firstMatch(text);
      if (match == null) break;

      final before = text.substring(0, match.start());
      final after = text.substring(match.end());
      if (person == 2) {
        // Omit the optional part.
        text = '$before$after';
      } else {
        // Include the optional part.
        text = '$before${match[1]}$after';
      }
    }

    // Handle irregular verbs like `[are|is]`.
    while (true) {
      final match = irregular.firstMatch(text);
      if (match == null) break;

      final before = text.substring(0, match.start());
      final after = text.substring(match.end());
      if (person == 2) {
        // Use the first form.
        text = '$before${match[1]}$after';
      } else {
        // Use the second form.
        text = '$before${match[2]}$after';
      }
    }

    return text;
  }

  static final MAX_MESSAGES = 6;

  final Queue<Message> messages;

  Log() : messages = new Queue<Message>();

  void add(String message, [Noun noun1, Noun noun2, Noun noun3]) {
    message = formatSentence(message, noun1, noun2, noun3);

    // See if it's a repeat of the last message.
    if (messages.length > 0) {
      final last = messages.last();
      if (last.text == message) {
        // It is, so just repeat the count.
        last.count++;
        return;
      }
    }

    // It's a new message.
    messages.add(new Message(message));
    if (messages.length > MAX_MESSAGES) messages.removeFirst();
  }

  /// The same message can apply to a variety of subjects and objects, and it
  /// may use pronouns of various forms. For example, a hit action may want to
  /// be able to say:
  ///
  /// * You hit the troll with your sword.
  /// * The troll hits you with its club.
  /// * The mermaid hits you with her fin.
  ///
  /// To avoid handling all of these cases at each message site, we use a simple
  /// formatting DSL that can handle pronouns, subject/verb agreement, etc.
  /// This function takes a format string and a series of nouns (numbered from
  /// 1 through 3 and creates an appropriately cases and tensed string.
  ///
  /// The following formatting is applied:
  ///
  /// ### Nouns: `{#}`
  ///
  /// A number inside curly braces expands to the name of that noun. For
  /// example, if noun 1 is a bat then `{1}` expands to `the bat`.
  ///
  /// ### Subjective pronouns: `{# he}`
  ///
  /// A number in curly brackets followed by `he` (with a space between)
  /// expands to the subjective pronoun for that noun. It takes into account
  /// the noun's person and gender. For example, if noun 2 is a mermaid then
  /// `{2 he}` expands to `she`.
  ///
  /// ### Objective pronouns: `{# him}`
  ///
  /// A number in curly brackets followed by `him` (with a space between)
  /// expands to the *objective* pronoun for that noun. It takes into account
  /// the noun's person and gender. For example, if noun 2 is a jelly then
  /// `{2 him}` expands to `it`.
  ///
  /// ### Possessive pronouns: `{# his}`
  ///
  /// A number in curly brackets followed by `his` (with a space between)
  /// expands to the possessive pronoun for that noun. It takes into account
  /// the noun's person and gender. For example, if noun 2 is a mermaid then
  /// `{2 his}` expands to `her`.
  ///
  /// ### Regular verbs: `[suffix]`
  ///
  /// A series of letters enclosed in square brackets defines an optional verb
  /// suffix. If noun 1 is second person, then the contents will be included.
  /// Otherwise they are omitted. For example, `open[s]` will result in `opens`
  /// if noun 1 is second-person (i.e. the [Hero]) or `open` if third-person.
  ///
  /// ### Irregular verbs: `[second|third]`
  ///
  /// Two words in square brackets separated by a pipe (`|`) defines an
  /// irregular verb. If noun 1 is second person that the first word is used,
  /// otherwise the second is. For example `[are|is]` will result in `are` if
  /// noun 1 is second-person (i.e. the [Hero]) or `is` if third-person.
  ///
  /// ### Sentence case
  ///
  /// Finally, the first letter in the result will be capitalized to properly
  /// sentence case it.
  String formatSentence(String text, [Noun noun1, Noun noun2, Noun noun3]) {
    var result = text;

    final nouns = [noun1, noun2, noun3];
    for (int i = 1; i <= 3; i++) {
      final noun = nouns[i - 1];

      if (noun != null) {
        result = result.replaceAll('{$i}', noun.nounText);

        // Handle pronouns.
        if (noun.person == 2) {
          result = result.replaceAll('{$i he}', 'you');
          result = result.replaceAll('{$i him}', 'you');
          result = result.replaceAll('{$i his}', 'your');
        } else {
          result = result.replaceAll('{$i he}', noun.gender.subjective);
          result = result.replaceAll('{$i him}', noun.gender.objective);
          result = result.replaceAll('{$i his}', noun.gender.possessive);
        }
      }
    }

    // Make the verb match the subject (which is assumed to be the first noun).
    if (noun1 != null) {
      result = Log.makeVerbsAgree(result, noun1.person);
    }

    // Sentence case it by capitalizing the first letter.
    return '${result[0].toUpperCase()}${result.substring(1)}';
  }
}

class Noun {
  final String nounText;
  int get person() => 3;
  Gender get gender() => Gender.NEUTER;

  Noun(this.nounText);
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

/// A single log entry.
class Message {
  final String text;

  /// The number of times this message has been repeated.
  int count = 1;

  Message(this.text);
}

