import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';

// Result class to differentiate between date selection, view all, and dismissal
class DatePickerResult {
  final DateTimeRange? dateRange;
  final bool isViewAll;

  DatePickerResult.dateRange(this.dateRange) : isViewAll = false;
  DatePickerResult.viewAll() : dateRange = null, isViewAll = true;
}

/// Callback function type for handling date range selection
/// Parameters:
/// - dateRange: Map with 'from' and 'to' keys (ISO format strings), or null for "View All"
/// - searchText: Current search text from search bar
typedef DateRangeCallback =
    Future<void> Function(Map<String, String>? dateRange, String? searchText);

class DateRangePicker extends StatefulWidget {
  final Function(String)? onDateRangeChanged;
  final GlobalKey<SearchBarWidgetState> searchBarKey;
  final DateRangeCallback onDateRangeSelected;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  const DateRangePicker({
    super.key,
    required this.searchBarKey,
    required this.onDateRangeSelected,
    this.onDateRangeChanged,
    this.initialFromDate,
    this.initialToDate,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  final ValueNotifier<bool> _sessionNotifier = ValueNotifier(false);

  @override
  void dispose() {
    _sessionNotifier.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00.000Z';
  }

  String _formatEndOfDayForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T23:59:59.999Z';
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    if (_sessionNotifier.value) return;
    _sessionNotifier.value = true;

    try {
      final now = DateTime.now();
      final defaultFromDate =
          widget.initialFromDate ?? now.subtract(const Duration(days: 30));
      final defaultToDate = widget.initialToDate ?? now;

      final result = await showGeneralDialog<DatePickerResult?>(
        context: context,
        barrierDismissible: true,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        pageBuilder: (context, animation1, animation2) {
          return CustomCalendarDialog(
            initialStart: defaultFromDate,
            initialEnd: defaultToDate,
            sessionNotifier: _sessionNotifier,
          );
        },
      );

      if (result == null) return;

      if (result.isViewAll) {
        widget.onDateRangeChanged?.call('All Data');
        await widget.onDateRangeSelected(
          {'from': '', 'to': ''},
          widget.searchBarKey.currentState?.getSearchBarText(),
        );
        return;
      }

      if (result.dateRange != null) {
        final newText =
            '${_formatDate(result.dateRange!.start)} - ${_formatDate(result.dateRange!.end)}';
        widget.onDateRangeChanged?.call(newText);
        await widget.onDateRangeSelected(
          {
            'from': _formatDateForAPI(result.dateRange!.start),
            'to': _formatEndOfDayForAPI(result.dateRange!.end),
          },
          widget.searchBarKey.currentState?.getSearchBarText(),
        );
      }
    } finally {
      if (mounted) _sessionNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCustomDatePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FCF9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ColorHelper.white, width: 1),
        ),
        child: Image.asset(
          Assets.dashboardDatePickerIcon,
          height: 18,
          width: 18,
        ),
      ),
    );
  }
}

class CustomCalendarDialog extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;
  final ValueNotifier<bool> sessionNotifier;

  const CustomCalendarDialog({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.sessionNotifier,
  });

  @override
  State<CustomCalendarDialog> createState() => _CustomCalendarDialogState();
}

class _CustomCalendarDialogState extends State<CustomCalendarDialog> {
  late DateTime currentMonth;
  DateTime? selectedStart;
  DateTime? selectedEnd;
  bool isSelectingEnd = false;
  bool isDragging = false;
  DateTime? dragStartDate;
  bool _isClosingDialog = false;

