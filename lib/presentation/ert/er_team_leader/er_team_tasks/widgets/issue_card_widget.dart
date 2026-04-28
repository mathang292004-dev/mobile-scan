import 'package:emergex/generated/assets.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/ert/er_team_leader/shared/model/issue_model.dart';

class IssueCardWidget extends StatelessWidget {
  final Issue issue;
  const IssueCardWidget({super.key, required this.issue});

  Color _getStatusColor(String status) {
    switch (status) {
      case "Resolved":
        return ColorHelper.textLightGreen;
      case "Progress":
        return ColorHelper.erteamleaderprogress;
      default:
        return ColorHelper.primaryColor;
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case "Resolved":
        return ColorHelper.erteamleaderresolveboder.withValues(alpha: 0.36);
      case "Progress":
        return ColorHelper.erteamleaderprogress.withValues(alpha: 0.4);
      default:
        return Colors.transparent;
    }
  }

  void _handleButtonPress(BuildContext context) {
    if (issue.status == "Resolved") {
      openScreen(Routes.overviewScreen, args: {});
    } else if (issue.status == "Progress") {
      openScreen(Routes.inProgressScreen, args: {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorHelper.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                issue.code,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ColorHelper.black5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(issue.status).withValues(alpha: 0.1),
                  border: Border.all(
                    color: _getStatusBorderColor(issue.status),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  issue.status,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getStatusColor(issue.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          Text(
            issue.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: ColorHelper.black5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            issue.subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: ColorHelper.black4),
          ),
          const SizedBox(height: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Transform.scale(
                    scale: 1.0,
                    child: Image.asset(
                      Assets.severity,
                      height: 12,
                      width: 17,
                      color: ColorHelper.tertiaryColor,
                    ),
                  ),

                  const SizedBox(width: 4),
                  Text(
                    "Severity: ${issue.severity}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColorHelper.tertiaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Transform.scale(
                        scale: 1.0,
                        child: Image.asset(
                          Assets.priority,
                          height: 12,
                          width: 17,
                          color: ColorHelper.tertiaryColor,
                        ),
                      ),

                      const SizedBox(width: 4),
                      Text(
                        "Priority: ${issue.priority}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorHelper.tertiaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  EmergexButton(
                    onPressed: () => _handleButtonPress(context),
                    text: TextHelper.viewdetails,
                    textColor: ColorHelper.white,
                    buttonHeight: 34,
                    width: 120,
                    borderRadius: 25,
                    colors: [ColorHelper.green, ColorHelper.green],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
