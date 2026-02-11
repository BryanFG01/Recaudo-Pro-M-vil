import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/business_provider.dart';

class BusinessHelper {
  /// Obtiene el business ID: primero del negocio seleccionado, si no del usuario actual.
  static String? getCurrentBusinessId(WidgetRef ref) {
    final selectedBusiness = ref.read(selectedBusinessProvider);
    if (selectedBusiness != null) return selectedBusiness.id;
    return ref.read(currentUserProvider)?.businessId;
  }

  static String getCurrentBusinessIdOrThrow(WidgetRef ref) {
    final businessId = getCurrentBusinessId(ref);
    if (businessId == null || businessId.isEmpty) {
      throw Exception('No hay un negocio seleccionado');
    }
    return businessId;
  }
}

