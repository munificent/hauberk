import 'package:hauberk/src/engine.dart';
import 'package:test/test.dart';

void main() {
  group('Object.fmt()', () {
    test('no arguments', () {
      expect('abcdef'.fmt(), 'abcdef');
    });

    test('width', () {
      expect('abcdef'.fmt(w: 0), 'abcdef');
      expect('abcdef'.fmt(w: 4), 'abcdef');

      // Aligns left.
      expect('abcdef'.fmt(w: 11), 'abcdef     ');
      expect(true.fmt(w: 11), 'true       ');
    });
  });

  group('int.fmt()', () {
    test('no arguments', () {
      expect(123.fmt(), '123');
    });

    test('width', () {
      expect((-123).fmt(w: 0), '-123');
      expect(123.fmt(w: 0), '123');
      expect((-123).fmt(w: 4), '-123');
      // Aligns right.
      expect(123.fmt(w: 4), ' 123');
      expect((-123).fmt(w: 11), '       -123');
      expect(123.fmt(w: 11), '        123');
    });
  });

  group('num.fmt()', () {
    test('no arguments', () {
      expect((12.34).fmt(), '12.34');
    });

    test('width', () {
      expect(12.34.fmt(w: 0), '12.34');
      expect(12.34.fmt(w: 4), '12.34');
      // Aligns right.
      expect(12.34.fmt(w: 11), '      12.34');
    });

    test('digits', () {
      expect(123.4567.fmt(d: 0), '123');
      expect(123.4567.fmt(d: 1), '123.5');
      expect(123.4567.fmt(d: 2), '123.46');
      expect(123.4567.fmt(d: 3), '123.457');
      expect(123.4567.fmt(d: 4), '123.4567');
      expect(123.4567.fmt(d: 5), '123.45670');
      expect(123.4567.fmt(d: 6), '123.456700');
    });

    test('width and digits', () {
      expect(123.4567.fmt(w: 4, d: 2), '123.46');
      expect(123.4567.fmt(w: 8, d: 2), '  123.46');
      expect(123.4567.fmt(w: 8, d: 3), ' 123.457');
      expect(123.4567.fmt(w: 8, d: 6), '123.456700');
      expect(123.4567.fmt(w: 12, d: 6), '  123.456700');
    });
  });

  group('num.fmtPercent()', () {
    test('no arguments', () {
      expect(123.fmtPercent(), '12300%');
      expect(0.123.fmtPercent(), '12.3%');
      expect(4.5.fmtPercent(), '450.0%');
      expect((-0.45).fmtPercent(), '-45.0%');
    });

    test('width', () {
      expect(.12345.fmtPercent(w: 6, d: 0), '   12%');
      expect(.12345.fmtPercent(w: 6, d: 1), ' 12.3%');
      expect(.12345.fmtPercent(w: 6, d: 2), '12.35%');
      expect(.12345.fmtPercent(w: 6, d: 3), '12.345%');
      expect(.12345.fmtPercent(w: 6, d: 4), '12.3450%');
      expect(.12345.fmtPercent(w: 12, d: 4), '    12.3450%');
    });

    test('digits', () {
      expect(.12345.fmtPercent(d: 0), '12%');
      expect(.12345.fmtPercent(d: 1), '12.3%');
      expect(.12345.fmtPercent(d: 2), '12.35%');
      expect(.12345.fmtPercent(d: 3), '12.345%');
      expect(.12345.fmtPercent(d: 4), '12.3450%');
    });

    test('width and digits', () {
      expect(.12345.fmtPercent(w: 0, d: 0), '12%');
      expect(.12345.fmtPercent(w: 0, d: 2), '12.35%');
      expect(.12345.fmtPercent(w: 0, d: 4), '12.3450%');

      expect(.12345.fmtPercent(w: 2, d: 0), '12%');
      expect(.12345.fmtPercent(w: 2, d: 2), '12.35%');
      expect(.12345.fmtPercent(w: 2, d: 4), '12.3450%');

      expect(.12345.fmtPercent(w: 4, d: 0), ' 12%');
      expect(.12345.fmtPercent(w: 4, d: 2), '12.35%');
      expect(.12345.fmtPercent(w: 4, d: 4), '12.3450%');

      expect(.12345.fmtPercent(w: 8, d: 0), '     12%');
      expect(.12345.fmtPercent(w: 8, d: 2), '  12.35%');
      expect(.12345.fmtPercent(w: 8, d: 4), '12.3450%');
    });
  });
}
