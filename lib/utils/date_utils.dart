// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class AppDateUtils {
  /// Formats a date string to 'dd/MM/yyyy' format.
  /// Returns the original string if parsing fails.
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}

