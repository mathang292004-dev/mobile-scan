import 'package:emergex/presentation/case_report/member/cubit/dashboard_cubit.dart';
import 'package:emergex/helpers/widgets/inputs/page_number_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/di/app_di.dart';
class PaginationControls extends StatelessWidget {
  const PaginationControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoaded) return const SizedBox.shrink();

        final cubit = AppDI.dashboardCubit;
        final currentPage = state.currentPage ?? 1;
        final totalPages = cubit.getTotalPages();

        if (totalPages <= 0 || state.incidents.isEmpty) {
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
                    ? () =>
                          _changePageWithCurrentFilter(context, currentPage - 1)
                    : null,
              ),
              ..._buildPageNumbers(context, currentPage, totalPages, cubit),
              _buildNavigationButton(
                context,
                icon: Icons.chevron_right,
                onPressed: currentPage < totalPages
                    ? () =>
                          _changePageWithCurrentFilter(context, currentPage + 1)
                    : null,
              ),
            ],
          ),
        );
      },
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
    );
  }

  void _changePageWithCurrentFilter(BuildContext context, int page) {
    final cubit = AppDI.dashboardCubit;
    final currentState = cubit.state;

    if (currentState is DashboardLoaded) {
      final currentPage = currentState.currentPage ?? 1;

      // Scroll to top if clicking the current page
      if (page == currentPage) {
        return;
      }

      // Get current filter parameters
      final currentIncidentStatus = currentState.incidentStatus;
      final currentSearch = currentState.searchQuery ?? '';
      final currentDaterange =
          currentState.fromDate != null && currentState.toDate != null
          ? {
              'from':
                  '${currentState.fromDate!.year}-${currentState.fromDate!.month.toString().padLeft(2, '0')}-${currentState.fromDate!.day.toString().padLeft(2, '0')}T00:00:00.000Z',
              'to':
                  '${currentState.toDate!.year}-${currentState.toDate!.month.toString().padLeft(2, '0')}-${currentState.toDate!.day.toString().padLeft(2, '0')}T00:00:00.000Z',
            }
          : null;

      // Load incidents with current filters and new page
      cubit.loadIncidents(
        page: page,
        limit: 10,
        incidentStatus: currentIncidentStatus,
        search: currentSearch,
        daterange: currentDaterange,
        selectedMetricIndex: currentState.selectedMetricIndex,
      );
    }
  }

  List<Widget> _buildPageNumbers(
    BuildContext context,
    int currentPage,
    int totalPages,
    DashboardCubit cubit,
  ) {
    final List<Widget> buttons = [];

    // If total pages <= 5, show all pages directly
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        buttons.add(
          PageNumberButton(
            pageNumber: i,
            isActive: currentPage == i,
            onTap: () => _changePageWithCurrentFilter(context, i),
          ),
        );
      }
      return buttons;
    }

    // Always show first page
    buttons.add(
      PageNumberButton(
        pageNumber: 1,
        isActive: currentPage == 1,
        onTap: () => _changePageWithCurrentFilter(context, 1),
      ),
    );

    // Case: current is 1 or 2 → show page 2, then ellipsis
    if (currentPage == 1 || currentPage == 2) {
      buttons.add(
        PageNumberButton(
          pageNumber: 2,
          isActive: currentPage == 2,
          onTap: () => _changePageWithCurrentFilter(context, 2),
        ),
      );
      buttons.add(_ellipsis(context));
    }

    // Middle pages
    if (currentPage > 2 && currentPage < totalPages - 1) {
      buttons.add(_ellipsis(context));
      buttons.add(
        PageNumberButton(
          pageNumber: currentPage,
          isActive: true,
          onTap: () => _changePageWithCurrentFilter(context, currentPage),
        ),
      );
      buttons.add(_ellipsis(context));
    }

    // Last or last-1 page
    if (currentPage == totalPages || currentPage == totalPages - 1) {
      buttons.add(_ellipsis(context));
      buttons.add(
        PageNumberButton(
          pageNumber: totalPages - 1,
          isActive: currentPage == totalPages - 1,
          onTap: () => _changePageWithCurrentFilter(context, totalPages - 1),
        ),
      );
    }

    // Always show last page
    buttons.add(
      PageNumberButton(
        pageNumber: totalPages,
        isActive: currentPage == totalPages,
        onTap: () => _changePageWithCurrentFilter(context, totalPages),
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
