import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/folder_model.dart';
import 'package:notes_app/models/note_model.dart';
import 'package:notes_app/models/sort_option.dart';
import 'package:notes_app/screens/home_screen.dart';
import 'package:notes_app/services/storage_service.dart';
import 'package:notes_app/utils/folder_utils.dart';
import 'package:notes_app/widgets/sort_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FolderUtils Sorting Tests', () {
    final now = DateTime.now();
    final folderA = FolderModel(
      id: 'f1',
      name: 'Alpha Folder',
      colorValue: 0xFF4F46E5,
      createdAt: now.subtract(const Duration(days: 3)),
      lastAccessedAt: now.subtract(const Duration(hours: 5)),
      accessCount: 10,
    );
    final folderB = FolderModel(
      id: 'f2',
      name: 'Zeta Folder',
      colorValue: 0xFF10B981,
      createdAt: now.subtract(const Duration(days: 1)),
      lastAccessedAt: now.subtract(const Duration(minutes: 10)),
      accessCount: 2,
    );
    final folderC = FolderModel(
      id: 'f3',
      name: 'Beta Folder',
      colorValue: 0xFFF59E0B,
      createdAt: now.subtract(const Duration(days: 2)),
      lastAccessedAt: now.subtract(const Duration(hours: 1)),
      accessCount: 25,
      isPinned: true, // Pinned should always be top
    );

    test('sortFolders by SortOption.title sorts alphabetically with pinned on top', () {
      final sorted = FolderUtils.sortFolders(
        [folderA, folderB, folderC],
        sortOption: SortOption.title,
      );

      // folderC is pinned -> index 0
      expect(sorted[0].id, folderC.id);
      // Alpha comes before Zeta
      expect(sorted[1].id, folderA.id);
      expect(sorted[2].id, folderB.id);
    });

    test('sortFolders by SortOption.lastAccessed sorts by most recent activity with pinned on top', () {
      final sorted = FolderUtils.sortFolders(
        [folderA, folderB, folderC],
        sortOption: SortOption.lastAccessed,
      );

      // folderC is pinned -> index 0
      expect(sorted[0].id, folderC.id);
      // folderB (10 mins ago) is more recent than folderA (5 hours ago)
      expect(sorted[1].id, folderB.id);
      expect(sorted[2].id, folderA.id);
    });

    test('sortFolders by SortOption.mostAccessed sorts by access count with pinned on top', () {
      final sorted = FolderUtils.sortFolders(
        [folderA, folderB, folderC],
        sortOption: SortOption.mostAccessed,
      );

      // folderC is pinned (25 accesses) -> index 0
      expect(sorted[0].id, folderC.id);
      // folderA (10 accesses) > folderB (2 accesses)
      expect(sorted[1].id, folderA.id);
      expect(sorted[2].id, folderB.id);
    });
  });

  group('NoteModel accessCount & lastAccessedAt serialization', () {
    test('NoteModel serializes and deserializes access tracking fields', () {
      final now = DateTime.now();
      final note = NoteModel(
        id: 'n1',
        title: 'Catatan Rapat',
        contentJson: '[{"insert":"Halo\\n"}]',
        plainText: 'Halo',
        createdAt: now,
        updatedAt: now,
        accessCount: 15,
        lastAccessedAt: now,
      );

      final map = note.toMap();
      expect(map['accessCount'], 15);
      expect(map['lastAccessedAt'], isNotNull);

      final fromMap = NoteModel.fromMap(map);
      expect(fromMap.accessCount, 15);
      expect(fromMap.lastAccessedAt, isNotNull);
    });
  });

  group('SortBottomSheet widget test', () {
    testWidgets('renders all 3 sorting options and triggers selection callback', (WidgetTester tester) async {
      SortOption? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SortBottomSheet.show(
                    context,
                    currentSortOption: SortOption.lastAccessed,
                    onSelect: (opt) {
                      selected = opt;
                    },
                  );
                },
                child: const Text('Open Sort Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the sort bottom sheet
      await tester.tap(find.text('Open Sort Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Urutkan File & Folder'), findsOneWidget);
      expect(find.text('Berdasarkan Judul'), findsOneWidget);
      expect(find.text('Terakhir Diakses / Diedit'), findsOneWidget);
      expect(find.text('Paling Sering Dibuka'), findsOneWidget);

      // Tap 'Paling Sering Dibuka'
      await tester.tap(find.text('Paling Sering Dibuka'));
      await tester.pumpAndSettle();

      expect(selected, SortOption.mostAccessed);
    });
  });

  group('HomeScreen Sort UI Integration test', () {
    testWidgets('HomeScreen displays sort button and opens SortBottomSheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Sort button in search bar
      final sortButton = find.byTooltip(
        'Urutkan: ${SortOption.lastAccessed.label}',
      );
      expect(sortButton, findsOneWidget);

      // Tap sort button to open sheet
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      expect(find.text('Urutkan File & Folder'), findsOneWidget);
      expect(find.text('Berdasarkan Judul'), findsOneWidget);
      expect(find.text('Paling Sering Dibuka'), findsOneWidget);

      // Select 'Berdasarkan Judul'
      await tester.tap(find.text('Berdasarkan Judul'));
      await tester.pumpAndSettle();

      // Sheet is closed
      expect(find.text('Urutkan File & Folder'), findsNothing);
    });

    testWidgets('mostAccessed sort option keeps higher accessed folder on top even after another folder is newly accessed', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'is_app_initialized_v2': true,
      });
      final storage = StorageService();
      final now = DateTime.now();
      final folderA = FolderModel(
        id: 'f_a',
        name: 'Folder A',
        colorValue: 0xFF4F46E5,
        accessCount: 10,
        createdAt: now.subtract(const Duration(days: 2)),
        lastAccessedAt: now.subtract(const Duration(hours: 1)),
      );
      final folderB = FolderModel(
        id: 'f_b',
        name: 'Folder B',
        colorValue: 0xFF10B981,
        accessCount: 1,
        createdAt: now.subtract(const Duration(days: 1)),
        lastAccessedAt: now, // accessed just now
      );

      await storage.saveFolders([folderA, folderB]);
      await storage.saveSortOption(SortOption.mostAccessed);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Folder A (10 accesses) must appear before Folder B (1 access)
      final textA = find.text('Folder A');
      final textB = find.text('Folder B');
      expect(textA, findsOneWidget);
      expect(textB, findsOneWidget);

      final posA = tester.getTopLeft(textA);
      final posB = tester.getTopLeft(textB);
      // In column/grid layout, Folder A is rendered first
      expect(posA.dy <= posB.dy, isTrue);
    });
  });
}
