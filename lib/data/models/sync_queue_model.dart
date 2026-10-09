enum SyncAction {
  upsertPlaylist,
  deletePlaylist,
  recordListeningSession,
  updateUserProfile,
}

enum SyncStatus {
  pending,
  inProgress,
  failed,
  completed,
}

/// Offline sync queue item for local-first architecture
class SyncQueueModel {
  final String id;
  final SyncAction action;
  final String payloadJson;
  final int retryCount;
  final SyncStatus status;
  final String? lastError;
  final DateTime createdAt;

  const SyncQueueModel({
    required this.id,
    required this.action,
    required this.payloadJson,
    this.retryCount = 0,
    this.status = SyncStatus.pending,
    this.lastError,
    required this.createdAt,
  });

  SyncQueueModel copyWith({
    String? id,
    SyncAction? action,
    String? payloadJson,
    int? retryCount,
    SyncStatus? status,
    String? lastError,
    DateTime? createdAt,
  }) {
    return SyncQueueModel(
      id: id ?? this.id,
      action: action ?? this.action,
      payloadJson: payloadJson ?? this.payloadJson,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action.name,
      'payloadJson': payloadJson,
      'retryCount': retryCount,
      'status': status.name,
      'lastError': lastError,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncQueueModel.fromMap(Map<String, dynamic> map) {
    return SyncQueueModel(
      id: map['id'] as String,
      action: SyncAction.values.firstWhere(
        (e) => e.name == map['action'],
        orElse: () => SyncAction.recordListeningSession,
      ),
      payloadJson: map['payloadJson'] as String? ?? '{}',
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SyncStatus.pending,
      ),
      lastError: map['lastError'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
