import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env.dart';
import '../storage/token_storage.dart';
import 'api_result.dart';

/// Central Dio client with auth injection + uniform error mapping.
/// Live backend envelope: `{ success: bool, message: String, result: dynamic, code?: String }`.
/// Legacy `{ status, data }` shape is also tolerated.
class ApiClient {
  final Dio dio;
  final TokenStorage tokens;

  /// Whether the backend has responded at least once (warm).
  static bool _backendWarm = false;

  ApiClient(this.tokens)
      : dio = Dio(BaseOptions(
          baseUrl: Env.baseUrl,
          connectTimeout: Env.connectTimeout,
          receiveTimeout: Env.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        )) {
    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        // Refresh is PUBLIC (refresh_token is the credential) — never send
        // a stale access token there.
        if (options.path.contains('/auth/refresh')) {
          options.headers.remove('Authorization');
        } else if (!options.headers.containsKey('Authorization')) {
          final t = await tokens.getToken();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
        }
        if (kDebugMode) {
          debugPrint(
              '[API] ${options.method} ${options.baseUrl}${options.path}');
        }
        handler.next(options);
      },
      onResponse: (res, handler) {
        _backendWarm = true;
        if (kDebugMode) {
          final body = res.data;
          final msg = body is Map ? body['message'] : null;
          debugPrint(
              '[API] ${res.statusCode} ${res.requestOptions.path} :: $msg');
        }
        handler.next(res);
      },
      onError: (DioException e, handler) async {
        final isAuthEndpoint = e.requestOptions.path.contains('/auth/refresh') ||
            e.requestOptions.path.contains('/login') ||
            e.requestOptions.path.contains('/signup');

        // Transparent token refresh on 401 Unauthorized
        if (e.response?.statusCode == 401 && !isAuthEndpoint) {
          final rt = await tokens.getRefreshToken();
          if (rt != null && rt.isNotEmpty) {
            try {
              final tokenDio = Dio(BaseOptions(baseUrl: Env.baseUrl));
              final refreshRes = await tokenDio.post(
                '/api/user/auth/refresh',
                data: {'refresh_token': rt, 'refreshToken': rt},
              );

              final body = refreshRes.data;
              String? newToken;
              String? newRefresh;
              if (body is Map) {
                final resMap = body['result'] is Map ? body['result'] : body;
                newToken = (resMap['token'] ?? resMap['accessToken'])?.toString();
                newRefresh = (resMap['refresh_token'] ?? resMap['refreshToken'])?.toString();
              }

              if (newToken != null && newToken.isNotEmpty) {
                await tokens.saveToken(newToken);
                if (newRefresh != null && newRefresh.isNotEmpty) {
                  await tokens.saveRefreshToken(newRefresh);
                }

                // Retry original request with newly minted token
                final retryOpts = e.requestOptions;
                retryOpts.headers['Authorization'] = 'Bearer $newToken';
                final clonedResponse = await dio.fetch(retryOpts);
                return handler.resolve(clonedResponse);
              }
            } catch (_) {
              await tokens.clear();
            }
          }
        }

        if (kDebugMode) {
          final body = e.response?.data;
          final msg = body is Map
              ? (body['message'] ?? body['code'] ?? body)
              : e.message;
          debugPrint(
              '[API] ERR ${e.response?.statusCode} ${e.requestOptions.path} :: $msg');
        }
        handler.next(e);
      },
    ));
  }

  /// Wake-up ping for Render cold starts.
  /// Retries 2× with exponential backoff. Uses the cold-start timeout.
  /// Returns true if the backend responded.
  Future<bool> wakeUp() async {
    if (_backendWarm) return true;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final warmDio = Dio(BaseOptions(
          baseUrl: Env.baseUrl,
          connectTimeout: Env.coldStartTimeout,
          receiveTimeout: Env.coldStartTimeout,
        ));
        await warmDio.get('/api/user/getAllcategory');
        _backendWarm = true;
        if (kDebugMode) debugPrint('[API] Backend warm after attempt ${attempt + 1}');
        return true;
      } on DioException catch (e) {
        if (e.response != null) {
          // Got a response (even error) means backend is alive
          _backendWarm = true;
          return true;
        }
        if (attempt < 2) {
          final delay = Duration(seconds: (attempt + 1) * 2);
          if (kDebugMode) debugPrint('[API] Wake-up attempt ${attempt + 1} failed, retry in ${delay.inSeconds}s');
          await Future.delayed(delay);
        }
      }
    }
    return false;
  }

  /// Unwrap `result` (live) → `data` (legacy) → raw body.
  dynamic _unwrap(Response res) {
    final body = res.data;
    if (body is Map) {
      if (body.containsKey('result')) return body['result'];
      if (body.containsKey('data')) return body['data'];
    }
    return body;
  }

  static String? codeOf(dynamic body) {
    if (body is Map) {
      final c = body['code'];
      if (c is String && c.isNotEmpty) return c;
      final r = body['result'];
      if (r is Map && r['code'] is String) return r['code'] as String;
    }
    return null;
  }

  String _errMsg(DioException e) {
    final d = e.response?.data;
    if (d is Map) {
      for (final k in ['message', 'error', 'msg']) {
        final v = d[k];
        if (v is String && v.isNotEmpty) return v;
      }
      final r = d['result'];
      if (r is Map) {
        for (final k in ['message', 'error']) {
          final v = r[k];
          if (v is String && v.isNotEmpty) return v;
        }
      }
      if (r is String && r.isNotEmpty) return r;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Request timed out. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach server. Check your connection.';
    }
    return 'Something went wrong (${e.response?.statusCode ?? 'network'}).';
  }

  static String? reasonOf(dynamic body) {
    if (body is Map) {
      final r = body['result'];
      if (r is Map) {
        if (r['reason'] != null) return r['reason'].toString();
        if (r['castError'] != null) return r['castError'].toString();
      }
      if (body['reason'] != null) return body['reason'].toString();
      if (body['castError'] != null) return body['castError'].toString();
    }
    return null;
  }

  ApiErr<T> _err<T>(DioException e) {
    final reason = reasonOf(e.response?.data);
    if (kDebugMode && reason != null) {
      debugPrint('[API Error] Status: ${e.response?.statusCode}, Reason/castError: $reason');
    }
    return ApiErr<T>(
      _errMsg(e),
      e.response?.statusCode,
      codeOf(e.response?.data),
      reason,
    );
  }

  Future<ApiResult<dynamic>> get(String path,
      {Map<String, dynamic>? query}) async {
    try {
      final res = await dio.get(path, queryParameters: query);
      return ApiOk(_unwrap(res));
    } on DioException catch (e) {
      return _err(e);
    }
  }

  Future<ApiResult<dynamic>> post(String path, [dynamic body]) async {
    try {
      final res = await dio.post(path, data: body ?? {});
      return ApiOk(_unwrap(res));
    } on DioException catch (e) {
      return _err(e);
    }
  }

  Future<ApiResult<dynamic>> put(String path, [dynamic body]) async {
    try {
      final res = await dio.put(path, data: body ?? {});
      return ApiOk(_unwrap(res));
    } on DioException catch (e) {
      return _err(e);
    }
  }

  Future<ApiResult<dynamic>> patch(String path, [dynamic body]) async {
    try {
      final res = await dio.patch(path, data: body ?? {});
      return ApiOk(_unwrap(res));
    } on DioException catch (e) {
      return _err(e);
    }
  }

  Future<ApiResult<dynamic>> delete(String path, [dynamic body]) async {
    try {
      final res = await dio.delete(path, data: body);
      return ApiOk(_unwrap(res));
    } on DioException catch (e) {
      return _err(e);
    }
  }
}
