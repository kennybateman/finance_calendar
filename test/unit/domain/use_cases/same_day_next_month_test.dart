import 'package:flutter_test/flutter_test.dart';
import 'package:finance_calendar/domain/use_cases/due_date.dart';

void main() {
  group('Can find same day next month using an anchor day method.\n', () {

    test('Parsing date strings', () async {
      final endOfMay = DateTime(2026, 5, 31);

      final endOfApril = DueDate.sameDayLastMonth(endOfMay, endOfMay.day);
      expect(endOfApril, DateTime(2026, 4, 30));

      final endOfJune = DueDate.sameDayNextMonth(endOfMay, endOfMay.day);
      expect(endOfJune, DateTime(2026, 6, 30));

      final endOfJuly = DueDate.sameDayNextMonth(endOfJune, endOfMay.day);
      expect(endOfJuly, DateTime(2026, 7, 31));
    });
  });
}