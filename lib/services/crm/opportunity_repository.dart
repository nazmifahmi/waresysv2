import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/crm/opportunity_model.dart';

class OpportunityRepository {
  static final OpportunityRepository _instance = OpportunityRepository._internal();
  factory OpportunityRepository() => _instance;
  OpportunityRepository._internal();

  CollectionReference<Map<String, dynamic>>? _opportunitiesCollection;
  
  // Cache for performance
  final Map<String, OpportunityModel> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Initialize Firestore collection
  Future<void> initialize() async {
    try {
      _opportunitiesCollection = FirebaseFirestore.instance.collection('opportunities');
    } catch (e) {
      throw Exception('Failed to initialize Opportunity Repository: $e');
    }
  }

  // Check if cache is valid
  bool _isCacheValid(String id) {
    if (!_cache.containsKey(id) || !_cacheTimestamps.containsKey(id)) {
      return false;
    }
    return DateTime.now().difference(_cacheTimestamps[id]!) < _cacheExpiry;
  }

  // Create new opportunity
  Future<String> createOpportunity(OpportunityModel opportunity) async {
    try {
      if (_opportunitiesCollection == null) await initialize();
      
      final docRef = await _opportunitiesCollection!.add(opportunity.toMap());
      
      // Update cache
      final newOpportunity = opportunity.copyWith(id: docRef.id);
      _cache[docRef.id] = newOpportunity;
      _cacheTimestamps[docRef.id] = DateTime.now();
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create opportunity: $e');
    }
  }

  // Get opportunity by ID
  Future<OpportunityModel?> getOpportunityById(String id) async {
    try {
      // Check cache first
      if (_isCacheValid(id)) {
        return _cache[id];
      }

      if (_opportunitiesCollection == null) await initialize();
      
      final doc = await _opportunitiesCollection!.doc(id).get();
      
      if (!doc.exists) return null;
      
      final opportunity = OpportunityModel.fromMap(doc.data()!).copyWith(id: doc.id);
      
      // Update cache
      _cache[id] = opportunity;
      _cacheTimestamps[id] = DateTime.now();
      
      return opportunity;
    } catch (e) {
      throw Exception('Failed to get opportunity: $e');
    }
  }

  // Get all opportunities with pagination
  Future<List<OpportunityModel>> getAllOpportunities({
    int limit = 20,
    DocumentSnapshot? startAfter,
    OpportunityStage? stage,
    double? minValue,
    double? maxValue,
  }) async {
    try {
      if (_opportunitiesCollection == null) await initialize();
      
      Query<Map<String, dynamic>> query = _opportunitiesCollection!;
      
      // Apply filters
      if (stage != null) {
        query = query.where('stage', isEqualTo: stage.name);
      }
      
      if (minValue != null) {
        query = query.where('amount', isGreaterThanOrEqualTo: minValue);
      }
      
      if (maxValue != null) {
        query = query.where('amount', isLessThanOrEqualTo: maxValue);
      }
      
      // Order by amount (highest first)
      query = query.orderBy('amount', descending: true);
      
      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      query = query.limit(limit);
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final opportunity = OpportunityModel.fromMap(doc.data()).copyWith(id: doc.id);
        
        // Update cache
        _cache[doc.id] = opportunity;
        _cacheTimestamps[doc.id] = DateTime.now();
        
        return opportunity;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get opportunities: $e');
    }
  }

