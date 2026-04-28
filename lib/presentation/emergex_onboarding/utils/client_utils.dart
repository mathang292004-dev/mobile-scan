import 'dart:io';
import 'dart:math';
import 'package:emergex/di/app_di.dart';
import 'package:emergex/generated/assets.dart';
import 'package:emergex/generated/color_helper.dart';
import 'package:emergex/helpers/nav_helper/nav_helper.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/client_view_cubit/client_form_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/client_view_cubit/filter_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/client_view_cubit/image_picker_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/cubit/project_view_cubit/project_filter_cubit.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_filter_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/client_request.dart';
import 'package:emergex/presentation/emergex_onboarding/model/project_filter_request.dart';
import 'package:flutter/material.dart';
import 'package:emergex/helpers/widgets/inputs/search_bar_widget.dart';

class ClientUtils {
  /// Check if button should be enabled based on current form state
  static bool isButtonEnabled({
    required ClientFormState formState,
    required File? profileFile,
    required String? imagePath,
    required bool isEditMode,
    required String? clientName,
    required String? email,
    required String? industry,
    required String? location,
    required String? profileUrl,
    String? initialStatus,
  }) {
    if (isEditMode) {
      // In edit mode: button enabled only if something changed
      final nameChanged = formState.name.trim() != (clientName ?? '');
      final emailChanged = formState.email.trim() != (email ?? '');
      final industryChanged = formState.industry.trim() != (industry ?? '');
      final locationChanged = formState.location.trim() != (location ?? '');
      final normalizedInitial = ClientFormCubit.normalizeStatus(initialStatus);
      final statusChanged = formState.status != normalizedInitial;

      // Check if image changed
      final hadOriginalImage = profileUrl != null && profileUrl.isNotEmpty;
      bool imageChanged;
      if (hadOriginalImage) {
        final imageStillThere =
            imagePath != null &&
            imagePath.isNotEmpty &&
            imagePath == profileUrl;
        final imageCleared = profileFile == null && !imageStillThere;
        final imageReplaced = profileFile != null;
        imageChanged = imageCleared || imageReplaced;
      } else {
        imageChanged = profileFile != null;
      }

      return nameChanged || emailChanged || industryChanged || locationChanged || imageChanged || statusChanged;
    } else {
      // In add mode: button enabled only if all required fields are filled
      final nameFilled = formState.name.trim().isNotEmpty;
      final emailFilled = formState.email.trim().isNotEmpty;
      final industryFilled = formState.industry.trim().isNotEmpty;
      final locationFilled = formState.location.trim().isNotEmpty;

      return nameFilled && emailFilled && industryFilled && locationFilled;
    }
  }

  /// Handle client submit (add or update)
  static void handleSubmit({
    required BuildContext context,
    required TextEditingController nameController,
    required TextEditingController idController,
    required TextEditingController emailController,
    required TextEditingController industryController,
    required TextEditingController locationController,
    required File? profileFile,
    required bool isEditMode,
    String? status,
    String? imagePath,
    String? profileUrl,
  }) {
    // Convert display label → API value
    String? apiStatus;
    if (isEditMode && status != null) {
      apiStatus = status.toLowerCase();
    }

    // Detect image deletion: had an original image, no new file selected, and path was cleared
    bool deleteImage = false;
    if (isEditMode && profileFile == null) {
      final hadOriginalImage = profileUrl != null && profileUrl.isNotEmpty;
      final imageStillThere =
          imagePath != null && imagePath.isNotEmpty && imagePath == profileUrl;
      deleteImage = hadOriginalImage && !imageStillThere;
    }

    final request = ClientRequest(
      clientName: nameController.text.trim(),
      clientId: idController.text.trim().isEmpty
          ? null
          : idController.text.trim(),
      email: emailController.text.trim(),
      industry: industryController.text.trim(),
      location: locationController.text.trim(),
      profileFile: profileFile,
      status: apiStatus,
      deleteImage: deleteImage,
    );

    final cubit = AppDI.clientCubit;
    if (isEditMode) {
      cubit.updateClient(request);
    } else {
      cubit.addClient(request);
    }
  }

