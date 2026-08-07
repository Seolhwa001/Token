import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:token/core/exchange_rate.dart';
import 'package:token/features/transaction/transaction_create_page.dart';
import 'package:token/features/transaction/transaction_submission.dart';

void main() {
  testWidgets(
    'transaction page explicitly offers UNCLASSIFIED and returns null resource',
    (tester) async {
      TransactionSubmission? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () async {
                      result = await Navigator.of(context)
                          .push<TransactionSubmission>(
                        MaterialPageRoute(
                          builder: (_) => TransactionCreatePage(
                            resources: const [],
                            ledger: const [],
                            exchangeRate: ExchangeRate.fromInt(100),
                          ),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('미분류로 저장'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, '금액(원)'),
        '13500',
      );

      await tester.tap(find.text('거래 저장'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.userResourceId, isNull);
      expect(result!.transaction.wonAmount, BigInt.from(13500));
    },
  );

  testWidgets(
    'transaction page remains scrollable on a short screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 500));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: TransactionCreatePage(
            resources: const [],
            ledger: const [],
            exchangeRate: ExchangeRate.fromInt(100),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      expect(find.text('거래 저장'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
