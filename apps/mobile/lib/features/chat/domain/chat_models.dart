import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String tripId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  bool isMine(String? uid) => uid != null && senderId == uid;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, tripId, body, createdAt];
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.createdAt,
    this.body,
    this.data = const {},
    this.readAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  String? get tripId {
    final v = data['trip_id'];
    return v is String ? v : null;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'generic',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      data: rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : const {},
      readAt: json['read_at'] == null
          ? null
          : DateTime.tryParse(json['read_at'] as String),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, type, readAt, createdAt];
}
