import '../../core/config/supabase_config.dart';
import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../models/collection_model.dart';

abstract class CollectionRemoteDataSource {
  Future<List<CollectionEntity>> getCollections();
  Future<List<CollectionEntity>> getRecentCollections({int limit = 10});
  Future<List<CollectionEntity>> getCollectionsByClientId(String clientId);
  Future<List<CollectionEntity>> getCollectionsByCreditId(String creditId);
  Future<CollectionEntity> createCollection(CollectionEntity collection,
      {String? businessId});
  Future<DashboardStatsEntity> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<Map<String, dynamic>>> getWeeklyCollection();
}

class CollectionRemoteDataSourceImpl implements CollectionRemoteDataSource {
  @override
  Future<List<CollectionEntity>> getCollections() async {
    try {
      final response = await SupabaseConfig.client
          .from('collections')
          .select()
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => CollectionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener recaudos: $e');
    }
  }

  @override
  Future<List<CollectionEntity>> getRecentCollections({int limit = 10}) async {
    try {
      final response = await SupabaseConfig.client
          .from('collections')
          .select()
          .order('payment_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CollectionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener recaudos recientes: $e');
    }
  }

  @override
  Future<List<CollectionEntity>> getCollectionsByClientId(
      String clientId) async {
    try {
      final response = await SupabaseConfig.client
          .from('collections')
          .select()
          .eq('client_id', clientId)
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => CollectionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener recaudos del cliente: $e');
    }
  }

  @override
  Future<List<CollectionEntity>> getCollectionsByCreditId(
      String creditId) async {
    try {
      final response = await SupabaseConfig.client
          .from('collections')
          .select()
          .eq('credit_id', creditId)
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => CollectionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener recaudos del crédito: $e');
    }
  }

  @override
  Future<CollectionEntity> createCollection(CollectionEntity collection,
      {String? businessId}) async {
    try {
      final collectionModel = CollectionModel(
        id: collection.id,
        creditId: collection.creditId,
        clientId: collection.clientId,
        amount: collection.amount,
        paymentDate: collection.paymentDate,
        notes: collection.notes,
        userId: collection.userId,
        paymentMethod: collection.paymentMethod,
        transactionReference: collection.transactionReference,
      );

      final response = await SupabaseConfig.client
          .from('collections')
          .insert(collectionModel.toJson(businessId: businessId))
          .select()
          .single();

      return CollectionModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      if (e.toString().contains('PGRST204') ||
          e.toString().contains('column "payment_method"')) {
        print('WARNING: Missing payment columns in DB, retrying without them.');
        // Retry without the new columns (graceful degradation)
        final fallbackModel = CollectionModel(
          id: collection.id,
          creditId: collection.creditId,
          clientId: collection.clientId,
          amount: collection.amount,
          paymentDate: collection.paymentDate,
          notes: collection.notes,
          userId: collection.userId,
          // Omit new fields
          paymentMethod: null,
          transactionReference: null,
        );

        // Remove keys manually from JSON to ensure they are not sent
        final json = fallbackModel.toJson(businessId: businessId);
        json.remove('payment_method');
        json.remove('transaction_reference');

        final response = await SupabaseConfig.client
            .from('collections')
            .insert(json)
            .select()
            .single();

        return CollectionModel.fromJson(Map<String, dynamic>.from(response));
      }
      throw Exception('Error al crear recaudo: $e');
    }
  }

  @override
  Future<DashboardStatsEntity> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Obtener recaudos del día con método de pago
      final dailyResponse = await SupabaseConfig.client
          .from('collections')
          .select('amount, payment_method')
          .gte('payment_date', todayStart.toIso8601String())
          .lt('payment_date', todayEnd.toIso8601String());

      double dailyCollection = 0;

      for (var item in dailyResponse as List) {
        final amount = (item['amount'] as num).toDouble();
        dailyCollection += amount;
      }

      // Obtener recaudos de la semana con método de pago
      final weeklyResponse = await SupabaseConfig.client
          .from('collections')
          .select('amount, payment_method, payment_date')
          .gte('payment_date', weekStart.toIso8601String());

