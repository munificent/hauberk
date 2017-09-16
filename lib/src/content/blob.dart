import 'package:piecemeal/piecemeal.dart';

class Blob {
  // TODO: This may generate unconnected regions. Decide if that's OK or not.

  /// Generate a blob inside a 16x16 bounding box.
  static Array2D<bool> make16() {
    var blob = new Blob._(8, 1);
    blob = new Blob._(16, 3, blob);
    return blob._cells;
  }

  /// Generate a blob inside a 32x32 bounding box.
  static Array2D<bool> make32() {
    var blob = new Blob._(8, 1);
    blob = new Blob._(16, 2, blob);
    blob = new Blob._(32, 5, blob);
    return blob._cells;
  }

  /// Generate a blob inside a 64x64 bounding box.
  static Array2D<bool> make64() {
    var blob = new Blob._(8, 2);
    blob = new Blob._(16, 2, blob);
    blob = new Blob._(32, 2, blob);
    blob = new Blob._(64, 6, blob);
    return blob._cells;
  }

  Array2D<bool> _cells;
  Array2D<bool> _dest;

  Blob._(int size, int smoothing, [Blob input])
  : _cells = new Array2D(size, size, false),
    _dest = new Array2D(size, size, false) {
    if (input != null) {
      // Generate noise based on the input blob but scaled up x2. Doing this
      // repeatedly lets us generate larger structure than you tend to get
      // otherwise.

      // Must scale from exactly a half size.
      assert(input._cells.width == size ~/ 2);

      for (var pos in _cells.bounds.inflate(-1)) {
        var value = input._cells.get(pos.x ~/ 2, pos.y ~/ 2) ? 0.3 : 0.7;
        _cells[pos] = rng.float(1.0) > value;
      }
    } else {
      // Fill with noise weighted towards the center to generate a single
      // blob in the middle.
      var center = _cells.bounds.center;
      var maxLength = (_cells.bounds.topLeft - _cells.bounds.center).length;
      for (var pos in _cells.bounds.inflate(-1)) {
        var distance = (pos - center).length / maxLength;

        _cells[pos] = rng.float(1.0) > distance;
      }
    }

    for (var i = 0; i < smoothing; i++) {
      for (var pos in _cells.bounds.inflate(-1)) {
        var walls = Direction.all.where((dir) => _cells[pos + dir]).length;
        if (_cells[pos]) walls++;

        _dest[pos] = walls >= 5;
      }

      // Swap the buffers.
      var temp = _cells;
      _cells = _dest;
      _dest = temp;
    }
  }
}
