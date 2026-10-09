import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:RecaudoPro/core/config/api_config.dart';

void main() {
  test('arma la URL con BASE_BACK y quita la barra final', () {
    dotenv.testLoad(fileInput: 'BASE_BACK=https://api.recaudopro.cloud/');
    expect(ApiConfig.buildApiUrl('/api/clients'), 'https://api.recaudopro.cloud/api/clients');
    expect(ApiConfig.buildApiUrlWithQuery('/api/businesses', {'code': 'DEMO 1'}),
        'https://api.recaudopro.cloud/api/businesses?code=DEMO%201');
  });

  test('sin BASE_BACK falla con un error claro (no usa un backend por defecto)', () {
    dotenv.testLoad(fileInput: 'OTRA=1');
    expect(() => ApiConfig.baseUrl, throwsA(isA<StateError>()));
  });
}
