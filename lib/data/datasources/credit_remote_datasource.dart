import '../../core/config/supabase_config.dart';
import '../../domain/entities/credit_entity.dart';
import '../models/credit_model.dart';

abstract class CreditRemoteDataSource {
  Future<List<CreditEntity>> getCredits();
  Future<List<CreditEntity>> getCreditsByClientId(String clientId);
  Future<CreditEntity?> getCreditById(String id);
  Future<CreditEntity> createCredit(CreditEntity credit, {String? businessId});
  Future<CreditEntity> updateCredit(CreditEntity credit, {String? businessId});
}

class CreditRemoteDataSourceImpl implements CreditRemoteDataSource {
  @override
  Future<List<CreditEntity>> getCredits() async {
    try {
      final response = await SupabaseConfig.client
          .from('credits')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CreditModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener créditos: $e');
    }
  }

  @override
  Future<List<CreditEntity>> getCreditsByClientId(String clientId) async {
    try {
      final response = await SupabaseConfig.client
          .from('credits')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CreditModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener créditos del cliente: $e');
    }
  }

  @override
  Future<CreditEntity?> getCreditById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from('credits')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return CreditModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Error al obtener crédito: $e');
    }
  }

  @override
  Future<CreditEntity> createCredit(CreditEntity credit,
      {String? businessId}) async {
    try {
      final creditModel = CreditModel(
        id: credit.id,
        clientId: credit.clientId,
        totalAmount: credit.totalAmount,
        installmentAmount: credit.installmentAmount,
        totalInstallments: credit.totalInstallments,
        paidInstallments: credit.paidInstallments,
        overdueInstallments: credit.overdueInstallments,
        totalBalance: credit.totalBalance,
        lastPaymentAmount: credit.lastPaymentAmount,
        lastPaymentDate: credit.lastPaymentDate,
        createdAt: credit.createdAt,
        nextDueDate: credit.nextDueDate,
      );

      final response = await SupabaseConfig.client
          .from('credits')
          .insert(creditModel.toJson(businessId: businessId))
          .select()
          .single();

      return CreditModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Error al crear crédito: $e');
    }
  }

  @override
  Future<CreditEntity> updateCredit(CreditEntity credit,
      {String? businessId}) async {
    try {
      /*
      final creditModel = CreditModel(
        id: credit.id,
        clientId: credit.clientId,
        totalAmount: credit.totalAmount,
        installmentAmount: credit.installmentAmount,
        totalInstallments: credit.totalInstallments,
        paidInstallments: credit.paidInstallments,
        overdueInstallments: credit.overdueInstallments,
        totalBalance: credit.totalBalance,
        lastPaymentAmount: credit.lastPaymentAmount,
        lastPaymentDate: credit.lastPaymentDate,
        createdAt: credit.createdAt,
        nextDueDate: credit.nextDueDate,
      );
      */

      // Construir mapa solo con los campos que cambian al realizar un pago
      // Esto evita problemas de RLS al tratar de actualizar campos que no deberían cambiar (como total_amount, etc.)
      final Map<String, dynamic> updateData = {
        'paid_installments': credit.paidInstallments,
        'total_balance': credit.totalBalance,
        'last_payment_amount': credit.lastPaymentAmount,
        'last_payment_date': credit.lastPaymentDate?.toIso8601String(),
        'overdue_installments': credit.overdueInstallments,
        // Incluir cualquier otro campo que se modifique durante el pago
      };

      // Si next_due_date cambia, incluirlo
      if (credit.nextDueDate != null) {
        updateData['next_due_date'] = credit.nextDueDate!.toIso8601String();
      }

      // Construir la consulta con filtros
      print('DEBUG: Attempting to update credit ${credit.id}');
      print('DEBUG: New balance: ${credit.totalBalance}');
      print('DEBUG: Update Payload keys: ${updateData.keys.toList()}');
      print('DEBUG: Business ID: $businessId');

      var query = SupabaseConfig.client
          .from('credits')
          .update(updateData)
          .eq('id', credit.id);

      // Filtrar por business_id si está disponible (requerido por RLS)
      if (businessId != null) {
        query = query.eq('business_id', businessId);
        print('DEBUG: Filtering by business_id: $businessId');
      }

      final responseList = await query.select();

      print(
          'DEBUG: Update response list length: ${(responseList as List).length}');

      if ((responseList as List).isEmpty) {
        print('DEBUG: Update failed - No rows returned');
        throw Exception(
            'No se encontró el crédito para actualizar. Verifica que pertenezca a tu negocio.');
      }

      final response = responseList.first;
      return CreditModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      print('DEBUG: Exception in updateCredit: $e');
      throw Exception('Error al actualizar crédito: $e');
    }
  }
}
