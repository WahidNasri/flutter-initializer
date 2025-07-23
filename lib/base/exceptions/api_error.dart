class ApiError {
  static ApiError? tryParse(dynamic data, int? statusCode) {
    try {
      if (statusCode == 401) {
        return ExpiredTokenApiError(code: statusCode.toString());
      } else if (statusCode == 413) {
        return PayloadTooLargeApiError(code: statusCode.toString());
      } else if (data is Map<String, dynamic>) {
        return ApiError.fromJson(data);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  final bool? success;
  final int? statusCode;
  final String code;
  final String? message;
  ApiError({required this.code, this.message, this.statusCode, this.success});

  ApiError.fromJson(Map<String, dynamic> m)
      : success = m['success'],
        statusCode = m['statusCode'],
        code = m['code'].toString(),
        message = m['message'];
}

class ExpiredTokenApiError extends ApiError {
  ExpiredTokenApiError({required super.code});
}

class PayloadTooLargeApiError extends ApiError {
  PayloadTooLargeApiError({required super.code});
}
