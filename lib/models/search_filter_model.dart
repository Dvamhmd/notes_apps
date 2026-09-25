import 'package:flutter/material.dart';

/// Target field filter for search
enum SearchTarget {
  all(
    label: 'Judul & Isi Teks',
    shortLabel: 'Judul & Teks',
    description: 'Cari di judul catatan dan isi teks di dalamnya',
    icon: Icons.text_snippet_outlined,
  ),
  titleOnly(
    label: 'Hanya Judul',
    shortLabel: 'Judul Saja',
    description: 'Hanya mencari berdasarkan judul catatan & nama folder',
    icon: Icons.title_rounded,
  ),
  contentOnly(
    label: 'Hanya Isi / Teks Catatan',
    shortLabel: 'Teks Saja',
    description: 'Hanya mencari di dalam isi / teks catatan',
    icon: Icons.notes_rounded,
  );

  final String label;
  final String shortLabel;
  final String description;
  final IconData icon;

  const SearchTarget({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
  });
}

/// Item type filter for search (Note, Folder, or All)
enum SearchItemType {
  all(
    label: 'Semua Jenis',
    shortLabel: 'Semua Jenis',
    description: 'Tampilkan hasil catatan dan folder',
    icon: Icons.auto_awesome_mosaic_rounded,
  ),
  notes(
    label: 'Hanya Catatan',
    shortLabel: 'Catatan',
    description: 'Hanya tampilkan file / catatan',
    icon: Icons.note_alt_outlined,
  ),
  folders(
    label: 'Hanya Folder',
    shortLabel: 'Folder',
    description: 'Hanya tampilkan folder',
    icon: Icons.folder_outlined,
  );

  final String label;
  final String shortLabel;
  final String description;
  final IconData icon;

  const SearchItemType({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
  });
}

/// Scope filter for search (Global or Current Folder / Parent folder)
enum SearchScope {
  global(
    label: 'Semua Menyeluruh',
    shortLabel: 'Menyeluruh',
    description: 'Mencari di seluruh folder dan subfolder',
    icon: Icons.public_rounded,
  ),
  currentFolder(
    label: 'Folder Induk / Ini Saja',
    shortLabel: 'Folder Ini',
    description: 'Hanya mencari di folder saat ini / folder induk',
    icon: Icons.folder_open_rounded,
  );

  final String label;
  final String shortLabel;
  final String description;
  final IconData icon;

  const SearchScope({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
  });
}

class SearchFilterConfig {
  final SearchTarget target;
  final SearchItemType itemType;
  final SearchScope scope;

  const SearchFilterConfig({
    this.target = SearchTarget.all,
    this.itemType = SearchItemType.all,
    this.scope = SearchScope.global,
  });

  bool get isDefault =>
      target == SearchTarget.all &&
      itemType == SearchItemType.all &&
      scope == SearchScope.global;

  int get activeFiltersCount {
    int count = 0;
    if (target != SearchTarget.all) count++;
    if (itemType != SearchItemType.all) count++;
    if (scope != SearchScope.global) count++;
    return count;
  }

  SearchFilterConfig copyWith({
    SearchTarget? target,
    SearchItemType? itemType,
    SearchScope? scope,
  }) {
    return SearchFilterConfig(
      target: target ?? this.target,
      itemType: itemType ?? this.itemType,
      scope: scope ?? this.scope,
    );
  }
}
