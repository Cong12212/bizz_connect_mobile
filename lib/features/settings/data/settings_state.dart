import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_repository.dart';
import 'models/company_models.dart';
import 'models/business_card_models.dart';

// Company state provider
final companyProvider =
    StateNotifierProvider<CompanyNotifier, AsyncValue<Company?>>((ref) {
      return CompanyNotifier(ref.read(settingsRepositoryProvider));
    });

class CompanyNotifier extends StateNotifier<AsyncValue<Company?>> {
  CompanyNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final SettingsRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final company = await _repo.getCompany();
      state = AsyncValue.data(company);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void update(Company? company) {
    state = AsyncValue.data(company);
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

// Business Card state provider
final businessCardProvider =
    StateNotifierProvider<BusinessCardNotifier, AsyncValue<BusinessCard?>>((
      ref,
    ) {
      return BusinessCardNotifier(ref.read(settingsRepositoryProvider));
    });

class BusinessCardNotifier extends StateNotifier<AsyncValue<BusinessCard?>> {
  BusinessCardNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final SettingsRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final card = await _repo.getBusinessCard();
      state = AsyncValue.data(card);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void update(BusinessCard? card) {
    state = AsyncValue.data(card);
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}
