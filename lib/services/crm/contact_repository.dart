import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/crm/contact_model.dart';

class ContactRepository {
  static final ContactRepository _instance = ContactRepository._internal();
  factory ContactRepository() => _instance;
  ContactRepository._internal();

  CollectionReference<Map<String, dynamic>>? _contactsCollection;
  
  // Cache for performance
  final Map<String, ContactModel> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Initialize Firestore collection
  Future<void> initialize() async {
    try {
      _contactsCollection = FirebaseFirestore.instance.collection('contacts');
    } catch (e) {
      throw Exception('Failed to initialize Contact Repository: $e');
    }
  }

  // Check if cache is valid
  bool _isCacheValid(String id) {
    if (!_cache.containsKey(id) || !_cacheTimestamps.containsKey(id)) {
      return false;
    }
    return DateTime.now().difference(_cacheTimestamps[id]!) < _cacheExpiry;
  }

  // Create new contact
  Future<String> createContact(ContactModel contact) async {
    try {
      if (_contactsCollection == null) await initialize();
      
      final docRef = await _contactsCollection!.add(contact.toMap());
      
      // Update cache
      final newContact = contact.copyWith(id: docRef.id);
      _cache[docRef.id] = newContact;
      _cacheTimestamps[docRef.id] = DateTime.now();
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create contact: $e');
    }
  }

  // Get contact by ID
  Future<ContactModel?> getContactById(String id) async {
    try {
      // Check cache first
      if (_isCacheValid(id)) {
        return _cache[id];
      }

      if (_contactsCollection == null) await initialize();
      
      final doc = await _contactsCollection!.doc(id).get();
      
      if (!doc.exists) return null;
      
      final contact = ContactModel.fromMap(doc.data()!).copyWith(id: doc.id);
      
      // Update cache
      _cache[id] = contact;
      _cacheTimestamps[id] = DateTime.now();
      
      return contact;
    } catch (e) {
      throw Exception('Failed to get contact: $e');
    }
  }

  // Get all contacts with pagination
  Future<List<ContactModel>> getAllContacts({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? companyId,
    ContactType? type,
  }) async {
    try {
      if (_contactsCollection == null) await initialize();
      
      Query<Map<String, dynamic>> query = _contactsCollection!;
      
      // Apply filters
      if (companyId != null) {
        query = query.where('companyId', isEqualTo: companyId);
      }
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      // Order by name
      query = query.orderBy('firstName');
      
      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      query = query.limit(limit);
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final contact = ContactModel.fromMap(doc.data()).copyWith(id: doc.id);
        
        // Update cache
        _cache[doc.id] = contact;
        _cacheTimestamps[doc.id] = DateTime.now();
        
        return contact;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get contacts: $e');
    }
  }

