library util.chain;

import 'dart:collection';

/// A doubly-linked list of nodes linked together into a ring.
class Chain<T> extends IterableBase<T> {
  Link<T> head;

  T get current => head.item;

  void add(T item) {
    if (head == null) {
      head = new Link<T>(item);
      return;
    }

    head.insertBefore(new Link<T>(item));
  }

  /// Removes the first occurence [item] from the chain. Returns `true` if the
  /// item was found and removed.
  bool remove(T item) {
    if (head == null) return false;

    var link = head;
    do {
      if (link.item == item) {
        link.remove();
        return true;
      }

      link = link.next;
    } while (link != head);

    return false;
  }

  void advance() {
    if (head == null) return;

    head = head.next;
  }

  Iterator<T> get iterator => new ChainIterator(head);
}

/// An [Iterator<T>] for iterating through a [Chain<T>].
class ChainIterator<T> implements Iterator<T> {
  Link<T> _current;
  Link<T> _last;

  ChainIterator(this._current);

  T get current => _current.item;

  bool moveNext() {
    // Stop if we've looped around.
    if (_current == _last) return false;

    // Now see if we're before the first iteration (where _last will be null).
    if (_last == null) _last = _current;

    _current = _current.next;
    return true;
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
