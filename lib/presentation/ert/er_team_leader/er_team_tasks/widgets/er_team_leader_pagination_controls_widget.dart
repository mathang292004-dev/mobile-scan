import 'package:emergex/presentation/ert/er_team_leader/er_team_tasks/cubit/er_team_leader_dashboard_cubit.dart';
import 'package:emergex/helpers/widgets/inputs/page_number_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/di/app_di.dart';

class ErTeamLeaderPaginationControlsWidget extends StatelessWidget {
  const ErTeamLeaderPaginationControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ErTeamLeaderDashboardCubit, ErTeamLeaderDashboardState>(
      builder: (context, state) {
        if (state.data == null || state.data!.result == null) {
          return const SizedBox.shrink();
        }

        final cubit = AppDI.erTeamLeaderDashboardCubit;
        final currentPage = (state.filters?.page ?? 0) + 1; // API uses 0-based, UI uses 1-based
        final totalPages = cubit.getTotalPages();
        final incidents = state.data!.result!;

        if (totalPages <= 0 || incidents.isEmpty) {
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
                    ? () => _changePageWithCurrentFilter(context, currentPage - 1)
                    : null,
              ),
              ..._buildPageNumbers(context, currentPage, totalPages, cubit),
              _buildNavigationButton(
                context,
                icon: Icons.chevron_right,
                onPressed: currentPage < totalPages
                    ? () => _changePageWithCurrentFilter(context, currentPage + 1)
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
    final cubit = AppDI.erTeamLeaderDashboardCubit;
    final currentState = cubit.state;

    final currentPage = (currentState.filters?.page ?? 0) + 1;

    // Scroll to top if clicking the current page
    if (page == currentPage) {
      return;
    }

    // Get current filter parameters
    final currentFilters = currentState.filters;

    // Load dashboard with current filters and new page (convert to 0-based)
    cubit.loadDashboard(
      page: page - 1, // Convert 1-based UI to 0-based API
      limit: currentFilters?.limit ?? 10,
      project: currentFilters?.project,
      title: currentFilters?.title,
      status: currentFilters?.status,
      severityLevels: currentFilters?.severityLevels,
      priority: currentFilters?.priority,
      search: currentFilters?.search,
      daterange: currentFilters?.daterange,
      loadMore: false,
      isRefresh: true,
    );
  }

  List<Widget> _buildPageNumbers(
    BuildContext context,
    int currentPage,
    int totalPages,
    ErTeamLeaderDashboardCubit cubit,
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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ColorHelper.textSecondary,
            ),
      ),
    );
  }
}