  // Get contacts stream for real-time updates
  Stream<List<ContactModel>> getContactsStream({
    String? companyId,
    ContactType? type,
    int limit = 20,
  }) {
    if (_contactsCollection == null) {
      return Stream.error('Repository not initialized');
    }

    Query<Map<String, dynamic>> query = _contactsCollection!;
    
    // Apply filters
    if (companyId != null) {
      query = query.where('companyId', isEqualTo: companyId);
    }
    
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    
    query = query.orderBy('firstName').limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final contact = ContactModel.fromMap(doc.data()).copyWith(id: doc.id);
        
        // Update cache for real-time data
        _cache[doc.id] = contact;
        _cacheTimestamps[doc.id] = DateTime.now();
        
        return contact;
      }).toList();
    });
  }

  // Update contact
  Future<void> updateContact(String id, ContactModel updatedContact) async {
    try {
      if (_contactsCollection == null) await initialize();
      
      final contactWithId = updatedContact.copyWith(
        id: id,
        updatedAt: DateTime.now(),
      );

      await _contactsCollection!.doc(id).update(contactWithId.toMap());
      
      // Update cache
      _cache[id] = contactWithId;
      _cacheTimestamps[id] = DateTime.now();
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  // Delete contact
  Future<void> deleteContact(String id) async {
    try {
      if (_contactsCollection == null) await initialize();
      
      await _contactsCollection!.doc(id).delete();
      
      // Remove from cache
      _cache.remove(id);
      _cacheTimestamps.remove(id);
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }

  // Get contacts by company
  Future<List<ContactModel>> getContactsByCompany(String companyId) async {
    try {
      if (_contactsCollection == null) await initialize();
      
      final query = _contactsCollection!
          .where('companyId', isEqualTo: companyId)
          .orderBy('firstName');
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => 
        ContactModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();
    } catch (e) {
      throw Exception('Failed to get contacts by company: $e');
    }
  }

  // Get contacts by type
  Future<List<ContactModel>> getContactsByType(ContactType type) async {
    try {
      if (_contactsCollection == null) await initialize();
      
      final query = _contactsCollection!
          .where('type', isEqualTo: type.name)
          .orderBy('firstName')
          .limit(50);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => 
        ContactModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();
    } catch (e) {
      throw Exception('Failed to get contacts by type: $e');
    }
  }

  // Search contacts
  Future<List<ContactModel>> searchContacts(String searchTerm) async {
    try {
      if (_contactsCollection == null) await initialize();
      
      if (searchTerm.isEmpty) return [];
      
      final searchTermLower = searchTerm.toLowerCase();
      
      // Search by first name
      final firstNameQuery = _contactsCollection!
          .where('firstName', isGreaterThanOrEqualTo: searchTermLower)
          .where('firstName', isLessThan: '${searchTermLower}z')
          .limit(10);
      
      final firstNameResults = await firstNameQuery.get();
      final contacts = firstNameResults.docs.map((doc) => 
        ContactModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();
      
      // Search by last name if no first name results
      if (contacts.isEmpty) {
        final lastNameQuery = _contactsCollection!
            .where('lastName', isGreaterThanOrEqualTo: searchTermLower)
            .where('lastName', isLessThan: '${searchTermLower}z')
            .limit(10);
        
        final lastNameResults = await lastNameQuery.get();
        final lastNameContacts = lastNameResults.docs.map((doc) => 
          ContactModel.fromMap(doc.data()).copyWith(id: doc.id)
        ).toList();
        
        contacts.addAll(lastNameContacts);
      }
      
      // Search by email if still no results
      if (contacts.isEmpty) {
        final emailQuery = _contactsCollection!
            .where('email', isGreaterThanOrEqualTo: searchTermLower)
            .where('email', isLessThan: '${searchTermLower}z')
            .limit(10);
        
        final emailResults = await emailQuery.get();
        final emailContacts = emailResults.docs.map((doc) => 
          ContactModel.fromMap(doc.data()).copyWith(id: doc.id)
        ).toList();
        
        contacts.addAll(emailContacts);
      }
      
      // Update cache
      for (final contact in contacts) {
        if (contact.id != null) {
          _cache[contact.id!] = contact;
          _cacheTimestamps[contact.id!] = DateTime.now();
        }
      }
      
      return contacts;
    } catch (e) {
      throw Exception('Failed to search contacts: $e');
    }
  }

  // Get contact statistics
  Future<Map<String, int>> getContactStatistics() async {
    try {
      if (_contactsCollection == null) await initialize();
      
      final allContacts = await _contactsCollection!.get();
      
      final stats = <String, int>{
        'total': allContacts.docs.length,
      };
      
      // Count by type
      for (final type in ContactType.values) {
        stats[type.name] = 0;
      }
      
      for (final doc in allContacts.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? 'primary';
        stats[type] = (stats[type] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get contact statistics: $e');
    }
  }

  // Get recent contacts
  Future<List<ContactModel>> getRecentContacts({int limit = 10}) async {
    try {
      if (_contactsCollection == null) await initialize();
      
      final query = _contactsCollection!
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => 
        ContactModel.fromMap(doc.data()).copyWith(id: doc.id)
      ).toList();
    } catch (e) {
      throw Exception('Failed to get recent contacts: $e');
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