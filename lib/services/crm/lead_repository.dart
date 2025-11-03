import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/crm/lead_model.dart';

class LeadRepository {
  static final LeadRepository _instance = LeadRepository._internal();
  factory LeadRepository() => _instance;
  LeadRepository._internal();

  CollectionReference<Map<String, dynamic>>? _leadsCollection;
  
  // Cache for performance
  final Map<String, LeadModel> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Initialize Firestore collection
  Future<void> initialize() async {
    try {
      _leadsCollection = FirebaseFirestore.instance.collection('leads');
    } catch (e) {
      throw Exception('Failed to initialize Lead Repository: $e');
    }
  }

  // Check if cache is valid
  bool _isCacheValid(String id) {
    if (!_cache.containsKey(id) || !_cacheTimestamps.containsKey(id)) {
      return false;
    }
    return DateTime.now().difference(_cacheTimestamps[id]!) < _cacheExpiry;
  }

  // Create new lead
  Future<String> createLead(LeadModel lead) async {
    try {
      if (_leadsCollection == null) await initialize();
      
      final docRef = await _leadsCollection!.add(lead.toMap());
      
      // Update cache
      final newLead = lead.copyWith(id: docRef.id);
      _cache[docRef.id] = newLead;
      _cacheTimestamps[docRef.id] = DateTime.now();
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create lead: $e');
    }
  }

  // Get lead by ID
  Future<LeadModel?> getLeadById(String id) async {
    try {
      // Check cache first
      if (_isCacheValid(id)) {
        return _cache[id];
      }

      if (_leadsCollection == null) await initialize();
      
      final doc = await _leadsCollection!.doc(id).get();
      
      if (!doc.exists) return null;
      
      final lead = LeadModel.fromMap(doc.data()!).copyWith(id: doc.id);
      
      // Update cache
      _cache[id] = lead;
      _cacheTimestamps[id] = DateTime.now();
      
      return lead;
    } catch (e) {
      throw Exception('Failed to get lead: $e');
    }
  }

  // Get all leads with pagination
  Future<List<LeadModel>> getAllLeads({
    int limit = 20,
    DocumentSnapshot? startAfter,
    LeadStatus? status,
    LeadSource? source,
  }) async {
    try {
      if (_leadsCollection == null) await initialize();
      
      Query<Map<String, dynamic>> query = _leadsCollection!;
      
      // Apply filters
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      if (source != null) {
        query = query.where('source', isEqualTo: source.name);
      }
      
      // Order by creation date
      query = query.orderBy('createdAt', descending: true);
      
      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      query = query.limit(limit);
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final lead = LeadModel.fromMap(doc.data()).copyWith(id: doc.id);
        
        // Update cache
        _cache[doc.id] = lead;
        _cacheTimestamps[doc.id] = DateTime.now();
        
        return lead;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get leads: $e');
    }
  }

  // Get leads stream for real-time updates
  Stream<List<LeadModel>> getLeadsStream({
    LeadStatus? status,
    LeadSource? source,
    int limit = 20,
  }) {
    if (_leadsCollection == null) {
      return Stream.error('Repository not initialized');
    }

    Query<Map<String, dynamic>> query = _leadsCollection!;
    
    // Apply filters
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    
    if (source != null) {
      query = query.where('source', isEqualTo: source.name);
    }
    
    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final lead = LeadModel.fromMap(doc.data()).copyWith(id: doc.id);
        
        // Update cache for real-time data
        _cache[doc.id] = lead;
        _cacheTimestamps[doc.id] = DateTime.now();
        
        return lead;
      }).toList();
    });
  }

  // Update lead
  Future<void> updateLead(String id, LeadModel updatedLead) async {
    try {
      if (_leadsCollection == null) await initialize();
      
      final leadWithId = updatedLead.copyWith(
        id: id,
        updatedAt: DateTime.now(),
      );

      await _leadsCollection!.doc(id).update(leadWithId.toMap());
      
      // Update cache
      _cache[id] = leadWithId;
      _cacheTimestamps[id] = DateTime.now();
    } catch (e) {
      throw Exception('Failed to update lead: $e');
    }
  }

  // Delete lead
  Future<void> deleteLead(String id) async {
    try {
      if (_leadsCollection == null) await initialize();
      
      await _leadsCollection!.doc(id).delete();
      
      // Remove from cache
      _cache.remove(id);
      _cacheTimestamps.remove(id);
    } catch (e) {
      throw Exception('Failed to delete lead: $e');
    }
  }

  // Convert lead to customer
  Future<void> convertLeadToCustomer(String leadId) async {
    try {
      if (_leadsCollection == null) await initialize();
      
      final lead = await getLeadById(leadId);
      if (lead == null) {
        throw Exception('Lead not found');
      }
      
      // Update lead status to converted
      await updateLead(leadId, lead.copyWith(
        status: LeadStatus.closed_won,
        updatedAt: DateTime.now(),
      ));
      
    } catch (e) {
      throw Exception('Failed to convert lead: $e');
    }
  }

  // Search leads
  Future<List<LeadModel>> searchLeads(String searchTerm) async {
    try {
      if (_leadsCollection == null) await initialize();
      
      if (searchTerm.isEmpty) return [];
      
      final searchTermLower = searchTerm.toLowerCase();
      
      // Search by name
      final nameQuery = _leadsCollection!
          .where('name', isGreaterThanOrEqualTo: searchTermLower)
          .where('name', isLessThan: searchTermLower + 'z')
          .limit(10);
      
      final nameResults = await nameQuery.get();
      final leads = nameResults.docs.map((doc) => 
        LeadModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();
      
      // Search by email if no name results
      if (leads.isEmpty) {
        final emailQuery = _leadsCollection!
            .where('email', isGreaterThanOrEqualTo: searchTermLower)
            .where('email', isLessThan: searchTermLower + 'z')
            .limit(10);
        
        final emailResults = await emailQuery.get();
        final emailLeads = emailResults.docs.map((doc) => 
          LeadModel.fromMap(doc.data()).copyWith(id: doc.id)
        ).toList();
        
        leads.addAll(emailLeads);
      }
      
      // Update cache
      for (final lead in leads) {
        if (lead.id != null) {
          _cache[lead.id!] = lead;
          _cacheTimestamps[lead.id!] = DateTime.now();
        }
      }
      
      return leads;
    } catch (e) {
      throw Exception('Failed to search leads: $e');
    }
  }

  // Get leads by status
  Future<List<LeadModel>> getLeadsByStatus(LeadStatus status) async {
    try {
      if (_leadsCollection == null) await initialize();
      
      final query = _leadsCollection!
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .limit(50);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => 
        LeadModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();
    } catch (e) {
      throw Exception('Failed to get leads by status: $e');
    }
  }

  // Get lead statistics
  Future<Map<String, int>> getLeadStatistics() async {
    try {
      if (_leadsCollection == null) await initialize();
      
      final allLeads = await _leadsCollection!.get();
      
      final stats = <String, int>{
        'total': allLeads.docs.length,
        'new': 0,
        'contacted': 0,
        'qualified': 0,
        'converted': 0,
        'lost': 0,
      };
      
      for (final doc in allLeads.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'new';
        stats[status] = (stats[status] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get lead statistics: $e');
    }
  }

  // Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Dispose resources
  void dispose() {
    clearCache();
  }
}