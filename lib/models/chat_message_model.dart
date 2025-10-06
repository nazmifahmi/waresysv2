import 'package:flutter/foundation.dart';

enum MessageType {
  text,
  image,
  system
}

enum MessageSender {
  user,
  ai
}

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final MessageSender sender;
  final DateTime timestamp;
  final String? imageUrl;
  final String? imagePath;
  final bool isLoading;
  final String? error;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.sender,
    required this.timestamp,
    this.imageUrl,
    this.imagePath,
    this.isLoading = false,
    this.error,
  });

  // Factory constructor untuk membuat pesan user
  factory ChatMessage.user({
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? imagePath,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      imagePath: imagePath,
    );
  }

  // Factory constructor untuk membuat pesan AI
  factory ChatMessage.ai({
    required String content,
    MessageType type = MessageType.text,
    bool isLoading = false,
    String? error,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isLoading: isLoading,
      error: error,
    );
  }

  // Factory constructor untuk membuat pesan loading
  factory ChatMessage.loading() {
    return ChatMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      content: 'AI sedang mengetik...',
      type: MessageType.system,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  // Factory constructor untuk membuat pesan error
  factory ChatMessage.error(String errorMessage) {
    return ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      content: 'Maaf, terjadi kesalahan: $errorMessage',
      type: MessageType.system,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      error: errorMessage,
    );
  }

  // Copy with method untuk update message
  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageSender? sender,
    DateTime? timestamp,
    String? imageUrl,
    String? imagePath,
    bool? isLoading,
    String? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  // Convert to JSON untuk penyimpanan
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'sender': sender.name,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'isLoading': isLoading,
      'error': error,
    };
  }

  // Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      sender: MessageSender.values.firstWhere(
        (e) => e.name == json['sender'],
        orElse: () => MessageSender.user,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      imageUrl: json['imageUrl'],
      imagePath: json['imagePath'],
      isLoading: json['isLoading'] ?? false,
      error: json['error'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, type: $type, sender: $sender, timestamp: $timestamp)';
  }
}