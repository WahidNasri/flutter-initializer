import 'package:dio/dio.dart';

import '../exceptions/api_error.dart';
import '../exceptions/base_error.dart';

abstract mixin class BaseRepository {
  RepositoryError handleError({
    String? location,
    required dynamic error,
    StackTrace? stackTrace,
  }) {
    if (error is DioException) {
      return _handleDioError(
        error: error,
        stackTrace: stackTrace,
      );
    }
    return RepositoryError(error: error, stackTrace: stackTrace);
  }

  RepositoryError _handleDioError({
    required DioException error,
    required StackTrace? stackTrace,
  }) {
    if (error.response != null) {
      ApiError? apiError = ApiError.tryParse(
        error.response!.data,
        error.response!.statusCode ?? 0,
      );
      if (apiError != null) {
        return RepositoryError(error: apiError);
      }
    }
    return RepositoryError(error: error, stackTrace: stackTrace);
  }
}
