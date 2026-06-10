import 'dart:convert';

class PredictionHistory {
  final String id;
  final String? userId;
  final String imageUrl;
  final String plantType;
  final String disease;
  final double confidence;
  final String severity;
  final DateTime createdAt;
  final String status;

  PredictionHistory({
    required this.id,
    this.userId,
    required this.imageUrl,
    required this.plantType,
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'plant_type': plantType,
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory PredictionHistory.fromMap(Map<String, dynamic> map) {
    return PredictionHistory(
      id: map['id'] ?? '',
      userId: map['user_id'],
      imageUrl: map['image_url'] ?? '',
      plantType: map['plant_type'] ?? '',
      disease: map['disease'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      severity: map['severity'] ?? '',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      status: map['status'] ?? '',
    );
  }


  String toJson() => json.encode(toMap());

  factory PredictionHistory.fromJson(String source) => 
      PredictionHistory.fromMap(json.decode(source));
}
