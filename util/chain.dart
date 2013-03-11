part of util;

/// A doubly-linked list of nodes linked together into a ring.
class Chain<T> implements Iterable<T> {
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

  // TODO(bob): Use a mixin when available.
  int get length {
    throw new UnimplementedError();
  }
  bool get isEmpty => IterableMixinWorkaround.isEmpty(this);
  T get first => IterableMixinWorkaround.first(this);
  T get last => IterableMixinWorkaround.last(this);
  T get single => IterableMixinWorkaround.single(this);
  Iterable<T> map(f(T element)) => IterableMixinWorkaround.map(this, f);
  // TODO(bob): Remove when removed from Iterable.
  Iterable<T> mappedBy(f(T element)) => IterableMixinWorkaround.map(this, f);
  Iterable<T> where(bool test(T element)) => IterableMixinWorkaround.where(this, test);
  Iterable expand(f(T element)) => IterableMixinWorkaround.expand(this, f);
  bool contains(T element) => IterableMixinWorkaround.contains(this, element);
  void forEach(void f(T o)) => IterableMixinWorkaround.forEach(this, f);
  bool any(bool f(T o)) => IterableMixinWorkaround.any(this, f);
  bool every(bool f(T o)) => IterableMixinWorkaround.every(this, f);
  reduce(seed, f(accumulator, T o)) => IterableMixinWorkaround.reduce(this, seed, f);
  String join([String separator]) => IterableMixinWorkaround.join(this, separator);
  List<T> toList({bool growable: true}) => new List.from(this, growable: growable);
  Set<T> toSet() => new Set.from(this);
  T min([int compare(T a, T b)]) => IterableMixinWorkaround.min(this, compare);
  T max([int compare(T a, T b)]) => IterableMixinWorkaround.max(this, compare);
  Iterable<T> take(int n) {
    throw new UnimplementedError();
  }
  Iterable<T> takeWhile(bool test(T value)) => IterableMixinWorkaround.takeWhile(this, test);
  Iterable<T> skip(int n) {
    throw new UnimplementedError();
  }
  Iterable<T> skipWhile(bool test(T value)) => IterableMixinWorkaround.skipWhile(this, test);
  T firstMatching(bool test(T value), {T orElse()}) => IterableMixinWorkaround.firstMatching(this, test, orElse);
  T lastMatching(bool test(T value), {T orElse()}) => IterableMixinWorkaround.lastMatching(this, test, orElse);
  T singleMatching(bool test(T value)) => IterableMixinWorkaround.singleMatching(this, test);
  T elementAt(int index) => IterableMixinWorkaround.elementAt(this, index);
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
