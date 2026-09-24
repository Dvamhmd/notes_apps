import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import '../utils/folder_utils.dart';

class StorageService {
  static const String _notesKey = 'user_notes_data_v1';
  static const String _foldersKey = 'user_folders_data_v1';
  static const String _initialSetupKey = 'is_app_initialized_v2'; // Bump version for nested folders demo

  final _uuid = const Uuid();

  Future<void> initializeDefaultsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool(_initialSetupKey) ?? false;
    if (!isInitialized) {
      final pekerjaanId = _uuid.v4();
      final shiftPagiId = _uuid.v4();
      final laporanPenjualanId = _uuid.v4();

      final defaultFolders = [
        FolderModel(
          id: pekerjaanId,
          name: 'Pekerjaan',
          colorValue: 0xFF3B82F6, // Blue
          createdAt: DateTime.now(),
        ),
        FolderModel(
          id: shiftPagiId,
          name: 'Shift Pagi',
          colorValue: 0xFF06B6D4, // Cyan
          createdAt: DateTime.now(),
          parentId: pekerjaanId,
        ),
        FolderModel(
          id: laporanPenjualanId,
          name: 'Laporan Penjualan',
          colorValue: 0xFF10B981, // Emerald
          createdAt: DateTime.now(),
          parentId: shiftPagiId,
        ),
        FolderModel(
          id: _uuid.v4(),
          name: 'Pribadi',
          colorValue: 0xFF8B5CF6, // Purple
          createdAt: DateTime.now(),
        ),
        FolderModel(
          id: _uuid.v4(),
          name: 'Ide & Rencana',
          colorValue: 0xFFF59E0B, // Amber
          createdAt: DateTime.now(),
        ),
      ];

      await saveFolders(defaultFolders);

      final welcomeNote = NoteModel(
        id: _uuid.v4(),
        title: 'Laporan Harian Shift Pagi',
        contentJson: json.encode([
          {
            'insert': 'Laporan Penjualan Shift Pagi ✨\n\n',
            'attributes': {'bold': true, 'size': '20'}
          },
          {
            'insert': 'Catatan ini tersimpan di dalam hirarki folder:\n',
          },
          {
            'insert': 'Pekerjaan > Shift Pagi > Laporan Penjualan\n\n',
            'attributes': {'bold': true, 'color': '#10B981'}
          },
          {
            'insert': 'Kini Anda dapat membuat folder di dalam folder (subfolder) tanpa batas kedalaman dan bernavigasi menggunakan breadcrumb hirarki di bagian atas layar!\n'
          }
        ]),
        plainText: 'Laporan Penjualan Shift Pagi. Catatan ini tersimpan di dalam hirarki folder Pekerjaan > Shift Pagi > Laporan Penjualan...',
        folderId: laporanPenjualanId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPinned: true,
      );

      final generalNote = NoteModel(
        id: _uuid.v4(),
        title: 'Selamat Datang di Notes!',
        contentJson: json.encode([
          {
            'insert': 'Selamat Datang di Aplikasi Notes ✨\n\n',
            'attributes': {'bold': true, 'size': '20'}
          },
          {
            'insert': 'Fitur Navigasi Hirarki:\n',
            'attributes': {'bold': true, 'underline': true}
          },
          {
            'insert': '• Buat folder di dalam folder (subfolder).\n• Navigasi mudah dengan jejak breadcrumb.\n• Pindahkan catatan antar level folder.\n• Kelola folder lewat menu titik 3 di pojok kanan atas.\n'
          }
        ]),
        plainText: 'Selamat Datang di Aplikasi Notes! Navigasi hirarki folder dan subfolder kini didukung.',
        folderId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPinned: true,
      );

      final existingNotes = await getNotes();
      if (existingNotes.isEmpty) {
        await saveNotes([welcomeNote, generalNote]);
      }
      await prefs.setBool(_initialSetupKey, true);
    }
  }

  // --- Notes Operations ---
  Future<List<NoteModel>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesJson = prefs.getString(_notesKey);
    if (notesJson == null || notesJson.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(notesJson);
      return decoded.map((item) => NoteModel.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveNotes(List<NoteModel> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> rawList =
        notes.map((n) => n.toMap()).toList();
    await prefs.setString(_notesKey, json.encode(rawList));
  }

  Future<void> saveOrUpdateNote(NoteModel note) async {
    final notes = await getNotes();
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      notes[index] = note;
    } else {
      notes.insert(0, note);
    }
    await saveNotes(notes);
  }

  Future<void> deleteNote(String noteId) async {
    final notes = await getNotes();
    notes.removeWhere((n) => n.id == noteId);
    await saveNotes(notes);
  }

  // --- Folders Operations ---
  Future<List<FolderModel>> getFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? foldersJson = prefs.getString(_foldersKey);
    if (foldersJson == null || foldersJson.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(foldersJson);
      return decoded.map((item) => FolderModel.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveFolders(List<FolderModel> folders) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> rawList =
        folders.map((f) => f.toMap()).toList();
    await prefs.setString(_foldersKey, json.encode(rawList));
  }

  Future<void> addFolder(FolderModel folder) async {
    final folders = await getFolders();
    folders.add(folder);
    await saveFolders(folders);
  }

  Future<void> updateFolder(FolderModel folder) async {
    final folders = await getFolders();
    final index = folders.indexWhere((f) => f.id == folder.id);
    if (index >= 0) {
      folders[index] = folder;
      await saveFolders(folders);
    }
  }

  Future<void> deleteFolder(String folderId, {bool deleteNotes = false}) async {
    final folders = await getFolders();
    final allToDelete = {
      folderId,
      ...FolderUtils.getDescendantFolderIds(folderId, folders)
    };

    folders.removeWhere((f) => allToDelete.contains(f.id));
    await saveFolders(folders);

    final notes = await getNotes();
    if (deleteNotes) {
      notes.removeWhere(
        (n) => n.folderId != null && allToDelete.contains(n.folderId),
      );
      await saveNotes(notes);
    } else {
      // Unassign deleted folders from any notes so they move to Root (Tanpa Folder)
      bool changed = false;
      for (var i = 0; i < notes.length; i++) {
        if (notes[i].folderId != null && allToDelete.contains(notes[i].folderId)) {
          notes[i] = notes[i].copyWith(folderId: null);
          changed = true;
        }
      }
      if (changed) {
        await saveNotes(notes);
      }
    }
  }

  Future<void> moveNote(String noteId, String? targetFolderId) async {
    final notes = await getNotes();
    final index = notes.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      notes[index] = notes[index].copyWith(folderId: targetFolderId);
      await saveNotes(notes);
    }
  }

  static const String _lineSpacingKey = 'pref_line_spacing_v1';

  Future<double> getLineSpacing() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_lineSpacingKey) ?? 1.55;
  }

  Future<void> saveLineSpacing(double spacing) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lineSpacingKey, spacing);
  }
}
