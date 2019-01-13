import 'package:piecemeal/piecemeal.dart';
import 'package:test/test.dart';

import 'package:hauberk/src/engine/core/resource.dart';

void main() {
  var resourceSet = ResourceSet<String>();
  resourceSet.defineTags("animal/mammal/rodent animal/reptile/snake");
  resourceSet.add("bird", tags: "animal");
  resourceSet.add("cat", tags: "mammal");
  resourceSet.add("mouse", tags: "rodent");
  resourceSet.add("lizard", tags: "reptile");
  resourceSet.add("cobra", tags: "snake");

  Map<String, double> runTrial(String tag, {bool includeParents}) {
    assert(includeParents != null);

    var counts = <String, int>{};
    for (var i = 0; i < 10000; i++) {
      var animal =
          resourceSet.tryChoose(1, tag: tag, includeParents: includeParents);
      counts.putIfAbsent(animal, () => 0);
      counts[animal]++;
    }

    var ratios = <String, double>{};
    counts.forEach((key, count) => ratios[key] = count / 10000);
    return ratios;
  }

  setUp(() {
    rng.setSeed(123);
  });

  group("tryChoose", () {
    group("with parents", () {
      test("with no tag", () {
        var ratios = runTrial(null, includeParents: true);
        expect(ratios["bird"], closeTo(0.2, 0.1));
        expect(ratios["cat"], closeTo(0.2, 0.1));
        expect(ratios["mouse"], closeTo(0.2, 0.1));
        expect(ratios["lizard"], closeTo(0.2, 0.1));
        expect(ratios["cobra"], closeTo(0.2, 0.1));
      });

      test("with root tag", () {
        var ratios = runTrial("animal", includeParents: true);
        expect(ratios["bird"], closeTo(0.2, 0.1));
        expect(ratios["cat"], closeTo(0.2, 0.1));
        expect(ratios["mouse"], closeTo(0.2, 0.1));
        expect(ratios["lizard"], closeTo(0.2, 0.1));
        expect(ratios["cobra"], closeTo(0.2, 0.1));
      });

      test("with non-leaf tag", () {
        var ratios = runTrial("mammal", includeParents: true);
        expect(ratios["bird"], lessThan(0.1));
        expect(ratios["cat"], closeTo(0.4, 0.1));
        expect(ratios["mouse"], closeTo(0.4, 0.1));
        expect(ratios["lizard"], lessThan(0.1));
        expect(ratios["cobra"], lessThan(0.1));
      });

      test("with leaf tag", () {
        var ratios = runTrial("rodent", includeParents: true);
        expect(ratios["bird"], lessThan(0.02));
        expect(ratios["cat"], closeTo(0.08, 0.02));
        expect(ratios["mouse"], closeTo(0.88, 0.1));
        expect(ratios["lizard"], lessThan(0.02));
        expect(ratios["cobra"], lessThan(0.02));
      });
    });

    group("without parents", () {
      test("with non-leaf tag", () {
        var ratios = runTrial("mammal", includeParents: false);
        expect(ratios["cat"], closeTo(0.5, 0.1));
        expect(ratios["mouse"], closeTo(0.5, 0.1));
        expect(ratios, isNot(contains("bird")));
        expect(ratios, isNot(contains("lizard")));
        expect(ratios, isNot(contains("cobra")));
      });

      test("with leaf tag", () {
        var ratios = runTrial("rodent", includeParents: false);
        expect(ratios, isNot(contains("cat")));
        expect(ratios["mouse"], equals(1.0));
        expect(ratios, isNot(contains("bird")));
        expect(ratios, isNot(contains("lizard")));
        expect(ratios, isNot(contains("cobra")));
      });
    });
  });
}
