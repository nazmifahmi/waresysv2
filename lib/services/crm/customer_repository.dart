import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/crm/customer_model.dart';

class CustomerRepository {
  static const String _collection = 'customers';
  
  // Lazy initialization with Firebase check
  CollectionReference<Map<String, dynamic>>? get _customersCollection {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance.collection(_collection);
  }

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;

  // Cache for frequently accessed customers
  final Map<String, CustomerModel> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Create customer
  Future<String?> createCustomer(CustomerModel customer) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for customer creation');
        return null;
      }

      final docRef = await _customersCollection!.add(customer.toMap());
      final createdCustomer = customer.copyWith(id: docRef.id);
      
      // Update cache
      _cache[docRef.id] = createdCustomer;
      _cacheTimestamps[docRef.id] = DateTime.now();
      
      print('✅ Customer created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating customer: $e');
      return null;
    }
  }

  // Get customer by ID with caching
  Future<CustomerModel?> getCustomerById(String id) async {
    try {
      // Check cache first
      if (_cache.containsKey(id) && _isCacheValid(id)) {
        print('📦 Customer loaded from cache: $id');
        return _cache[id];
      }

      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for customer retrieval');
        return null;
      }

      final doc = await _customersCollection!.doc(id).get();
      if (!doc.exists) {
        print('⚠️ Customer not found: $id');
        return null;
      }

      final customer = CustomerModel.fromMap(doc.data()!).copyWith(id: doc.id);
      
      // Update cache
      _cache[id] = customer;
      _cacheTimestamps[id] = DateTime.now();
      
      return customer;
    } catch (e) {
      print('❌ Error getting customer: $e');
      return null;
    }
  }

  // Get all customers with pagination and filtering
  Future<List<CustomerModel>> getCustomers({
    int limit = 20,
    DocumentSnapshot? startAfter,
    CustomerStatus? status,
    CustomerSegment? segment,
    String? searchQuery,
  }) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for customers retrieval');
        return [];
      }

      Query<Map<String, dynamic>> query = _customersCollection!;

      // Apply filters - ensure proper ordering for compound queries
      if (status != null) {
        print('🔍 Filtering customers by status: ${status.name}');
        query = query.where('status', isEqualTo: status.name);
      }
      if (segment != null) {
        print('🔍 Filtering customers by segment: ${segment.name}');
        query = query.where('segment', isEqualTo: segment.name);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        print('🔍 Searching customers with query: $searchLower');
        query = query.where('searchName', isGreaterThanOrEqualTo: searchLower)
                    .where('searchName', isLessThan: searchLower + 'z');
      }

      // Apply ordering and pagination
      query = query.orderBy('createdAt', descending: true);
      
      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final customers = snapshot.docs.map((doc) => 
        CustomerModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();
      
      print('✅ Retrieved ${customers.length} customers');
      return customers;
    } catch (e) {
      print('❌ Error getting customers: $e');
      return [];
    }
  }

  // Watch customers real-time
  Stream<List<CustomerModel>> watchCustomers({
    CustomerStatus? status,
    CustomerSegment? segment,
    int limit = 20,
  }) {
    if (!_isFirebaseAvailable) {
      print('⚠️ Firebase not available for customers stream');
      return Stream.value([]);
    }

    Query<Map<String, dynamic>> query = _customersCollection!;

    // Apply filters with proper ordering
    if (status != null) {
      print('🔍 Watching customers by status: ${status.name}');
      query = query.where('status', isEqualTo: status.name);
    }
    if (segment != null) {
      print('🔍 Watching customers by segment: ${segment.name}');
      query = query.where('segment', isEqualTo: segment.name);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      final customers = snapshot.docs.map((doc) {
        final customer = CustomerModel.fromMap(doc.data()).copyWith(id: doc.id);
        
        // Update cache for real-time data
        _cache[doc.id] = customer;
        _cacheTimestamps[doc.id] = DateTime.now();
        
        return customer;
      }).toList();
      
      print('📡 Stream updated with ${customers.length} customers');
      return customers;
    });
  }

  // Update customer
  Future<bool> updateCustomer(String id, CustomerModel customer) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for customer update');
        return false;
      }

      final updatedCustomer = customer.copyWith(
        id: id,
        updatedAt: DateTime.now(),
      );

      await _customersCollection!.doc(id).update(updatedCustomer.toMap());
      
      // Update cache
      _cache[id] = updatedCustomer;
      _cacheTimestamps[id] = DateTime.now();
      
      print('✅ Customer updated successfully: $id');
      return true;
    } catch (e) {
      print('❌ Error updating customer: $e');
      return false;
    }
  }

  // Delete customer
  Future<bool> deleteCustomer(String id) async {
    try {
      if (!_isFirebaseAvailable) {
        print('⚠️ Firebase not available for customer deletion');
        return false;
      }

      await _customersCollection!.doc(id).delete();
      
      // Remove from cache
      _cache.remove(id);
      _cacheTimestamps.remove(id);
      
      print('✅ Customer deleted successfully: $id');
      return true;
    } catch (e) {
      print('❌ Error deleting customer: $e');
      return false;
    }
  }

  // Search customers by multiple criteria
  Future<List<CustomerModel>> searchCustomers({
    required String query,
    CustomerStatus? status,
    CustomerSegment? segment,
    int limit = 20,
  }) async {
    try {
      if (!_isFirebaseAvailable || query.isEmpty) {
        return [];
      }

      final searchLower = query.toLowerCase();
      Query<Map<String, dynamic>> firestoreQuery = _customersCollection!;

      // Apply filters
      if (status != null) {
        firestoreQuery = firestoreQuery.where('status', isEqualTo: status.name);
      }
      if (segment != null) {
        firestoreQuery = firestoreQuery.where('segment', isEqualTo: segment.name);
      }

      // Search by name
      firestoreQuery = firestoreQuery
          .where('searchName', isGreaterThanOrEqualTo: searchLower)
          .where('searchName', isLessThan: searchLower + 'z')
          .limit(limit);

      final nameResults = await firestoreQuery.get();
      final customers = nameResults.docs.map((doc) => 
        CustomerModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();

      // Also search by email if query looks like email
      if (query.contains('@')) {
        final emailQuery = _customersCollection!
            .where('searchEmail', isGreaterThanOrEqualTo: searchLower)
            .where('searchEmail', isLessThan: searchLower + 'z')
            .limit(limit);

        final emailResults = await emailQuery.get();
        final emailCustomers = emailResults.docs.map((doc) => 
          CustomerModel.fromMap(doc.data()).copyWith(id: doc.id)
        ).toList();

        // Merge results and remove duplicates
        final allCustomers = [...customers, ...emailCustomers];
        final uniqueCustomers = <String, CustomerModel>{};
        for (final customer in allCustomers) {
          uniqueCustomers[customer.id] = customer;
        }
        return uniqueCustomers.values.toList();
      }

      return customers;
    } catch (e) {
      print('❌ Error searching customers: $e');
      return [];
    }
  }

  // Get customers by segment for analytics
  Future<Map<CustomerSegment, int>> getCustomersBySegment() async {
    try {
      if (!_isFirebaseAvailable) {
        return {};
      }

      final Map<CustomerSegment, int> segmentCounts = {};
      
      for (final segment in CustomerSegment.values) {
        final query = _customersCollection!
            .where('segment', isEqualTo: segment.name);
        final snapshot = await query.count().get();
        segmentCounts[segment] = snapshot.count ?? 0;
      }

      return segmentCounts;
    } catch (e) {
      print('❌ Error getting customers by segment: $e');
      return {};
    }
  }

  // Get top customers by value
  Future<List<CustomerModel>> getTopCustomers({int limit = 10}) async {
    try {
      if (!_isFirebaseAvailable) {
        return [];
      }

      final query = _customersCollection!
          .orderBy('totalPurchaseValue', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => 
        CustomerModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();
    } catch (e) {
      print('❌ Error getting top customers: $e');
      return [];
    }
  }

  // Get customer statistics
  Future<Map<String, int>> getCustomerStatistics() async {
    try {
      if (!_isFirebaseAvailable) {
        return {
          'total': 0,
          'active': 0,
          'inactive': 0,
          'premium': 0,
          'standard': 0,
          'basic': 0,
        };
      }

      final snapshot = await _customersCollection!.get();
      final customers = snapshot.docs.map((doc) => 
        CustomerModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();

      final stats = <String, int>{
        'total': customers.length,
        'active': 0,
        'inactive': 0,
        'premium': 0,
        'standard': 0,
        'basic': 0,
      };

      for (final customer in customers) {
        // Count by status
        if (customer.status == CustomerStatus.active) {
          stats['active'] = (stats['active'] ?? 0) + 1;
        } else {
          stats['inactive'] = (stats['inactive'] ?? 0) + 1;
        }

        // Count by segment
        switch (customer.segment) {
          case CustomerSegment.premium:
            stats['premium'] = (stats['premium'] ?? 0) + 1;
            break;
          case CustomerSegment.standard:
            stats['standard'] = (stats['standard'] ?? 0) + 1;
            break;
          case CustomerSegment.basic:
            stats['basic'] = (stats['basic'] ?? 0) + 1;
            break;
          case CustomerSegment.vip:
            stats['premium'] = (stats['premium'] ?? 0) + 1; // Count VIP as premium
            break;
        }
      }

      return stats;
    } catch (e) {
      print('❌ Error getting customer statistics: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'premium': 0,
        'standard': 0,
        'basic': 0,
      };
    }
  }

  // Cache management
  bool _isCacheValid(String id) {
    final timestamp = _cacheTimestamps[id];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    print('🧹 Customer cache cleared');
  }

  // Batch operations
  Future<bool> batchUpdateCustomers(List<CustomerModel> customers) async {
    try {
      if (!_isFirebaseAvailable || customers.isEmpty) {
        return false;
      }

      final batch = FirebaseFirestore.instance.batch();
      
      for (final customer in customers) {
        if (customer.id.isNotEmpty) {
          final docRef = _customersCollection!.doc(customer.id);
          batch.update(docRef, customer.copyWith(
            updatedAt: DateTime.now(),
          ).toMap());
        }
      }

      await batch.commit();
      
      // Update cache
      for (final customer in customers) {
        if (customer.id.isNotEmpty) {
          _cache[customer.id] = customer;
          _cacheTimestamps[customer.id] = DateTime.now();
        }
      }

      print('✅ Batch update completed for ${customers.length} customers');
      return true;
    } catch (e) {
      print('❌ Error in batch update: $e');
      return false;
    }
  }
}