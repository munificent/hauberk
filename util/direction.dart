class Direction extends Vec {
  static final NONE = const Direction(0, 0);
  static final N  = const Direction(0, -1);
  static final NE = const Direction(1, -1);
  static final E  = const Direction(1, 0);
  static final SE = const Direction(1, 1);
  static final S  = const Direction(0, 1);
  static final SW = const Direction(-1, 1);
  static final W  = const Direction(-1, 0);
  static final NW = const Direction(-1, -1);

  const Direction(int x, int y) : super(x, y);

  Direction get rotateLeft45() {
    switch (this) {
      case NONE: return NONE;
      case N: return NW;
      case NE: return N;
      case E: return NE;
      case SE: return E;
      case S: return SE;
      case SW: return S;
      case W: return SW;
      case NW: return W;
    }
  }

  Direction get rotateRight45() {
    switch (this) {
      case NONE: return NONE;
      case N: return NE;
      case NE: return E;
      case E: return SE;
      case SE: return S;
      case S: return SW;
      case SW: return W;
      case W: return NW;
      case NW: return N;
    }
  }

  Direction get rotateLeft90() {
    switch (this) {
      case NONE: return NONE;
      case N: return W;
      case NE: return NW;
      case E: return N;
      case SE: return NE;
      case S: return E;
      case SW: return SE;
      case W: return S;
      case NW: return SW;
    }
  }

  Direction get rotateRight90() {
    switch (this) {
      case NONE: return NONE;
      case N: return E;
      case NE: return SE;
      case E: return S;
      case SE: return SW;
      case S: return W;
      case SW: return NW;
      case W: return N;
      case NW: return NE;
    }
  }

  Direction get rotate180() {
    switch (this) {
      case NONE: return NONE;
      case N: return S;
      case NE: return SW;
      case E: return W;
      case SE: return NW;
      case S: return N;
      case SW: return NE;
      case W: return E;
      case NW: return SE;
    }
  }
}
