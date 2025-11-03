import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/opportunity_model.dart';
import '../../services/crm/crm_service.dart';

// Opportunity State Classes
class OpportunityState {
  final List<OpportunityModel> opportunities;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const OpportunityState({
    this.opportunities = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  OpportunityState copyWith({
    List<OpportunityModel>? opportunities,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return OpportunityState(
      opportunities: opportunities ?? this.opportunities,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Opportunity Notifier
class OpportunityNotifier extends StateNotifier<OpportunityState> {
  final CRMService _crmService;

  OpportunityNotifier(this._crmService) : super(const OpportunityState());
  // Removed auto-loading to prevent data duplication and inconsistency

  Future<void> loadOpportunities({
    OpportunityStage? stage,
    double? minValue,
    double? maxValue,
    bool refresh = false,
  }) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      await _crmService.initialize();
      
      final opportunities = await _crmService.getAllOpportunities(
        limit: 20,
        stage: stage,
        minValue: minValue,
        maxValue: maxValue,
      );

      state = state.copyWith(
        opportunities: refresh ? opportunities : [...state.opportunities, ...opportunities],
        isLoading: false,
        hasMore: opportunities.length == 20,
        currentPage: refresh ? 1 : state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshOpportunities({
    OpportunityStage? stage,
    double? minValue,
    double? maxValue,
  }) async {
    state = state.copyWith(opportunities: [], currentPage: 0);
    await loadOpportunities(
      stage: stage,
      minValue: minValue,
      maxValue: maxValue,
      refresh: true,
    );
  }

  Future<void> createOpportunity(OpportunityModel opportunity) async {
    try {
      await _crmService.initialize();
      final opportunityId = await _crmService.createOpportunity(opportunity);
      
      final newOpportunity = opportunity.copyWith(id: opportunityId);
      state = state.copyWith(
        opportunities: [newOpportunity, ...state.opportunities],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateOpportunity(String id, OpportunityModel opportunity) async {
    try {
      await _crmService.initialize();
      await _crmService.updateOpportunity(id, opportunity);
      
      final updatedOpportunities = state.opportunities.map((o) {
        return o.id == id ? opportunity.copyWith(id: id) : o;
      }).toList();
      
      state = state.copyWith(opportunities: updatedOpportunities);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteOpportunity(String id) async {
    try {
      await _crmService.initialize();
      await _crmService.deleteOpportunity(id);
      
      final updatedOpportunities = state.opportunities.where((o) => o.id != id).toList();
      state = state.copyWith(opportunities: updatedOpportunities);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<List<OpportunityModel>> searchOpportunities(String query) async {
    try {
      await _crmService.initialize();
      return await _crmService.searchOpportunities(query);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<List<OpportunityModel>> getOpportunitiesByCustomer(String customerId) async {
    try {
      await _crmService.initialize();
      return await _crmService.getOpportunitiesByCustomer(customerId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Opportunity Providers
final opportunityProvider = StateNotifierProvider<OpportunityNotifier, OpportunityState>((ref) {
  final crmService = ref.watch(crmServiceProvider);
  return OpportunityNotifier(crmService);
});

// Opportunity Stream Provider
final opportunityStreamProvider = StreamProvider.family<List<OpportunityModel>, Map<String, dynamic>>((ref, filters) {
  final crmService = ref.watch(crmServiceProvider);
  return crmService.getOpportunitiesStream(
    stage: filters['stage'] as OpportunityStage?,
    limit: filters['limit'] as int? ?? 20,
  );
});

// Individual Opportunity Provider
final opportunityByIdProvider = FutureProvider.family<OpportunityModel?, String>((ref, id) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.getOpportunityById(id);
});

// Opportunity Statistics Provider
final opportunityStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  final dashboardData = await crmService.getDashboardData();
  return dashboardData['opportunities'] as Map<String, dynamic>;
});

// Sales Pipeline Provider
final salesPipelineProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.getSalesPipeline();
});

// Opportunities by Customer Provider
final opportunitiesByCustomerProvider = FutureProvider.family<List<OpportunityModel>, String>((ref, customerId) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.getOpportunitiesByCustomer(customerId);
});

// Opportunity Search Provider
final opportunitySearchProvider = FutureProvider.family<List<OpportunityModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.searchOpportunities(query);
});

// Opportunity Filter State
class OpportunityFilterState {
  final OpportunityStage? stage;
  final double? minValue;
  final double? maxValue;
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? customerId;

  const OpportunityFilterState({
    this.stage,
    this.minValue,
    this.maxValue,
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.customerId,
  });

  OpportunityFilterState copyWith({
    OpportunityStage? stage,
    double? minValue,
    double? maxValue,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
  }) {
    return OpportunityFilterState(
      stage: stage,
      minValue: minValue,
      maxValue: maxValue,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate,
      endDate: endDate,
      customerId: customerId,
    );
  }
}

// Opportunity Filter Notifier
class OpportunityFilterNotifier extends StateNotifier<OpportunityFilterState> {
  OpportunityFilterNotifier() : super(const OpportunityFilterState());

  void setStage(OpportunityStage? stage) {
    state = state.copyWith(stage: stage);
  }

  void setValueRange(double? minValue, double? maxValue) {
    state = state.copyWith(minValue: minValue, maxValue: maxValue);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  void setCustomerId(String? customerId) {
    state = state.copyWith(customerId: customerId);
  }

  void clearFilters() {
    state = const OpportunityFilterState();
  }
}

// Opportunity Filter Provider
final opportunityFilterProvider = StateNotifierProvider<OpportunityFilterNotifier, OpportunityFilterState>((ref) {
  return OpportunityFilterNotifier();
});

// CRM Service Provider (imported from customer_provider)
final crmServiceProvider = Provider<CRMService>((ref) {
  return CRMService();
});