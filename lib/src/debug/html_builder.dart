import 'dart:js_interop';

import 'package:web/web.dart' as web;

class HtmlBuilder {
  final StringBuffer _buffer = StringBuffer();

  /// Whether we need to start a new `<tr>` before the next `<td>` is written.
  bool _needsRow = false;

  void h2(String text) {
    _buffer.writeln('<h2>$text</h2>');
  }

  void table() {
    _tag('table');
    // Implicitly start a head and row in it.
    thead();
  }

  void thead() {
    _tag('thead');
    _needsRow = true;
  }

  void tbody() {
    _finishTr();
    _end('thead');
    _tag('tbody');
    _needsRow = true;
  }

  void tbodyEnd() {
    _finishTr();
    _end('tbody');
  }

  void tableEnd() {
    tbodyEnd();
    _end('table');
  }

  void td(Object contents, {bool? right, Object? width, int? colspan}) {
    // Numbers default to right justification.
    tdBegin(right: right ?? contents is num, width: width, colspan: colspan);
    write(contents.toString());
    tdEnd();
  }

  void tdBegin({bool right = false, Object? width, int? colspan}) {
    if (_needsRow) {
      _tag('tr');
      _needsRow = false;
    }

    _tag(
      'td',
      cssClass: right ? 'r' : null,
      width: width,
      attributes: {if (colspan != null) 'colspan': colspan},
    );
  }

  void tdEnd() {
    _end('td');
  }

  void trEnd() {
    // Complete the current row.
    _finishTr();

    // Start a new one if more cells are written.
    _needsRow = true;
  }

  void write(String text) {
    _buffer.write(text);
  }

  void writeln(String text) {
    _buffer.writeln(text);
  }

  void appendToBody() {
    web.document
        .querySelector('body')!
        .insertAdjacentHTML('beforeend', _buffer.toString().toJS);
  }

  void replaceContents(String selector) {
    web.document.querySelector(selector)!.innerHTML = _buffer.toString().toJS;
  }

  @override
  String toString() => _buffer.toString();

  void _tag(
    String tag, {
    Map<String, Object>? attributes,
    String? cssClass,
    Object? width,
  }) {
    if (width is num) width = '${width}px';
    if (width is! String?) {
      throw ArgumentError('Width must be number or String.');
    }

    _buffer.write('<$tag');

    if (cssClass != null) _buffer.write(' class=$cssClass');
    if (width != null) _buffer.write(' style="width: $width;"');

    if (attributes != null) {
      attributes.forEach((name, value) {
        _buffer.write(' $name=$value');
      });
    }

    _buffer.write('>');
  }

  void _end(String tag) {
    _buffer.writeln('</$tag>');
  }

  void _finishTr() {
    if (!_needsRow) _end('tr');
  }
}
