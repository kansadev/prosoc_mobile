import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/utils/api_error_helper.dart';

void main() {
  group('ApiErrorHelper.isTechnicalContent', () {
    test('détecte une page HTML de maintenance / proxy', () {
      expect(
        ApiErrorHelper.isTechnicalContent(
          '<!DOCTYPE html><html><head><title>502 Bad Gateway</title></head>'
          '<body><h1>502 Bad Gateway</h1></body></html>',
        ),
        isTrue,
      );
      expect(
        ApiErrorHelper.isTechnicalContent('<h2>App offline</h2>'),
        isTrue,
      );
    });

    test('détecte exceptions, traces et JSON brut', () {
      expect(
        ApiErrorHelper.isTechnicalContent(
          'System.NullReferenceException: Object reference not set',
        ),
        isTrue,
      );
      expect(
        ApiErrorHelper.isTechnicalContent(
          'Erreur\n   at Prosoc.Api.Controllers.AdhesionController.Create()',
        ),
        isTrue,
      );
      expect(ApiErrorHelper.isTechnicalContent('{"type":"x"}'), isTrue);
    });

    test('laisse passer les messages métier', () {
      expect(
        ApiErrorHelper.isTechnicalContent(
          'Le solde du compte virtuel est insuffisant.',
        ),
        isFalse,
      );
      expect(
        ApiErrorHelper.isTechnicalContent(
          "Un paiement électronique est déjà en cours pour cet affilié.",
        ),
        isFalse,
      );
      expect(ApiErrorHelper.isTechnicalContent(null), isFalse);
    });
  });

  test('sanitizeForDisplay remplace le HTML par un message utilisateur', () {
    expect(
      ApiErrorHelper.sanitizeForDisplay('<html>503</html>', statusCode: 503),
      ApiErrorHelper.userFacingMessage(statusCode: 503),
    );
    expect(
      ApiErrorHelper.sanitizeForDisplay('Téléphone invalide.'),
      'Téléphone invalide.',
    );
  });
}
