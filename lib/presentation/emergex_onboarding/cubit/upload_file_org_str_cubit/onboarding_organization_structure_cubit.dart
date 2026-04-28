import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:emergex/base/cubit/emergex_app_state.dart';
import 'package:emergex/data/model/upload_doc/fetch_roles_response.dart';
import 'package:emergex/data/model/upload_doc/incident_file_upload_response.dart';
import 'package:emergex/data/model/upload_doc/upload_doc_onboarding.dart';
import 'package:emergex/presentation/emergex_onboarding/use_cases/upload_doc_use_case/upload_doc_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingOrganizationStructureState extends Equatable {
  const OnboardingOrganizationStructureState({
    this.onboardingOrganizationStructure,
    this.processState = ProcessState.none,
    this.isLoading = false,
    this.errorMessage,
    this.uploadedFiles = const {},
    this.selectedCategory = 'Project Specific',
    this.isUploadingDocument = false,
    this.uploadProgress = 0.0,
    this.fetchedRoles,
    this.selectedProjectId,
    this.fileUploadProgress = const {},
    this.uploadingFileNames = const {},
    this.selectedClientId,
    this.selectedClientName,
    this.navigationSource,
    this.isAmendDoc = false,
  });

  final OnboardingOrganizationStructure? onboardingOrganizationStructure;
  final ProcessState processState;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, List<UploadedFileItem>> uploadedFiles;
  final String selectedCategory;
  final bool isUploadingDocument;
  final double uploadProgress;
  final FetchRolesResponse? fetchedRoles;
  final String? selectedProjectId;
  // Map of file identifier (path) to upload progress (0.0 to 1.0)
  final Map<String, double> fileUploadProgress;
  // Map of file identifier (path) to file name for display
  final Map<String, String> uploadingFileNames;
  // Client context to preserve during navigation
  final String? selectedClientId;
  final String? selectedClientName;
  // Navigation source to track which screen initiated navigation to RolesScreen
  // Values: 'projectListScreen' or 'viewProjectScreen'
  final String? navigationSource;
  // Whether the current upload is an amend doc operation
  final bool isAmendDoc;

  factory OnboardingOrganizationStructureState.initial() =>
      const OnboardingOrganizationStructureState(
        processState: ProcessState.none,
        uploadedFiles: {},
        selectedCategory: 'Project Specific',
        fileUploadProgress: {},
        uploadingFileNames: {},
        navigationSource: null,
        isAmendDoc: false,
      );

  /// Get files for the selected category
  List<UploadedFileItem> get filesForSelectedCategory =>
      uploadedFiles[selectedCategory] ?? [];

  OnboardingOrganizationStructureState copyWith({
    OnboardingOrganizationStructure? onboardingOrganizationStructure,
    ProcessState? processState,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Map<String, List<UploadedFileItem>>? uploadedFiles,
    String? selectedCategory,
    bool? isUploadingDocument,
    double? uploadProgress,
    FetchRolesResponse? fetchedRoles,
    String? selectedProjectId,
    bool clearSelectedProjectId = false,
    Map<String, double>? fileUploadProgress,
    Map<String, String>? uploadingFileNames,
    bool clearFileUploadProgress = false,
    String? selectedClientId,
    String? selectedClientName,
    String? navigationSource,
    bool clearNavigationSource = false,
    bool? isAmendDoc,
  }) {
    return OnboardingOrganizationStructureState(
      onboardingOrganizationStructure:
          onboardingOrganizationStructure ??
          this.onboardingOrganizationStructure,
      processState: processState ?? this.processState,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      uploadedFiles: uploadedFiles ?? this.uploadedFiles,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isUploadingDocument: isUploadingDocument ?? this.isUploadingDocument,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      fetchedRoles: fetchedRoles ?? this.fetchedRoles,
      selectedProjectId: clearSelectedProjectId
          ? null
          : (selectedProjectId ?? this.selectedProjectId),
      fileUploadProgress: clearFileUploadProgress
          ? {}
          : (fileUploadProgress ?? this.fileUploadProgress),
      uploadingFileNames: uploadingFileNames ?? this.uploadingFileNames,
      selectedClientId: selectedClientId ?? this.selectedClientId,
      selectedClientName: selectedClientName ?? this.selectedClientName,
      navigationSource: clearNavigationSource
          ? null
          : (navigationSource ?? this.navigationSource),
      isAmendDoc: isAmendDoc ?? this.isAmendDoc,
    );
  }

  @override
  List<Object?> get props => [
    onboardingOrganizationStructure,
    processState,
    isLoading,
    errorMessage,
    uploadedFiles,
    selectedCategory,
    isUploadingDocument,
    uploadProgress,
    fetchedRoles,
    selectedProjectId,
    fileUploadProgress,
    uploadingFileNames,
    selectedClientId,
    selectedClientName,
    navigationSource,
    isAmendDoc,
  ];
}

