import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/lead_model.dart';
import '../../services/crm/crm_service.dart';

// Lead State Classes
class LeadState {
  final List<LeadModel> leads;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const LeadState({
    this.leads = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  LeadState copyWith({
    List<LeadModel>? leads,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return LeadState(
      leads: leads ?? this.leads,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Lead Notifier
class LeadNotifier extends StateNotifier<LeadState> {
  final CRMService _crmService;

  LeadNotifier(this._crmService) : super(const LeadState());
  // Removed auto-loading to prevent data duplication and inconsistency

  Future<void> loadLeads({
    LeadStatus? status,
    LeadSource? source,
    bool refresh = false,
  }) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      await _crmService.initialize();
      
      final leads = await _crmService.getAllLeads(
        limit: 20,
        status: status,
        source: source,
      );

      state = state.copyWith(
        leads: refresh ? leads : [...state.leads, ...leads],
        isLoading: false,
        hasMore: leads.length == 20,
        currentPage: refresh ? 1 : state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshLeads({
    LeadStatus? status,
    LeadSource? source,
  }) async {
    state = state.copyWith(leads: [], currentPage: 0);
    await loadLeads(status: status, source: source, refresh: true);
  }

  Future<void> createLead(LeadModel lead) async {
    try {
      await _crmService.initialize();
      final leadId = await _crmService.createLead(lead);
      
      final newLead = lead.copyWith(id: leadId);
      state = state.copyWith(
        leads: [newLead, ...state.leads],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateLead(String id, LeadModel lead) async {
    try {
      await _crmService.initialize();
      await _crmService.updateLead(id, lead);
      
      final updatedLeads = state.leads.map((l) {
        return l.id == id ? lead.copyWith(id: id) : l;
      }).toList();
      
      state = state.copyWith(leads: updatedLeads);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteLead(String id) async {
    try {
      await _crmService.initialize();
      await _crmService.deleteLead(id);
      
      final updatedLeads = state.leads.where((l) => l.id != id).toList();
      state = state.copyWith(leads: updatedLeads);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> convertLeadToCustomer(String leadId) async {
    try {
      await _crmService.initialize();
      await _crmService.convertLeadToCustomer(leadId);
      
      // Update lead status to converted
      final updatedLeads = state.leads.map((l) {
        return l.id == leadId 
            ? l.copyWith(status: LeadStatus.closed_won)
            : l;
      }).toList();
      
      state = state.copyWith(leads: updatedLeads);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<List<LeadModel>> searchLeads(String query) async {
    try {
      await _crmService.initialize();
      return await _crmService.searchLeads(query);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Lead Providers
final leadProvider = StateNotifierProvider<LeadNotifier, LeadState>((ref) {
  final crmService = ref.watch(crmServiceProvider);
  return LeadNotifier(crmService);
});

// Lead Stream Provider
final leadStreamProvider = StreamProvider.family<List<LeadModel>, Map<String, dynamic>>((ref, filters) {
  final crmService = ref.watch(crmServiceProvider);
  return crmService.getLeadsStream(
    status: filters['status'] as LeadStatus?,
    source: filters['source'] as LeadSource?,
    limit: filters['limit'] as int? ?? 20,
  );
});

// Individual Lead Provider
final leadByIdProvider = FutureProvider.family<LeadModel?, String>((ref, id) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.getLeadById(id);
});

// Lead Statistics Provider
final leadStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  final dashboardData = await crmService.getDashboardData();
  return dashboardData['leads'] as Map<String, int>;
});

// Leads by Status Provider
final leadsByStatusProvider = FutureProvider.family<List<LeadModel>, LeadStatus>((ref, status) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.getLeadsByStatus(status);
});

// Lead Search Provider
final leadSearchProvider = FutureProvider.family<List<LeadModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.searchLeads(query);
});

// Lead Filter State
class LeadFilterState {
  final LeadStatus? status;
  final LeadSource? source;
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;

  const LeadFilterState({
    this.status,
    this.source,
    this.searchQuery = '',
    this.startDate,
    this.endDate,
  });

  LeadFilterState copyWith({
    LeadStatus? status,
    LeadSource? source,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return LeadFilterState(
      status: status,
      source: source,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

// Lead Filter Notifier
class LeadFilterNotifier extends StateNotifier<LeadFilterState> {
  LeadFilterNotifier() : super(const LeadFilterState());

  void setStatus(LeadStatus? status) {
    state = state.copyWith(status: status);
  }

  void setSource(LeadSource? source) {
    state = state.copyWith(source: source);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  void clearFilters() {
    state = const LeadFilterState();
  }
}

// Lead Filter Provider
final leadFilterProvider = StateNotifierProvider<LeadFilterNotifier, LeadFilterState>((ref) {
  return LeadFilterNotifier();
});

// CRM Service Provider (imported from customer_provider)
final crmServiceProvider = Provider<CRMService>((ref) {
  return CRMService();
});