      double weeklyCollection = 0;
      double weeklyCash = 0;
      double weeklyTransaction = 0;
      int weeklyCashCount = 0;
      int weeklyTransactionCount = 0;
      final Map<int, double> weeklyData = {};

      for (var item in weeklyResponse as List) {
        final amount = (item['amount'] as num).toDouble();
        final paymentMethod = item['payment_method'] as String?;
        final paymentDate = DateTime.parse(item['payment_date'] as String);
        final weekday = paymentDate.weekday;

        weeklyCollection += amount;
        weeklyData[weekday] = (weeklyData[weekday] ?? 0) + amount;

        if (paymentMethod?.toLowerCase() == 'efectivo') {
          weeklyCash += amount;
          weeklyCashCount++;
        } else if (paymentMethod?.toLowerCase() == 'transacción' ||
            paymentMethod?.toLowerCase() == 'transaccion') {
          weeklyTransaction += amount;
          weeklyTransactionCount++;
        }
      }

      // Obtener recaudos del mes con método de pago
      final monthlyResponse = await SupabaseConfig.client
          .from('collections')
          .select('amount, payment_method')
          .gte('payment_date', monthStart.toIso8601String());

      double monthlyCollection = 0;

      for (var item in monthlyResponse as List) {
        final amount = (item['amount'] as num).toDouble();
        monthlyCollection += amount;
      }

      // Obtener créditos activos y clientes únicos
      final creditsResponse = await SupabaseConfig.client
          .from('credits')
          .select('id, overdue_installments, client_id')
          .gt('total_balance', 0);

      final activeCredits = (creditsResponse as List).length;
      final clientsInArrears = (creditsResponse as List)
          .where((c) => (c['overdue_installments'] as int) > 0)
          .length;

      // Obtener total de clientes únicos
      final uniqueClients = (creditsResponse as List)
          .map((c) => c['client_id'] as String)
          .toSet()
          .length;

      // Calcular porcentajes
      final totalCredits = activeCredits;
      final upToDateCount = activeCredits - clientsInArrears;
      final upToDatePercentage =
          totalCredits > 0 ? (upToDateCount / totalCredits) * 100 : 0.0;
      final overduePercentage = 100 - upToDatePercentage;

      // Determinar qué período usar según startDate/endDate
      double totalCollected;
      double cashCollection;
      double transactionCollection;
      int cashCount;
      int transactionCount;
      List<Map<String, dynamic>> dailyCollectionData = [];

