import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/client_repository.dart';
import '../domain/client.dart';

class ClientListFilter {
  const ClientListFilter({this.query = '', this.industry});
  final String query;
  final String? industry;
  ClientListFilter copyWith({String? query, String? industry, bool clearIndustry = false}) {
    return ClientListFilter(
      query: query ?? this.query,
      industry: clearIndustry ? null : (industry ?? this.industry),
    );
  }
}

final clientFilterProvider = StateProvider<ClientListFilter>((_) => const ClientListFilter());

final clientListProvider = FutureProvider.autoDispose<ClientPage>((ref) async {
  final repo = ref.watch(clientRepositoryProvider);
  final filter = ref.watch(clientFilterProvider);
  return repo.list(q: filter.query, industry: filter.industry);
});

final clientDetailProvider = FutureProvider.autoDispose.family<Client, String>((ref, id) async {
  return ref.watch(clientRepositoryProvider).getById(id);
});

final clientHiringHistoryProvider =
    FutureProvider.autoDispose.family<List<HiringHistoryItem>, String>((ref, id) async {
  return ref.watch(clientRepositoryProvider).hiringHistory(id);
});
