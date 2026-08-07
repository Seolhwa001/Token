import 'transaction.dart';

class TransactionSubmission {
  final TokenTransaction transaction;
  final String? userResourceId;

  const TransactionSubmission({
    required this.transaction,
    this.userResourceId,
  });
}
