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