  // Get opportunities stream for real-time updates
  Stream<List<OpportunityModel>> getOpportunitiesStream({
    OpportunityStage? stage,
    int limit = 20,
  }) {
    if (_opportunitiesCollection == null) {
      return Stream.error('Repository not initialized');
    }

    Query<Map<String, dynamic>> query = _opportunitiesCollection!;
    
    // Apply filters
    if (stage != null) {
      query = query.where('stage', isEqualTo: stage.name);
    }
    
    query = query.orderBy('amount', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final opportunity = OpportunityModel.fromMap(doc.data()).copyWith(id: doc.id);
        
        // Update cache for real-time data
        _cache[doc.id] = opportunity;
        _cacheTimestamps[doc.id] = DateTime.now();
        
        return opportunity;
      }).toList();
    });
  }

  // Update opportunity
  Future<void> updateOpportunity(String id, OpportunityModel updatedOpportunity) async {
    try {
      if (_opportunitiesCollection == null) await initialize();
      
      final opportunityWithId = updatedOpportunity.copyWith(
        id: id,
        updatedAt: DateTime.now(),
      );

      await _opportunitiesCollection!.doc(id).update(opportunityWithId.toMap());
      
      // Update cache
      _cache[id] = opportunityWithId;
      _cacheTimestamps[id] = DateTime.now();
    } catch (e) {
      throw Exception('Failed to update opportunity: $e');
    }
  }

  // Delete opportunity
  Future<void> deleteOpportunity(String id) async {
    try {
      if (_opportunitiesCollection == null) await initialize();
      
      await _opportunitiesCollection!.doc(id).delete();
      
      // Remove from cache
      _cache.remove(id);
      _cacheTimestamps.remove(id);
    } catch (e) {
      throw Exception('Failed to delete opportunity: $e');
    }
  }

  // Get opportunities by stage
  Future<List<OpportunityModel>> getOpportunitiesByStage(OpportunityStage stage) async {
    try {
      if (_opportunitiesCollection == null) await initialize();
      
      final query = _opportunitiesCollection!
          .where('stage', isEqualTo: stage.name)
          .orderBy('amount', descending: true)
          .limit(50);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => 
        OpportunityModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();
    } catch (e) {
      throw Exception('Failed to get opportunities by stage: $e');
    }
  }

  // Get opportunities by customer
  Future<List<OpportunityModel>> getOpportunitiesByCustomer(String customerId) async {
    try {
      if (_opportunitiesCollection == null) await initialize();
      
      final query = _opportunitiesCollection!
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => 
        OpportunityModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();
    } catch (e) {
      throw Exception('Failed to get opportunities by customer: $e');
    }
  }

  // Search opportunities
  Future<List<OpportunityModel>> searchOpportunities(String searchTerm) async {
    try {
      if (_opportunitiesCollection == null) await initialize();
      
      if (searchTerm.isEmpty) return [];
      
      final searchTermLower = searchTerm.toLowerCase();
      
      // Search by normalized name field
      final nameQuery = _opportunitiesCollection!
          .where('searchName', isGreaterThanOrEqualTo: searchTermLower)
          .where('searchName', isLessThan: '${searchTermLower}z')
          .limit(10);
      
      final nameResults = await nameQuery.get();
      final opportunities = nameResults.docs.map((doc) => 
        OpportunityModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();
      
      // Update cache
      for (final opportunity in opportunities) {
        if (opportunity.id != null) {
          _cache[opportunity.id!] = opportunity;
          _cacheTimestamps[opportunity.id!] = DateTime.now();
        }
      }
      
      return opportunities;
    } catch (e) {
      throw Exception('Failed to search opportunities: $e');
    }
  }

  // Get opportunity statistics
  Future<Map<String, dynamic>> getOpportunityStatistics() async {
    try {
      if (_opportunitiesCollection == null) await initialize();
      
      final allOpportunities = await _opportunitiesCollection!.get();
      
      final stats = <String, dynamic>{
        'total': allOpportunities.docs.length,
        'totalValue': 0.0,
        'averageValue': 0.0,
        'stageBreakdown': <String, int>{},
        'wonOpportunities': 0,
        'lostOpportunities': 0,
      };
      
      double totalValue = 0.0;
      
      for (final doc in allOpportunities.docs) {
        final data = doc.data();
        final value = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final stage = data['stage'] as String? ?? 'prospecting';
        
        totalValue += value;
        
        // Count by stage
        final stageBreakdown = stats['stageBreakdown'] as Map<String, int>;
        stageBreakdown[stage] = (stageBreakdown[stage] ?? 0) + 1;
        
        // Count won/lost
        if (stage == 'closed_won') {
          stats['wonOpportunities'] = (stats['wonOpportunities'] as int) + 1;
        } else if (stage == 'closed_lost') {
          stats['lostOpportunities'] = (stats['lostOpportunities'] as int) + 1;
        }
      }
      
      stats['totalValue'] = totalValue;
      stats['averageValue'] = allOpportunities.docs.isNotEmpty 
          ? totalValue / allOpportunities.docs.length 
          : 0.0;
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get opportunity statistics: $e');
    }
  }

  // Get sales pipeline data
  Future<List<Map<String, dynamic>>> getSalesPipeline() async {
    try {
      if (_opportunitiesCollection == null) await initialize();
      
      final pipeline = <Map<String, dynamic>>[];
      
      // Get opportunities grouped by stage
      for (final stage in OpportunityStage.values) {
        final query = _opportunitiesCollection!
            .where('stage', isEqualTo: stage.name);
        
        final snapshot = await query.get();
        
        double stageValue = 0.0;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final value = (data['amount'] as num?)?.toDouble() ?? 0.0;
          stageValue += value;
        }
        
        pipeline.add({
          'stage': stage.name,
          'count': snapshot.docs.length,
          'value': stageValue,
        });
      }
      
      return pipeline;
    } catch (e) {
      throw Exception('Failed to get sales pipeline: $e');
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