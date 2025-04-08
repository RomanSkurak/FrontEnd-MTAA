class FlashcardSet {
  final int setId;
  final int userId;
  final String name;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardSet({
    required this.setId,
    required this.userId,
    required this.name,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    return FlashcardSet(
      setId: json['set_id'],
      userId: json['user_id'],
      name: json['name'],
      isPublic: json['is_public_fyn'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Flashcard {
  final int flashcardId;
  final int setId;
  final String name;
  final String front;
  final String back;
  final String dataType;

  Flashcard({
    required this.flashcardId,
    required this.setId,
    required this.name,
    required this.front,
    required this.back,
    required this.dataType,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      flashcardId: json['flashcard_id'],
      setId: json['set_id'],
      name: json['name'],
      front: json['front_side'],
      back: json['back_side'],
      dataType: json['data_type'],
    );
  }
}