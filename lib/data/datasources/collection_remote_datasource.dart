import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../domain/entities/collection_entity.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../models/collection_model.dart';
import 'credit_remote_datasource.dart';

abstract class CollectionRemoteDataSource {
  Future<List<CollectionEntity>> getCollections({String? businessId});
  Future<List<CollectionEntity>> getRecentCollections({
    String? businessId,
    int limit = 10,
  });
  Future<List<CollectionEntity>> getCollectionsByClientId(
    String clientId, {
    String? businessId,
  });
  Future<List<CollectionEntity>> getCollectionsByCreditId(
    String creditId, {
    String? businessId,
  });
  Future<CollectionEntity> createCollection(
    CollectionEntity collection, {
    String? businessId,
  });
  Future<DashboardStatsEntity> getDashboardStats({
    String? businessId,
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? filterClientIds,
    String? filterUserId,
  });
  Future<List<Map<String, dynamic>>> getWeeklyCollection({String? businessId});
}

class CollectionRemoteDataSourceImpl implements CollectionRemoteDataSource {
  CollectionRemoteDataSourceImpl([CreditRemoteDataSource? creditDataSource])
      : _creditDataSource = creditDataSource;

  final CreditRemoteDataSource? _creditDataSource;

  @override
  Future<List<CollectionEntity>> getCollections({String? businessId}) async {
    final query = <String, String>{};
    if (businessId != null) query['business_id'] = businessId;
    final url = query.isEmpty
        ? ApiConfig.buildApiUrl('/api/collections')
        : ApiConfig.buildApiUrlWithQuery('/api/collections', query);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error al obtener recaudos: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) =>
            CollectionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<CollectionEntity>> getRecentCollections({
    String? businessId,
    int limit = 10,
  }) async {
    final query = <String, String>{'limit': limit.toString()};
    if (businessId != null) query['business_id'] = businessId;
    final url = ApiConfig.buildApiUrlWithQuery('/api/collections', query);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error al obtener recaudos recientes: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) =>
            CollectionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<CollectionEntity>> getCollectionsByClientId(
    String clientId, {
    String? businessId,
  }) async {
    final query = <String, String>{'client_id': clientId};
    if (businessId != null) query['business_id'] = businessId;
    final url = ApiConfig.buildApiUrlWithQuery('/api/collections', query);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error al obtener recaudos del cliente: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) =>
            CollectionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<List<CollectionEntity>> getCollectionsByCreditId(
    String creditId, {
    String? businessId,
  }) async {
    final query = <String, String>{'credit_id': creditId};
    if (businessId != null) query['business_id'] = businessId;
    final url = ApiConfig.buildApiUrlWithQuery('/api/collections', query);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Error al obtener recaudos del crédito: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) =>
            CollectionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<CollectionEntity> createCollection(
    CollectionEntity collection, {
    String? businessId,
  }) async {
    final url = ApiConfig.buildApiUrl('/api/collections');
    // Body según API: credit_id, client_id, amount, notes, user_id,
    // payment_method, transaction_reference, opcional business_id (sin id ni payment_date)
    final body = <String, dynamic>{
      'credit_id': collection.creditId,
      'client_id': collection.clientId,
      'amount': collection.amount,
      'user_id': collection.userId,
    };
    if (collection.notes != null && collection.notes!.isNotEmpty) {
      body['notes'] = collection.notes;
    }
    if (collection.paymentMethod != null &&
        collection.paymentMethod!.isNotEmpty) {
      body['payment_method'] = collection.paymentMethod;
    }
    if (collection.transactionReference != null &&
        collection.transactionReference!.isNotEmpty) {
      body['transaction_reference'] = collection.transactionReference;
    }
    if (businessId != null && businessId.isNotEmpty) {
      body['business_id'] = businessId;
    }
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Error al crear recaudo: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        if (err is Map<String, dynamic>) {
          final msg = err['message'] ?? err['error'] ?? err['detail'];
          if (msg != null) message = msg is String ? msg : msg.toString();
        }
      } catch (_) {
        if (response.body.isNotEmpty) message += '\n${response.body}';
      }
      throw Exception(message);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CollectionModel.fromJson(data);
  }

  @override
  Future<DashboardStatsEntity> getDashboardStats({
    String? businessId,
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? filterClientIds,
    String? filterUserId,
  }) async {
    if (businessId == null || businessId.isEmpty) {
      throw Exception('business_id requerido para estadísticas');
    }
    // Siempre obtener datos de GET /api/collections y GET /api/credits; calcular en cliente
    var list = await getCollections(businessId: businessId);
    if (filterClientIds != null && filterClientIds.isNotEmpty) {
      final ids = filterClientIds;
      list = list.where((c) => ids.contains(c.clientId)).toList();
    }
    // Solo recaudos hechos por este usuario (recaudo del día = del cobrador actual)
    if (filterUserId != null && filterUserId.isNotEmpty) {
      list = list.where((c) => c.userId == filterUserId).toList();
    }
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    double daily = 0, weekly = 0, monthly = 0;
    double totalAcumulado = 0;
    double cashCollection = 0, transactionCollection = 0;
    int cashCount = 0, transactionCount = 0;
    final dailyByWeekday = <int, double>{};
    final cashByWeekday = <int, double>{};
    final transactionByWeekday = <int, double>{};

    for (final c in list) {
      totalAcumulado += c.amount;
      final d = c.paymentDate;
      if (!d.isBefore(todayStart) && d.isBefore(todayEnd)) daily += c.amount;
      if (!d.isBefore(weekStart)) {
        weekly += c.amount;
        final w = d.weekday;
        dailyByWeekday[w] = (dailyByWeekday[w] ?? 0) + c.amount;
        final isCash = c.paymentMethod?.toLowerCase().contains('efectivo') ??
            c.paymentMethod?.toLowerCase().contains('cash') ?? false;
        if (isCash) {
          cashCollection += c.amount;
          cashCount++;
          cashByWeekday[w] = (cashByWeekday[w] ?? 0) + c.amount;
        } else {
          transactionCollection += c.amount;
          transactionCount++;
          transactionByWeekday[w] = (transactionByWeekday[w] ?? 0) + c.amount;
        }
      }
      if (!d.isBefore(monthStart)) monthly += c.amount;
    }

    int activeCredits = 0;
    int clientsInArrears = 0;
    final activeClientIds = <String>{};
    if (_creditDataSource != null) {
      try {
        var credits = await _creditDataSource!.getCreditsByBusiness(businessId);
        if (filterClientIds != null && filterClientIds.isNotEmpty) {
          final ids = filterClientIds;
          credits = credits.where((cr) => ids.contains(cr.clientId)).toList();
        }
        // Usar saldo del summary (GET /api/credits/summary/{id}) para contar activos;
        // el listado a veces devuelve total_balance en 0.
        final summaries = await Future.wait(
          credits.map((cr) => _creditDataSource!.getCreditSummaryById(cr.id)),
        );
        for (var i = 0; i < credits.length; i++) {
          final cr = credits[i];
          final summary = summaries[i];
          final balance = summary?.totalBalance ?? cr.totalBalance;
          if (balance > 0) {
            activeCredits++;
            activeClientIds.add(cr.clientId);
          }
          if (cr.overdueInstallments > 0) clientsInArrears++;
        }
      } catch (_) {}
    }
    final totalCollected = totalAcumulado;
    final totalCredits = activeCredits;
    final upToDateCount = totalCredits > 0 ? totalCredits - clientsInArrears : 0;
    final upToDatePercentage =
        totalCredits > 0 ? (upToDateCount / totalCredits) * 100 : 0.0;
    final overduePercentage = 100 - upToDatePercentage;

    final weeklyCollectionData = <Map<String, dynamic>>[];
    for (int i = 1; i <= 7; i++) {
      weeklyCollectionData.add({
        'day': i,
        'label': ['L', 'M', 'X', 'J', 'V', 'S', 'D'][i - 1],
        'amount': dailyByWeekday[i] ?? 0.0,
        'cash': cashByWeekday[i] ?? 0.0,
        'transaction': transactionByWeekday[i] ?? 0.0,
      });
    }

    return DashboardStatsEntity(
      dailyCollection: daily,
      weeklyCollection: weekly,
      monthlyCollection: monthly,
      activeCredits: activeCredits,
      clientsInArrears: clientsInArrears,
      totalCollected: totalCollected,
      upToDatePercentage: upToDatePercentage,
      overduePercentage: overduePercentage,
      cashCollection: cashCollection,
      transactionCollection: transactionCollection,
      cashCount: cashCount,
      transactionCount: transactionCount,
      weeklyCollectionData: weeklyCollectionData,
      totalClients: activeClientIds.length,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyCollection({
    String? businessId,
  }) async {
    final list = await getRecentCollections(businessId: businessId, limit: 100);
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final Map<int, double> dailyTotals = {};
    for (final c in list) {
      if (c.paymentDate.isAfter(weekStart) ||
          c.paymentDate.isAtSameMomentAs(weekStart)) {
        final w = c.paymentDate.weekday;
        dailyTotals[w] = (dailyTotals[w] ?? 0) + c.amount;
      }
    }
    final result = <Map<String, dynamic>>[];
    for (int i = 1; i <= 7; i++) {
      result.add({'day': i, 'amount': dailyTotals[i] ?? 0.0});
    }
    return result;
  }
}
