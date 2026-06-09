import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('Parsing date strings\n', () {

    test('Parsing date strings', () async {
      var expectedDate = DateTime(2001,9,1);
      var datestring = "2001-9-1";
      expect(RegExp(r'^\d{2,4}-\d{1,2}-\d{1,2}$').hasMatch(datestring), true);
      expect(DateFormat('yyyy-MM-dd').parse(datestring), expectedDate);

      datestring = "2001-09-01";
      expect(RegExp(r'^\d{4}-\d{1,2}-\d{1,2}$').hasMatch(datestring), true);
      expect(DateFormat('yyyy-MM-dd').parse(datestring), expectedDate);

      datestring = "9/1/2001";
      expect(RegExp(r'^\d{1,2}/\d{1,2}/\d{2,4}$').hasMatch(datestring), true);
      expect(DateFormat('MM/dd/yyyy').parse(datestring), expectedDate);
    });
  });
}