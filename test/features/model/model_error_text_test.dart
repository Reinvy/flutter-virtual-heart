// Unit test — pemetaan ModelErrorKind ke AppStrings (FR-04).
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_heart/core/l10n/app_strings.dart';
import 'package:virtual_heart/features/model/model_error_text.dart';
import 'package:virtual_heart/services/ai/model_service.dart';

void main() {
  const id = IndonesianStrings();
  const en = EnglishStrings();

  test('setiap ModelErrorKind punya pesan terlokalisasi di kedua bahasa', () {
    for (final kind in ModelErrorKind.values) {
      final idMessage = modelErrorMessage(id, kind);
      final enMessage = modelErrorMessage(en, kind);
      expect(idMessage.trim(), isNotEmpty, reason: 'ID kosong untuk ${kind.name}');
      expect(enMessage.trim(), isNotEmpty, reason: 'EN kosong untuk ${kind.name}');
    }
  });

  test('jenis yang berbeda memakai copy yang berbeda', () {
    expect(
      modelErrorMessage(id, ModelErrorKind.storage),
      isNot(modelErrorMessage(id, ModelErrorKind.network)),
    );
    expect(
      modelErrorMessage(en, ModelErrorKind.auth),
      isNot(modelErrorMessage(en, ModelErrorKind.unknown)),
    );
  });
}
