import 'package:emergex/generated/color_helper.dart';
import 'package:flutter/material.dart';

class CustomDropdown extends StatefulWidget {
  final List<String> items;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final TextStyle? textStyle;
  final double? iconSize;
  final Color? iconColor;

  /// Optional color for the selected value text (overrides default).
  final Color? selectedTextColor;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.initialValue,
    required this.onChanged,
    this.isFullWidth = false,
    this.padding,
    this.margin,
    this.decoration,
    this.textStyle,
    this.iconSize,
    this.iconColor,
    this.selectedTextColor,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  final OverlayPortalController _tooltipController = OverlayPortalController();
  final _link = LayerLink();
  late String _currentValue;
  bool _isOpen = false; // Track open state manually

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(CustomDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update current value if the initial value prop changes
    if (widget.initialValue != oldWidget.initialValue) {
      _currentValue = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _tooltipController,
        overlayChildBuilder: (BuildContext context) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // close when tapping outside
              setState(() {
                _isOpen = !_isOpen;
              });
              _tooltipController.toggle();
            },
            child: Stack(
              children: [
                // full screen transparent layer to detect outside taps
                Positioned.fill(child: Container(color: Colors.transparent)),
                // your dropdown
                CompositedTransformFollower(
                  link: _link,
                  targetAnchor: Alignment.bottomCenter,
                  followerAnchor: Alignment.topCenter,
                  offset: const Offset(0, 8),
                  child: _buildDropdownMenu(),
                ),
              ],
            ),
          );
        },
        child: _buildDropdownButton(),
      ),
    );
  }

  Widget _buildDropdownButton() {
    final bool isOpen = _isOpen;

    if (widget.isFullWidth) {
      // Matches Figma 32:103525:
      //   white bg, 1px black@10% border, radius 8, padding 16/8
      //   text: Poppins Medium 12px, green primary
      //   chevron: 16px, generic icon @ 50% opacity (rotated when open)
      return GestureDetector(
        onTap: () {
          setState(() {
            _isOpen = !_isOpen;
          });
          _tooltipController.toggle();
        },
        child: Container(
          width: double.infinity,
          padding:
              widget.padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration:
              widget.decoration ??
              BoxDecoration(
                color: ColorHelper.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorHelper.black.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _currentValue,
                  style:
                      widget.textStyle ??
                      Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: widget.selectedTextColor ?? ColorHelper.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color:
                      widget.iconColor ??
                      ColorHelper.black.withValues(alpha: 0.5),
                  size: widget.iconSize ?? 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Color buttonColor = isOpen
        ? ColorHelper.dropdownColor
        : ColorHelper.surfaceColor;
    final Color textColor = isOpen
        ? ColorHelper.white
        : ColorHelper.successColor;
    final Color borderColor = isOpen
        ? ColorHelper.transparent
        : ColorHelper.successColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isOpen = !_isOpen;
        });
        _tooltipController.toggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: widget.margin ?? const EdgeInsets.only(right: 8),
        decoration:
            widget.decoration ??
            BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: borderColor, width: 1.5),
            ),
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentValue,
                style:
                    widget.textStyle ??
                    Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: textColor),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: widget.iconColor ?? textColor,
                  size: widget.iconSize ?? 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownMenu() {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 16.0;

    return Material(
        color: Colors.transparent,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: SizedBox(
              width: widget.isFullWidth
                  ? screenWidth - (horizontalPadding * 2)
                  : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: widget.isFullWidth
                      ? screenWidth - (horizontalPadding * 2)
                      : 150,
                  maxHeight: 300,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: ColorHelper.surfaceColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _isOpen = false;
                    _tooltipController.hide();
                  });
                  widget.onChanged(item);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            },
          ),
        ),),),
      ),
    );
  }
}
