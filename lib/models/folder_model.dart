import 'dart:convert';

class FolderModel {
  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;
  final String? parentId; // ID of parent folder if this is a subfolder
  final bool isPinned;
  final int accessCount;
  final DateTime? lastAccessedAt;
  final bool isLocked;
  final String? password;

  FolderModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
    this.parentId,
    this.isPinned = false,
    this.accessCount = 0,
    this.lastAccessedAt,
    this.isLocked = false,
    this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
      'isPinned': isPinned,
      'accessCount': accessCount,
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'isLocked': isLocked,
      'password': password,
    };
  }

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    final pass = map['password'] as String?;
    final locked = map['isLocked'] == true || (pass != null && pass.isNotEmpty);
    return FolderModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF4F46E5,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      parentId: map['parentId'],
      isPinned: map['isPinned'] ?? false,
      accessCount: map['accessCount'] ?? 0,
      lastAccessedAt: map['lastAccessedAt'] != null
          ? DateTime.tryParse(map['lastAccessedAt'])
          : null,
      isLocked: locked,
      password: pass,
    );
  }

  String toJson() => json.encode(toMap());

  factory FolderModel.fromJson(String source) =>
      FolderModel.fromMap(json.decode(source));

  FolderModel copyWith({
    String? id,
    String? name,
    int? colorValue,
    DateTime? createdAt,
    String? parentId,
    bool clearParent = false,
    bool? isPinned,
    int? accessCount,
    DateTime? lastAccessedAt,
    bool? isLocked,
    String? password,
    bool clearPassword = false,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      isPinned: isPinned ?? this.isPinned,
      accessCount: accessCount ?? this.accessCount,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isLocked: isLocked ?? this.isLocked,
      password: clearPassword ? null : (password ?? this.password),
    );
  }
}


