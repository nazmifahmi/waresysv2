import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/contact_model.dart';
import '../../services/crm/crm_service.dart';

// Contact State Classes
class ContactState {
  final List<ContactModel> contacts;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const ContactState({
    this.contacts = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  ContactState copyWith({
    List<ContactModel>? contacts,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return ContactState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Contact Notifier
class ContactNotifier extends StateNotifier<ContactState> {
  final CRMService _crmService;

  ContactNotifier(this._crmService) : super(const ContactState());
  // Removed auto-loading to prevent data duplication and inconsistency

  Future<void> loadContacts({
    String? companyId,
    ContactType? type,
    bool refresh = false,
  }) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      await _crmService.initialize();
      
      final contacts = await _crmService.getAllContacts(
        limit: 20,
        companyId: companyId,
        type: type,
      );

      state = state.copyWith(
        contacts: refresh ? contacts : [...state.contacts, ...contacts],
        isLoading: false,
        hasMore: contacts.length == 20,
        currentPage: refresh ? 1 : state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshContacts({
    String? companyId,
    ContactType? type,
  }) async {
    state = state.copyWith(contacts: [], currentPage: 0);
    await loadContacts(companyId: companyId, type: type, refresh: true);
  }

  Future<void> createContact(ContactModel contact) async {
    try {
      await _crmService.initialize();
      final contactId = await _crmService.createContact(contact);
      
      final newContact = contact.copyWith(id: contactId);
      state = state.copyWith(
        contacts: [newContact, ...state.contacts],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateContact(String id, ContactModel contact) async {
    try {
      await _crmService.initialize();
      await _crmService.updateContact(id, contact);
      
      final updatedContacts = state.contacts.map((c) {
        return c.id == id ? contact.copyWith(id: id) : c;
      }).toList();
      
      state = state.copyWith(contacts: updatedContacts);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      await _crmService.initialize();
      await _crmService.deleteContact(id);
      
      final updatedContacts = state.contacts.where((c) => c.id != id).toList();
      state = state.copyWith(contacts: updatedContacts);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<List<ContactModel>> searchContacts(String query) async {
    try {
      await _crmService.initialize();
      return await _crmService.searchContacts(query);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<List<ContactModel>> getContactsByCompany(String companyId) async {
    try {
      await _crmService.initialize();
      return await _crmService.getContactsByCompany(companyId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Contact Providers
final contactProvider = StateNotifierProvider<ContactNotifier, ContactState>((ref) {
  final crmService = ref.watch(crmServiceProvider);
  return ContactNotifier(crmService);
});

// Contact Stream Provider
final contactStreamProvider = StreamProvider.family<List<ContactModel>, Map<String, dynamic>>((ref, filters) {
  final crmService = ref.watch(crmServiceProvider);
  return crmService.getContactsStream(
    companyId: filters['companyId'] as String?,
    type: filters['type'] as ContactType?,
    limit: filters['limit'] as int? ?? 20,
  );
});

// Individual Contact Provider
final contactByIdProvider = FutureProvider.family<ContactModel?, String>((ref, id) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.getContactById(id);
});

// Contact Statistics Provider
final contactStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  final dashboardData = await crmService.getDashboardData();
  return dashboardData['contacts'] as Map<String, int>;
});

// Recent Contacts Provider
final recentContactsProvider = FutureProvider<List<ContactModel>>((ref) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.getRecentContacts(limit: 10);
});

// Contacts by Company Provider
final contactsByCompanyProvider = FutureProvider.family<List<ContactModel>, String>((ref, companyId) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.getContactsByCompany(companyId);
});

// Contact Search Provider
final contactSearchProvider = FutureProvider.family<List<ContactModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.searchContacts(query);
});

// Contact Filter State
class ContactFilterState {
  final ContactType? type;
  final String? companyId;
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;

  const ContactFilterState({
    this.type,
    this.companyId,
    this.searchQuery = '',
    this.startDate,
    this.endDate,
  });

  ContactFilterState copyWith({
    ContactType? type,
    String? companyId,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ContactFilterState(
      type: type,
      companyId: companyId,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

// Contact Filter Notifier
class ContactFilterNotifier extends StateNotifier<ContactFilterState> {
  ContactFilterNotifier() : super(const ContactFilterState());

  void setType(ContactType? type) {
    state = state.copyWith(type: type);
  }

  void setCompanyId(String? companyId) {
    state = state.copyWith(companyId: companyId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  void clearFilters() {
    state = const ContactFilterState();
  }
}

// Contact Filter Provider
final contactFilterProvider = StateNotifierProvider<ContactFilterNotifier, ContactFilterState>((ref) {
  return ContactFilterNotifier();
});

// CRM Service Provider (imported from customer_provider)
final crmServiceProvider = Provider<CRMService>((ref) {
  return CRMService();
});