// Unit test — klasifikasi error model lokal & Cloud BYOK (Genkit).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genkit/genkit.dart' as gk;
import 'package:virtual_heart/services/ai/model_service.dart';

void main() {
  group('classifyModelError', () {
    test('ModelException diteruskan apa adanya', () {
      expect(
        classifyModelError(const ModelException(ModelErrorKind.storage)),
        ModelErrorKind.storage,
      );
    });

    test('GenkitException & TimeoutException dipetakan ke kind yang tepat', () {
      expect(
        classifyModelError(
          gk.GenkitException('Bad key', status: gk.StatusCode.unauthenticated),
        ),
        ModelErrorKind.auth,
      );
      expect(
        classifyModelError(
          gk.GenkitException('Quota', status: gk.StatusCode.resourceExhausted),
        ),
        ModelErrorKind.rateLimited,
      );
      expect(
        classifyModelError(
          gk.GenkitException('Missing model', status: gk.StatusCode.notFound),
        ),
        ModelErrorKind.notFound,
      );
      expect(
        classifyModelError(
          gk.GenkitException('Bad param', status: gk.StatusCode.invalidArgument),
        ),
        ModelErrorKind.invalidConfig,
      );
      expect(
        classifyModelError(
          gk.GenkitException('Slow', status: gk.StatusCode.deadlineExceeded),
        ),
        ModelErrorKind.timeout,
      );
      expect(
        classifyModelError(gk.CancelledException(reason: 'stop')),
        ModelErrorKind.cancelled,
      );
      expect(classifyModelError(TimeoutException('late')), ModelErrorKind.timeout);
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
