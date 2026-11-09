// Unit test — klasifikasi error model (FR-04).
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/services/ai/model_service.dart';

void main() {
  group('classifyModelError', () {
    test('ModelException diteruskan apa adanya', () {
      expect(
        classifyModelError(const ModelException(ModelErrorKind.storage)),
        ModelErrorKind.storage,
      );
    });

    test('status HTTP dipetakan ke jenis yang tepat', () {
      expect(classifyModelError(Exception('HTTP 404 Not Found')), ModelErrorKind.notFound);
      expect(classifyModelError(Exception('HTTP 401')), ModelErrorKind.auth);
      expect(classifyModelError(Exception('HTTP 403 forbidden')), ModelErrorKind.auth);
      expect(classifyModelError(Exception('429 Too Many Requests')), ModelErrorKind.rateLimited);
    });

    test('pembatalan dan penyimpanan dikenali', () {
      expect(classifyModelError(Exception('Download cancelled by user')), ModelErrorKind.cancelled);
      expect(classifyModelError(Exception('ENOSPC: no space left')), ModelErrorKind.storage);
    });

    test('file rusak dan kegagalan engine dikenali', () {
      expect(classifyModelError(Exception('invalid model format')), ModelErrorKind.invalidFile);
      expect(classifyModelError(StateError('Model not ready')), ModelErrorKind.engine);
      expect(classifyModelError(const ContextLimitReachedException()), ModelErrorKind.engine);
    });

    test('error jaringan dikenali', () {
      expect(
        classifyModelError(Exception('SocketException: Failed host lookup')),
        ModelErrorKind.network,
      );
    });

    test('sisanya unknown', () {
      expect(classifyModelError(Exception('???')), ModelErrorKind.unknown);
    });
  });
}
