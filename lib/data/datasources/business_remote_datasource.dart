import '../../core/config/supabase_config.dart';
import '../../domain/entities/business_entity.dart';
import '../models/business_model.dart';

abstract class BusinessRemoteDataSource {
  Future<List<BusinessEntity>> getBusinesses();
  Future<List<BusinessEntity>> searchBusinesses(String query);
  Future<BusinessEntity?> getBusinessByCode(String code);
  Future<BusinessEntity?> getBusinessById(String id);
}

class BusinessRemoteDataSourceImpl implements BusinessRemoteDataSource {
  @override
  Future<List<BusinessEntity>> getBusinesses() async {
    try {
      final response = await SupabaseConfig.client
          .from('businesses')
          .select()
          .eq('is_active', true)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => BusinessModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener negocios: $e');
    }
  }

  @override
  Future<List<BusinessEntity>> searchBusinesses(String query) async {
    try {
      final response = await SupabaseConfig.client
          .from('businesses')
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$query%,code.ilike.%$query%')
          .order('name', ascending: true);

      return (response as List)
          .map((json) => BusinessModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar negocios: $e');
    }
  }

  @override
  Future<BusinessEntity?> getBusinessByCode(String code) async {
    try {
      final response = await SupabaseConfig.client
          .from('businesses')
          .select()
          .eq('code', code)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return BusinessModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener negocio: $e');
    }
  }

  @override
  Future<BusinessEntity?> getBusinessById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from('businesses')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return BusinessModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error al obtener negocio: $e');
    }
  }
}

