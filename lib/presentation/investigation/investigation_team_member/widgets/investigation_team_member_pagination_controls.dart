import 'package:emergex/helpers/widgets/inputs/page_number_button.dart';
import 'package:flutter/material.dart';
import 'package:emergex/generated/color_helper.dart';

class InvestigationTeamMemberPaginationControls extends StatelessWidget {
  final int totalPages;
  final int currentPage;
  final Function(int) onPageChanged;

  const InvestigationTeamMemberPaginationControls({
    super.key,
    required this.totalPages,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 0) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8.0,
        children: [
          _buildNavigationButton(
            context,
            icon: Icons.chevron_left,
            onPressed: currentPage > 1
                ? () => onPageChanged(currentPage - 1)
                : null,
          ),
          ..._buildPageNumbers(context),
          _buildNavigationButton(
            context,
            icon: Icons.chevron_right,
            onPressed: currentPage < totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20, color: ColorHelper.textSecondary),
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context) {
    final List<Widget> buttons = [];

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        buttons.add(
          PageNumberButton(
            pageNumber: i,
            isActive: currentPage == i,
            onTap: () => onPageChanged(i),
          ),
        );
      }
      return buttons;
    }

    buttons.add(
      PageNumberButton(
        pageNumber: 1,
        isActive: currentPage == 1,
        onTap: () => onPageChanged(1),
      ),
    );

    if (currentPage == 1 || currentPage == 2) {
      buttons.add(
        PageNumberButton(
          pageNumber: 2,
          isActive: currentPage == 2,
          onTap: () => onPageChanged(2),
        ),
      );
      buttons.add(_ellipsis(context));
    }

    if (currentPage > 2 && currentPage < totalPages - 1) {
      buttons.add(_ellipsis(context));
      buttons.add(
        PageNumberButton(
          pageNumber: currentPage,
          isActive: true,
          onTap: () => onPageChanged(currentPage),
        ),
      );
      buttons.add(_ellipsis(context));
    }

    if (currentPage == totalPages || currentPage == totalPages - 1) {
      buttons.add(_ellipsis(context));
      buttons.add(
        PageNumberButton(
          pageNumber: totalPages - 1,
          isActive: currentPage == totalPages - 1,
          onTap: () => onPageChanged(totalPages - 1),
        ),
      );
    }

    buttons.add(
      PageNumberButton(
        pageNumber: totalPages,
        isActive: currentPage == totalPages,
        onTap: () => onPageChanged(totalPages),
      ),
    );

    return buttons;
  }

  Widget _ellipsis(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: ColorHelper.textSecondary),
      ),
    );
  }
}
