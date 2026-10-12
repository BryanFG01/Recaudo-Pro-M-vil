import 'dart:convert';

import '../../core/config/api_config.dart';
import '../../domain/entities/app_notification_entity.dart';
import 'api_client.dart';

/// GET /api/notifications?after=<id>: avisos del cobrador (null si no hay conexión).
class NotificationRemoteDataSource {
  NotificationRemoteDataSource([ApiClient? api]) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<NotificationsPageEntity?> fetch({int? after}) async {
    final url = after == null
        ? ApiConfig.buildApiUrl('/api/notifications')
        : ApiConfig.buildApiUrlWithQuery('/api/notifications', {'after': '$after'});
    final response = await _api.tryGet(Uri.parse(url));
    if (response == null || response.statusCode != 200) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (body['items'] as List<dynamic>? ?? [])
        .map((e) => _fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return NotificationsPageEntity(items: items, lastId: (body['last_id'] as num?)?.toInt() ?? after ?? 0);
  }

  static AppNotificationEntity _fromJson(Map<String, dynamic> json) => AppNotificationEntity(
        id: (json['id'] as num).toInt(),
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: json['created_at'] is String ? DateTime.tryParse(json['created_at'] as String)?.toLocal() : null,
      );
}
