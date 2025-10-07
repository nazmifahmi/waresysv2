import 'package:cloud_firestore/cloud_firestore.dart';

enum CampaignType { EMAIL, PUSH_NOTIFICATION }
enum CampaignStatus { DRAFT, RUNNING, COMPLETED }

class CampaignModel {
  final String campaignId;
  final String name;
  final CampaignType type;
  final List<String> targetAudience; // list of contactIds for now
  final CampaignStatus status;
  final int sentCount;

  CampaignModel({
    required this.campaignId,
    required this.name,
    required this.type,
    required this.targetAudience,
    this.status = CampaignStatus.DRAFT,
    this.sentCount = 0,
  }) : assert(campaignId.isNotEmpty), assert(name.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'campaignId': campaignId,
        'name': name,
        'type': type.name,
        'targetAudience': targetAudience,
        'status': status.name,
        'sentCount': sentCount,
      };

  factory CampaignModel.fromMap(Map<String, dynamic> map) => CampaignModel(
        campaignId: map['campaignId'],
        name: map['name'],
        type: CampaignType.values.firstWhere((e) => e.name == map['type']),
        targetAudience: (map['targetAudience'] as List).map((e) => e.toString()).toList(),
        status: CampaignStatus.values.firstWhere((e) => e.name == map['status']),
        sentCount: (map['sentCount'] ?? 0) as int,
      );

  factory CampaignModel.fromDoc(DocumentSnapshot doc) =>
      CampaignModel.fromMap({...doc.data() as Map<String, dynamic>, 'campaignId': doc.id});
}