class OnboardingOrganizationStructureCubit
    extends Cubit<OnboardingOrganizationStructureState> {
  final OnboardingOrganizationStructureUseCase _useCase;
  Timer? _progressTimer;
  Timer? _fileUploadProgressTimer;
  Stopwatch? _stopwatch;
  Stopwatch? _fileUploadStopwatch;
  bool _isFileUploadCancelled = false;
  CancelToken? _fileUploadCancelToken;
  // Map of file path to its cancel token and progress timer
  final Map<String, CancelToken> _fileCancelTokens = {};
  final Map<String, Timer> _fileProgressTimers = {};
  final Map<String, Stopwatch> _fileStopwatches = {};
  // Map of file path to its category
  final Map<String, String> _fileUploadCategories = {};

  OnboardingOrganizationStructureCubit(this._useCase)
    : super(OnboardingOrganizationStructureState.initial());

  @override
  Future<void> close() {
    _progressTimer?.cancel();
    _fileUploadProgressTimer?.cancel();
    _stopwatch?.stop();
    _fileUploadStopwatch?.stop();
    _fileUploadCancelToken?.cancel('Cubit disposed');
    // Cancel all individual file uploads
    for (var cancelToken in _fileCancelTokens.values) {
      cancelToken.cancel('Cubit disposed');
    }
    for (var timer in _fileProgressTimers.values) {
      timer.cancel();
    }
    for (var stopwatch in _fileStopwatches.values) {
      stopwatch.stop();
    }
    _fileCancelTokens.clear();
    _fileProgressTimers.clear();
    _fileStopwatches.clear();
    _fileUploadCategories.clear();
    return super.close();
  }

  /// Cancel file upload (all files)
  void cancelFileUpload() {
    _isFileUploadCancelled = true;
    _fileUploadProgressTimer?.cancel();
    _fileUploadStopwatch?.stop();
    // Cancel the API request
    _fileUploadCancelToken?.cancel('File upload cancelled by user');
    _fileUploadCancelToken = null;
    emit(
      state.copyWith(
        isLoading: false,
        uploadProgress: 0.0,
        processState: ProcessState.none,
        clearFileUploadProgress: true,
      ),
    );
  }

  /// Cancel individual file upload
  void cancelFileUploadById(String filePath) {
    // Cancel the specific file's upload
    _fileCancelTokens[filePath]?.cancel('File upload cancelled by user');
    _fileProgressTimers[filePath]?.cancel();
    _fileStopwatches[filePath]?.stop();

    // Remove from maps
    _fileCancelTokens.remove(filePath);
    _fileProgressTimers.remove(filePath);
    _fileStopwatches.remove(filePath);
    _fileUploadCategories.remove(filePath);

    // Update state to remove this file's progress
    final updatedProgress = Map<String, double>.from(state.fileUploadProgress)
      ..remove(filePath);
    final updatedFileNames = Map<String, String>.from(state.uploadingFileNames)
      ..remove(filePath);

    emit(
      state.copyWith(
        fileUploadProgress: updatedProgress,
        uploadingFileNames: updatedFileNames,
        isLoading: updatedProgress.isNotEmpty,
      ),
    );
  }

  Future<void> uploadDocument(String projectId, bool isSaveAsDraft) async {
    // Cancel any existing timer
    _progressTimer?.cancel();
    _stopwatch?.stop();

    try {
      // Start upload with initial progress
      emit(
        state.copyWith(
          isUploadingDocument: !isSaveAsDraft,
          uploadProgress: 0.0,
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      // Only start progress simulation if not saving as draft
      if (!isSaveAsDraft) {
        // Start progress timer with incremental progress pattern (slower updates)
        _progressTimer = Timer.periodic(const Duration(milliseconds: 1000), (
          timer,
        ) {
          if (!state.isUploadingDocument) {
            timer.cancel();
            return;
          }

          // Get current progress
          final currentProgress = state.uploadProgress;

          // Calculate increment based on current progress
          double increment;
          if (currentProgress < 0.1) {
            increment = 0.01; // +1% if < 10%
          } else if (currentProgress < 0.2) {
            increment = 0.02; // +2% if < 20%
          } else if (currentProgress < 0.3) {
            increment = 0.03; // +3% if < 30%
          } else {
            increment = 0.04; // +4% if >= 30%
          }

          // Calculate new progress, capped at 90%
          final newProgress = math.min(currentProgress + increment, 0.90);

          emit(state.copyWith(uploadProgress: newProgress));
        });
      }

      // Build payload with uploaded file items
      final payload = buildUploadPayload(projectId, isSaveAsDraft);

      // Call use case with the payload
      final response = await _useCase.uploadDocumentWithPayload(payload);

      // Cancel progress timer
      _progressTimer?.cancel();
      _stopwatch?.stop();

      if (response.success == true && response.data != null) {
        // Complete upload successfully
        emit(
          state.copyWith(
            onboardingOrganizationStructure: response.data,
            processState: ProcessState.done,
            isUploadingDocument: false,
            uploadProgress: 1.0,
            isLoading: false,
            errorMessage: null,
            clearError: true,
            isAmendDoc: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isUploadingDocument: false,
            uploadProgress: 0.0,
            isLoading: false,
            errorMessage: response.error ?? response.message ?? 'Upload failed',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      // Cancel progress timer on error
      _progressTimer?.cancel();
      _stopwatch?.stop();

      emit(
        state.copyWith(
          processState: ProcessState.error,
          isUploadingDocument: false,
          uploadProgress: 0.0,
          isLoading: false,
          errorMessage: 'Failed to upload document: ${e.toString()}',
          clearError: false,
        ),
      );
    }
  }

  /// Upload a single file with individual progress tracking
  Future<void> _uploadSingleFile(
    File file,
    String currentSelectedCategory,
  ) async {
    final filePath = file.path;
    final fileName = file.path.split('/').last;

    // Create cancel token for this file
    final cancelToken = CancelToken();
    _fileCancelTokens[filePath] = cancelToken;
    // Store the category for this file
    _fileUploadCategories[filePath] = currentSelectedCategory;

    // Initialize progress and file name in state
    final updatedProgress = Map<String, double>.from(state.fileUploadProgress)
      ..[filePath] = 0.0;
    final updatedFileNames = Map<String, String>.from(state.uploadingFileNames)
      ..[filePath] = fileName;

    emit(
      state.copyWith(
        fileUploadProgress: updatedProgress,
        uploadingFileNames: updatedFileNames,
        isLoading: true,
        processState: ProcessState.loading,
        errorMessage: null,
        clearError: true,
      ),
    );

    // Start progress simulation
    final stopwatch = Stopwatch()..start();
    _fileStopwatches[filePath] = stopwatch;

    final progressTimer = Timer.periodic(const Duration(milliseconds: 300), (
      timer,
    ) {
      // Check if file was cancelled
      if (!_fileCancelTokens.containsKey(filePath) || cancelToken.isCancelled) {
        timer.cancel();
        return;
      }

      final elapsed = stopwatch.elapsedMilliseconds / 5000.0; // 5 seconds total
      double progress;

      // Mimic 40% → 80% → 90% → 98% pattern
      if (elapsed < 0.4) {
        progress = elapsed * 1.0; // fast: 0-40%
      } else if (elapsed < 0.8) {
        progress = 0.4 + (elapsed - 0.4) * 0.5; // medium: 40-80%
      } else if (elapsed < 0.9) {
        progress = 0.9 * elapsed; // slow: 80-90%
      } else {
        progress = math.min(elapsed, 0.98); // very slow: stop at 98%
      }

      // Update progress for this specific file
      final currentProgress = Map<String, double>.from(state.fileUploadProgress)
        ..[filePath] = progress.clamp(0.0, 0.98);
      emit(state.copyWith(fileUploadProgress: currentProgress));
    });
    _fileProgressTimers[filePath] = progressTimer;

    try {
      // Upload single file
      final response = await _useCase.uploadOrganizationStructureFiles([
        file,
      ], cancelToken: cancelToken);

      // Cancel progress timer
      progressTimer.cancel();
      stopwatch.stop();
      _fileProgressTimers.remove(filePath);
      _fileStopwatches.remove(filePath);
      _fileCancelTokens.remove(filePath);
      _fileUploadCategories.remove(filePath);

      if (response.success == true &&
          response.data != null &&
          response.data!.files.isNotEmpty) {
        // Get uploaded file items from response
        final uploadedItems = response.data!.files;

        // Add uploaded items to the selected category
        final category = currentSelectedCategory;
        final currentFiles = List<UploadedFileItem>.from(
          state.uploadedFiles[category] ?? [],
        );
        currentFiles.addAll(uploadedItems);

        final updatedFiles = Map<String, List<UploadedFileItem>>.from(
          state.uploadedFiles,
        )..[category] = currentFiles;

        // Remove this file from progress tracking
        final finalProgress = Map<String, double>.from(state.fileUploadProgress)
          ..remove(filePath);
        final finalFileNames = Map<String, String>.from(
          state.uploadingFileNames,
        )..remove(filePath);

        emit(
          state.copyWith(
            uploadedFiles: updatedFiles,
            fileUploadProgress: finalProgress,
            uploadingFileNames: finalFileNames,
            isLoading: finalProgress.isNotEmpty,
            errorMessage: null,
            clearError: true,
            processState: finalProgress.isEmpty
                ? ProcessState.done
                : ProcessState.loading,
          ),
        );
      } else {
        // Remove from progress tracking on error
        final finalProgress = Map<String, double>.from(state.fileUploadProgress)
          ..remove(filePath);
        final finalFileNames = Map<String, String>.from(
          state.uploadingFileNames,
        )..remove(filePath);

        emit(
          state.copyWith(
            fileUploadProgress: finalProgress,
            uploadingFileNames: finalFileNames,
            isLoading: finalProgress.isNotEmpty,
            errorMessage:
                response.error ??
                response.message ??
                'Failed to upload file: $fileName',
            clearError: false,
            processState: finalProgress.isEmpty
                ? ProcessState.error
                : ProcessState.loading,
          ),
        );
      }
    } catch (e) {
      // Cancel progress timer on error
      progressTimer.cancel();
      stopwatch.stop();
      _fileProgressTimers.remove(filePath);
      _fileStopwatches.remove(filePath);
      _fileCancelTokens.remove(filePath);
      _fileUploadCategories.remove(filePath);

      // Check if error is due to cancellation
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // Remove from progress tracking
        final finalProgress = Map<String, double>.from(state.fileUploadProgress)
          ..remove(filePath);
        final finalFileNames = Map<String, String>.from(
          state.uploadingFileNames,
        )..remove(filePath);

        emit(
          state.copyWith(
            fileUploadProgress: finalProgress,
            uploadingFileNames: finalFileNames,
            isLoading: finalProgress.isNotEmpty,
            processState: finalProgress.isEmpty
                ? ProcessState.none
                : ProcessState.loading,
          ),
        );
      } else {
        // Remove from progress tracking on error
        final finalProgress = Map<String, double>.from(state.fileUploadProgress)
          ..remove(filePath);
        final finalFileNames = Map<String, String>.from(
          state.uploadingFileNames,
        )..remove(filePath);

        emit(
          state.copyWith(
            fileUploadProgress: finalProgress,
            uploadingFileNames: finalFileNames,
            isLoading: finalProgress.isNotEmpty,
            errorMessage: 'Failed to upload file $fileName: ${e.toString()}',
            clearError: false,
            processState: finalProgress.isEmpty
                ? ProcessState.error
                : ProcessState.loading,
          ),
        );
      }
    }
  }

  Future<void> pickFiles(String currentSelectedCategory) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final List<File> newFiles = [];

        for (var platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (await file.exists()) {
              newFiles.add(file);
            }
          }
        }

        // Upload all files in parallel
        if (newFiles.isNotEmpty) {
          await Future.wait(
            newFiles.map(
              (file) => _uploadSingleFile(file, currentSelectedCategory),
            ),
            eagerError:
                false, // Continue uploading other files even if one fails
          );
        }
      }
    } catch (e) {
      // Handle any errors during file picking
      if (!_isFileUploadCancelled) {
        emit(
          state.copyWith(
            isLoading: state.fileUploadProgress.isNotEmpty,
            errorMessage: 'Failed to pick files: ${e.toString()}',
            clearError: false,
            processState: state.fileUploadProgress.isEmpty
                ? ProcessState.error
                : ProcessState.loading,
          ),
        );
      }
    }
  }

  Future<void> addFiles(List<File> files) async {
    if (files.isEmpty) return;

    try {
      // Show loading state
      emit(
        state.copyWith(isLoading: true, errorMessage: null, clearError: true),
      );

      // Upload files to server
      final response = await _useCase.uploadOrganizationStructureFiles(files);

      if (response.success == true &&
          response.data != null &&
          response.data!.files.isNotEmpty) {
        // Get uploaded file items from response
        final uploadedItems = response.data!.files;

        // Add uploaded items to the selected category
        final category = state.selectedCategory;
        final currentFiles = List<UploadedFileItem>.from(
          state.uploadedFiles[category] ?? [],
        );
        currentFiles.addAll(uploadedItems);

        final updatedFiles = Map<String, List<UploadedFileItem>>.from(
          state.uploadedFiles,
        )..[category] = currentFiles;

        emit(
          state.copyWith(
            uploadedFiles: updatedFiles,
            isLoading: false,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage:
                response.error ?? response.message ?? 'Failed to upload files',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to upload files: ${e.toString()}',
          clearError: false,
        ),
      );
    }
  }

  void removeFile(int index) {
    final category = state.selectedCategory;
    final categoryFiles = state.uploadedFiles[category];

    if (categoryFiles != null && index >= 0 && index < categoryFiles.length) {
      final updatedCategoryFiles = List<UploadedFileItem>.from(categoryFiles)
        ..removeAt(index);

      final updatedFiles = Map<String, List<UploadedFileItem>>.from(
        state.uploadedFiles,
      );
      if (updatedCategoryFiles.isEmpty) {
        updatedFiles.remove(category);
      } else {
        updatedFiles[category] = updatedCategoryFiles;
      }

      emit(state.copyWith(uploadedFiles: updatedFiles));
    }
  }

  void clearFiles() {
    final category = state.selectedCategory;
    final updatedFiles = Map<String, List<UploadedFileItem>>.from(
      state.uploadedFiles,
    )..remove(category);

    emit(state.copyWith(uploadedFiles: updatedFiles));
  }

  void clearAllFiles() {
    emit(state.copyWith(uploadedFiles: {}, selectedCategory: ''));
  }

  void selectCategory(String category) {
    emit(
      state.copyWith(
        selectedCategory: category,
        processState: ProcessState.done,
      ),
    );
  }

  /// Set client context for navigation state persistence
  void setClientContext(String clientId, String clientName) {
    emit(
      state.copyWith(
        selectedClientId: clientId,
        selectedClientName: clientName,
      ),
    );
  }

  /// Set navigation source for proper back navigation from RolesScreen
  /// Values: 'projectListScreen' or 'viewProjectScreen'
  void setNavigationSource(String source) {
    emit(state.copyWith(navigationSource: source));
  }

  void setAmendDoc(bool value) {
    emit(state.copyWith(isAmendDoc: value));
  }

  /// Clear navigation source when leaving the navigation context
  void clearNavigationSource() {
    emit(state.copyWith(clearNavigationSource: true));
  }

  /// Get file upload progress filtered by the selected category
  Map<String, double> getFileUploadProgressForCategory(String category) {
    final filteredProgress = <String, double>{};
    state.fileUploadProgress.forEach((filePath, progress) {
      if (_fileUploadCategories[filePath] == category) {
        filteredProgress[filePath] = progress;
      }
    });
    return filteredProgress;
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void reset() {
    emit(OnboardingOrganizationStructureState.initial());
  }

  /// Complete onboarding for a project
  Future<void> completeOnboarding(String projectId) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      final response = await _useCase.completeOnboarding(projectId);

      if (response.success == true && response.data != null) {
        emit(
          state.copyWith(
            processState: ProcessState.done,
            isLoading: false,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ??
                response.message ??
                'Failed to complete onboarding',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to complete onboarding: ${e.toString()}',
          clearError: false,
        ),
      );
    }
  }

  /// Fetch roles by projectId
  Future<void> fetchRoles(String projectId) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
          selectedProjectId: projectId,
        ),
      );

      final response = await _useCase.fetchRoles(projectId);

      if (response.success == true && response.data != null) {
        final fetchedRolesData = response.data!;
        // Update onboardingOrganizationStructure with fetched roles
        final currentStructure = state.onboardingOrganizationStructure;
        final updatedStructure = OnboardingOrganizationStructure(
          roles: fetchedRolesData.roles,
          tasks: currentStructure?.tasks,
          users: currentStructure?.users,
        );

        emit(
          state.copyWith(
            onboardingOrganizationStructure: updatedStructure,
            fetchedRoles: fetchedRolesData,
            processState: ProcessState.done,
            isLoading: false,
            selectedProjectId: projectId,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ?? response.message ?? 'Failed to fetch roles',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to fetch roles: ${e.toString()}',
          clearError: false,
        ),
      );
    }
  }

  /// Create a new role
  Future<void> createRole(Map<String, dynamic> payload) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      final response = await _useCase.createRole(payload);

      if (response.success == true && response.data != null) {
        // Update onboardingOrganizationStructure with the new role
        final currentStructure = state.onboardingOrganizationStructure;
        final currentRoles = List<Role>.from(currentStructure?.roles ?? []);

        final newRole = response.data!;

        // Check if this is an update or create
        final index = currentRoles.indexWhere(
          (r) => r.roleId == newRole.roleId,
        );
        if (index != -1) {
          currentRoles[index] = newRole;
        } else {
          currentRoles.add(newRole);
        }

        final updatedStructure = OnboardingOrganizationStructure(
          roles: currentRoles,
          tasks: currentStructure?.tasks,
          users: currentStructure?.users,
        );

        // Note: fetchRoles is NOT called here to prevent duplicate ProcessState.done
        // emissions which cause duplicate toast messages. The calling screen
        // (organized_edit_member.dart) already handles refreshing role data via
        // roleDetailsCubit.getRoleDetails() after successful save.

        emit(
          state.copyWith(
            onboardingOrganizationStructure: updatedStructure,
            processState: ProcessState.done,
            isLoading: false,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ?? response.message ?? 'Failed to create role',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to create role: ${e.toString()}',
          clearError: false,
        ),
      );
    }
  }

  /// Delete a role
  Future<void> deleteRole(String roleId, String projectId) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      final response = await _useCase.deleteRole(roleId, projectId);

      if (response.success == true) {
        // Remove the deleted role from the state
        final currentStructure = state.onboardingOrganizationStructure;
        if (currentStructure != null && currentStructure.roles != null) {
          final updatedRoles = currentStructure.roles!
              .where((role) => role.roleId != roleId)
              .toList();

          final updatedStructure = OnboardingOrganizationStructure(
            roles: updatedRoles,
            tasks: currentStructure.tasks,
            users: currentStructure.users,
          );

          emit(
            state.copyWith(
              onboardingOrganizationStructure: updatedStructure,
              processState: ProcessState.done,
              isLoading: false,
              errorMessage: null,
              clearError: true,
            ),
          );
        } else {
          emit(
            state.copyWith(
              processState: ProcessState.done,
              isLoading: false,
              errorMessage: null,
              clearError: true,
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ?? response.message ?? 'Failed to delete role',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to delete role: ${e.toString()}',
          clearError: false,
        ),
      );
    }
  }

  /// View details (docs) for a project
  /// Fetches the document section data and updates the uploadedFiles map
  Future<void> viewDetails(String projectId, String view) async {
    try {
      emit(
        state.copyWith(
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
          selectedProjectId: projectId,
        ),
      );

      final response = await _useCase.viewDetails(projectId, view);

      if (response.success == true && response.data != null) {
        final viewDetailsData = response.data!;

        // Convert ViewDetailsResponse section to uploadedFiles map format
        final Map<String, List<UploadedFileItem>> updatedFiles = {};

        if (viewDetailsData.section != null) {
          final section = viewDetailsData.section!;

          // Map API category keys to display category names
          if (section.projectSpecific.isNotEmpty) {
            updatedFiles['Project Specific'] = section.projectSpecific
                .map((item) => item.toUploadedFileItem())
                .toList();
          }

          if (section.clientsInternal.isNotEmpty) {
            updatedFiles["Client's Internal"] = section.clientsInternal
                .map((item) => item.toUploadedFileItem())
                .toList();
          }

          if (section.clientRef.isNotEmpty) {
            updatedFiles['Client Reports'] = section.clientRef
                .map((item) => item.toUploadedFileItem())
                .toList();
          }

          if (section.global.isNotEmpty) {
            updatedFiles['General Docs'] = section.global
                .map((item) => item.toUploadedFileItem())
                .toList();
          }
        }

        // Update state with the fetched files and emit the response data
        // The onboardingOrganizationStructure will be updated with the section data
        emit(
          state.copyWith(
            uploadedFiles: updatedFiles,
            onboardingOrganizationStructure: OnboardingOrganizationStructure(
              // Keep existing roles, tasks, users if any
              roles: state.onboardingOrganizationStructure?.roles,
              tasks: state.onboardingOrganizationStructure?.tasks,
              users: state.onboardingOrganizationStructure?.users,
            ),
            processState: ProcessState.done,
            isLoading: false,
            errorMessage: null,
            clearError: true,
            selectedProjectId: projectId,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isLoading: false,
            errorMessage:
                response.error ??
                response.message ??
                'Failed to fetch view details',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          processState: ProcessState.error,
          isLoading: false,
          errorMessage: 'Failed to fetch view details: ${e.toString()}',
          clearError: false,
        ),
      );
    }
  }

  /// Upload documents for all projects (General Docs category)
  Future<void> uploadDocsForAllProjects(
    List<String> projectIds,
    bool isSaveAsDraft,
  ) async {
    // Cancel any existing timer
    _progressTimer?.cancel();
    _stopwatch?.stop();

    try {
      // Start upload with initial progress
      emit(
        state.copyWith(
          isUploadingDocument: !isSaveAsDraft,
          uploadProgress: 0.0,
          processState: ProcessState.loading,
          isLoading: true,
          errorMessage: null,
          clearError: true,
        ),
      );

      // Only start progress simulation if not saving as draft
      if (!isSaveAsDraft) {
        // Start progress timer with incremental progress pattern
        _progressTimer = Timer.periodic(const Duration(milliseconds: 1000), (
          timer,
        ) {
          if (!state.isUploadingDocument) {
            timer.cancel();
            return;
          }

          final currentProgress = state.uploadProgress;
          double increment;
          if (currentProgress < 0.1) {
            increment = 0.01;
          } else if (currentProgress < 0.2) {
            increment = 0.02;
          } else if (currentProgress < 0.3) {
            increment = 0.03;
          } else {
            increment = 0.04;
          }

          final newProgress = math.min(currentProgress + increment, 0.90);
          emit(state.copyWith(uploadProgress: newProgress));
        });
      }

      // Build payload with uploaded file items for all projects
      final payload = buildUploadDocsForAllProjectsPayload(
        projectIds,
        isSaveAsDraft,
      );

      // Call the new uploadDocsForAllProjects use case
      final response = await _useCase.uploadDocsForAllProjects(payload);

      // Cancel progress timer
      _progressTimer?.cancel();
      _stopwatch?.stop();

      if (response.success == true && response.data != null) {
        // Complete upload successfully
        emit(
          state.copyWith(
            onboardingOrganizationStructure: response.data,
            processState: ProcessState.done,
            isUploadingDocument: false,
            uploadProgress: 1.0,
            isLoading: false,
            errorMessage: null,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            processState: ProcessState.error,
            isUploadingDocument: false,
            uploadProgress: 0.0,
            isLoading: false,
            errorMessage: response.error ?? response.message ?? 'Upload failed',
            clearError: false,
          ),
        );
      }
    } catch (e) {
      // Cancel progress timer on error
      _progressTimer?.cancel();
      _stopwatch?.stop();

      emit(
        state.copyWith(
          processState: ProcessState.error,
          isUploadingDocument: false,
          uploadProgress: 0.0,
          isLoading: false,
          errorMessage: 'Upload error: ${e.toString()}',
          clearError: false,
        ),
      );
    }
  }

  /// Build upload payload for all projects (General Docs)
  Map<String, dynamic> buildUploadDocsForAllProjectsPayload(
    List<String> projectIds,
    bool isSaveAsDraft,
  ) {
    // Map display category names to API category keys
    const categoryMap = {
      'Project Specific': 'projectSpecific',
      "Client's Internal": 'clientsInternal',
      'Client Reports': 'clientRef',
      'General Docs': 'global',
    };

    final Map<String, dynamic> payload = {
      'projectIds': projectIds,
      'saveAsDraft': isSaveAsDraft,
    };

    state.uploadedFiles.forEach((displayCategory, uploadedItems) {
      final apiCategoryKey = categoryMap[displayCategory];
      if (apiCategoryKey != null && uploadedItems.isNotEmpty) {
        // Convert UploadedFileItem to JSON format
        payload[apiCategoryKey] = uploadedItems
            .map(
              (item) => <String, dynamic>{
                'fileUrl': item.fileUrl,
                'key': item.key,
                'fileType': item.fileType,
                'fileSize': item.fileSize,
                'fileName': item.fileName,
              },
            )
            .toList();
      }
    });

    return payload;
  }

  /// Build upload payload with uploaded file items organized by category
  /// Returns a Map that matches the API payload structure
  Map<String, dynamic> buildUploadPayload(
    String projectId,
    bool isSaveAsDraft,
  ) {
    // Map display category names to API category keys
    const categoryMap = {
      'Project Specific': 'projectSpecific',
      "Client's Internal": 'clientsInternal',
      'Client Reports': 'clientRef',
      'General Docs': 'global',
    };

    final Map<String, dynamic> payload = {
      'projectId': projectId,
      'saveAsDraft': isSaveAsDraft,
      'amendDoc': state.isAmendDoc,
    };

    state.uploadedFiles.forEach((displayCategory, uploadedItems) {
      final apiCategoryKey = categoryMap[displayCategory];
      if (apiCategoryKey != null && uploadedItems.isNotEmpty) {
        // Convert UploadedFileItem to JSON format
        payload[apiCategoryKey] = uploadedItems
            .map(
              (item) => <String, dynamic>{
                'fileUrl': item.fileUrl,
                'key': item.key,
                'fileType': item.fileType,
                'fileSize': item.fileSize,
                'fileName': item.fileName,
              },
            )
            .toList();
      }
    });

    return payload;
  }
}
