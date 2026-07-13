import 'package:flutter_test/flutter_test.dart';
import 'package:masar/core/formatters.dart';

void main() {
  group('arabicDigits', () {
    test('converts all Western digits', () {
      expect(arabicDigits(1234567890), '١٢٣٤٥٦٧٨٩٠');
    });
  });

  group('lessonCountLabel', () {
    test('Arabic plural categories', () {
      expect(lessonCountLabel(0), 'لا دروس');
      expect(lessonCountLabel(1), 'درس واحد');
      expect(lessonCountLabel(2), 'درسان');
      expect(lessonCountLabel(5), '٥ دروس');
      expect(lessonCountLabel(10), '١٠ دروس');
      expect(lessonCountLabel(11), '١١ درسًا');
      expect(lessonCountLabel(99), '٩٩ درسًا');
      expect(lessonCountLabel(100), '١٠٠ درس');
      expect(lessonCountLabel(340), '٣٤٠ درسًا');
    });
  });

  group('stageCountLabel', () {
    test('Arabic plural categories', () {
      expect(stageCountLabel(1), 'مرحلة واحدة');
      expect(stageCountLabel(2), 'مرحلتان');
      expect(stageCountLabel(3), '٣ مراحل');
      expect(stageCountLabel(11), '١١ مرحلة');
    });
  });

  group('durationLabel', () {
    test('minutes only', () {
      expect(durationLabel(const Duration(minutes: 45)), '٤٥ دقيقة');
      expect(durationLabel(const Duration(minutes: 1)), 'دقيقة');
      expect(durationLabel(const Duration(minutes: 2)), 'دقيقتان');
      expect(durationLabel(const Duration(minutes: 5)), '٥ دقائق');
    });

    test('hours only', () {
      expect(durationLabel(const Duration(hours: 1)), 'ساعة');
      expect(durationLabel(const Duration(hours: 2)), 'ساعتان');
      expect(durationLabel(const Duration(hours: 3)), '٣ ساعات');
    });

    test('hours and minutes', () {
      expect(
        durationLabel(const Duration(hours: 1, minutes: 10)),
        'ساعة و١٠ دقائق',
      );
      expect(
        durationLabel(const Duration(hours: 3, minutes: 5)),
        '٣ ساعات و٥ دقائق',
      );
    });

    test('sub-minute', () {
      expect(durationLabel(const Duration(seconds: 30)), 'أقل من دقيقة');
    });
  });

  group('clockLabel', () {
    test('minutes and seconds', () {
      expect(clockLabel(const Duration(minutes: 45, seconds: 7)), '٤٥:٠٧');
    });
    test('with hours', () {
      expect(
        clockLabel(const Duration(hours: 1, minutes: 2, seconds: 30)),
        '١:٠٢:٣٠',
      );
    });
  });

  group('percentLabel', () {
    test('rounds and clamps', () {
      expect(percentLabel(0.646), '٪٦٥');
      expect(percentLabel(1.2), '٪١٠٠');
      expect(percentLabel(0), '٪٠');
    });
  });
}
