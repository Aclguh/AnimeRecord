/// 通用业务结果封装（基于 Dart 3 sealed class，支持类型安全的模式匹配穷尽处理）
sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Failure() => null,
      };

  E? get errorOrNull => switch (this) {
        Failure(:final error) => error,
        Success() => null,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(E error) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Failure(:final error) => failure(error),
    };
  }
}

/// 成功业务结果
final class Success<T, E> extends Result<T, E> {
  final T data;
  const Success(this.data);
}

/// 失败业务结果
final class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}
