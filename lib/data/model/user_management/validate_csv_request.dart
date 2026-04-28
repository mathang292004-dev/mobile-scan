import 'dart:io';

class ValidateCsvRequest {
  final String clientId;
  final File file;

  const ValidateCsvRequest({
    required this.clientId,
    required this.file,
  });
}
