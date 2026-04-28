class GetUsersRequest {
  final String clientId;
  final int page;
  final int limit;
  final String search;
  final String status;
  final String startDate;
  final String endDate;
  final String filterName;
  final String filterRole;
  final String filterEmail;
  final String filterProject;
  final String sortBy;
  final String sortOrder;

  const GetUsersRequest({
    required this.clientId,
    this.page = 1,
    this.limit = 10,
    this.search = '',
    this.status = '',
    this.startDate = '',
    this.endDate = '',
    this.filterName = '',
    this.filterRole = '',
    this.filterEmail = '',
    this.filterProject = '',
    this.sortBy = 'name',
    this.sortOrder = 'asc',
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'page': page,
      'limit': limit,
      'search': search,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'filterName': filterName,
      'filterRole': filterRole,
      'filterEmail': filterEmail,
      'filterProject': filterProject,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }
}
