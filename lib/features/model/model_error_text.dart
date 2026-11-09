// Teks error model (FR-04) — dipetakan dari [ModelErrorKind] ke AppStrings.
//
// Dipisah dari widget agar bisa diuji tanpa membangun widget tree.
import '../../core/l10n/app_strings.dart';
import '../../services/ai/model_service.dart';

String modelErrorMessage(AppStrings strings, ModelErrorKind kind) => switch (kind) {
  ModelErrorKind.network => strings.modelErrorNetwork,
  ModelErrorKind.auth => strings.modelErrorAuth,
  ModelErrorKind.notFound => strings.modelErrorNotFound,
  ModelErrorKind.rateLimited => strings.modelErrorRateLimit,
  ModelErrorKind.storage => strings.modelErrorStorage,
  ModelErrorKind.invalidFile => strings.modelErrorInvalidFile,
  ModelErrorKind.engine => strings.modelErrorEngine,
  ModelErrorKind.cancelled => strings.modelCancelledSnack,
  ModelErrorKind.unknown => strings.modelErrorUnknown,
};
