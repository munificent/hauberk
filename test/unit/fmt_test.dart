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
      expect((-123).fmt(), '-123');
    });

    test('comma separators', () {
      expect(1234.fmt(), '1,234');
      expect(12345.fmt(), '12,345');
      expect(123456.fmt(), '123,456');
      expect(1234567.fmt(), '1,234,567');
      expect(12345678.fmt(), '12,345,678');
      expect(123456789.fmt(), '123,456,789');
      expect(1234567891.fmt(), '1,234,567,891');
      expect(12345678912.fmt(), '12,345,678,912');
      expect(123456789123.fmt(), '123,456,789,123');
      expect(1234567891234.fmt(), '1,234,567,891,234');
      expect(12345678912345.fmt(), '12,345,678,912,345');
      expect(123456789123456.fmt(), '123,456,789,123,456');
      expect(1234567891234567.fmt(), '1,234,567,891,234,567');
      expect(12345678912345678.fmt(), '12,345,678,912,345,678');

      expect((-1234).fmt(), '-1,234');
      expect((-12345).fmt(), '-12,345');
      expect((-123456).fmt(), '-123,456');
      expect((-1234567).fmt(), '-1,234,567');
      expect((-12345678).fmt(), '-12,345,678');
      expect((-123456789).fmt(), '-123,456,789');
      expect((-1234567891).fmt(), '-1,234,567,891');
      expect((-12345678912).fmt(), '-12,345,678,912');
      expect((-123456789123).fmt(), '-123,456,789,123');
      expect((-1234567891234).fmt(), '-1,234,567,891,234');
      expect((-12345678912345).fmt(), '-12,345,678,912,345');
      expect((-123456789123456).fmt(), '-123,456,789,123,456');
      expect((-1234567891234567).fmt(), '-1,234,567,891,234,567');
      expect((-12345678912345678).fmt(), '-12,345,678,912,345,678');
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

    test('sign', () {
      expect(123.fmt(sign: true), '+123');
      expect(0.fmt(sign: true), '0');
      expect((-1).fmt(sign: true), '-1');
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
      expect(0.123.fmtPercent(), '12%');
      expect(4.5.fmtPercent(), '450%');
      expect((-0.45).fmtPercent(), '-45%');
    });

    test('width', () {
      expect(.12345.fmtPercent(w: 0), '12%');
      expect(.12345.fmtPercent(w: 2), '12%');
      expect(.12345.fmtPercent(w: 4), ' 12%');
      expect(.12345.fmtPercent(w: 8), '     12%');
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
