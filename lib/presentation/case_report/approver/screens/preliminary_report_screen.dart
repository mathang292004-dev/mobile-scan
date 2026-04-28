import 'dart:io';

import 'package:emergex/data/model/incident/preliminary_report_model.dart';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/dialog_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/helpers/text_helper.dart';
import 'package:emergex/helpers/widgets/core/app_bar_widget.dart';
import 'package:emergex/helpers/widgets/core/app_container.dart';
import 'package:emergex/helpers/widgets/core/app_scaffold.dart';
import 'package:emergex/helpers/widgets/feedback/movable_floating_button.dart';
import 'package:emergex/helpers/widgets/feedback/pdf_viewer_dialog.dart';
import 'package:emergex/helpers/widgets/inputs/app_textfield.dart';
import 'package:emergex/helpers/widgets/inputs/emergex_button.dart';
import 'package:emergex/presentation/case_report/approver/cubit/preliminary_report_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_cubit.dart';
import 'package:emergex/presentation/common/cubit/incident_details_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../emergex_onboarding/cubit/client_view_cubit/image_picker_cubit.dart';
import '../widgets/ai_Insights_overlay.dart';

class PreliminaryReportScreen extends StatefulWidget {
  final String incidentId;
  const PreliminaryReportScreen({super.key, required this.incidentId});

  @override
  State<PreliminaryReportScreen> createState() =>
      _PreliminaryReportScreenState();
}

class _PreliminaryReportScreenState extends State<PreliminaryReportScreen> {
  int _selectedTabIndex = 0;
  late final PreliminaryReportCubit _cubit;
  bool _pendingAdvanceTab = false;
  bool _pendingBackAfterSave = false;

  // Section 1 – Incident Category, Classification and Basic Information
  final _incidentCategoryCtrl = TextEditingController();
  final _incidentClassificationCtrl = TextEditingController();
  final _onshoreOffshoreCtrl = TextEditingController();
  final _onjobOffjobCtrl = TextEditingController();
  final _dayNightCtrl = TextEditingController();
  final _incidentDateCtrl = TextEditingController();
  final _incidentLocationCtrl = TextEditingController();
  final _briefSummaryCtrl = TextEditingController();
  final _actionsTakenCtrl = TextEditingController();
  final _propertyDamageCtrl = TextEditingController();
  final _injuryIllnessCtrl = TextEditingController();
  final _natureOfInjuryCtrl = TextEditingController();
  final _bodyAreaPartCtrl = TextEditingController();
  final _accidentTypesCtrl = TextEditingController();
  final _sourceOfInjuriesCtrl = TextEditingController();
  final _hazardousConditionsCtrl = TextEditingController();

  // Contractor Information – main fields
  final _nameOfInvolvedCtrl = TextEditingController();
  final _idBadgeIqamaCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _jobClassificationCtrl = TextEditingController();
  final _employmentTypeCtrl = TextEditingController();
  final _supervisorNameCtrl = TextEditingController();
  final _contractorEndDateCtrl = TextEditingController();
  final _insuranceProviderCtrl = TextEditingController();
  final _primeContractorCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _projectNameCtrl = TextEditingController();

  // Contractor Coordination – Prepared By
  final _preparedByNameCtrl = TextEditingController();
  // _preparedBySignatureCtrl removed – replaced by image picker
  String? _preparedBySignaturePath;
  final _preparedByDateCtrl = TextEditingController();
  final _preparedByContactCtrl = TextEditingController();

  // Contractor Coordination – Contractor Project Manager
  final _managerNameCtrl = TextEditingController();
  // _managerSignatureCtrl removed – replaced by image picker
  String? _managerSignaturePath;
  final _managerDateCtrl = TextEditingController();
  final _managerContactCtrl = TextEditingController();

  // Contractor Information – Witness and others involved
  final _witness1Ctrl = TextEditingController();
  final _witness2Ctrl = TextEditingController();
  final _witness3Ctrl = TextEditingController();
  final _witness4Ctrl = TextEditingController();

  // SAMPT fields
  final _departmentCtrl = TextEditingController();
  final _divisionCtrl = TextEditingController();
  final _divisionSapOrgCodeCtrl = TextEditingController();
  final _blNumberCtrl = TextEditingController();
  final _contractNumberCtrl = TextEditingController();
  final _divisionHeadNameCtrl = TextEditingController();
  // _divisionHeadSignatureCtrl removed – replaced by image picker
  String? _divisionHeadSignaturePath;

  // Investigation Status signature path
  String? _investigationSignaturePath;
  final _pirReceivedDateCtrl = TextEditingController();
  final _finalReportReceivedCtrl = TextEditingController();
  final _divisionSafetyCoordinatorCtrl = TextEditingController();
  final _gi6001NotificationsCtrl = TextEditingController();
  final _samptCommentsCtrl = TextEditingController();

