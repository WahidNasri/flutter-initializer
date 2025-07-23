import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';

import '../../main.dart';

enum WeekDayViewMode { firstLetter, firstThreeLetters, full }

enum MonthViewMode {
  firstThreeLetters,
  full,
}

extension DateTimeExtensions on DateTime {
  int get timestamp {
    int recurrenceId = toLocal().millisecondsSinceEpoch;
    return recurrenceId;
  }

//#region Formatting
  String format([String? format]) {
    //Get current locale, fallback to english in case this method is used outside Flutter context.
    final currentLocale = appKey.currentContext?.locale ?? const Locale('en');
    final locale = currentLocale.languageCode.toLowerCase();
    return DateFormat(format ?? 'dd/MM/yyyy', locale).format(this).replaceArabicNumber();
  }

  String formatDate({String separator = "/", bool yearFirst = false}) {
    if (yearFirst) {
      return format("yyyy${separator}MM${separator}dd");
    } else {
      return format("dd${separator}MM${separator}yyyy");
    }
  }

  String formatTime({bool twentyFour = true, bool showSeconds = false}) {
    String timeFormat = "";
    if (twentyFour) {
      timeFormat = showSeconds ? "HH:mm:ss" : "HH:mm";
    } else {
      timeFormat = showSeconds ? "hh:mm:ss a" : "hh:mm a";
    }
    return format(timeFormat);
  }

  String formatWeekDay({WeekDayViewMode mode = WeekDayViewMode.firstThreeLetters}) {
    if (mode == WeekDayViewMode.firstThreeLetters) {
      return format("EEE");
    } else if (mode == WeekDayViewMode.full) {
      return format("EEEE");
    } else if (mode == WeekDayViewMode.firstLetter) {
      return format("EEE")[0];
    }
    return "";
  }

  String formatYear() {
    return format("yyyy");
  }

  String formatMonth([MonthViewMode monthViewMode = MonthViewMode.firstThreeLetters]) {
    return format(monthViewMode == MonthViewMode.firstThreeLetters ? 'MMM' : 'MMMM');
  }

  String formatDayAndMonth({MonthViewMode monthViewMode = MonthViewMode.firstThreeLetters}) {
    return format("dd ${monthViewMode == MonthViewMode.firstThreeLetters ? 'MMM' : 'MMMM'} ");
  }

  String formatMonthAndYear([MonthViewMode monthViewMode = MonthViewMode.full]) {
    return format("${monthViewMode == MonthViewMode.firstThreeLetters ? 'MMM' : 'MMMM'} yyyy");
  }

  String formatFullDateTime({bool twentyFour = true, MonthViewMode monthViewMode = MonthViewMode.firstThreeLetters, bool showDayName = false}) {
    return format("${showDayName ? 'EEEE , ' : ''}dd ${monthViewMode == MonthViewMode.firstThreeLetters ? 'MMM' : 'MMMM'} yyyy, ${twentyFour ? 'HH:mm' : 'hh:mm a'}");
  }

  /// Gets the formatted date that includes the week day and the full date.
  /// For example:
  /// ```dart
  /// final date = DateTime(2023, DateTime.november, 5);
  /// print(date.formatFullDateWithWeekDay()); // Sunday, 05 Nov 2023
  /// ```
  /// the arguments `monthViewMode` and `weekDayViewMode` will determine the day of week and month spelling
  /// between `firstLetter`, `firstThreeLetters` and `full`.
  String formatFullDate({
    MonthViewMode monthViewMode = MonthViewMode.firstThreeLetters,
    WeekDayViewMode weekDayViewMode = WeekDayViewMode.full,
    showDayName = false,
  }) {
    String dayString = '';
    if (showDayName) dayString += '${formatWeekDay(mode: weekDayViewMode)}, ';
    return dayString + format("dd ${monthViewMode == MonthViewMode.firstThreeLetters ? 'MMM' : 'MMMM'} yyyy");
  }

