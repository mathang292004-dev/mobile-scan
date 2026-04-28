import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

/// Green gradient card showing high risk cases count and action needed.
class HighRiskCardWidget extends StatelessWidget {
  final int riskCount;
  final int actionNeededCount;
  final Widget icon;
  final VoidCallback? onTap;

  const HighRiskCardWidget({
    super.key,
    required this.riskCount,
    required this.actionNeededCount,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorHelper.primaryColor,
              ColorHelper.buttonColor,
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: ColorHelper.white),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: ColorHelper.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(27),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${TextHelper.highRiskCases} : ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: ColorHelper.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                        ),
                        TextSpan(
                          text: '$riskCount',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: ColorHelper.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 21,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$actionNeededCount ${TextHelper.casesNeedImmediateAction}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorHelper.highRiskSubtext,
                          fontWeight: FontWeight.w400,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