  // Investigation Status fields
  final _causeAnalysisCtrl = TextEditingController();
  final _investigationActionStatusCtrl = TextEditingController();
  final _dateClosedCtrl = TextEditingController();

  // Section 2 – X' Appropriate Block
  final _preliminaryPageCtrl = TextEditingController();
  final _submit24hrsCtrl = TextEditingController();
  final _finalCtrl = TextEditingController();
  final _submit3daysCtrl = TextEditingController();

  @override
  void dispose() {
    _incidentCategoryCtrl.dispose();
    _incidentClassificationCtrl.dispose();
    _onshoreOffshoreCtrl.dispose();
    _onjobOffjobCtrl.dispose();
    _dayNightCtrl.dispose();
    _incidentDateCtrl.dispose();
    _incidentLocationCtrl.dispose();
    _briefSummaryCtrl.dispose();
    _actionsTakenCtrl.dispose();
    _propertyDamageCtrl.dispose();
    _injuryIllnessCtrl.dispose();
    _natureOfInjuryCtrl.dispose();
    _bodyAreaPartCtrl.dispose();
    _accidentTypesCtrl.dispose();
    _sourceOfInjuriesCtrl.dispose();
    _hazardousConditionsCtrl.dispose();
    _nameOfInvolvedCtrl.dispose();
    _idBadgeIqamaCtrl.dispose();
    _contactNumberCtrl.dispose();
    _jobTitleCtrl.dispose();
    _jobClassificationCtrl.dispose();
    _employmentTypeCtrl.dispose();
    _supervisorNameCtrl.dispose();
    _contractorEndDateCtrl.dispose();
    _insuranceProviderCtrl.dispose();
    _primeContractorCtrl.dispose();
    _clientNameCtrl.dispose();
    _projectNameCtrl.dispose();
    _preparedByNameCtrl.dispose();
    _preparedByDateCtrl.dispose();
    _preparedByContactCtrl.dispose();
    _managerNameCtrl.dispose();
    _managerDateCtrl.dispose();
    _managerContactCtrl.dispose();
    _witness1Ctrl.dispose();
    _witness2Ctrl.dispose();
    _witness3Ctrl.dispose();
    _witness4Ctrl.dispose();
    _departmentCtrl.dispose();
    _divisionCtrl.dispose();
    _divisionSapOrgCodeCtrl.dispose();
    _blNumberCtrl.dispose();
    _contractNumberCtrl.dispose();
    _divisionHeadNameCtrl.dispose();
    _pirReceivedDateCtrl.dispose();
    _finalReportReceivedCtrl.dispose();
    _divisionSafetyCoordinatorCtrl.dispose();
    _gi6001NotificationsCtrl.dispose();
    _samptCommentsCtrl.dispose();
    _causeAnalysisCtrl.dispose();
    _investigationActionStatusCtrl.dispose();
    _dateClosedCtrl.dispose();
    _preliminaryPageCtrl.dispose();
    _submit24hrsCtrl.dispose();
    _finalCtrl.dispose();
    _submit3daysCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cubit = AppDI.preliminaryReportCubit;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.fetch(widget.incidentId);
      AppDI.incidentDetailsCubit.getIncidentById(widget.incidentId);
    });
  }

  void _populateControllers(PreliminaryReportData data) {
    final i = data.incidentInfo;
    _incidentCategoryCtrl.text          = i?.incidentCategory ?? '';
    _incidentClassificationCtrl.text    = i?.incidentClassification ?? '';
    _onshoreOffshoreCtrl.text           = i?.onshoreOffshore ?? '';
    _onjobOffjobCtrl.text               = i?.onjobOffjob ?? '';
    _dayNightCtrl.text                  = i?.dayNight ?? '';
    _incidentDateCtrl.text              = i?.incidentDate ?? '';
    _incidentLocationCtrl.text          = i?.incidentLocation ?? '';
    _briefSummaryCtrl.text              = i?.briefSummary ?? '';
    _actionsTakenCtrl.text              = i?.immediateCorrectiveActions ?? '';
    _propertyDamageCtrl.text            = i?.propertyDamageDescription ?? '';
    _injuryIllnessCtrl.text             = i?.injuryDescription ?? '';
    _natureOfInjuryCtrl.text            = i?.natureOfInjury ?? '';
    _bodyAreaPartCtrl.text              = i?.bodyAreaPart ?? '';
    _accidentTypesCtrl.text             = i?.accidentTypes ?? '';
    _sourceOfInjuriesCtrl.text          = i?.sourceOfInjuries ?? '';
    _hazardousConditionsCtrl.text       = i?.hazardousConditions ?? '';
    _preliminaryPageCtrl.text           = i?.appropriateBlock?.preliminary ?? '';
    _submit24hrsCtrl.text               = i?.appropriateBlock?.submitWithin24hrs ?? '';
    _finalCtrl.text                     = i?.appropriateBlock?.finalField ?? '';
    _submit3daysCtrl.text               = i?.appropriateBlock?.submitWithin3Days ?? '';

    final c = data.contractorInfo;
    _nameOfInvolvedCtrl.text            = c?.nameOfInvolved ?? '';
    _idBadgeIqamaCtrl.text              = c?.badgeOrIqama ?? '';
    _contactNumberCtrl.text             = c?.contactNo ?? '';
    _jobTitleCtrl.text                  = c?.jobTitle ?? '';
    _jobClassificationCtrl.text         = c?.jobClassification ?? '';
    _employmentTypeCtrl.text            = c?.employmentType ?? '';
    _supervisorNameCtrl.text            = c?.supervisorName ?? '';
    _contractorEndDateCtrl.text         = c?.contractorEndDate ?? '';
    _insuranceProviderCtrl.text         = c?.insuranceProvider ?? '';
    _primeContractorCtrl.text           = c?.primeContractor ?? '';
    _clientNameCtrl.text                = c?.clientName ?? '';
    _projectNameCtrl.text               = c?.projectName ?? '';
    final w = c?.witnesses ?? [];
    _witness1Ctrl.text = w.isNotEmpty ? w[0] : '';
    _witness2Ctrl.text = w.length > 1 ? w[1] : '';
    _witness3Ctrl.text = w.length > 2 ? w[2] : '';
    _witness4Ctrl.text = w.length > 3 ? w[3] : '';

    final cc = data.contractorCoordination;
    final pb = cc?.preparedBy is Map<String, dynamic>
        ? cc!.preparedBy as Map<String, dynamic>
        : null;
    final mgr = cc?.contractorProjectManager is Map<String, dynamic>
        ? cc!.contractorProjectManager as Map<String, dynamic>
        : null;
    _preparedByNameCtrl.text    = pb?['name']?.toString() ?? '';
    _preparedBySignaturePath    = pb?['signature']?.toString();
    _preparedByDateCtrl.text    = pb?['date']?.toString() ?? '';
    _preparedByContactCtrl.text = pb?['contactNo']?.toString() ?? '';
    _managerNameCtrl.text       = mgr?['name']?.toString() ?? '';
    _managerSignaturePath       = mgr?['signature']?.toString();
    _managerDateCtrl.text       = mgr?['date']?.toString() ?? '';
    _managerContactCtrl.text    = mgr?['contactNo']?.toString() ?? '';

    final s = data.sampt;
    _departmentCtrl.text                = s?.department ?? '';
    _divisionCtrl.text                  = s?.division ?? '';
    _divisionSapOrgCodeCtrl.text        = s?.divisionSapOrgCode ?? '';
    _blNumberCtrl.text                  = s?.blNumber ?? '';
    _contractNumberCtrl.text            = s?.contractNumber ?? '';
    final dh = s?.divisionHead is Map<String, dynamic>
        ? s!.divisionHead as Map<String, dynamic>
        : null;
    _divisionHeadNameCtrl.text          = dh?['name']?.toString() ?? '';
    _divisionHeadSignaturePath          = dh?['signature']?.toString();
    _pirReceivedDateCtrl.text           = dh?['pirReceivedDate']?.toString() ?? '';
    _finalReportReceivedCtrl.text       = dh?['finalReportReceived']?.toString() ?? '';
    _divisionSafetyCoordinatorCtrl.text = dh?['divisionSafetyCoordinatorInitials']?.toString() ?? '';
    _gi6001NotificationsCtrl.text       = dh?['gi6001NotificationsMade']?.toString() ?? '';
    _samptCommentsCtrl.text             = dh?['comments']?.toString() ?? '';

    final inv = data.investigationStatus;
    _causeAnalysisCtrl.text             = inv?.incidentCauseAnalysisSystemsUsed ?? '';
    _investigationActionStatusCtrl.text = inv?.investigationActionStatus ?? '';
    _dateClosedCtrl.text                = inv?.dateClosed ?? '';
    _investigationSignaturePath         = inv?.signature?.toString();

    setState(() {});
  }

  final List<String> _tabs = [
    TextHelper.incidentInformation,
    TextHelper.contractorInformation,
    TextHelper.contractorCoordination,
    TextHelper.sampt,
    TextHelper.investigationStatusTab,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (_) => ImagePickerCubit(),
        child: BlocListener<PreliminaryReportCubit, PreliminaryReportState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state is PreliminaryReportLoaded) {
          _populateControllers(state.data);
        } else if (state is PreliminaryReportSaving) {
          showLoader(context);
        } else if (state is PreliminaryReportSaved) {
          hideLoader(context);
          _populateControllers(state.data);
          if (_pendingAdvanceTab) {
            setState(() => _selectedTabIndex++);
            _pendingAdvanceTab = false;
          }
          if (_pendingBackAfterSave) {
            _pendingBackAfterSave = false;
            back();
          }
        } else if (state is PreliminaryReportPdfReady) {
          hideLoader(context);
          showDialog(
            context: context,
            builder: (_) => PdfViewerDialog(
              pdfUrl: state.localPath,
              fileName: 'preliminary_report_${widget.incidentId}.pdf',
            ),
          );
        } else if (state is PreliminaryReportError) {
          hideLoader(context);
          _pendingBackAfterSave = false;
          showSnackBar(context, state.message, isSuccess: false);
        }
      },
      child: BlocBuilder<IncidentDetailsCubit, IncidentDetailsState>(
        bloc: AppDI.incidentDetailsCubit,
        builder: (context, incidentState) {
          final loadedIncident =
              incidentState is IncidentDetailsLoaded &&
                      incidentState.incident.incidentId == widget.incidentId
                  ? incidentState.incident
                  : null;

          return AppScaffold(
            backgroundColor: ColorHelper.primaryBackground,
            appBar: AppBarWidget(
              showBackButton: false,
              showBottomBackButton: true,
              bottomTitle: TextHelper.preliminaryReport,
              bottomTitleSuffix: '- ${widget.incidentId}',
              onPressed: () => Navigator.pop(context),
            ),
            floatingActionButton: MovableFloatingButton(onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: ColorHelper.transparent,
                isScrollControlled: true,
                builder: (context) => AiInsightsOverlay(
                  incident: loadedIncident,
                  showIncidentDetails: true,
                ),
              );
            }),
            child: BlocBuilder<PreliminaryReportCubit, PreliminaryReportState>(
              bloc: _cubit,
              builder: (context, state) {
                if (state is PreliminaryReportLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PreliminaryReportError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ColorHelper.errorColor,
                            ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildTabSelector(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildSelectedTabContent(),
                      ),
                    ),
                    _buildBottomActions(),
                  ],
                );
              },
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: ColorHelper.surfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final isSelected = index == _selectedTabIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorHelper.primaryColor
                        : ColorHelper.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      color: isSelected
                          ? ColorHelper.white
                          : ColorHelper.textTertiary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildIncidentInformation();
      case 1:
        return _buildContractorInformation();
      case 2:
        return _buildContractorCoordinationContent();
      case 3:
        return _buildSAMPTContent();
      case 4:
        return _buildInvestigationStatusContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIncidentInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Incident Category, Classification and Basic Information',
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: '',
          children: [
            _buildInputField(
              label: 'Incident Category',
              controller: _incidentCategoryCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: 'Incident classification',
              controller: _incidentClassificationCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: 'Onshore/offshore',
              controller: _onshoreOffshoreCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: 'Onjob/offjob',
              controller: _onjobOffjobCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: 'Day/night',
              controller: _dayNightCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: 'Incident date',
              controller: _incidentDateCtrl,
              isRequired: true,
              isDate: true,
            ),
            _buildInputField( 
              label: 'Incident Location',
              controller: _incidentLocationCtrl,
              isRequired: true,
              maxLines: 4,
              minLines: 3,
            ),
            _buildInputField(
              label: 'Brief summary of incident',
              controller: _briefSummaryCtrl,
              isRequired: true,
              maxLines: 4,
              minLines: 3,
            ),
            _buildInputField(
              label: 'Actions taken (Immediate corrective actions)',
              controller: _actionsTakenCtrl,
              maxLines: 3,
              minLines: 2,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 16),
              child: RichText(
                text: const TextSpan(
                  text: 'Note : ',
                  style: TextStyle(
                    color: ColorHelper.starColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text:
                          'This is different from the Intermediate and RootCauses of Incident identified in pages 5 and 6.',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
            _buildInputField(
              label: 'Describe property damage (if any)',
              controller: _propertyDamageCtrl,
            ),
            _buildInputField(
              label: 'Describe injury or illness (if any)',
              controller: _injuryIllnessCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: 'Nature of injury',
              controller: _natureOfInjuryCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: 'Body area part',
              controller: _bodyAreaPartCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: 'Accident types',
              controller: _accidentTypesCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: 'Source of injuries',
              controller: _sourceOfInjuriesCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: 'Hazardous conditions',
              controller: _hazardousConditionsCtrl,
              isRequired: true,
            ),
          ],
        ),
        const SizedBox(height: 20),
        // "X' Appropriate Block" — title inside the card, fields in inner container
        AppContainer(
          padding: const EdgeInsets.all(12),
          radius: 20,
          color: ColorHelper.userListBackgroundColor.withValues(alpha: 0.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "X' Appropriate Block",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: ColorHelper.black4,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorHelper.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildInputField(
                      label: 'Preliminary (Page 1)',
                      controller: _preliminaryPageCtrl,
                      isRequired: true,
                    ),
                    _buildInputField(
                      label: 'Submit within 24 HRS',
                      controller: _submit24hrsCtrl,
                      isRequired: true,
                    ),
                    _buildInputField(
                      label: 'Final',
                      controller: _finalCtrl,
                      isRequired: true,
                    ),
                    _buildInputField(
                      label: 'Submit within 3 DAYS',
                      controller: _submit3daysCtrl,
                      isRequired: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    int maxLines = 1,
    int minLines = 1,
    bool isDate = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: RichText(
              text: TextSpan(
                text: label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF333333),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                children: [
                  if (isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: ColorHelper.starColor),
                    ),
                ],
              ),
            ),
          ),
          AppTextField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            fillColor: ColorHelper.white.withValues(alpha: 0.7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            readOnly: isDate,
            onTap: isDate
                ? () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      controller.text =
                          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  }
                : null,
            suffixIcon: isDate
                ? const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: ColorHelper.textTertiary,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  /// Signature field with image picker – stores selected path in [imagePath]/[onImageSelected].
  Widget _buildSignaturePickerField({
    required String label,
    bool isRequired = false,
    required String? imagePath,
    required void Function(String? path) onImageSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: RichText(
              text: TextSpan(
                text: label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF333333),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                children: [
                  if (isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: ColorHelper.starColor),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                allowMultiple: false,
              );
              if (result != null && result.files.isNotEmpty) {
                onImageSelected(result.files.first.path);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ColorHelper.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: imagePath != null && imagePath.isNotEmpty
                        ? (imagePath.startsWith('http')
                            ? Image.network(
                                imagePath,
                                height: 40,
                                fit: BoxFit.contain,
                                alignment: Alignment.centerLeft,
                              )
                            : Image.file(
                                File(imagePath),
                                height: 40,
                                fit: BoxFit.contain,
                                alignment: Alignment.centerLeft,
                              ))
                        : Text(
                            label,
                            style: const TextStyle(
                              fontFamily: 'Cursive',
                              fontSize: 16,
                              color: Color(0xFF1B4D89),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ),
                  EmergexButton(
                    text: TextHelper.uploadESign,
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: false,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        onImageSelected(result.files.first.path);
                      }
                    },
                    buttonHeight: 32,
                    textSize: 11,
                    borderRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title}) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: ColorHelper.black4,
        fontSize: 14,
      ),
    );
  }

  Widget _buildContractorInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: TextHelper.contractorInformation,
          
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: '',
          children: [
            _buildInputField(
              label: TextHelper.nameOfInvolved,
              controller: _nameOfInvolvedCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.idBadgeOrIqama,
              controller: _idBadgeIqamaCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.contactNumber,
              controller: _contactNumberCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.jobTitle,
              controller: _jobTitleCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.jobClassification,
              controller: _jobClassificationCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.employmentType,
              controller: _employmentTypeCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.supervisorName,
              controller: _supervisorNameCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.contractorEndDate,
              controller: _contractorEndDateCtrl,
              isRequired: true,
              isDate: true,
            ),
            _buildInputField(
              label: TextHelper.insuranceProvider,
              controller: _insuranceProviderCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.primeContractorCompanyName,
              controller: _primeContractorCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.clientName,
              controller: _clientNameCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.projectName,
              controller: _projectNameCtrl,
              isRequired: true,
              maxLines: 3,
              minLines: 2,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: TextHelper.witnessAndOthersInvolved,
          children: [
            _buildInputField(
              label: TextHelper.witness1,
              controller: _witness1Ctrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.witness2,
              controller: _witness2Ctrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.witness3,
              controller: _witness3Ctrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.witness4,
              controller: _witness4Ctrl,
              isRequired: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSAMPTContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: TextHelper.samptUseOnly),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: '',
          children: [
            _buildInputField(
              label: TextHelper.department,
              controller: _departmentCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.division,
              controller: _divisionCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.divisionSapOrgCode,
              controller: _divisionSapOrgCodeCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.blNumberLine,
              controller: _blNumberCtrl,
              isRequired: true,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Text(
                TextHelper.blNumberFormatHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColorHelper.red,
                  fontSize: 10,
                ),
              ),
            ),
            _buildInputField(
              label: TextHelper.contractNumber,
              controller: _contractNumberCtrl,
              isRequired: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: TextHelper.divisionHead,
          children: [
            _buildInputField(
              label: TextHelper.nameLabel,
              controller: _divisionHeadNameCtrl,
              isRequired: true,
            ),
            _buildSignaturePickerField(
              label: TextHelper.signature,
              isRequired: true,
              imagePath: _divisionHeadSignaturePath,
              onImageSelected: (path) => setState(() => _divisionHeadSignaturePath = path),
            ),
            _buildInputField(
              label: TextHelper.pirReceivedDate,
              controller: _pirReceivedDateCtrl,
              isRequired: true,
              isDate: true,
            ),
            _buildInputField(
              label: TextHelper.finalReportReceived,
              controller: _finalReportReceivedCtrl,
              isRequired: true,
              isDate: true,
            ),
            _buildInputField(
              label: TextHelper.divisionSafetyCoordinatorInitials,
              controller: _divisionSafetyCoordinatorCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.gi6001NotificationsMade,
              controller: _gi6001NotificationsCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.comments,
              controller: _samptCommentsCtrl,
              isRequired: true,
              maxLines: 3,
              minLines: 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvestigationStatusContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: TextHelper.investigationStatusTab),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: '',
          children: [
            _buildInputField(
              label: TextHelper.incidentCauseAnalysisSystemsUsed,
              controller: _causeAnalysisCtrl,
            ),
            _buildInputField(
              label: TextHelper.investigationActionStatus,
              controller: _investigationActionStatusCtrl,
              isRequired: true,
            ),
            _buildInputField(
              label: TextHelper.dateClosed,
              controller: _dateClosedCtrl,
              isRequired: true,
              isDate: true,
            ),
            _buildSignaturePickerField(
              label: TextHelper.signature,
              imagePath: _investigationSignaturePath,
              onImageSelected: (path) => setState(() => _investigationSignaturePath = path),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContractorCoordinationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: TextHelper.contractorRepresentativeLine),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: TextHelper.preparedBy,
          children: [
            _buildInputField(
              label: TextHelper.nameLabel,
              controller: _preparedByNameCtrl,
              isRequired: true,
            ),
            _buildSignaturePickerField(
              label: TextHelper.signature,
              imagePath: _preparedBySignaturePath,
              onImageSelected: (path) => setState(() => _preparedBySignaturePath = path),
            ),
            _buildInputField(
              label: TextHelper.date,
              controller: _preparedByDateCtrl,
              isRequired: true,
              isDate: true,
            ),
            _buildInputField(
              label: TextHelper.contactNo,
              controller: _preparedByContactCtrl,
              isRequired: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: TextHelper.contractorProjectManager,
          children: [
            _buildInputField(
              label: TextHelper.nameLabel,
              controller: _managerNameCtrl,
              isRequired: true,
            ),
            _buildSignaturePickerField(
              label: TextHelper.signature,
              imagePath: _managerSignaturePath,
              onImageSelected: (path) => setState(() => _managerSignaturePath = path),
            ),
            _buildInputField(
              label: TextHelper.date,
              controller: _managerDateCtrl,
              isRequired: true,
              isDate: true,
            ),
            _buildInputField(
              label: TextHelper.contactNo,
              controller: _managerContactCtrl,
              isRequired: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return AppContainer(
      padding: const EdgeInsets.all(12),
      radius: 20,
      color: ColorHelper.userListBackgroundColor.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorHelper.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
          ],
          ...children,
        ],
      ),
    );
  }

  String _tabKey() => const [
        'incidentInfo',
        'contractorInfo',
        'contractorCoordination',
        'sampt',
        'investigationStatus',
      ][_selectedTabIndex];

  Map<String, dynamic> _buildCurrentTabData() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildIncidentInfoData();
      case 1:
        return _buildContractorInfoData();
      case 2:
        return _buildContractorCoordinationData();
      case 3:
        return _buildSamptData();
      case 4:
        return _buildInvestigationData();
      default:
        return {};
    }
  }

  Map<String, dynamic> _buildIncidentInfoData() => {
        'incidentCategory': _incidentCategoryCtrl.text.trim(),
        'incidentClassification': _incidentClassificationCtrl.text.trim(),
        'onshoreOffshore': _onshoreOffshoreCtrl.text.trim(),
        'onjobOffjob': _onjobOffjobCtrl.text.trim(),
        'dayNight': _dayNightCtrl.text.trim(),
        'incidentDate': _incidentDateCtrl.text.trim(),
        'incidentLocation': _incidentLocationCtrl.text.trim(),
        'briefSummary': _briefSummaryCtrl.text.trim(),
        'immediateCorrectiveActions': _actionsTakenCtrl.text.trim(),
        'propertyDamageDescription': _propertyDamageCtrl.text.trim(),
        'injuryDescription': _injuryIllnessCtrl.text.trim(),
        'natureOfInjury': _natureOfInjuryCtrl.text.trim(),
        'bodyAreaPart': _bodyAreaPartCtrl.text.trim(),
        'accidentTypes': _accidentTypesCtrl.text.trim(),
        'sourceOfInjuries': _sourceOfInjuriesCtrl.text.trim(),
        'hazardousConditions': _hazardousConditionsCtrl.text.trim(),
        'appropriateBlock': {
          'preliminary': _preliminaryPageCtrl.text.trim(),
          'submitWithin24hrs': _submit24hrsCtrl.text.trim(),
          'final': _finalCtrl.text.trim(),
          'submitWithin3Days': _submit3daysCtrl.text.trim(),
        },
      };

  Map<String, dynamic> _buildContractorInfoData() {
    final witnesses = <Map<String, dynamic>>[];
    for (final ctrl in [
      _witness1Ctrl,
      _witness2Ctrl,
      _witness3Ctrl,
      _witness4Ctrl,
    ]) {
      if (ctrl.text.trim().isNotEmpty) {
        witnesses.add({'name': ctrl.text.trim()});
      }
    }
    return {
      'nameOfInvolved': _nameOfInvolvedCtrl.text.trim(),
      'badgeOrIqama': _idBadgeIqamaCtrl.text.trim(),
      'contactNo': _contactNumberCtrl.text.trim(),
      'jobTitle': _jobTitleCtrl.text.trim(),
      'jobClassification': _jobClassificationCtrl.text.trim(),
      'employmentType': _employmentTypeCtrl.text.trim(),
      'supervisorName': _supervisorNameCtrl.text.trim(),
      'contractorEndDate': _contractorEndDateCtrl.text.trim(),
      'insuranceProvider': _insuranceProviderCtrl.text.trim(),
      'primeContractor': _primeContractorCtrl.text.trim(),
      'clientName': _clientNameCtrl.text.trim(),
      'projectName': _projectNameCtrl.text.trim(),
      'witnesses': witnesses,
    };
  }

  Map<String, dynamic> _buildContractorCoordinationData() => {
        'preparedBy': {
          'name': _preparedByNameCtrl.text.trim(),
          'signature': _preparedBySignaturePath ?? '',
          'date': _preparedByDateCtrl.text.trim(),
          'contactNo': _preparedByContactCtrl.text.trim(),
        },
        'contractorProjectManager': {
          'name': _managerNameCtrl.text.trim(),
          'signature': _managerSignaturePath ?? '',
          'date': _managerDateCtrl.text.trim(),
          'contactNo': _managerContactCtrl.text.trim(),
        },
      };

  Map<String, dynamic> _buildSamptData() => {
        'department': _departmentCtrl.text.trim(),
        'division': _divisionCtrl.text.trim(),
        'divisionSapOrgCode': _divisionSapOrgCodeCtrl.text.trim(),
        'blNumber': _blNumberCtrl.text.trim(),
        'contractNumber': _contractNumberCtrl.text.trim(),
        'divisionHead': {
          'name': _divisionHeadNameCtrl.text.trim(),
          'signature': _divisionHeadSignaturePath ?? '',
          'pirReceivedDate': _pirReceivedDateCtrl.text.trim(),
          'finalReportReceived': _finalReportReceivedCtrl.text.trim().isEmpty
              ? null
              : _finalReportReceivedCtrl.text.trim(),
          'divisionSafetyCoordinatorInitials':
              _divisionSafetyCoordinatorCtrl.text.trim(),
          'gi6001NotificationsMade':
              _gi6001NotificationsCtrl.text.trim().toLowerCase() == 'true',
          'comments': _samptCommentsCtrl.text.trim(),
        },
      };

  Map<String, dynamic> _buildInvestigationData() => {
        'incidentCauseAnalysisSystemsUsed':
            _causeAnalysisCtrl.text.trim().toLowerCase() == 'true',
        'investigationActionStatus': _investigationActionStatusCtrl.text.trim(),
        'dateClosed': _dateClosedCtrl.text.trim().isEmpty
            ? null
            : _dateClosedCtrl.text.trim(),
        'signature': _investigationSignaturePath?.isEmpty ?? true
            ? null
            : _investigationSignaturePath,
      };

  /// Validates only the required fields in the **currently visible tab**.
  bool _areCurrentTabRequiredFieldsFilled() {
    switch (_selectedTabIndex) {
      case 0: // Incident Information
        final controllers = [
          _incidentCategoryCtrl,
          _incidentClassificationCtrl,
          _onshoreOffshoreCtrl,
          _onjobOffjobCtrl,
          _dayNightCtrl,
          _incidentDateCtrl,
          _incidentLocationCtrl,
          _briefSummaryCtrl,
          _injuryIllnessCtrl,
          _natureOfInjuryCtrl,
          _bodyAreaPartCtrl,
          _accidentTypesCtrl,
          _sourceOfInjuriesCtrl,
          _hazardousConditionsCtrl,
          _preliminaryPageCtrl,
          _submit24hrsCtrl,
          _finalCtrl,
          _submit3daysCtrl,
        ];
        return controllers.every((c) => c.text.trim().isNotEmpty);

      case 1: // Contractor Information
        final controllers = [
          _nameOfInvolvedCtrl,
          _idBadgeIqamaCtrl,
          _contactNumberCtrl,
          _jobTitleCtrl,
          _jobClassificationCtrl,
          _employmentTypeCtrl,
          _supervisorNameCtrl,
          _contractorEndDateCtrl,
          _insuranceProviderCtrl,
          _primeContractorCtrl,
          _clientNameCtrl,
          _projectNameCtrl,
          _witness1Ctrl,
          _witness2Ctrl,
          _witness3Ctrl,
          _witness4Ctrl,
        ];
        return controllers.every((c) => c.text.trim().isNotEmpty);

      case 2: // Contractor Coordination
        final controllers = [
          _preparedByNameCtrl,
          _preparedByDateCtrl,
          _preparedByContactCtrl,
          _managerNameCtrl,
          _managerDateCtrl,
          _managerContactCtrl,
        ];
        return controllers.every((c) => c.text.trim().isNotEmpty);

      case 3: // SAMPT
        final controllers = [
          _departmentCtrl,
          _divisionCtrl,
          _divisionSapOrgCodeCtrl,
          _blNumberCtrl,
          _contractNumberCtrl,
          _divisionHeadNameCtrl,
          _pirReceivedDateCtrl,
          _finalReportReceivedCtrl,
          _divisionSafetyCoordinatorCtrl,
          _gi6001NotificationsCtrl,
          _samptCommentsCtrl,
        ];
        return controllers.every((c) => c.text.trim().isNotEmpty) &&
            (_divisionHeadSignaturePath?.isNotEmpty ?? false);

      case 4: // Investigation Status
        return _investigationActionStatusCtrl.text.trim().isNotEmpty &&
            _dateClosedCtrl.text.trim().isNotEmpty;

      default:
        return true;
    }
  }

  Widget _buildBottomActions() {
    final isInvestigationTab = _selectedTabIndex == 4;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ColorHelper.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: EmergexButton(
              text: TextHelper.cancel,
              onPressed: () => showLeavePageDialog(
                context,
                () => back(),
              ),
              colors: [ColorHelper.white, ColorHelper.white],
              textColor: ColorHelper.primaryColor,
              borderColor: const Color(0xFF3CA128),
              borderRadius: 8,
              buttonHeight: 48,
              textSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          if (isInvestigationTab) ...[
            Expanded(
              child: EmergexButton(
                text: TextHelper.save,
                onPressed: () {
                  if (!_areCurrentTabRequiredFieldsFilled()) {
                    showSnackBar(
                      context,
                      'Please fill all the required fields',
                      isSuccess: false,
                    );
                    return;
                  }

                  _pendingBackAfterSave = true;
                  _cubit.save(
                    widget.incidentId,
                    _tabKey(),
                    _buildCurrentTabData(),
                  );
                },
                colors: const [ColorHelper.primaryColor, ColorHelper.buttonColor],
                borderColor: ColorHelper.transparent,
                borderRadius: 30,
                buttonHeight: 48,
                textSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EmergexButton(
                text: TextHelper.exportAsPdf,
                onPressed: () => _cubit.exportPdf(widget.incidentId),
                colors: const [ColorHelper.primaryColor, ColorHelper.buttonColor],
                borderColor: ColorHelper.transparent,
                borderRadius: 8,
                buttonHeight: 48,
                textSize: 12,
              ),
            ),
          ] else ...[
            Expanded(
              child: EmergexButton(
                text: TextHelper.continueText,
                onPressed: () {
                  if (!_areCurrentTabRequiredFieldsFilled()) {
                    showSnackBar(
                      context,
                      'Please fill all the required fields',
                      isSuccess: false,
                    );
                    return;
                  }
                  _pendingAdvanceTab = true;
                  _cubit.save(
                    widget.incidentId,
                    _tabKey(),
                    _buildCurrentTabData(),
                  );
                },
                colors: const [ColorHelper.primaryColor, ColorHelper.buttonColor],
                borderColor: ColorHelper.transparent,
                borderRadius: 8,
                buttonHeight: 48,
                textSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
