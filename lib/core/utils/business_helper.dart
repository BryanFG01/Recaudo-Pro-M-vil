import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/business_provider.dart';

class BusinessHelper {
  static String? getCurrentBusinessId(WidgetRef ref) {
    final selectedBusiness = ref.read(selectedBusinessProvider);
    return selectedBusiness?.id;
  }

  static String? getCurrentBusinessIdOrThrow(WidgetRef ref) {
    final businessId = getCurrentBusinessId(ref);
    if (businessId == null) {
      throw Exception('No hay un negocio seleccionado');
    }
    return businessId;
  }
}

