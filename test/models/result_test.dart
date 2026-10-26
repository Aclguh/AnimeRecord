import 'package:anime_record/models/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result<T, E> Tests', () {
    test('Success returns expected properties and executes when branch', () {
      const Result<int, String> result = Success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 42);
      expect(result.errorOrNull, isNull);

      final val = result.when(
        success: (data) => 'got $data',
        failure: (err) => 'err $err',
      );
      expect(val, 'got 42');
    });

    test('Failure returns expected properties and executes when branch', () {
      const Result<int, String> result = Failure('something went wrong');

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.errorOrNull, 'something went wrong');

      final val = result.when(
        success: (data) => 'got $data',
        failure: (err) => 'err: $err',
      );
      expect(val, 'err: something went wrong');
    });
  });
}
