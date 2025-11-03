import 'customer_repository.dart';
import 'lead_repository.dart';
import 'opportunity_repository.dart';
import 'contact_repository.dart';
import '../../models/crm/customer_model.dart';
import '../../models/crm/lead_model.dart';
import '../../models/crm/opportunity_model.dart';
import '../../models/crm/contact_model.dart';

class CRMService {
  static final CRMService _instance = CRMService._internal();
  factory CRMService() => _instance;
  CRMService._internal();

  // Repository instances
  final CustomerRepository _customerRepository = CustomerRepository();
  final LeadRepository _leadRepository = LeadRepository();
  final OpportunityRepository _opportunityRepository = OpportunityRepository();
  final ContactRepository _contactRepository = ContactRepository();

  bool _isInitialized = false;
  
  // Cache for frequently accessed data
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Initialize all repositories
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await Future.wait([
        _leadRepository.initialize(),
        _opportunityRepository.initialize(),
        _contactRepository.initialize(),
      ]);
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize CRM Service: $e');
    }
  }

  // Cache management
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  void _setCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  T? _getCache<T>(String key) {
    if (_isCacheValid(key)) {
      return _cache[key] as T?;
    }
    return null;
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Customer operations
  Future<String?> createCustomer(CustomerModel customer) async {
    await _ensureInitialized();
    try {
      final result = await _customerRepository.createCustomer(customer);
      // Clear customer cache when new data is created
      _cache.removeWhere((key, value) => key.startsWith('customers_'));
      return result;
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  Future<CustomerModel?> getCustomerById(String id) async {
    await _ensureInitialized();
    return _customerRepository.getCustomerById(id);
  }

  Future<List<CustomerModel>> getAllCustomers({
    int limit = 20,
    CustomerStatus? status,
  }) async {
    await _ensureInitialized();
    
    final cacheKey = 'customers_${limit}_${status?.toString() ?? 'all'}';
    final cached = _getCache<List<CustomerModel>>(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    try {
      final customers = await _customerRepository.getCustomers(
        limit: limit,
        status: status,
      );
      _setCache(cacheKey, customers);
      return customers;
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }

  Stream<List<CustomerModel>> getCustomersStream({
    CustomerStatus? status,
    int limit = 20,
  }) {
    return _customerRepository.watchCustomers(
      status: status,
      limit: limit,
    );
  }

  Future<void> updateCustomer(String id, CustomerModel customer) async {
    await _ensureInitialized();
    await _customerRepository.updateCustomer(id, customer);
  }

  Future<void> deleteCustomer(String id) async {
    await _ensureInitialized();
    await _customerRepository.deleteCustomer(id);
  }

  Future<List<CustomerModel>> searchCustomers(String searchTerm) async {
    await _ensureInitialized();
    return _customerRepository.searchCustomers(query: searchTerm);
  }

  // Lead operations
  Future<String> createLead(LeadModel lead) async {
    await _ensureInitialized();
    try {
      final result = await _leadRepository.createLead(lead);
      // Clear lead cache when new data is created
      _cache.removeWhere((key, value) => key.startsWith('leads_'));
      return result;
    } catch (e) {
      throw Exception('Failed to create lead: $e');
    }
  }

  Future<LeadModel?> getLeadById(String id) async {
    await _ensureInitialized();
    return await _leadRepository.getLeadById(id);
  }

  Future<List<LeadModel>> getAllLeads({
    int limit = 20,
    LeadStatus? status,
    LeadSource? source,
  }) async {
    await _ensureInitialized();
    
    final cacheKey = 'leads_${limit}_${status?.toString() ?? 'all'}_${source?.toString() ?? 'all'}';
    final cached = _getCache<List<LeadModel>>(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    try {
      final leads = await _leadRepository.getAllLeads(
        limit: limit,
        status: status,
        source: source,
      );
      _setCache(cacheKey, leads);
      return leads;
    } catch (e) {
      throw Exception('Failed to load leads: $e');
    }
  }

  Stream<List<LeadModel>> getLeadsStream({
    LeadStatus? status,
    LeadSource? source,
    int limit = 20,
  }) {
    return _leadRepository.getLeadsStream(
      status: status,
      source: source,
      limit: limit,
    );
  }

  Future<void> updateLead(String id, LeadModel lead) async {
    await _ensureInitialized();
    return await _leadRepository.updateLead(id, lead);
  }

  Future<void> deleteLead(String id) async {
    await _ensureInitialized();
    return await _leadRepository.deleteLead(id);
  }

  Future<void> convertLeadToCustomer(String leadId) async {
    await _ensureInitialized();
    
    // Get the lead
    final lead = await _leadRepository.getLeadById(leadId);
    if (lead == null) {
      throw Exception('Lead not found');
    }
    
    // Create customer from lead
    final customer = CustomerModel(
      id: '',
      name: lead.name,
      email: lead.email,
      phone: lead.phone,
      company: lead.company,
      segment: CustomerSegment.standard,
      status: CustomerStatus.active,
      address: '',
      city: '',
      province: lead.industry ?? '',
      notes: 'Converted from lead: ${lead.name}',
      tags: [],
      customFields: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'system',
    );
    
    // Create the customer
    await _customerRepository.createCustomer(customer);
    
    // Convert the lead
    await _leadRepository.convertLeadToCustomer(leadId);
  }

  Future<List<LeadModel>> searchLeads(String searchTerm) async {
    await _ensureInitialized();
    return await _leadRepository.searchLeads(searchTerm);
  }

  Future<List<LeadModel>> getLeadsByStatus(LeadStatus status) async {
    await _ensureInitialized();
    return await _leadRepository.getLeadsByStatus(status);
  }

  // Opportunity operations
  Future<String> createOpportunity(OpportunityModel opportunity) async {
    await _ensureInitialized();
    return await _opportunityRepository.createOpportunity(opportunity);
  }

  Future<OpportunityModel?> getOpportunityById(String id) async {
    await _ensureInitialized();
    return await _opportunityRepository.getOpportunityById(id);
  }

  Future<List<OpportunityModel>> getAllOpportunities({
    int limit = 20,
    OpportunityStage? stage,
    double? minValue,
    double? maxValue,
  }) async {
    await _ensureInitialized();
    return await _opportunityRepository.getAllOpportunities(
      limit: limit,
      stage: stage,
      minValue: minValue,
      maxValue: maxValue,
    );
  }

  Stream<List<OpportunityModel>> getOpportunitiesStream({
    OpportunityStage? stage,
    int limit = 20,
  }) {
    return _opportunityRepository.getOpportunitiesStream(
      stage: stage,
      limit: limit,
    );
  }

  Future<void> updateOpportunity(String id, OpportunityModel opportunity) async {
    await _ensureInitialized();
    return await _opportunityRepository.updateOpportunity(id, opportunity);
  }

  Future<void> deleteOpportunity(String id) async {
    await _ensureInitialized();
    return await _opportunityRepository.deleteOpportunity(id);
  }

  Future<List<OpportunityModel>> getOpportunitiesByCustomer(String customerId) async {
    await _ensureInitialized();
    return await _opportunityRepository.getOpportunitiesByCustomer(customerId);
  }

  Future<List<OpportunityModel>> searchOpportunities(String searchTerm) async {
    await _ensureInitialized();
    return await _opportunityRepository.searchOpportunities(searchTerm);
  }

  // Contact operations
  Future<String> createContact(ContactModel contact) async {
    await _ensureInitialized();
    return await _contactRepository.createContact(contact);
  }

  Future<ContactModel?> getContactById(String id) async {
    await _ensureInitialized();
    return await _contactRepository.getContactById(id);
  }

  Future<List<ContactModel>> getAllContacts({
    int limit = 20,
    String? companyId,
    ContactType? type,
  }) async {
    await _ensureInitialized();
    return await _contactRepository.getAllContacts(
      limit: limit,
      companyId: companyId,
      type: type,
    );
  }

  Stream<List<ContactModel>> getContactsStream({
    String? companyId,
    ContactType? type,
    int limit = 20,
  }) {
    return _contactRepository.getContactsStream(
      companyId: companyId,
      type: type,
      limit: limit,
    );
  }

  Future<void> updateContact(String id, ContactModel contact) async {
    await _ensureInitialized();
    return await _contactRepository.updateContact(id, contact);
  }

  Future<void> deleteContact(String id) async {
    await _ensureInitialized();
    return await _contactRepository.deleteContact(id);
  }

  Future<List<ContactModel>> getContactsByCompany(String companyId) async {
    await _ensureInitialized();
    return await _contactRepository.getContactsByCompany(companyId);
  }

  Future<List<ContactModel>> searchContacts(String searchTerm) async {
    await _ensureInitialized();
    return await _contactRepository.searchContacts(searchTerm);
  }

  // Dashboard and analytics
  Future<Map<String, dynamic>> getDashboardData() async {
    await _ensureInitialized();
    
    try {
      final results = await Future.wait([
        _customerRepository.getCustomerStatistics(),
        _leadRepository.getLeadStatistics(),
        _opportunityRepository.getOpportunityStatistics(),
        _contactRepository.getContactStatistics(),
      ]);
      
      return {
        'customers': results[0],
        'leads': results[1],
        'opportunities': results[2],
        'contacts': results[3],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get dashboard data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSalesPipeline() async {
    await _ensureInitialized();
    return await _opportunityRepository.getSalesPipeline();
  }

  Future<List<CustomerModel>> getTopCustomers({int limit = 10}) async {
    await _ensureInitialized();
    return await _customerRepository.getTopCustomers(limit: limit);
  }

  Future<List<ContactModel>> getRecentContacts({int limit = 10}) async {
    await _ensureInitialized();
    return await _contactRepository.getRecentContacts(limit: limit);
  }

  // Utility methods
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        throw Exception('Failed to initialize CRM Service: $e');
      }
    }
  }

  // Clear all caches
  void clearAllCaches() {
    clearCache(); // Clear service-level cache
    _customerRepository.clearCache();
    _leadRepository.clearCache();
    _opportunityRepository.clearCache();
    _contactRepository.clearCache();
  }

  // Dispose all resources
  void dispose() {
    _customerRepository.clearCache();
    _leadRepository.dispose();
    _opportunityRepository.dispose();
    _contactRepository.dispose();
    _isInitialized = false;
  }
}