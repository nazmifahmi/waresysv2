import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String feedbackId;
  final String customerId;
  final int rating;
  final String message;
  final DateTime date;

  FeedbackModel({
    required this.feedbackId,
    required this.customerId,
    required this.rating,
    required this.message,
    required this.date,
  }) : assert(feedbackId.isNotEmpty, 'feedbackId cannot be empty'),
       assert(customerId.isNotEmpty, 'customerId cannot be empty'),
       assert(rating >= 1 && rating <= 5, 'rating must be between 1 and 5'),
       assert(message.isNotEmpty, 'message cannot be empty');

  Map<String, dynamic> toMap() => {
        'feedbackId': feedbackId,
        'customerId': customerId,
        'rating': rating,
        'message': message,
        'date': Timestamp.fromDate(date),
      };

  factory FeedbackModel.fromMap(Map<String, dynamic> map) => FeedbackModel(
        feedbackId: map['feedbackId'],
        customerId: map['customerId'],
        rating: (map['rating'] as num).toInt(),
        message: map['message'],
        date: (map['date'] as Timestamp).toDate(),
      );

  factory FeedbackModel.fromDoc(DocumentSnapshot doc) =>
      FeedbackModel.fromMap({...doc.data() as Map<String, dynamic>, 'feedbackId': doc.id});
}