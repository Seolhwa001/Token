enum TransactionLifecycleState {
  newTransaction,
  classified,
  ledgerCreated,
  analyzed,
  refunded,
  cancelled,
  reclassified,
}

class TransactionLifecycleEvent {
  final String id;
  final String transactionId;
  final TransactionLifecycleState state;
  final DateTime createdAt;

  const TransactionLifecycleEvent({
    required this.id,
    required this.transactionId,
    required this.state,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'transactionId': transactionId,
        'state': state.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TransactionLifecycleEvent.fromJson(Map<String, Object?> json) =>
      TransactionLifecycleEvent(
        id: json['id'] as String,
        transactionId: json['transactionId'] as String,
        state: TransactionLifecycleState.values.byName(json['state'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
