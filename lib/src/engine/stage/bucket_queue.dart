import 'dart:collection';
import 'dart:math' as math;

// TODO: Move to piecemeal?
/// A fast priority queue optimized for non-zero integer priorities in a narrow
/// range.
///
/// Internally, as the name implies, this uses a bucket queue. This means that
/// priorities ("costs", since lower is considered higher priority) need to be
/// integers ranging from 0 to some hopefully small-ish maximum.
///
/// This also does not support updating the priority of a previously enqueued
/// item. Instead, the item is enqueue redundantly. When the higher cost one is
/// visited later, it can be ignored. In practice, this tends to be faster than
/// finding the previous item to update its priority.
///
/// See:
///
/// * https://en.wikipedia.org/wiki/Bucket_queue
/// * https://www.redblobgames.com/pathfinding/a-star/implementation.html#algorithm
class BucketQueue<T> {
  final List<Queue<T>> _buckets = [];
  int _bucket = 0;

  void reset() {
    _buckets.clear();
  }

  void add(T value, int cost) {
    _bucket = math.min(_bucket, cost);

    // Grow the bucket array if needed.
    if (_buckets.length <= cost + 1) _buckets.length = cost + 1;

    // Find the bucket, or create it if needed.
    var bucket = _buckets[cost];
    if (bucket == null) {
      bucket = Queue();
      _buckets[cost] = bucket;
    }

    bucket.add(value);
  }

  /// Removes the best item from the queue or returns `null` if the queue is
  /// empty.
  T removeNext() {
    // Advance past any empty buckets.
    while (_bucket < _buckets.length &&
        (_buckets[_bucket] == null || _buckets[_bucket].isEmpty)) {
      _bucket++;
    }

    // If we ran out of buckets, the queue is empty.
    if (_bucket >= _buckets.length) return null;

    return _buckets[_bucket].removeFirst();
  }
}
