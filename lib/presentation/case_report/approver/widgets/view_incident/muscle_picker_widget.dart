import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
class MusclePickerWidget extends StatefulWidget {
  final List<Map<String, dynamic>> injuredParts;
  const MusclePickerWidget({super.key, required this.injuredParts});

  @override
  State<MusclePickerWidget> createState() => _MusclePickerWidgetState();
}

class _MusclePickerWidgetState extends State<MusclePickerWidget> {
  int _currentIndex = 0;

  String _formatBodyPartName(String bodyPart) {
    return bodyPart
        .split('_')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: ColorHelper.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ColorHelper.surfaceColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            TextHelper.personnelInjury,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),

          if (widget.injuredParts.isNotEmpty) ...[
            Text(
              widget.injuredParts[_currentIndex]['injuriedPersonName'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Row(
              children: [
                Flexible(
                  child: Text(
                    widget.injuredParts[_currentIndex]['injuriedPersonId'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorHelper.successColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: SvgPicture.asset(
              Assets.reportIncidentScreenMFront,
              width: 322,
              height: 300,
              colorMapper: InjuryColorMapper(
                widget.injuredParts.isNotEmpty &&
                        widget.injuredParts[_currentIndex]['injuries'] != null
                    ? (widget.injuredParts[_currentIndex]['injuries'] as List)
                          .where((part) => part['bodyPart'] != null)
                          .map((part) => part['bodyPart'] as String)
                          .toList()
                    : [],
              ),
              fit: BoxFit.contain,
              allowDrawingOutsideViewBox: true,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.injuredParts.isNotEmpty &&
              widget.injuredParts[_currentIndex]['injuries'] != null)
            ...(widget.injuredParts[_currentIndex]['injuries'] as List).map(
              (part) => Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: ColorHelper.surfaceColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ColorHelper.surfaceColor, width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          Assets.reportIncidentScreenInjury,
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatBodyPartName(part['bodyPart'] as String? ?? ''),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: ColorHelper.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Image.asset(
                          Assets.reportIncidentScreenWarning,
                          width: 15,
                          height: 15,
                          color: ColorHelper.warningRedColor,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(part['category'] as String? ?? '',style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                            color: ColorHelper.warningRedColor,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (widget.injuredParts.length > 1)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      if (_currentIndex > 0) {
                        _currentIndex--;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: ColorHelper.surfaceColor.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: ColorHelper.surfaceColor,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: _currentIndex > 0
                          ? ColorHelper.black
                          : ColorHelper.grey,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Text('${_currentIndex + 1}'),
                      Text('/'),
                      Text('${widget.injuredParts.length}'),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      if (_currentIndex < widget.injuredParts.length - 1) {
                        _currentIndex++;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: ColorHelper.surfaceColor.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: ColorHelper.surfaceColor,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: _currentIndex < widget.injuredParts.length - 1
                          ? ColorHelper.black
                          : ColorHelper.grey,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class InjuryColorMapper extends ColorMapper {
  final List<String> injuredParts;

  const InjuryColorMapper(this.injuredParts);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (id != null) {
      // Check if the id exists in the list of maps
      if (injuredParts.contains(id)) {
        return ColorHelper.red;
      }
    }
    return ColorHelper.grey;
  }
}
