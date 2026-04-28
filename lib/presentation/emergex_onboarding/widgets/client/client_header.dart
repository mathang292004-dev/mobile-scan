import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:flutter/material.dart';

class ClientHeader extends StatelessWidget {
  //final bool showBackButton;
  final bool isProjectPage;
  final bool isApexPage;
  const ClientHeader({
    super.key,
    this.isProjectPage = false,
    this.isApexPage = false,
  });
  @override
  Widget build(BuildContext context) {
    final titleText = isProjectPage
        ? TextHelper.projects
        : isApexPage
        ? TextHelper.apexPage
        : TextHelper.emergexClients;
    final subtitleText = isProjectPage
        ? TextHelper.subprojectstext
        : TextHelper.manageText;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(),
          ),
          SizedBox(height: 10),
          Text(
            subtitleText,
            softWrap: true,
            overflow: TextOverflow.visible,
            maxLines: 2,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: ColorHelper.tertiaryColor),
          ),
        ],
      ),
    );
  }
}
