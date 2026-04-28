import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/helpers/widgets/dashboard/app_metric_card.dart';
import 'package:emergex/helpers/widgets/dashboard/app_pagination_controls.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/helpers/widgets/dashboard/app_dashboard_header.dart';
import 'package:emergex/presentation/user_onboarding/cubit/user_management_cubit.dart';
import 'package:emergex/presentation/user_onboarding/cubit/user_management_state.dart';
import 'package:emergex/presentation/user_onboarding/utils/user_management_utils.dart';
import 'package:emergex/presentation/user_onboarding/widgets/user_filter_widget.dart';
import 'package:emergex/presentation/user_onboarding/widgets/user_list_card_widget.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<SearchBarWidgetState> searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  @override
  void initState() {
    super.initState();
    final cubit = AppDI.userManagementCubit;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (cubit.state.processState == UserManagementProcessState.initial) {
        cubit.loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = AppDI.userManagementCubit;

    return AppScaffold(
      useGradient: true,
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      appBar: const AppBarWidget(showBackButton: false),
      child: BlocConsumer<UserManagementCubit, UserManagementState>(
        bloc: cubit,
        listener: (context, state) {
          UserManagementUtils.handleStateChange(context, state);
          // Scroll to top when data is loaded (done or error)
          if (state.processState == UserManagementProcessState.loaded ||
              state.processState == UserManagementProcessState.error) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AppDashboardHeader(
                  title: TextHelper.userManagement,
                  searchBarKey: searchBarKey,
                  initialFromDate: state.fromDate,
                  initialToDate: state.toDate,
                  onDateRangeChanged: (newText) {
                    if (newText == TextHelper.allDates) {
                      cubit.clearDateFilter();
                    }
                  },
                  onDateRangeSelected: (dateRange, searchText) async {
                    cubit.onDateRangeSelected(dateRange, searchText);
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => cubit.refreshUsers(),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetricCards(context, state, cubit),
                        const SizedBox(height: 10),
                        _buildAddNewUserButton(context),
                        const SizedBox(height: 10),
                        _buildUserListSection(context, state, cubit),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCards(
    BuildContext context,
    UserManagementState state,
    UserManagementCubit cubit,
  ) {
    final isError = state.processState == UserManagementProcessState.error;
    return AppMetricCard(
      titles: [
        TextHelper.totalUsers,
        TextHelper.activeUsers,
        TextHelper.inactiveUsers,
      ],
      counts: [
        UserManagementUtils.formatNumber(isError ? 0 : state.stats.totalUsers),
        UserManagementUtils.formatNumber(isError ? 0 : state.stats.activeUsers),
        UserManagementUtils.formatNumber(
          isError ? 0 : state.stats.inactiveUsers,
        ),
      ],
      icons: [
        Image.asset(
          Assets.dashboardIconTotalIncidents,
          width: 16,
          height: 16,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person,
            size: 16,
            color: ColorHelper.primaryColor,
          ),
        ),
        Image.asset(
          Assets.activeUsersIcon,
          width: 16,
          height: 16,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.person,
            size: 16,
            color: ColorHelper.primaryColor,
          ),
        ),
        Image.asset(
          Assets.dashboardIconPending,
          width: 16,
          height: 16,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.people,
            size: 16,
            color: ColorHelper.primaryColor,
          ),
        ),
      ],
      selectedIndex: state.selectedMetricIndex,
      onTaps: [
        () => cubit.onMetricTap(0),
        () => cubit.onMetricTap(1),
        () => cubit.onMetricTap(2),
      ],
    );
  }

  Widget _buildAddNewUserButton(BuildContext context) {
    return EmergexButton(
      onPressed: () => UserManagementUtils.showAddUserOptionsDialog(context),
      text: TextHelper.addNewUser,
      leadingIcon: Icon(
        Icons.add,
        size: 18,
        color: ColorHelper.white,
        fontWeight: FontWeight.w600,
      ),
      textSize: 14,
      fontWeight: FontWeight.w600,
      borderRadius: 24,
      buttonHeight: 48,
    );
  }

  Widget _buildUserListSection(
    BuildContext context,
    UserManagementState state,
    UserManagementCubit cubit,
  ) {
    return AppContainer(
      padding: const EdgeInsets.all(12),
      radius: 24,
      alpha: 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TextHelper.emergex,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ColorHelper.userCardTitle,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SearchBarWidget(
                  key: searchBarKey,
                  hintText: TextHelper.search,
                  onChanged: cubit.onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => UserFilterWidget.show(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: ColorHelper.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      Assets.funnelIcon,
                      color: ColorHelper.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Error state
          if (state.processState == UserManagementProcessState.error)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage ?? TextHelper.somethingWentWrong,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColorHelper.tertiaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => cubit.loadUsers(),
                      child: Text(
                        TextHelper.retry,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: ColorHelper.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Empty state
          else if (state.processState == UserManagementProcessState.loaded &&
              state.users.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  TextHelper.noProjectsFor,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorHelper.tertiaryColor,
                  ),
                ),
              ),
            )
          // User list
          else if (state.users.isNotEmpty)
            ...state.users.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < state.users.length - 1 ? 10 : 0,
                ),
                child: UserListCardWidget(
                  user: user,
                  onDelete: () =>
                      UserManagementUtils.confirmDeleteUser(context, user.id),
                ),
              );
            }),

          const SizedBox(height: 12),

          // Pagination controls
          if (state.processState == UserManagementProcessState.loaded)
            Center(
              child: AppPaginationControls(
                totalPages: state.totalPages,
                currentPage: state.currentPage,
                onPageChanged: cubit.goToPage,
              ),
            ),
        ],
      ),
    );
  }
}
