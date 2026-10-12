import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recaudo_pro/core/config/api_config.dart';

void main() {
  test('arma la URL con BASE_BACK y quita la barra final', () {
    dotenv.testLoad(fileInput: 'BASE_BACK=https://api.recaudopro.cloud/');
    expect(ApiConfig.buildApiUrl('/api/clients'), 'https://api.recaudopro.cloud/api/clients');
    expect(ApiConfig.buildApiUrlWithQuery('/api/businesses', {'code': 'DEMO 1'}),
        'https://api.recaudopro.cloud/api/businesses?code=DEMO%201');
  });

  test('--dart-define tiene prioridad sobre .env (API local sin tocar .env)', () {
    expect(ApiConfig.resolveBaseUrl(compiled: 'http://192.168.40.8:3001/', fromEnv: 'https://api.recaudopro.cloud'),
        'http://192.168.40.8:3001');
    expect(ApiConfig.resolveBaseUrl(compiled: '', fromEnv: 'https://api.recaudopro.cloud/'), 'https://api.recaudopro.cloud');
  });

  test('sin BASE_BACK falla con un error claro (no usa un backend por defecto)', () {
    dotenv.testLoad(fileInput: 'OTRA=1');
    expect(() => ApiConfig.baseUrl, throwsA(isA<StateError>()));
  });
}
