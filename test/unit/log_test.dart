import 'package:hauberk/src/engine/core/log.dart';
import 'package:test/test.dart';

void main() {
  group('Log.wordWrap()', () {
    testWordWrap(String label, String input, List<String> expected) {
      test(label, () {
        expect(Log.wordWrap(20, input), equals(expected));
      });
    }

    testWordWrap('empty', '', <String>[]);
    testWordWrap('no wrapping', 'no wrapping', ['no wrapping']);

    testWordWrap(
      'split at last word',
      'first second third fourth fifth sixth',
      [
        'first second third',
        'fourth fifth sixth',
      ],
    );

    testWordWrap(
      'multiple lines',
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
          'tempor incididunt ut labore et dolore magna aliqua. Ut enim ad '
          'minim veniam, quis nostrud exercitation ullamco laboris nisi ut '
          'aliquip ex ea commodo consequat.',
      [
        'Lorem ipsum dolor',
        'sit amet,',
        'consectetur',
        'adipiscing elit, sed',
        'do eiusmod tempor',
        'incididunt ut labore',
        'et dolore magna',
        'aliqua. Ut enim ad',
        'minim veniam, quis',
        'nostrud exercitation',
        'ullamco laboris nisi',
        'ut aliquip ex ea',
        'commodo consequat.',
      ],
    );

    testWordWrap(
      'collapse spaces',
      '  first    second  third      fourth    fifth        sixth     ',
      [
        'first second third',
        'fourth fifth sixth',
      ],
    );

    testWordWrap(
      'no split from trailing spaces',
      'no word wrapping      ',
      ['no word wrapping'],
    );

    testWordWrap(
      'explicit newlines',
      'first\nsecond third\n\nfourth fifth sixth seventh eigth',
      ['first', 'second third', '', 'fourth fifth sixth', 'seventh eigth'],
    );

    testWordWrap(
      'explicit newlines after wrapped line',
      'first second third fourth fifth\n\nsixth seventh eigth',
      ['first second third', 'fourth fifth', '', 'sixth seventh eigth'],
    );

    testWordWrap(
      'wrap at character if no spaces',
      'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz',
      [
        'abcdefghijklmnopqrst',
        'uvwxyz0123456789abcd',
        'efghijklmnopqrstuvwx',
        'yz'
      ],
    );
  });
}
