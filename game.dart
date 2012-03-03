/// Root class for the game engine. All game state is contained within this.
class Game {
  final Level        level;
  final Chain<Actor> actors;
  final List<Effect> effects;

  final Hero hero;

  Game()
  : level = new Level(90, 30),
    actors = new Chain<Actor>(),
    effects = <Effect>[],
    hero = new Hero(3, 4)
  {
    actors.add(hero);

    for (int i = 0; i < 30; i++) {
      actors.add(new Beetle(i + 10, 9));
      actors.add(new Beetle(i + 10, 10));
      actors.add(new Beetle(i + 10, 8));
      actors.add(new Beetle(i + 10, 11));
    }
  }

  GameResult update() {
    /*
    effects.clear();

    if (action != null) {
      action.update();
      return;
    }
    */

    while (true) {
      if (actors.current.canTakeTurn && actors.current.needsInput) {
        return const GameResult(needInput: true, needPause: false);
      }

      if (actors.current.gainEnergy()) {
        // TODO(bob): Double check here is gross.
        if (actors.current.needsInput) {
          return const GameResult(needInput: true, needPause: false);
        }

        final action = actors.current.takeTurn();
        action.perform(this, actors.current);
        actors.advance();
      }
    }
  }
}

class GameResult {
  final bool needInput;
  final bool needPause;

  const GameResult([this.needInput, this.needPause]);
}

/// A doubly-linked list of nodes linked together into a ring.
class Chain<T> implements Iterable<T> {
  Link<T> head;

  T get current() => head.item;

  void add(T item) {
    if (head == null) {
      head = new Link<T>(item);
      return;
    }

    head.insertBefore(new Link<T>(item));
  }

  void advance() {
    if (head == null) return;

    head = head.next;
  }

  Iterator<T> iterator() => new ChainIterator(head);
}

/// An [Iterator<T>] for iterating through a [Chain<T>].
class ChainIterator<T> {
  Link<T> _current;
  Link<T> _last;

  ChainIterator(this._current);

  bool hasNext() {
    return _current != _last;
  }

  T next() {
    if (_last == null) _last = _current;

    _current = _current.next;
    return _current.item;
  }
}

/// One link in a [Chain<T>].
class Link<T> {
  final T item;
  Link<T> prev;
  Link<T> next;

  Link(this.item) {
    prev = this;
    next = this;
  }

  void insertBefore(Link<T> other) {
    other.prev = prev;
    other.next = this;

    prev.next = other;
    prev = other;
  }

  void insertAfter(Link<T> other) {
    other.prev = this;
    other.next = next;

    next.prev = other;
    next = other;
  }

  void remove() {
    // Link the other items around this one.
    prev.next = next;
    next.prev = prev;

    // Make this item now a chain by itself.
    prev = this;
    next = this;
  }
}

/// A two-dimensional point.
class Pt {
  final int x;
  final int y;

  const Pt(this.x, this.y);

  Pt operator +(Pt other) => new Pt(x + other.x, y + other.y);
  Pt operator -(Pt other) => new Pt(x - other.x, y - other.y);
}

class Effect {
  final Pt pos;
}

class Action {
  void perform(Game game, Actor actor) {}
}

class MoveAction extends Action {
  final Pt offset;

  MoveAction(this.offset);

  void perform(Game game, Actor actor) {
    actor.pos += offset;
  }
}