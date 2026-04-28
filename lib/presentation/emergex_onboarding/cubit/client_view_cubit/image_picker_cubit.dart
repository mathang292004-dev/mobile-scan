import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

class ImagePickerState extends Equatable {
  final File? selectedImage;
  final String? imagePath;
  final String? errorMessage;

  const ImagePickerState({
    this.selectedImage,
    this.imagePath,
    this.errorMessage,
  });

  factory ImagePickerState.initial() => const ImagePickerState();

  ImagePickerState copyWith({
    File? selectedImage,
    String? imagePath,
    String? errorMessage,
    bool clearImage = false,
    bool clearError = false,
  }) {
    return ImagePickerState(
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [selectedImage, imagePath, errorMessage];
}

class ImagePickerCubit extends Cubit<ImagePickerState> {
  ImagePickerCubit() : super(ImagePickerState.initial());

  Future<void> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        emit(
          state.copyWith(
            selectedImage: file,
            imagePath: result.files.first.path,
            clearError: true,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Failed to pick image: ${e.toString()}'),
      );
    }
  }

  void clearImage() {
    emit(state.copyWith(clearImage: true, clearError: true));
  }

  void setInitialImage(String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
        // It's a network image, just store the path
        emit(state.copyWith(imagePath: imagePath, clearError: true));
      } else {
        // It's a local file
        try {
          final file = File(imagePath);
          emit(
            state.copyWith(
              selectedImage: file,
              imagePath: imagePath,
              clearError: true,
            ),
          );
        } catch (e) {
          emit(
            state.copyWith(
              errorMessage: 'Failed to load image: ${e.toString()}',
            ),
          );
        }
      }
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
