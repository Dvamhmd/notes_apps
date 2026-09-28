import 'package:flutter/material.dart';

/// Opsi pengurutan (sorting) untuk file catatan dan folder
enum SortOption {
  manual(
    id: 'manual',
    label: 'Nonaktif (Urutan Manual)',
    subtitle: 'Atur susunan bebas & geser di Kelola Folder',
    icon: Icons.drag_indicator_rounded,
  ),
  lastAccessed(
    id: 'last_accessed',
    label: 'Terakhir Diakses / Diedit',
    subtitle: 'Aktivitas terbaru di urutan teratas',
    icon: Icons.access_time_filled_rounded,
  ),
  title(
    id: 'title',
    label: 'Berdasarkan Judul',
    subtitle: 'Nama / Judul alfabetis (A - Z)',
    icon: Icons.sort_by_alpha_rounded,
  ),
  mostAccessed(
    id: 'most_accessed',
    label: 'Paling Sering Dibuka',
    subtitle: 'Frekuensi terbanyak dibuka',
    icon: Icons.local_fire_department_rounded,
  );

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;

  const SortOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  bool get isActive => this != SortOption.manual;

  static SortOption fromId(String? id) {
    switch (id) {
      case 'manual':
        return SortOption.manual;
      case 'title':
        return SortOption.title;
      case 'most_accessed':
        return SortOption.mostAccessed;
      case 'last_accessed':
      default:
        return SortOption.lastAccessed;
    }
  }
}