      if (startDate != null && endDate != null) {
        // Filtrar por período específico con datos por día
        final periodResponse = await SupabaseConfig.client
            .from('collections')
            .select('amount, payment_method, payment_date')
            .gte('payment_date', startDate.toIso8601String())
            .lt('payment_date', endDate.toIso8601String())
            .order('payment_date', ascending: true);

        totalCollected = 0;
        cashCollection = 0;
        transactionCollection = 0;
        cashCount = 0;
        transactionCount = 0;

        // Agrupar por día
        final Map<String, double> dailyData = {};
        final Map<String, double> dailyCashData = {};
        final Map<String, double> dailyTransactionData = {};

        for (var item in periodResponse as List) {
          final amount = (item['amount'] as num).toDouble();
          final paymentMethod = item['payment_method'] as String?;
          final paymentDate = DateTime.parse(item['payment_date'] as String);
          final dayKey =
              '${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.day.toString().padLeft(2, '0')}';

          totalCollected += amount;
          dailyData[dayKey] = (dailyData[dayKey] ?? 0) + amount;

          if (paymentMethod?.toLowerCase() == 'efectivo') {
            cashCollection += amount;
            cashCount++;
            dailyCashData[dayKey] = (dailyCashData[dayKey] ?? 0) + amount;
          } else if (paymentMethod?.toLowerCase() == 'transacción' ||
              paymentMethod?.toLowerCase() == 'transaccion') {
            transactionCollection += amount;
            transactionCount++;
            dailyTransactionData[dayKey] =
                (dailyTransactionData[dayKey] ?? 0) + amount;
          }
        }

        // Crear lista de días según el período
        final daysDiff = endDate.difference(startDate).inDays;

        if (daysDiff == 1) {
          // Hoy: solo un día
          final todayKey =
              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
          dailyCollectionData.add({
            'day': startDate.day,
            'label': 'Hoy',
            'amount': dailyData[todayKey] ?? 0.0,
            'cash': dailyCashData[todayKey] ?? 0.0,
            'transaction': dailyTransactionData[todayKey] ?? 0.0,
          });
        } else if (daysDiff <= 7) {
          // Semana: 7 días
          final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
          for (int i = 0; i < 7; i++) {
            final currentDate = startDate.add(Duration(days: i));
            final dayKey =
                '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
            dailyCollectionData.add({
              'day': currentDate.weekday,
              'label': dayLabels[i],
              'amount': dailyData[dayKey] ?? 0.0,
              'cash': dailyCashData[dayKey] ?? 0.0,
              'transaction': dailyTransactionData[dayKey] ?? 0.0,
            });
          }
        } else {
          // Mes: agrupar por día del mes (solo días hasta hoy)
          var currentDate = startDate;
          final today = DateTime(now.year, now.month, now.day);
          while (currentDate.isBefore(endDate) &&
              currentDate.isBefore(today.add(const Duration(days: 1)))) {
            final dayKey =
                '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
            dailyCollectionData.add({
              'day': currentDate.day,
              'label': currentDate.day.toString(),
              'amount': dailyData[dayKey] ?? 0.0,
              'cash': dailyCashData[dayKey] ?? 0.0,
              'transaction': dailyTransactionData[dayKey] ?? 0.0,
            });
            // Avanzar al siguiente día
            currentDate = currentDate.add(const Duration(days: 1));
            // Solo hasta el día actual
            if (currentDate.isAfter(today)) break;
          }
        }
      } else {
        // Por defecto usar semana
        totalCollected = weeklyCollection;
        cashCollection = weeklyCash;
        transactionCollection = weeklyTransaction;
        cashCount = weeklyCashCount;
        transactionCount = weeklyTransactionCount;

        // Crear datos para gráfica semanal
        final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
        for (int i = 1; i <= 7; i++) {
          dailyCollectionData.add({
            'day': i,
            'label': dayLabels[i - 1],
            'amount': weeklyData[i] ?? 0.0,
            'cash': 0.0,
            'transaction': 0.0,
          });
        }
      }

      return DashboardStatsEntity(
        dailyCollection: dailyCollection,
        weeklyCollection: weeklyCollection,
        monthlyCollection: monthlyCollection,
        activeCredits: activeCredits,
        clientsInArrears: clientsInArrears,
        totalCollected: totalCollected,
        upToDatePercentage: upToDatePercentage,
        overduePercentage: overduePercentage,
        cashCollection: cashCollection,
        transactionCollection: transactionCollection,
        cashCount: cashCount,
        transactionCount: transactionCount,
        weeklyCollectionData: dailyCollectionData,
        totalClients: uniqueClients,
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyCollection() async {
    try {
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      final response = await SupabaseConfig.client
          .from('collections')
          .select('amount, payment_date')
          .gte('payment_date', weekStart.toIso8601String())
          .order('payment_date', ascending: true);

      // Agrupar por día de la semana
      final Map<int, double> dailyTotals = {};
      for (var item in response as List) {
        final date = DateTime.parse(item['payment_date'] as String);
        final weekday = date.weekday;
        dailyTotals[weekday] =
            (dailyTotals[weekday] ?? 0) + (item['amount'] as num).toDouble();
      }

      // Crear lista con todos los días de la semana
      final List<Map<String, dynamic>> weeklyData = [];
      for (int i = 1; i <= 7; i++) {
        weeklyData.add({'day': i, 'amount': dailyTotals[i] ?? 0.0});
      }

      return weeklyData;
    } catch (e) {
      throw Exception('Error al obtener recaudo semanal: $e');
    }
  }
}
