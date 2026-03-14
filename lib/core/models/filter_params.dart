/// Optional filter/sort/pagination parameters sent to the API as query params.
/// All fields are nullable — null values are omitted from the query string.
class FilterParams {
  final String? search;
  final String? orderBy;
  final String? orderDir; // 'ASC' | 'DESC'
  final int? page;
  final int? limit;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  // Entity-specific filters
  final String? changeType; // 'inbound' | 'outbound' | 'adjustment'
  final bool? isRead;
  final bool? isLowStock;
  final bool? isShared;
  final bool? isAuto;
  final int? brandId;
  final int? storeId;
  final String? defaultUnit;

  const FilterParams({
    this.search,
    this.orderBy,
    this.orderDir,
    this.page,
    this.limit,
    this.dateFrom,
    this.dateTo,
    this.changeType,
    this.isRead,
    this.isLowStock,
    this.isShared,
    this.isAuto,
    this.brandId,
    this.storeId,
    this.defaultUnit,
  });

  /// Converts to a Dio queryParameters map, omitting null values.
  /// Booleans are sent as strings ('true'/'false') since the backend reads them as strings.
  /// DateTimes are sent as date-only strings ('yyyy-MM-dd').
  Map<String, dynamic> toQueryParameters() {
    final map = <String, dynamic>{};
    if (search != null) map['search'] = search;
    if (orderBy != null) map['orderBy'] = orderBy;
    if (orderDir != null) map['orderDir'] = orderDir;
    if (page != null) map['page'] = page;
    if (limit != null) map['limit'] = limit;
    if (dateFrom != null) {
      map['date_from'] =
          '${dateFrom!.year.toString().padLeft(4, '0')}-${dateFrom!.month.toString().padLeft(2, '0')}-${dateFrom!.day.toString().padLeft(2, '0')}';
    }
    if (dateTo != null) {
      map['date_to'] =
          '${dateTo!.year.toString().padLeft(4, '0')}-${dateTo!.month.toString().padLeft(2, '0')}-${dateTo!.day.toString().padLeft(2, '0')}';
    }
    if (changeType != null) map['change_type'] = changeType;
    if (isRead != null) map['is_read'] = isRead.toString();
    if (isLowStock != null) map['is_low_stock'] = isLowStock.toString();
    if (isShared != null) map['is_shared'] = isShared.toString();
    if (isAuto != null) map['is_auto'] = isAuto.toString();
    if (brandId != null) map['brand_id'] = brandId;
    if (storeId != null) map['store_id'] = storeId;
    if (defaultUnit != null) map['default_unit'] = defaultUnit;
    return map;
  }

  FilterParams copyWith({
    String? search,
    String? orderBy,
    String? orderDir,
    int? page,
    int? limit,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? changeType,
    bool? isRead,
    bool? isLowStock,
    bool? isShared,
    bool? isAuto,
    int? brandId,
    int? storeId,
    String? defaultUnit,
  }) =>
      FilterParams(
        search: search ?? this.search,
        orderBy: orderBy ?? this.orderBy,
        orderDir: orderDir ?? this.orderDir,
        page: page ?? this.page,
        limit: limit ?? this.limit,
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: dateTo ?? this.dateTo,
        changeType: changeType ?? this.changeType,
        isRead: isRead ?? this.isRead,
        isLowStock: isLowStock ?? this.isLowStock,
        isShared: isShared ?? this.isShared,
        isAuto: isAuto ?? this.isAuto,
        brandId: brandId ?? this.brandId,
        storeId: storeId ?? this.storeId,
        defaultUnit: defaultUnit ?? this.defaultUnit,
      );

  static const FilterParams empty = FilterParams();
}
