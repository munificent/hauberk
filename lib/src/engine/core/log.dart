import 'thing.dart';

/// The message log.
class Log {
  /// Conjugates the verb pattern in [text] to agree with [pronoun].
  ///
  /// Verbs are written like `run[s]` or `[is|are]. The first category is is
  /// for agreeing with a third-person singular noun ("it runs") and the second
  /// is for a second-person noun ("you run").
  static String conjugate(String text, Pronoun pronoun) {
    var first = switch (pronoun) {
      Pronoun.you || Pronoun.they => true,
      Pronoun.she || Pronoun.he || Pronoun.it => false,
    };

    return text.replaceAllMapped(_quantifier, (match) {
      var firstPart = match[1]!;
      if (match[3] case var secondPart?) {
        return first ? firstPart : secondPart;
      } else {
        // Only one part, so it's implicitly the plural part with an empty
        // string for the singular.
        return first ? '' : firstPart;
      }
    });
  }

  static List<String> wordWrap(int width, String text) {
    var lines = <String>[];
    var line = '';
    var wordStart = -1;

    void finishWord(int end) {
      if (wordStart == -1) return;

      if (line.isNotEmpty) line += ' ';
      line += text.substring(wordStart, end);
      wordStart = -1;
    }

    void finishLine() {
      lines.add(line);
      line = '';
    }

    for (var i = 0; i < text.length; i++) {
      switch (text[i]) {
        case ' ':
          finishWord(i);

        case '\n':
          finishWord(i);
          finishLine();
          wordStart = -1;

        case _:
          // Begin a new word here if we aren't already in one.
          if (wordStart == -1) wordStart = i;

          // Include the character we're currently processing.
          var wordLength = i - wordStart + 1;

          if (line.isEmpty && wordLength > width) {
            // The word is longer than a line, so character split it.
            finishWord(i);
            finishLine();
            wordStart = i;
          } else if (line.isNotEmpty && line.length + 1 + wordLength > width) {
            // There isn't room to append a space and the word to the current
            // line, so wrap before it.
            finishLine();
          }
      }
    }

    finishWord(text.length);
    if (line.isNotEmpty) finishLine();

    return lines;
  }

  static const _maxMessages = 100;

  final messages = <Message>[];

  void message(String message, [Thing? thing1, Thing? thing2, Thing? thing3]) {
    _add(LogType.message, message, thing1, thing2, thing3);
  }

  void error(String message, [Thing? thing1, Thing? thing2, Thing? thing3]) {
    _add(LogType.error, message, thing1, thing2, thing3);
  }

  void quest(String message, [Thing? thing1, Thing? thing2, Thing? thing3]) {
    _add(LogType.quest, message, thing1, thing2, thing3);
  }

  void gain(String message, [Thing? thing1, Thing? thing2, Thing? thing3]) {
    _add(LogType.gain, message, thing1, thing2, thing3);
  }

  void help(String message, [Thing? thing1, Thing? thing2, Thing? thing3]) {
    _add(LogType.help, message, thing1, thing2, thing3);
  }

  void debug(String message, [Thing? thing1, Thing? thing2, Thing? thing3]) {
    _add(LogType.debug, message, thing1, thing2, thing3);
  }

  void _add(
    LogType type,
    String message, [
    Thing? thing1,
    Thing? thing2,
    Thing? thing3,
  ]) {
    message = _format(message, thing1, thing2, thing3);

    // See if it's a repeat of the last message.
    if (messages.isNotEmpty) {
      var last = messages.last;
      if (last.text == message) {
        // It is, so just repeat the count.
        last.count++;
        return;
      }
    }

    // It's a new message.
    messages.add(Message(type, message));
    if (messages.length > _maxMessages) messages.removeAt(0);
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
  /// Otherwise they are omitted. For example, `open[s]` will result in `open`
  /// if noun 1 is second-person (i.e. the hero) or `opens` if third-person.
  ///
  /// ### Irregular verbs: `[second|third]`
  ///
  /// Two words in square brackets separated by a pipe (`|`) defines an
  /// irregular verb. If noun 1 is second person that the first word is used,
  /// otherwise the second is. For example `[are|is]` will result in `are` if
  /// noun 1 is second-person (i.e. the hero) or `is` if third-person.
  ///
  /// ### Sentence case
  ///
  /// Finally, the first letter in the result will be capitalized to properly
  /// sentence case it.
  String _format(String text, [Thing? thing1, Thing? thing2, Thing? thing3]) {
    var result = text;

    var things = [thing1, thing2, thing3];
    for (var i = 1; i <= 3; i++) {
      if (things[i - 1] case var thing?) {
        result = result.replaceAll('{$i}', thing.noun.indefinite);
        result = result.replaceAll('{the $i}', thing.noun.definite);

        // Handle pronouns.
        result = result.replaceAll('{$i he}', thing.noun.pronoun.subjective);
        result = result.replaceAll('{$i him}', thing.noun.pronoun.objective);
        result = result.replaceAll('{$i his}', thing.noun.pronoun.possessive);
      }
    }

    // Make the verb match the subject (which is assumed to be the first thing).
    if (thing1 != null) {
      result = Log.conjugate(result, thing1.noun.pronoun);
    }

    // Sentence case it by capitalizing the first letter.
    return '${result[0].toUpperCase()}${result.substring(1)}';
  }

  static final RegExp _quantifier = RegExp(
    r"\[" // Opening "[".
    r"([^|\]]+)" // First or only part inside square brackets.
    r"(\|([^\]]+))?" // Optional "|" followed by second part.
    r"\]", // Closing "]".
  );
}

enum LogType {
  /// Normal log messages.
  message,

  /// Messages when the player tries an invalid action.
  error,

  /// Messages related to the hero's quest.
  quest,

  /// Messages when the hero levels up or gains powers.
  gain,

  /// Help or tutorial messages.
  help,

  /// Internal debug messages for hacking on the game.
  debug,
}

/// A single log entry.
class Message {
  final LogType type;
  final String text;

  /// The number of times this message has been repeated.
  int count;

  Message(this.type, this.text, [this.count = 1]);
}
