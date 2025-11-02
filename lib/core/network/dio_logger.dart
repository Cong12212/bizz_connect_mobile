import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioLogger extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('🌐 ━━━━━━━ REQUEST ━━━━━━━');
    debugPrint('📍 URL: ${options.uri}');
    debugPrint('🔧 Method: ${options.method}');
    debugPrint('📨 Headers: ${options.headers}');
    if (options.data != null) {
      debugPrint('📦 Data: ${options.data}');
    }
    if (options.queryParameters.isNotEmpty) {
      debugPrint('🔍 Query: ${options.queryParameters}');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('✅ ━━━━━━━ RESPONSE ━━━━━━━');
    debugPrint('📍 URL: ${response.requestOptions.uri}');
    debugPrint('📊 Status: ${response.statusCode}');
    debugPrint('📦 Data: ${response.data}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('❌ ━━━━━━━ ERROR ━━━━━━━');
    debugPrint('📍 URL: ${err.requestOptions.uri}');
    debugPrint('⚠️ Type: ${err.type}');
    debugPrint('💬 Message: ${err.message}');
    if (err.response != null) {
      debugPrint('📊 Status: ${err.response?.statusCode}');
      debugPrint('📦 Data: ${err.response?.data}');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━');
    super.onError(err, handler);
  }
}