  String timeAwareFormat({WeekDayViewMode weekDayViewMode = WeekDayViewMode.firstThreeLetters, bool twentyFour = true}) {
    final daysSinceNow = daysSince();
    if (isSameDay(DateTime.now())) {
      return formatTime(twentyFour: twentyFour);
    } else if (daysSinceNow == 1) {
      //the day before, event the difference in hours is less than 24
      return 'Yesterday'.tr();
    } else if (daysSinceNow < 7) {
      return formatWeekDay(mode: weekDayViewMode);
    } else if (year == DateTime.now().year) {
      return format("dd MMM");
    }

    return formatDate();
  }

  int daysSince({DateTime? date}) {
    date = date ?? DateTime.now();
    return DateTime(date.year, date.month, date.day).difference(DateTime(year, month, day)).inDays;
  }

//#endregion

//#region Altering
  DateTime withFormattedTime({required String input, required String format, String locale = "en"}) {
    final parsed = DateFormat(format, locale).parse(input);
    return withTime(hours: parsed.hour, minutes: parsed.minute, seconds: parsed.second);
  }

  DateTime withTime({int? hours, int? minutes, int? seconds}) {
    return DateTime(year, month, day, hours ?? hour, minutes ?? minute, seconds ?? second);
  }

  DateTime toFirstDayOfMonth() => DateTime(year, month, 1);

  DateTime withTimeFromDt(DateTime dateTime) {
    return withTime(hours: dateTime.hour, minutes: dateTime.minute, seconds: dateTime.second);
  }

  DateTime dateOnly() {
    return DateTime(year, month, day);
  }

//#endregion

  ({DateTime start, DateTime end}) getMonthWindow({bool includeOtherMonthsParts = false, bool sixWeeks = true}) {
    var start = copyWith(day: 1);
    var end = (month < 12) ? DateTime(year, month + 1, 0) : DateTime(year + 1, 1, 0);

    if (includeOtherMonthsParts) {
      if (start.weekday != DateTime.sunday) {
        final recentSunday = DateTime(start.year, start.month, start.day - start.weekday % 7);

        start = recentSunday;
      }
      final lastWeekDay = end.add(Duration(days: DateTime.daysPerWeek - end.weekday - 1)); // -1 because sunday is the first day of week
      final globalDiff = lastWeekDay.difference(start).inDays;
      final weeksCount = globalDiff % 7;
      if (weeksCount <= 6 && sixWeeks) {
        end = lastWeekDay.add(const Duration(days: 7));
      } else {
        end = lastWeekDay;
      }
    }
    //if 1st of the month is the start of the window, include the previous day to handle UTC dates
    if (start.day == 1) {
      start = start.subtract(const Duration(days: 1));
    }
    return (start: start, end: end);
  }

  bool isBetweenStringDateTimes({required String startDateTime, required String endDateTime}) => isBefore(DateTime.parse(endDateTime)) && isAfter(DateTime.parse(startDateTime));

  bool isBetween({required DateTime start, required DateTime end}) => isBefore(end) && isAfter(start);

  String toFullyReadableDateTimeFormat() {
    final currentLocale = appKey.currentContext?.locale ?? const Locale('en');
    final locale = currentLocale.languageCode.toLowerCase();
    return DateFormat('MMMM d, yyyy h:mm:ss a', locale).format(this).replaceArabicNumber();
  }

  DateTime addMonths(int months) {
    return copyWith(month: month + months);
  }

  DateTime subtractMonths(int months) {
    return copyWith(month: month - months);
  }

  DateTime addYears(int years) {
    return copyWith(year: year + years);
  }
}

extension NullabelDateTimeExtension on DateTime? {
  bool isSameDay(DateTime? otherDt) {
    if (this == null || otherDt == null) {
      return false;
    }
    return this!.year == otherDt.year && this!.month == otherDt.month && this!.day == otherDt.day;
  }
}

extension StringNumberExt on String {
  String replaceArabicNumber() {
    var input = this;
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }
}