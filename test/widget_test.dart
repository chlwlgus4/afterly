import 'package:flutter_test/flutter_test.dart';
import 'package:afterly/utils/face_guide_filter.dart';

void main() {
  group('EmaFilter', () {
    test('first value is returned as-is', () {
      final filter = EmaFilter(alpha: 0.2);
      expect(filter.update(10.0), 10.0);
    });

    test('smooths subsequent values', () {
      final filter = EmaFilter(alpha: 0.5);
      filter.update(10.0);
      final result = filter.update(20.0);
      expect(result, 15.0);
    });
  });

  group('HysteresisChecker', () {
    test('turns on when below onThreshold', () {
      final checker = HysteresisChecker(onThreshold: 5.0, offThreshold: 6.0);
      expect(checker.check(4.0), true);
    });

    test('stays on between thresholds', () {
      final checker = HysteresisChecker(onThreshold: 5.0, offThreshold: 6.0);
      checker.check(4.0); // ON
      expect(checker.check(5.5), true); // between thresholds → stays ON
    });

    test('turns off when above offThreshold', () {
      final checker = HysteresisChecker(onThreshold: 5.0, offThreshold: 6.0);
      checker.check(4.0); // ON
      expect(checker.check(7.0), false); // above OFF → turns OFF
    });
  });
}