  @override
  void initState() {
    super.initState();
    // Open calendar on the month of the initially selected end date (to date)
    // This allows users to see the end of their previously selected date range immediately
    currentMonth = DateTime(widget.initialEnd.year, widget.initialEnd.month);
    selectedStart = widget.initialStart;
    selectedEnd = widget.initialEnd;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 400 ? 350.0 : screenWidth * 0.9;

    return Dialog(
      backgroundColor: ColorHelper.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          width: dialogWidth,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildWeekDays(),
              const SizedBox(height: 10),
              _buildCalendarGrid(),
              const SizedBox(height: 20),
              _buildViewAllDataButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllDataButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _safePop(DatePickerResult.viewAll());
        },

        style: ElevatedButton.styleFrom(
          backgroundColor: ColorHelper.dateRangeColor,
          foregroundColor: ColorHelper.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          'View all Data',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ColorHelper.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: const Icon(
            Icons.chevron_left,
            size: 20,
            color: ColorHelper.textPrimary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: _showMonthPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorHelper.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: ColorHelper.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _getMonthText(),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontSize: 12,
                                  color: ColorHelper.textPrimary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Image.asset(
                            Assets.calendarDropDownIcon,
                            width: 5,
                            height: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: GestureDetector(
                  onTap: _showYearPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorHelper.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: ColorHelper.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            currentMonth.year.toString(),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontSize: 12,
                                  color: ColorHelper.textPrimary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Image.asset(
                            Assets.calendarDropDownIcon,
                            width: 5,
                            height: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(
            Icons.chevron_right,
            size: 20,
            color: ColorHelper.textPrimary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  Widget _buildWeekDays() {
    const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: weekDays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ColorHelper.textSecondary,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    List<Widget> dayWidgets = [];

    // Add empty spaces for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      dayWidgets.add(_buildDayWidget(date));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      padding: EdgeInsets.zero,
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      children: dayWidgets,
    );
  }

  Widget _buildDayWidget(DateTime date) {
    final isDisabled = _isFutureDate(date);
    final isSelected = _isDateSelected(date);
    final isInRange = _isDateInRange(date);
    final isStartDate =
        selectedStart != null && _isSameDay(date, selectedStart!);
    final isEndDate = selectedEnd != null && _isSameDay(date, selectedEnd!);
    final isToday = _isSameDay(date, DateTime.now());
    final isCurrentMonth = date.month == currentMonth.month;

    // Determine the background color
    Color? backgroundColor;
    if (isInRange) {
      backgroundColor = ColorHelper.dateRangeLightGreen;
    }

    // Determine border radius based on position in range and week boundaries
    BorderRadius? borderRadius;
    if (isStartDate && isEndDate) {
      borderRadius = BorderRadius.circular(50);
    } else if (isInRange || isStartDate || isEndDate) {
      final isStartOfWeek = date.weekday == 1; // Monday
      final isEndOfWeek = date.weekday == 7; // Sunday

      bool hasLeftRadius = isStartDate || isStartOfWeek;
      bool hasRightRadius = isEndDate || isEndOfWeek;

      borderRadius = BorderRadius.only(
        topLeft: hasLeftRadius ? const Radius.circular(50) : Radius.zero,
        bottomLeft: hasLeftRadius ? const Radius.circular(50) : Radius.zero,
        topRight: hasRightRadius ? const Radius.circular(50) : Radius.zero,
        bottomRight: hasRightRadius ? const Radius.circular(50) : Radius.zero,
      );
    }

    // Determine inner circle color for selected days
    Color innerCircleColor = ColorHelper.transparent;
    if (isStartDate || isEndDate) {
      innerCircleColor = ColorHelper.dateRangeGreen;
    }

    // Determine text color
    Color textColor;
    if (isDisabled) {
      textColor = Colors.grey;
    } else if (isSelected) {
      textColor = ColorHelper.white;
    } else if (!isCurrentMonth) {
      textColor = ColorHelper.textSecondary;
    } else {
      textColor = ColorHelper.textPrimary;
    }

    // Today's date indicator (border)
    BoxDecoration? todayDecoration;
    if (isToday && !isSelected) {
      todayDecoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ColorHelper.black, width: 1.5),
      );
    }

    return GestureDetector(
      onTap: isDisabled ? null : () => _onDateTapped(date),
      onPanStart: isDisabled ? null : (_) => _onDatePanStart(date),
      onPanUpdate: isDisabled
          ? null
          : (details) => _onDatePanUpdate(date, details),
      onPanEnd: isDisabled ? null : (_) => _onDatePanEnd(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: isStartDate || isEndDate
                ? BoxDecoration(color: innerCircleColor, shape: BoxShape.circle)
                : todayDecoration,
            alignment: Alignment.center,
            child: Text(
              date.day.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onDatePanStart(DateTime date) {
    setState(() {
      isDragging = true;
      dragStartDate = date;
      selectedStart = date;
      selectedEnd = null;
      isSelectingEnd = true;
    });
  }

  void _onDatePanUpdate(DateTime date, DragUpdateDetails details) {
    if (!isDragging || dragStartDate == null) return;

    setState(() {
      if (date.isBefore(dragStartDate!)) {
        selectedStart = date;
        selectedEnd = dragStartDate;
      } else if (date.isAfter(dragStartDate!)) {
        selectedStart = dragStartDate;
        selectedEnd = date;
      } else {
        selectedStart = date;
        selectedEnd = null;
      }
    });
  }

  void _onDatePanEnd() {
    if (_hasPopped || _isClosingDialog) return;

    if (isDragging && selectedStart != null) {
      setState(() {
        isDragging = false;
        isSelectingEnd = false;
      });

      final endDate = selectedEnd ?? selectedStart!;
      _isClosingDialog = true;

      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        if (selectedStart == null) return;
        _safePop(
          DatePickerResult.dateRange(
            DateTimeRange(start: selectedStart!, end: endDate),
          ),
        );
      });
    } else {
      setState(() {
        isDragging = false;
      });
    }
  }

  void _showMonthPicker() async {
    final months = [
      TextHelper.january,
      TextHelper.february,
      TextHelper.march,
      TextHelper.april,
      TextHelper.may,
      TextHelper.june,
      TextHelper.july,
      TextHelper.august,
      TextHelper.september,
      TextHelper.october,
      TextHelper.november,
      TextHelper.december,
    ];

    final selectedMonth = await showDialog<int>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: ColorHelper.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 300, // Reduced height
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: ScrollController(
                    initialScrollOffset:
                        (currentMonth.month - 1) *
                        56.0, // Auto-scroll to selected month
                  ),
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final isSelected = index + 1 == currentMonth.month;
                    return GestureDetector(
                      onTap: () => Navigator.of(context).pop(index + 1),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? ColorHelper.dateRangeGreen
                              : ColorHelper.transparent,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Text(
                          months[index],
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 16,
                                color: isSelected
                                    ? ColorHelper.white
                                    : ColorHelper.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedMonth != null) {
      setState(() {
        currentMonth = DateTime(currentMonth.year, selectedMonth);
      });
    }
  }

  void _showYearPicker() async {
    final currentYear = DateTime.now().year;
    final years = List.generate(21, (index) => currentYear - 10 + index);

    final selectedYear = await showDialog<int>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: ColorHelper.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 300, // Reduced height
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            controller: ScrollController(
              initialScrollOffset:
                  years.indexOf(currentMonth.year - 1) *
                  56.0, // Auto-scroll to selected year
            ),
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              final isSelected = year == currentMonth.year;
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(year),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? ColorHelper.dateRangeGreen
                        : ColorHelper.transparent,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Center(
                    child: Text(
                      year.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: isSelected
                            ? ColorHelper.white
                            : ColorHelper.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    if (selectedYear != null) {
      setState(() {
        currentMonth = DateTime(selectedYear, currentMonth.month);
      });
    }
  }

  bool _hasPopped = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _safePop(DatePickerResult result) {
    if (!widget.sessionNotifier.value) return;
    if (_hasPopped) return;
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    _hasPopped = true;
    widget.sessionNotifier.value = false;
    Navigator.of(context).pop(result);
  }

  void _onDateTapped(DateTime date) {
    if (_hasPopped || isDragging || _isClosingDialog) return;

    setState(() {
      if (selectedStart == null || selectedEnd != null) {
        selectedStart = date;
        selectedEnd = null;
        isSelectingEnd = true;
      } else if (date.isBefore(selectedStart!)) {
        selectedStart = date;
      } else {
        selectedEnd = date;
        isSelectingEnd = false;
        _isClosingDialog = true;

        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          if (selectedStart == null || selectedEnd == null) return;
          _safePop(
            DatePickerResult.dateRange(
              DateTimeRange(start: selectedStart!, end: selectedEnd!),
            ),
          );
        });
      }
    });
  }

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
  }

  String _getMonthText() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[currentMonth.month - 1];
  }

  bool _isDateSelected(DateTime date) {
    return (selectedStart != null && _isSameDay(date, selectedStart!)) ||
        (selectedEnd != null && _isSameDay(date, selectedEnd!));
  }

  bool _isDateInRange(DateTime date) {
    if (selectedStart == null || selectedEnd == null) return false;

    // Make sure we're comparing dates without time components
    final start = DateTime(
      selectedStart!.year,
      selectedStart!.month,
      selectedStart!.day,
    );
    final end = DateTime(
      selectedEnd!.year,
      selectedEnd!.month,
      selectedEnd!.day,
    );
    final current = DateTime(date.year, date.month, date.day);

    return (current.isAfter(start) && current.isBefore(end)) ||
        _isSameDay(date, selectedStart!) ||
        _isSameDay(date, selectedEnd!);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isFutureDate(DateTime date) {
    final today = DateTime.now();
    final current = DateTime(date.year, date.month, date.day);
    final now = DateTime(today.year, today.month, today.day);
    return current.isAfter(now);
  }
}
