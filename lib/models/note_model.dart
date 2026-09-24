import 'dart:convert';

class NoteModel {
  final String id;
  String title;
  String contentJson;
  String plainText;
  String? folderId;
  DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;
  double? lineSpacing;

  NoteModel({
    required this.id,
    required this.title,
    required this.contentJson,
    required this.plainText,
    this.folderId,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.lineSpacing,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'contentJson': contentJson,
      'plainText': plainText,
      'folderId': folderId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'lineSpacing': lineSpacing,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      contentJson: map['contentJson'] ?? r'[{"insert":"\n"}]',
      plainText: map['plainText'] ?? '',
      folderId: map['folderId'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      isPinned: map['isPinned'] ?? false,
      lineSpacing: (map['lineSpacing'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory NoteModel.fromJson(String source) =>
      NoteModel.fromMap(json.decode(source));

  static const Object _sentinel = Object();

  NoteModel copyWith({
    String? id,
    String? title,
    String? contentJson,
    String? plainText,
    Object? folderId = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    Object? lineSpacing = _sentinel,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      contentJson: contentJson ?? this.contentJson,
      plainText: plainText ?? this.plainText,
      folderId: identical(folderId, _sentinel)
          ? this.folderId
          : folderId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      lineSpacing: identical(lineSpacing, _sentinel)
          ? this.lineSpacing
          : lineSpacing as double?,
    );
  }
}
