import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosoc/utils/jwt_claims.dart';

String _jwt(Map<String, dynamic> payload) {
  String part(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(payload)}.signature';
}

void main() {
  test('claims `permission` multiples', () {
    final token = _jwt({
      'permission': ['CREATE_COLLECTE', 'READ_SOUSCRIPTION_PRESTATION'],
    });
    expect(JwtClaims.values(token, 'permission'), [
      'CREATE_COLLECTE',
      'READ_SOUSCRIPTION_PRESTATION',
    ]);
  });

  test('claim `permission` unique', () {
    final token = _jwt({'permission': 'SCAN_BON_ENVOI'});
    expect(JwtClaims.values(token, 'permission'), ['SCAN_BON_ENVOI']);
  });

  test('jeton absent ou invalide : aucune permission', () {
    expect(JwtClaims.values(null, 'permission'), isEmpty);
    expect(JwtClaims.values('pas-un-jwt', 'permission'), isEmpty);
    expect(JwtClaims.values(_jwt({}), 'permission'), isEmpty);
  });
}
