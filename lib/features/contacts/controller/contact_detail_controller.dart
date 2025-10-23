// lib/features/contacts/controller/contact_detail_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/contacts_repository.dart';
import '../data/models.dart';

class ContactDetailState {
  final Contact? selected;
  final bool loading;
  final String? error;

  const ContactDetailState({this.selected, this.loading = false, this.error});

  ContactDetailState copyWith({
    Contact? selected,
    bool? loading,
    String? error,
  }) => ContactDetailState(
    selected: selected ?? this.selected,
    loading: loading ?? this.loading,
    error: error,
  );
}

class ContactDetailController extends StateNotifier<ContactDetailState> {
  ContactDetailController(this.ref) : super(const ContactDetailState());
  final Ref ref;

  Future<void> fetch(int id) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = ref.read(contactsRepositoryProvider);
      final full = await repo.getContact(id);
      state = state.copyWith(selected: full, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void clear() => state = const ContactDetailState();
  void setSelected(Contact c) => state = state.copyWith(selected: c);
}

final contactDetailControllerProvider =
    StateNotifierProvider<ContactDetailController, ContactDetailState>(
      (ref) => ContactDetailController(ref),
    );
