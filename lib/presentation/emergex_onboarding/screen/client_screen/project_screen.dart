import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/permission_helper.dart';
import 'package:emergex/helpers/routes.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/feedback/app_loader.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/project_view_cubit/project_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/widgets/client/client_search_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/project/project_card_widget.dart';

class ClientProjectScreen extends StatelessWidget {
  const ClientProjectScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    this.imageUrl,
  });

  final String clientId;
  final String clientName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final GlobalKey<SearchBarWidgetState> searchBarKey =
        GlobalKey<SearchBarWidgetState>();

    // Store client context in the onboarding cubit for persistence
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (clientId.isNotEmpty && clientName.isNotEmpty) {
        AppDI.onboardingOrganizationStructureCubit.setClientContext(
          clientId,
          clientName,
        );
      }
    });

    return AppScaffold(
      useGradient: true,
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      showDrawer: false,
      appBar: AppBarWidget(hasNotifications: true),
      showBottomNav: false,
      resizeToAvoidBottomInset:
          false, // Keep bottom button fixed when keyboard opens
      child: BlocConsumer<ProjectCubit, ProjectState>(
        listener: (context, state) {
          if (state.processState == ProcessState.error &&
              state.errorMessage != null &&
              state.errorMessage!.isNotEmpty) {
            showSnackBar(context, state.errorMessage!, isSuccess: false);
          }
          // Only show delete success messages here (create/update are handled in dialogs)
          if (state.successMessage != null &&
              state.successMessage!.isNotEmpty &&
              state.successMessage!.toLowerCase().contains('deleted')) {
            showSnackBar(context, state.successMessage!, isSuccess: true);
            // Clear success message after showing
            AppDI.projectCubit.clearError();
          }
          if (state.processState == ProcessState.loading) {
            loaderService.showLoader();
          } else if (state.processState == ProcessState.done ||
              state.processState == ProcessState.error) {
            loaderService.hideLoader();
          }
        },
        builder: (context, state) {
          // Fallback to Cubit state if constructor args are empty
          final displayClientName = clientName.isNotEmpty
              ? clientName
              : (AppDI
                        .onboardingOrganizationStructureCubit
                        .state
                        .selectedClientName ??
                    'Unknown Client');
          final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
          return Stack(
            children: [
              // 🔹 SCROLLABLE CONTENT
              RefreshIndicator(
                onRefresh: () async {
                  await AppDI.projectCubit.refreshProjects();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 90),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                openScreen(
                                  Routes.clientViewScreen,
                                  clearOldStacks: true,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ColorHelper.white.withValues(
                                    alpha: 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: ColorHelper.textLight,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_left,
                                  size: 24,
                                  color: ColorHelper.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  displayClientName,
                                  maxLines: 3,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: ColorHelper.textSecondary,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 8),
                          child: Text(
                            'Manage all onboarding projects for $displayClientName',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: ColorHelper.tertiaryColor),
                          ),
                        ),

                        const SizedBox(height: 10),

                        ClientSearchHeader(
                          searchBarKey: searchBarKey,
                          isApex: true,
                          projectSection: true,
                          hintText: 'Search Project',
                        ),

                        const SizedBox(height: 10),

                        if (state.projects.isEmpty &&
                            state.processState != ProcessState.loading)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  Assets.noProjectImg,
                                  height: 120,
                                  width: 120,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  TextHelper.noProjectsFor,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    TextHelper.noProjectsForProject,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium!.color,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: [
                              ...state.projects.map((project) {
                                final projectMap = {
                                  'Title': project.projectName,
                                  'code': project.projectId,
                                  'work sites': project.workSites,
                                  'location': project.location,
                                  'Employees': project.employeesAssigned,
                                  'CreatedDate': project.createdAt != null
                                      ? project.createdAt!.split('T')[0]
                                      : 'N/A',
                                  'status': project.status,
                                  'description': project.description,
                                  'uploadedStatus': project.uploadStatus,
                                };

                                return ProjectCardWidget(
                                  project: projectMap,
                                  apexscreen: false,
                                  isClient: false,
                                );
                              }),
                              const SizedBox(height: 20),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 🔹 FIXED BOTTOM BUTTON (NON-MOVABLE)
              if (!isKeyboardOpen &&
                  PermissionHelper.hasFullAccessPermission(
                    moduleName: "EmergeX Client Onboarding",
                    featureName: "Upload or Reupload files",
                  ))
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorHelper.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: EmergexButton(
                      text: TextHelper.uploadDocsForAllProjects,
                      textColor: ColorHelper.white,
                      borderRadius: 12,
                      buttonHeight: 40,
                      onPressed: () {
                        openScreen(
                          Routes.uploadDocumentsScreen,
                          args: {'selectedCategory': 'General Docs'},
                        );
                      },
                      disabled: state.projects.isEmpty,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
