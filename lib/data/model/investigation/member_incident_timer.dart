import 'package:equatable/equatable.dart';

class MemberIncidentTimer extends Equatable {
  final String? startTime;
  final String? endTime;
  final int? timeTaken;

  const MemberIncidentTimer({this.startTime, this.endTime, this.timeTaken});

  factory MemberIncidentTimer.fromJson(Map<String, dynamic> json) {
    return MemberIncidentTimer(
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      timeTaken: json['timeTaken'] is int
          ? json['timeTaken'] as int
          : int.tryParse(json['timeTaken']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [startTime, endTime, timeTaken];
}
