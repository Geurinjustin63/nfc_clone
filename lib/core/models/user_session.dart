import 'package:uuid/uuid.dart';

enum SessionType {
  biometric,
  pin,
  password,
  guest,
}

enum SessionStatus {
  active,
  expired,
  terminated,
  locked,
}

class UserSession {
  final String id;
  final SessionType type;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime lastAccessAt;
  final DateTime expiresAt;
  final String deviceId;
  final String deviceInfo;
  final int failedAttempts;
  final Map<String, dynamic> metadata;

  UserSession({
    String? id,
    required this.type,
    this.status = SessionStatus.active,
    DateTime? createdAt,
    DateTime? lastAccessAt,
    DateTime? expiresAt,
    required this.deviceId,
    required this.deviceInfo,
    this.failedAttempts = 0,
    this.metadata = const {},
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastAccessAt = lastAccessAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 8));

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      id: map['id'],
      type: SessionType.values[map['type']],
      status: SessionStatus.values[map['status']],
      createdAt: DateTime.parse(map['created_at']),
      lastAccessAt: DateTime.parse(map['last_access_at']),
      expiresAt: DateTime.parse(map['expires_at']),
      deviceId: map['device_id'],
      deviceInfo: map['device_info'],
      failedAttempts: map['failed_attempts'] ?? 0,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'status': status.index,
      'created_at': createdAt.toIso8601String(),
      'last_access_at': lastAccessAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'device_id': deviceId,
      'device_info': deviceInfo,
      'failed_attempts': failedAttempts,
      'metadata': metadata,
    };
  }

  UserSession copyWith({
    SessionType? type,
    SessionStatus? status,
    DateTime? lastAccessAt,
    DateTime? expiresAt,
    int? failedAttempts,
    Map<String, dynamic>? metadata,
  }) {
    return UserSession(
      id: id,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt,
      lastAccessAt: lastAccessAt ?? DateTime.now(),
      expiresAt: expiresAt ?? this.expiresAt,
      deviceId: deviceId,
      deviceInfo: deviceInfo,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isValid {
    return status == SessionStatus.active && DateTime.now().isBefore(expiresAt);
  }

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  Duration get remainingTime {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  Duration get sessionDuration {
    return lastAccessAt.difference(createdAt);
  }

  @override
  String toString() {
    return 'UserSession{id: $id, type: $type, status: $status, valid: $isValid}';
  }
}