class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

sealed class ApiResult<T> {
  const ApiResult();
}

class ApiOk<T> extends ApiResult<T> {
  final T data;
  const ApiOk(this.data);
}

class ApiErr<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  final String? code;
  final String? reason;
  const ApiErr(this.message, [this.statusCode, this.code, this.reason]);
}
