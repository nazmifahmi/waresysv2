import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/customer_model.dart';
import '../../services/crm/crm_service.dart';

// CRM Service Provider
final crmServiceProvider = Provider<CRMService>((ref) {
  return CRMService();
});

// Customer State Classes
class CustomerState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  CustomerState copyWith({
    List<CustomerModel>? customers,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Customer Notifier
class CustomerNotifier extends StateNotifier<CustomerState> {
  final CRMService _crmService;

  CustomerNotifier(this._crmService) : super(const CustomerState());
  // Removed auto-loading to prevent data duplication and inconsistency

  Future<void> loadCustomers({
    CustomerStatus? status,
    bool refresh = false,
  }) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      await _crmService.initialize();
      
      final customers = await _crmService.getAllCustomers(
        limit: 20,
        status: status,
      );

      state = state.copyWith(
        customers: refresh ? customers : [...state.customers, ...customers],
        isLoading: false,
        hasMore: customers.length == 20,
        currentPage: refresh ? 1 : state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshCustomers({CustomerStatus? status}) async {
    state = state.copyWith(customers: [], currentPage: 0);
    await loadCustomers(status: status, refresh: true);
  }

  Future<void> createCustomer(CustomerModel customer) async {
    try {
      await _crmService.initialize();
      final customerId = await _crmService.createCustomer(customer);
      
      if (customerId != null) {
        final newCustomer = customer.copyWith(id: customerId);
        state = state.copyWith(
          customers: [newCustomer, ...state.customers],
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateCustomer(String id, CustomerModel customer) async {
    try {
      await _crmService.initialize();
      await _crmService.updateCustomer(id, customer);
      
      final updatedCustomers = state.customers.map((c) {
        return c.id == id ? customer.copyWith(id: id) : c;
      }).toList();
      
      state = state.copyWith(customers: updatedCustomers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _crmService.initialize();
      await _crmService.deleteCustomer(id);
      
      final updatedCustomers = state.customers.where((c) => c.id != id).toList();
      state = state.copyWith(customers: updatedCustomers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      await _crmService.initialize();
      return await _crmService.searchCustomers(query);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Customer Providers
final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  final crmService = ref.watch(crmServiceProvider);
  return CustomerNotifier(crmService);
});

// Customer Stream Provider
final customerStreamProvider = StreamProvider.family<List<CustomerModel>, CustomerStatus?>((ref, status) {
  final crmService = ref.watch(crmServiceProvider);
  return crmService.getCustomersStream(status: status);
});

// Individual Customer Provider
final customerByIdProvider = FutureProvider.family<CustomerModel?, String>((ref, id) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.getCustomerById(id);
});

// Customer Statistics Provider
final customerStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  final dashboardData = await crmService.getDashboardData();
  return dashboardData['customers'] as Map<String, int>;
});

// Top Customers Provider
final topCustomersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.getTopCustomers(limit: 10);
});

// Customer Search Provider
final customerSearchProvider = FutureProvider.family<List<CustomerModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  final crmService = ref.watch(crmServiceProvider);
  await crmService.initialize();
  return await crmService.searchCustomers(query);
});

// Customer Filter State
class CustomerFilterState {
  final CustomerStatus? status;
  final CustomerSegment? segment;
  final String searchQuery;

  const CustomerFilterState({
    this.status,
    this.segment,
    this.searchQuery = '',
  });

  CustomerFilterState copyWith({
    CustomerStatus? status,
    CustomerSegment? segment,
    String? searchQuery,
  }) {
    return CustomerFilterState(
      status: status,
      segment: segment,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// Customer Filter Notifier
class CustomerFilterNotifier extends StateNotifier<CustomerFilterState> {
  CustomerFilterNotifier() : super(const CustomerFilterState());

  void setStatus(CustomerStatus? status) {
    state = state.copyWith(status: status);
  }

  void setSegment(CustomerSegment? segment) {
    state = state.copyWith(segment: segment);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = const CustomerFilterState();
  }
}

// Customer Filter Provider
final customerFilterProvider = StateNotifierProvider<CustomerFilterNotifier, CustomerFilterState>((ref) {
  return CustomerFilterNotifier();
});