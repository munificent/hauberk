/// The message log.
class Log {
  /// Given a noun pattern, returns the unquantified singular form of it.
  /// Examples:
  ///
  /// ```
  /// singular("dog");           // "dog"
  /// singular("dogg[y|ies]");   // "doggy"
  /// singular("cockroach[es]"); // "cockroach"
  /// ```
  static String singular(String text) => _categorize(text, isFirst: true);

  /// Conjugates the verb pattern in [text] to agree with [pronoun].
  static String conjugate(String text, Pronoun pronoun) {
    var isFirst = pronoun == Pronoun.you || pronoun == Pronoun.they;
    return _categorize(text, isFirst: isFirst);
  }

  /// Quantifies the noun pattern in [text] to create a noun phrase for that
  /// number. Examples:
  ///
  /// ```
  /// quantify("bunn[y|ies]", 1); // -> "a bunny"
  /// quantify("bunn[y|ies]", 2); // -> "2 bunnies"
  /// quantify("bunn[y|ies]", 2); // -> "2 bunnies"
  /// quantify("(a) unicorn", 1); // -> "a unicorn"
  /// quantify("ocelot", 1);      // -> "an ocelot"
  /// ```
  ///
  /// If [article] is false, then omits the "a"/"an" if the count is 1.
  static String quantify(String text, int count) {
    String quantity;
    if (count == 1) {
      // Handle irregular nouns that start with a vowel but use "a", like
      // "a unicorn".
      if (text.startsWith("(a) ")) {
        quantity = "a";
        text = text.substring(4);
      } else if ("aeiouAEIOU".contains(text[0])) {
        quantity = "an";
      } else {
        quantity = "a";
      }
    } else {
      quantity = count.toString();
    }

    return "$quantity ${_categorize(text, isFirst: count == 1, force: true)}";
  }

  /// Quantifies the noun pattern in [text] to create a noun phrase for that
  /// number. Examples:
  ///
  /// ```
  /// quantify("bunn[y|ies]", 1); // -> "bunny"
  /// quantify("bunn[y|ies]", 2); // -> "2 bunnies"
  /// quantify("bunn[y|ies]", 2); // -> "2 bunnies"
  /// quantify("(a) unicorn", 1); // -> "unicorn"
  /// quantify("ocelot", 1);      // -> "ocelot"
  /// ```
  ///
  /// Unlike [quantify()], omits the article.
  ///
  /// If [article] is false, then omits the "a"/"an" if the count is 1.
  static String quantifyWithoutArticle(String text, int count) {
    if (count == 1) {
      // Strip off the article from text with an explicit one.
      if (text.startsWith("(a) ")) {
        text = text.substring(4);
      }
      return _categorize(text, isFirst: true, force: true);
    } else {
      return "$count ${_categorize(text, isFirst: false, force: true)}";
    }
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

  void message(String message, [Noun? noun1, Noun? noun2, Noun? noun3]) {
    add(LogType.message, message, noun1, noun2, noun3);
  }

  void error(String message, [Noun? noun1, Noun? noun2, Noun? noun3]) {
    add(LogType.error, message, noun1, noun2, noun3);
  }

  void quest(String message, [Noun? noun1, Noun? noun2, Noun? noun3]) {
    add(LogType.quest, message, noun1, noun2, noun3);
  }

  void gain(String message, [Noun? noun1, Noun? noun2, Noun? noun3]) {
    add(LogType.gain, message, noun1, noun2, noun3);
  }

  void help(String message, [Noun? noun1, Noun? noun2, Noun? noun3]) {
    add(LogType.help, message, noun1, noun2, noun3);
  }

  void cheat(String message, [Noun? noun1, Noun? noun2, Noun? noun3]) {
    add(LogType.cheat, message, noun1, noun2, noun3);
  }

  void add(LogType type, String message,
      [Noun? noun1, Noun? noun2, Noun? noun3]) {
    message = _format(message, noun1, noun2, noun3);

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
  String _format(String text, [Noun? noun1, Noun? noun2, Noun? noun3]) {
    var result = text;

    var nouns = [noun1, noun2, noun3];
    for (var i = 1; i <= 3; i++) {
      var noun = nouns[i - 1];

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
      result = Log.conjugate(result, noun1.pronoun);
    }

    // Sentence case it by capitalizing the first letter.
    return '${result[0].toUpperCase()}${result.substring(1)}';
  }

  /// Parses a string and chooses one of two grammatical categories.
  ///
  /// If used for verbs, selects a verb form to agree with a subject. In that
  /// case, the first category is is for agreeing with a third-person singular
  /// noun ("it runs") and the second is for a second-person noun ("you run").
  ///
  /// If used for a noun, selects a number. The first category is singular
  /// ("knife") and the second is plural ("knives").
  ///
  /// Examples:
  ///
  /// ```
  /// _categorize("run[s]", isFirst: true)       // -> "run"
  /// _categorize("run[s]", isFirst: false)      // -> "runs"
  /// _categorize("bunn[y|ies]", isFirst: true)  // -> "bunny"
  /// _categorize("bunn[y|ies]", isFirst: false) // -> "bunnies"
  /// ```
  ///
  /// If [force] is `true`, then a trailing "s" will be added to the end if
  /// [isFirst] is `false` and [text] doesn't have any formatting.
  static String _categorize(String text,
      {required bool isFirst, bool force = false}) {
    var optionalSuffix = RegExp(r'\[(\w+?)\]');
    var irregular = RegExp(r'\[([^|]+)\|([^\]]+)\]');

    // If it's a regular word in second category, just add an "s".
    if (force && !isFirst && !text.contains("[")) return "${text}s";

    // Handle words with optional suffixes like `close[s]` and `sword[s]`.
    while (true) {
      var match = optionalSuffix.firstMatch(text);
      if (match == null) break;

      var before = text.substring(0, match.start);
      var after = text.substring(match.end);
      if (isFirst) {
        // Omit the optional part.
        text = '$before$after';
      } else {
        // Include the optional part.
        text = '$before${match[1]}$after';
      }
    }

    // Handle irregular words like `[are|is]` and `sta[ff|aves]`.
    while (true) {
      var match = irregular.firstMatch(text);
      if (match == null) break;

      var before = text.substring(0, match.start);
      var after = text.substring(match.end);
      if (isFirst) {
        // Use the first form.
        text = '$before${match[1]}$after';
      } else {
        // Use the second form.
        text = '$before${match[2]}$after';
      }
    }

    return text;
  }
}

class Noun {
  final String nounText;

  Pronoun get pronoun => Pronoun.it;

  Noun(this.nounText);

  @override
  String toString() => nounText;
}

class Pronoun {
  // See http://en.wikipedia.org/wiki/English_personal_pronouns.
  static const you = Pronoun('you', 'you', 'your');
  static const she = Pronoun('she', 'her', 'her');
  static const he = Pronoun('he', 'him', 'his');
  static const it = Pronoun('it', 'it', 'its');
  static const they = Pronoun('they', 'them', 'their');

  final String subjective;
  final String objective;
  final String possessive;

  const Pronoun(this.subjective, this.objective, this.possessive);
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

  /// Help or tutorial messages.
  cheat,
}

/// A single log entry.
class Message {
  final LogType type;
  final String text;

  /// The number of times this message has been repeated.
  int count;

  Message(this.type, this.text, [this.count = 1]);
}