  /// Generates a unique client ID in the format: CLT-XXXXX
  static String generateUniqueClientId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase();
    final randomPart = Random().nextInt(999).toRadixString(36).toUpperCase();
    return 'CLT-$timestamp$randomPart';
  }

  /// Build image widget from ImagePickerState
  static Widget buildImage(ImagePickerState imageState) {
    if (imageState.selectedImage != null) {
      return Image.file(
        imageState.selectedImage!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      );
    } else if (imageState.imagePath != null &&
        (imageState.imagePath!.startsWith('http') ||
            imageState.imagePath!.startsWith('https'))) {
      return Image.network(
        imageState.imagePath!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          Assets.categoryIcon,
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
      );
    } else {
      return Image.asset(Assets.staticLogo, fit: BoxFit.fill);
    }
  }

  static String? getCurrentSearchTextFromSearchBar(
    BuildContext context, {
    bool forClient = true,
  }) {
    try {
      final searchBarState = context
          .findAncestorStateOfType<SearchBarWidgetState>();
      final searchText = searchBarState?.getSearchBarText();
      if (searchText?.isNotEmpty ?? false) {
        return searchText;
      }
    } catch (e) {
      // Ignore
    }

    final currentSearch = forClient
        ? AppDI.clientCubit.state.appliedFilters?.search
        : AppDI.projectCubit.state.appliedFilters?.search;

    return (currentSearch?.trim().isNotEmpty ?? false) ? currentSearch : null;
  }

  static void applyFilters(BuildContext context, FilterState filterState) {
    final clientCubit = AppDI.clientCubit;
    final currentSearchText = getCurrentSearchTextFromSearchBar(
      context,
      forClient: true,
    );
    final trimmedLocation = filterState.location?.trim();

    String? searchValue = currentSearchText?.trim();
    if (searchValue?.isEmpty ?? true) {
      searchValue = filterState.search?.trim();
      if (searchValue?.isEmpty ?? false) {
        searchValue = null;
      }
    }

    clientCubit.getClients(
      filters: ClientFilterRequest(
        status: filterState.selectedStatus?.toLowerCase(),

        dateRange: filterState.fromDate != null || filterState.toDate != null
            ? DateRange(
                from: formatDate(filterState.fromDate),
                to: formatDate(filterState.toDate),
              )
            : DateRange(from: '', to: ''),
        industries: filterState.selectedIndustries.isNotEmpty
            ? filterState.selectedIndustries.toList()
            : null,
        location: trimmedLocation?.isNotEmpty == true ? trimmedLocation : null,
        search: searchValue,
      ),
    );

    back();
  }

  static void applySearch(String searchQuery) {
    final clientCubit = AppDI.clientCubit;
    final currentFilters = clientCubit.state.appliedFilters;
    final filterRequest =
        currentFilters?.copyWith(search: searchQuery.trim()) ??
        ClientFilterRequest(search: searchQuery.trim());
    clientCubit.getClients(filters: filterRequest);
  }

  static void applyProjectSearch(String searchQuery) {
    final projectCubit = AppDI.projectCubit;
    final clientId = projectCubit.state.clientId ?? '';
    if (clientId.isEmpty) return;

    final currentFilters = projectCubit.state.appliedFilters;
    final filterRequest =
        currentFilters?.copyWith(search: searchQuery.trim(), projectId: '') ??
        ProjectFilterRequest(
          search: searchQuery.trim(),
          projectId: '',
          projectName: '',
        );

    projectCubit.getProjects(clientId: clientId, filters: filterRequest);
  }

  static String? formatDate(DateTime? date) {
    if (date == null) return null;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> showClientDatePicker({
    required BuildContext context,
    required Function(DateTime) onDateSelected,
    DateTime? initialDate,
    required bool isFromDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // If selecting from date and toDate is already set, restrict to dates before toDate
    // If selecting to date and fromDate is already set, restrict to dates after fromDate
    final firstDate = isFromDate
        ? DateTime(2000)
        : (fromDate ?? DateTime(2000));
    final lastDate = isFromDate ? (toDate ?? today) : today;

    // Calculate initialDate ensuring it's within the valid range
    DateTime? calculatedInitialDate;
    if (initialDate != null) {
      // Clamp initialDate to be within firstDate and lastDate
      if (initialDate.isBefore(firstDate)) {
        calculatedInitialDate = firstDate;
      } else if (initialDate.isAfter(lastDate)) {
        calculatedInitialDate = lastDate;
      } else {
        calculatedInitialDate = initialDate;
      }
    } else {
      // Default initialDate based on context
      if (isFromDate) {
        // For from date: use toDate if set (but not after it), otherwise today
        calculatedInitialDate = toDate != null && toDate.isBefore(today)
            ? toDate
            : today;
        // Ensure it's not after lastDate
        if (calculatedInitialDate.isAfter(lastDate)) {
          calculatedInitialDate = lastDate;
        }
      } else {
        // For to date: use fromDate if set, otherwise today
        calculatedInitialDate = fromDate ?? today;
        // Ensure it's not before firstDate
        if (calculatedInitialDate.isBefore(firstDate)) {
          calculatedInitialDate = firstDate;
        }
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: calculatedInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorHelper.primaryColor,
              onPrimary: ColorHelper.white,
              surface: ColorHelper.white,
              onSurface: ColorHelper.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ColorHelper.primaryColor,
              ),
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  static bool hasMeaningfulFilters(ClientFilterRequest? filters) {
    if (filters == null) return false;
    if (filters.status?.isNotEmpty ?? false) return true;
    if (filters.dateRange?.from?.isNotEmpty ?? false) return true;
    if (filters.dateRange?.to?.isNotEmpty ?? false) return true;
    if (filters.industries?.isNotEmpty ?? false) return true;
    if (filters.location?.isNotEmpty ?? false) return true;
    if (filters.search?.isNotEmpty ?? false) return true;
    return false;
  }

  static DateTime? parseDateFromString(String? dateString) {
    if (dateString?.isEmpty ?? true) return null;
    try {
      final parts = dateString!.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  static String? capitalizeStatus(String? status) {
    if (status?.isEmpty ?? true) return null;
    final lower = status!.toLowerCase();
    if (lower == 'active') return 'Active';
    if (lower == 'inactive') return 'InActive';
    return status[0].toUpperCase() + status.substring(1);
  }

  static FilterState? getInitialFilterState() {
    final appliedFilters = AppDI.clientCubit.state.appliedFilters;
    if (!hasMeaningfulFilters(appliedFilters)) return null;

    final fromDate =
        appliedFilters!.dateRange?.from != null &&
            appliedFilters.dateRange!.from!.isNotEmpty
        ? parseDateFromString(appliedFilters.dateRange!.from)
        : null;
    final toDate =
        appliedFilters.dateRange?.to != null &&
            appliedFilters.dateRange!.to!.isNotEmpty
        ? parseDateFromString(appliedFilters.dateRange!.to)
        : null;
    final status = capitalizeStatus(appliedFilters.status);

    return FilterState(
      selectedStatus: status?.isEmpty == true ? null : status,
      selectedIndustries: appliedFilters.industries?.toSet() ?? const {},
      fromDate: fromDate,
      toDate: toDate,
      location: appliedFilters.location?.isEmpty == true
          ? null
          : appliedFilters.location,
      search: appliedFilters.search?.isEmpty == true
          ? null
          : appliedFilters.search,
    );
  }

  static void applyProjectFilters(
    BuildContext context,
    ProjectFilterState filterState,
  ) {
    final projectCubit = AppDI.projectCubit;
    final clientId = projectCubit.state.clientId ?? '';
    if (clientId.isEmpty) {
      back();
      return;
    }

    final currentSearchText = getCurrentSearchTextFromSearchBar(
      context,
      forClient: false,
    );
    final trimmedLocation = filterState.location?.trim();
    final trimmedProjectId = filterState.projectId?.trim();

    String searchValue = currentSearchText?.trim() ?? '';
    if (searchValue.isEmpty) {
      searchValue = projectCubit.state.appliedFilters?.search?.trim() ?? '';
    }

    projectCubit.getProjects(
      clientId: clientId,
      filters: ProjectFilterRequest(
        status: filterState.selectedStatus,
        dateRange: filterState.fromDate != null || filterState.toDate != null
            ? DateRange(
                from: formatDate(filterState.fromDate),
                to: formatDate(filterState.toDate),
              )
            : DateRange(from: '', to: ''),
        workSites: filterState.selectedWorkSite?.isNotEmpty == true
            ? filterState.selectedWorkSite
            : null,
        location: trimmedLocation?.isNotEmpty == true ? trimmedLocation : null,
        search: searchValue,
        projectName: '',
        projectId: trimmedProjectId?.isNotEmpty == true
            ? trimmedProjectId
            : null,
      ),
    );

    back();
  }

  static ProjectFilterState? getInitialProjectFilterState() {
    final appliedFilters = AppDI.projectCubit.state.appliedFilters;
    if (appliedFilters == null) return null;

    final fromDate =
        appliedFilters.dateRange?.from != null &&
            appliedFilters.dateRange!.from!.isNotEmpty
        ? parseDateFromString(appliedFilters.dateRange!.from)
        : null;
    final toDate =
        appliedFilters.dateRange?.to != null &&
            appliedFilters.dateRange!.to!.isNotEmpty
        ? parseDateFromString(appliedFilters.dateRange!.to)
        : null;
    final status = capitalizeStatus(appliedFilters.status);

    return ProjectFilterState(
      selectedStatus: status?.isEmpty == true ? null : status,
      selectedWorkSite: appliedFilters.workSites?.isEmpty == true
          ? null
          : appliedFilters.workSites,
      fromDate: fromDate,
      toDate: toDate,
      location: appliedFilters.location?.isEmpty == true
          ? null
          : appliedFilters.location,
      projectId: appliedFilters.projectId?.isEmpty == true
          ? null
          : appliedFilters.projectId,
    );
  }

  static Future<void> showProjectDatePicker({
    required BuildContext context,
    required Function(DateTime) onDateSelected,
    DateTime? initialDate,
    required bool isFromDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return showClientDatePicker(
      context: context,
      onDateSelected: onDateSelected,
      initialDate: initialDate,
      isFromDate: isFromDate,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
