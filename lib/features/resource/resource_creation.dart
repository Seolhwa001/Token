import '../../core/token_amount.dart';
import 'resource.dart';

class ResourceCreation {
  final Resource resource;
  final TokenAmount initialAmount;

  const ResourceCreation({
    required this.resource,
    required this.initialAmount,
  });
}
