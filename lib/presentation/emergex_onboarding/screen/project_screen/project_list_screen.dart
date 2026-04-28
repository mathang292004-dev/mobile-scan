import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/base/cubit/emergex_app_cubit.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/project/project_card_widget.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  // Static key to persist across rebuilds (e.g. keyboard open)
  // while allowing dispose on navigation.
  static final GlobalKey<SearchBarWidgetState> searchBarKey =
      GlobalKey<SearchBarWidgetState>();

  @override
  Widget build(BuildContext context) {
    final clientId =
        AppDI
            .emergexAppCubit
            .state
            .userPermissions
            ?.permissions
            .first
            .clientId ??
        '';
    // Fixed: Only fetch projects if permissions are fully loaded (prevents race condition)
    // and if the projected Client ID differs from the current one.
    final permissionState = AppDI.emergexAppCubit.state.permissionLoadingState;
    if (clientId.isNotEmpty &&
        permissionState == ProcessState.done &&
        AppDI.projectCubit.state.clientId != clientId) {
      AppDI.projectCubit.getProjects(clientId: clientId);
    }

    return AppScaffold(
      useGradient: true,
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      showDrawer: false,
      appBar: AppBarWidget(hasNotifications: true),
      showBottomNav: false,
      resizeToAvoidBottomInset: false,
      child: BlocListener<EmergexAppCubit, EmergexAppState>(
        bloc: AppDI.emergexAppCubit,
        listenWhen: (previous, current) =>
            previous.permissionLoadingState != ProcessState.done &&
            current.permissionLoadingState == ProcessState.done,
        listener: (context, state) {
          final newClientId =
              state.userPermissions?.permissions.first.clientId ?? '';
          if (newClientId.isNotEmpty) {
            // Permission loaded or changed: fetch projects
            AppDI.projectCubit.getProjects(clientId: newClientId);
          }
        },
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
            final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    await AppDI.projectCubit.refreshProjects();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: 90 + MediaQuery.of(context).viewInsets.bottom,
                    ),
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
                              if (state.clientImage != null &&
                                  state.clientImage!.startsWith('http')) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: state.clientImage!,
                                    width: 75,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Image.asset(
                                      Assets.staticLogo,
                                      width: 75,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                    errorWidget: (_, __, ___) => Image.asset(
                                      Assets.staticLogo,
                                      width: 75,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    state.clientName ?? clientId,
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
                              'Manage all onboarding projects for ${state.clientName ?? clientId}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: ColorHelper.tertiaryColor),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClientSearchHeader(
                            searchBarKey: searchBarKey,
                            isApex: true,
                            projectSection: true,
                            isClient: true,
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
                                    isClient: true,
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
                if (!isKeyboardOpen &&
                    PermissionHelper.hasFullAccessPermission(
                      moduleName: "Client Admin",
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
      ),
    );
  }
}
