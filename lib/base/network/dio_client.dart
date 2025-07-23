import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../local_storage/app_storage.dart';
import 'api_routes.dart';

final appDio = Provider((ref) => DioClient(storage: ref.read(appStorage)).generalDio);

class DioClient{
  final AppStorage storage;

  DioClient({required this.storage});

  Dio get generalDio{
    return Dio(BaseOptions(baseUrl: ApiRoutes.baseUrl))
      ..interceptors.addAll([
        _authInterceptor,
        if (kDebugMode)
          _loggerInterceptor
      ]);
  }
  InterceptorsWrapper get _authInterceptor => InterceptorsWrapper(
      onRequest: (options, handler) async {
        //todo: read access token
        final accessToken = null;
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers[HttpHeaders.authorizationHeader] =
          'Bearer $accessToken';
        }
        handler.next(options);
      }
  );
  Interceptor get _loggerInterceptor => PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
      enabled: kDebugMode,
      filter: (options, args){
        // don't print requests with uris containing '/posts'
        if(options.path.contains('/posts')){
          return false;
        }
        // don't print responses with unit8 list data
        return !args.isResponse || !args.hasUint8ListData;
      }
  );
}