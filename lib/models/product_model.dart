import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final int minStock;
  final String category;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? sku; // Stock Keeping Unit

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.minStock,
    required this.category,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.sku,
  });

  // Convert Product to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'minStock': minStock,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'sku': sku,
    };
  }

  // Create Product from Firestore Document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      minStock: data['minStock'] ?? 5,
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      sku: data['sku'],
    );
  }

  // Create a copy of Product with some fields updated
  Product copyWith({
    String? name,
    String? description,
    double? price,
    int? stock,
    int? minStock,
    String? category,
    String? imageUrl,
    DateTime? updatedAt,
    String? sku,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      sku: sku ?? this.sku,
    );
  }
} 