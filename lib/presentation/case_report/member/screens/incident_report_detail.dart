import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/presentation/case_report/approver/utils/approver_utils.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/assets_damage_section.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/incident_details_card.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/incident_summary_card.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/property_damage_section.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/uploaded_files_section.dart';
import 'package:emergex/presentation/case_report/approver/widgets/view_incident/muscle_picker_widget.dart';
import 'package:emergex/presentation/case_report/member/widgets/incident_error_state.dart';
import 'package:emergex/presentation/case_report/utils/case_report_data_utils.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../generated/color_helper.dart';
import '../../../../helpers/nav_helper/nav_helper.dart';
import '../../../../helpers/routes.dart';
import '../../../../helpers/text_helper.dart';
import '../../../../helpers/widgets/core/app_bar_widget.dart';
import '../../../../helpers/widgets/core/app_scaffold.dart';
import '../../../../helpers/widgets/utils/unfocus_on_scroll_wrapper.dart';
import '../../../../data/model/incident/incident_detail.dart';

class IncidentReportDetailsScreen extends StatelessWidget {
  final String? incidentId;
  const IncidentReportDetailsScreen({super.key, this.incidentId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<IncidentDetailsCubit, IncidentDetailsState>(
      listener: (context, state) {},
      listenWhen: (previous, current) => previous != current,
      child: BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
        builder: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (incidentId != null && incidentId!.isNotEmpty) {
              final shouldLoadData =
                  state is! IncidentDetailsLoaded ||
                  state.incident.incidentId != incidentId;

              if (shouldLoadData) {
                AppDI.incidentDetailsCubit.getIncidentById(incidentId!);
              }
            }
          });

          return _buildScreen(context, state);
        },
      ),
    );
  }

  Widget _buildScreen(BuildContext context, IncidentDetailsState state) {
    return AppScaffold(
      useGradient: true,
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
      appBar: AppBarWidget(
        hasNotifications: true,
        showBottomBackButton: true,
        bottomTitle: state is IncidentDetailsLoaded && _isCurrentIncident(state)
            ? state.incident.incidentId
            : TextHelper.incidentReport,
        onPressed: () {
          performDashboardSearch();
          openScreen(Routes.homeScreen, clearOldStacks: true);
        },
      ),
      child: _buildBody(context, state),
    );
  }

  bool _isCurrentIncident(IncidentDetailsLoaded state) {
    return state.incident.incidentId == incidentId;
  }

  Widget _buildBody(BuildContext context, IncidentDetailsState state) {
    if (state is IncidentDetailsError) {
      return IncidentErrorState(
        incidentId: incidentId,
        errorMessage: state.message,
      );
    } else if (state is IncidentDetailsLoaded && _isCurrentIncident(state)) {
      return _buildIncidentDetails(context, state.incident);
    } else {
      return _buildLoadingState();
    }
  }

  Widget _buildLoadingState() {
    return Center(child: Container());
  }

  Widget _buildIncidentDetails(BuildContext context, IncidentDetails incident) {
    return UnfocusOnScrollWrapper(
      child: RefreshIndicator(
        onRefresh: () async {
          // Clear cache and reload data
          AppDI.incidentDetailsCubit.clearCache();
          if (incidentId != null && incidentId!.isNotEmpty) {
            await AppDI.incidentDetailsCubit.getIncidentById(incidentId!);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: ColorHelper.surfaceColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: ColorHelper.surfaceColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TextHelper.emergeXCaseOverview,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: 16,
                            color: ColorHelper.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorHelper.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                Assets.summaryIcon,
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                TextHelper.summary,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: ColorHelper.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...CaseReportDataUtils.getSummaries(incident).map(
                            (summary) => IncidentSummaryCard(
                              summary: summary,
                              isEditing: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    IncidentDetailsCard(
                      incidentOverview: CaseReportDataUtils.getIncidentOverview(incident),
                      isEditing: false,
                      rowSize: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              MusclePickerWidget(injuredParts: getInjuredParts(incident)),
              const SizedBox(height: 20),
              AssetsDamageSection(
                incident: incident,
                assetsDamage: CaseReportDataUtils.getAssetsDamage(incident),
                isEditable: false,
              ),
              const SizedBox(height: 20),
              PropertyDamageSection(
                propertyDamage: CaseReportDataUtils.getPropertyDamage(incident),
                isEdit: false,
              ),

              const SizedBox(height: 20),
              UploadedFilesSection(uploadedFiles: incident.uploadedFiles!),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
