import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/main.dart';
import 'package:notes_app/models/note_model.dart';
import 'package:notes_app/services/rich_clipboard_service.dart';
import 'package:notes_app/widgets/note_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Notes App smoke test - loads HomeScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Catatan Baru'), findsOneWidget);
  });

  testWidgets('Test QuillEditor underline text style rendering', (WidgetTester tester) async {
    final doc = Document()..insert(0, 'Test Underline Text\n');
    doc.format(0, 19, Attribute.underline);
    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          fontFamily: 'Poppins',
        ),
        home: Scaffold(
          body: QuillEditor.basic(
            controller: controller,
            config: QuillEditorConfig(
              customStyleBuilder: (Attribute attribute) {
                if (attribute.key == Attribute.underline.key) {
                  return const TextStyle(
                    decoration: TextDecoration.underline,
                    decorationThickness: 1.3,
                    decorationStyle: TextDecorationStyle.solid,
                  );
                }
                return const TextStyle();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final richTextFinder = find.byType(RichText);
    expect(richTextFinder, findsWidgets);
  });

  testWidgets('Test NoteCard renders selection checkbox badge when isSelectionMode is true', (WidgetTester tester) async {
    final note = NoteModel(
      id: 'test-1',
      title: 'Catatan Tes',
      contentJson: r'[{"insert":"Isi catatan tes\n"}]',
      plainText: 'Isi catatan tes',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteCard(
            note: note,
            isSelectionMode: true,
            isSelected: true,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catatan Tes'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('Catatan Tes'));
    expect(tapped, isTrue);
  });

  test('Test RichClipboardService copies and pastes formatting intact', () async {
    final doc = Document();
    doc.insert(0, 'Hello Bold and Colored Text\n');
    doc.format(0, 10, Attribute.bold);
    doc.format(6, 4, const ColorAttribute('#FF0000'));

    final controller = QuillController(
      document: doc,
      selection: const TextSelection(baseOffset: 0, extentOffset: 10),
    );

    // Copy selected text
    await RichClipboardService.copySelection(controller);

    expect(RichClipboardService.cachedPlainText, 'Hello Bold');
    expect(RichClipboardService.cachedRichDelta, isNotNull);

    // Create a target controller and paste
    final targetDoc = Document()..insert(0, 'Start: \n');
    final targetController = QuillController(
      document: targetDoc,
      selection: const TextSelection.collapsed(offset: 7),
    );

    final pasteSuccess = await RichClipboardService.paste(targetController);
    expect(pasteSuccess, isTrue);

    final resultDelta = targetController.document.toDelta();
    final ops = resultDelta.toList();

    // Verify bold and color formatting were preserved in pasted text
    expect(ops.any((op) => op.attributes != null && op.attributes!['bold'] == true), isTrue);
    expect(ops.any((op) => op.attributes != null && op.attributes!['color'] == '#FF0000'), isTrue);
    expect(targetController.document.toPlainText(), contains('Start: Hello Bold'));
  });

  testWidgets('Test search filter bottom sheet from search field icon', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    // Tap the filter icon button in the search field to open filter sheet
    final filterIcon = find.byIcon(Icons.tune_rounded);
    expect(filterIcon, findsOneWidget);
    await tester.tap(filterIcon);
    await tester.pumpAndSettle();

    // Verify filter sheet elements
    expect(find.text('Filter Pencarian'), findsOneWidget);
    expect(find.text('Cakupan Pencarian'), findsOneWidget);
    expect(find.text('Jenis Item yang Dicari'), findsOneWidget);
    expect(find.text('Cari Berdasarkan'), findsOneWidget);

    final applyBtnFinder = find.text('Terapkan Filter');
    await tester.scrollUntilVisible(
      applyBtnFinder,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(applyBtnFinder);
    await tester.pumpAndSettle();
  });
}














