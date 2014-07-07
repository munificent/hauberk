library hauberk.engine.log;

import 'dart:collection';

/// The message log.
class Log {
  /// Parses strings that have singular and plural options and selects one of
  /// the two. Examples:
  ///
  ///     parsePlural("nothing", isPlural: false)     // "nothing"
  ///     parsePlural("nothing", isPlural: true)      // "nothing"
  ///     parsePlural("run[s]", isPlural: false)      // "run"
  ///     parsePlural("run[s]", isPlural: true)       // "runs"
  ///     parsePlural("bunn[y|ies]", isPlural: false) // "bunny"
  ///     parsePlural("bunn[y|ies]", isPlural: true)  // "bunnies"
  ///
  /// If [forcePlural] is `true`, then a trailing "s" will be added to the end
  /// if [isPlural] is `true` and [text] doesn't have any formatting.
  static String parsePlural(String text,
                            {bool isPlural, bool forcePlural: false}) {
    var optionalSuffix = new RegExp(r'\[(\w+?)\]');
    var irregular = new RegExp(r'\[([^|]+)\|([^\]]+)\]');

    // If it's a regular plural word, just add an "s".
    if (forcePlural == true && isPlural == true && !text.contains("[")) {
      return "${text}s";
    }

    // Handle verbs with optional suffixes like `close[s]`.
    while (true) {
      var match = optionalSuffix.firstMatch(text);
      if (match == null) break;

      var before = text.substring(0, match.start);
      var after = text.substring(match.end);
      if (isPlural) {
        // Include the optional part.
        text = '$before${match[1]}$after';
      } else {
        // Omit the optional part.
        text = '$before$after';
      }
    }

    // Handle irregular verbs like `[are|is]`.
    while (true) {
      var match = irregular.firstMatch(text);
      if (match == null) break;

      var before = text.substring(0, match.start);
      var after = text.substring(match.end);
      if (isPlural) {
        // Use the second form.
        text = '$before${match[2]}$after';
      } else {
        // Use the first form.
        text = '$before${match[1]}$after';
      }
    }

    return text;
  }

  static String makeVerbsAgree(String text, Pronoun pronoun) {
    var isPlural = pronoun != Pronoun.YOU && pronoun != Pronoun.THEY;
    return parsePlural(text, isPlural: isPlural);
  }

  static const MAX_MESSAGES = 6;

  final Queue<Message> messages;

  Log() : messages = new Queue<Message>();

  void message(String message, [Noun noun1, Noun noun2, Noun noun3]) {
    add(LogType.MESSAGE, message, noun1, noun2, noun3);
  }

  void error(String message, [Noun noun1, Noun noun2, Noun noun3]) {
    add(LogType.ERROR, message, noun1, noun2, noun3);
  }

  void quest(String message, [Noun noun1, Noun noun2, Noun noun3]) {
    add(LogType.QUEST, message, noun1, noun2, noun3);
  }

  void gain(String message, [Noun noun1, Noun noun2, Noun noun3]) {
    add(LogType.GAIN, message, noun1, noun2, noun3);
  }

  void help(String message, [Noun noun1, Noun noun2, Noun noun3]) {
    add(LogType.HELP, message, noun1, noun2, noun3);
  }

  void add(LogType type, String message, [Noun noun1, Noun noun2, Noun noun3]) {
    message = formatSentence(message, noun1, noun2, noun3);

    // See if it's a repeat of the last message.
    if (messages.length > 0) {
      final last = messages.last;
      if (last.text == message) {
        // It is, so just repeat the count.
        last.count++;
        return;
      }
    }

    // It's a new message.
    messages.add(new Message(type, message));
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
        result = result.replaceAll('{$i he}', noun.pronoun.subjective);
        result = result.replaceAll('{$i him}', noun.pronoun.objective);
        result = result.replaceAll('{$i his}', noun.pronoun.possessive);
      }
    }

    // Make the verb match the subject (which is assumed to be the first noun).
    if (noun1 != null) {
      result = Log.makeVerbsAgree(result, noun1.pronoun);
    }

    // Sentence case it by capitalizing the first letter.
    return '${result[0].toUpperCase()}${result.substring(1)}';
  }
}

class Noun {
  final String nounText;
  Pronoun get pronoun => Pronoun.IT;

  Noun(this.nounText);

  String toString() => nounText;
}

/// A noun-like thing that can be quantified.
abstract class Quantifiable {
  String get singular;
  String get plural;
  Pronoun get pronoun;
}

/// A [Noun] for a specific quantity of some thing.
class Quantity implements Noun {
  final int count;
  final Quantifiable _object;

  String get nounText {
    // TODO: a/an.
    if (count == 1) return "a ${_object.singular}";

    var quantity;
    switch (count) {
      case 2: quantity = "two"; break;
      case 3: quantity = "three"; break;
      case 4: quantity = "four"; break;
      case 5: quantity = "five"; break;
      case 6: quantity = "six"; break;
      case 7: quantity = "seven"; break;
      case 8: quantity = "eight"; break;
      case 9: quantity = "nine"; break;
      case 10: quantity = "ten"; break;
      default:
        quantity = count.toString();
    }

    return "$quantity ${_object.plural}";
  }

  Pronoun get pronoun => count == 1 ? _object.pronoun : Pronoun.THEY;

  Quantity(this.count, this._object);
}

class Pronoun {
  // See http://en.wikipedia.org/wiki/English_personal_pronouns.
  static final YOU  = const Pronoun('you',  'you',  'your');
  static final SHE  = const Pronoun('she',  'her',  'her');
  static final HE   = const Pronoun('he',   'him',  'his');
  static final IT   = const Pronoun('it',   'it',   'its');
  static final THEY = const Pronoun('they', 'them', 'their');

  final String subjective;
  final String objective;
  final String possessive;

  const Pronoun(this.subjective, this.objective, this.possessive);
}

class LogType {
  /// Normal log messages.
  static const MESSAGE = const LogType._("MESSAGE");

  /// Messages when the player tries an invalid action.
  static const ERROR = const LogType._("ERROR");

  /// Messages related to the hero's quest.
  static const QUEST = const LogType._("QUEST");

  /// Messages when the hero levels up or gains powers.
  static const GAIN = const LogType._("GAIN");

  /// Help or tutorial messages.
  static const HELP = const LogType._("HELP");

  final String _name;
  const LogType._(this._name);

  String toString() => _name;
}

/// A single log entry.
class Message {
  final LogType type;
  final String text;

  /// The number of times this message has been repeated.
  int count = 1;

  Message(this.type, this.text);
}

