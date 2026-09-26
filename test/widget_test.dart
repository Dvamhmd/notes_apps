import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/main.dart';
import 'package:notes_app/models/note_model.dart';
import 'package:notes_app/screens/note_editor_screen.dart';
import 'package:notes_app/services/rich_clipboard_service.dart';
import 'package:notes_app/services/smart_quill_controller.dart';
import 'package:notes_app/widgets/custom_toolbar.dart';
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

  testWidgets('Test NoteEditorScreen renders bullet and numbering with correct alignment', (WidgetTester tester) async {
    final doc = Document()
      ..insert(0, 'Bullet item\nNumber item\n')
      ..format(0, 11, Attribute.ul)
      ..format(12, 11, Attribute.ol);

    final note = NoteModel(
      id: 'test-bullet-note',
      title: 'Daftar Tugas',
      contentJson: json.encode(doc.toDelta().toJson()),
      plainText: 'Bullet item\nNumber item',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lineSpacing: 1.6,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Poppins'),
        home: NoteEditorScreen(
          note: note,
          folders: const [],
          onSave: (_) {},
          onDelete: (_) {},
          onFolderCreated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Editor loaded
    expect(find.text('Daftar Tugas'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);

    // Verify bullet and numbering widgets are present and laid out
    final numberFinder = find.text('1.');
    final numberRect = tester.getRect(numberFinder);
    expect(numberRect.height, greaterThan(0));
    expect(numberRect.width, greaterThan(0));
  });
  test('Test SmartQuillController maintains inline format changes on newline and space after text deletion', () {
    final doc = Document();
    final controller = SmartQuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // 1. Line 1: Type "Hello" with bold
    controller.formatSelection(Attribute.bold);
    controller.replaceText(0, 0, 'Hello', const TextSelection.collapsed(offset: 5));
    expect(controller.getSelectionStyle().containsKey(Attribute.bold.key), isTrue);

    // 2. Press Enter to Line 2
    controller.replaceText(5, 0, '\n', const TextSelection.collapsed(offset: 6));

    // 3. Turn off bold on Line 2
    controller.formatSelection(Attribute.clone(Attribute.bold, null));
    expect(controller.getSelectionStyle().containsKey(Attribute.bold.key), isFalse);

    // 4. Type "world" on Line 2
    controller.replaceText(6, 0, 'world', const TextSelection.collapsed(offset: 11));
    expect(controller.getSelectionStyle().containsKey(Attribute.bold.key), isFalse);

    // 5. Delete all text "world" on Line 2 (back to offset 6, start of line 2)
    controller.replaceText(6, 5, '', const TextSelection.collapsed(offset: 6));
    expect(controller.getSelectionStyle().containsKey(Attribute.bold.key), isFalse,
        reason: 'Line 2 should retain unbolded style after deleting all text on line 2');

    // 6. Retype "again" on Line 2 -> verify it remains unbolded
    controller.replaceText(6, 0, 'again', const TextSelection.collapsed(offset: 11));
    final againOp = controller.document.toDelta().toList().firstWhere(
        (op) => op.data is String && (op.data as String).contains('again'));
    expect(againOp.attributes == null || againOp.attributes!['bold'] != true, isTrue);

    // 7. Same line space test:
    var curOffset = controller.document.length - 1;
    controller.updateSelection(TextSelection.collapsed(offset: curOffset), ChangeSource.local);

    // Turn bold ON and type word with space
    controller.formatSelection(Attribute.bold);
    controller.replaceText(curOffset, 0, ' boldword ', TextSelection.collapsed(offset: curOffset + 10));

    // After space, turn bold OFF and type word
    curOffset = controller.document.length - 1;
    controller.formatSelection(Attribute.clone(Attribute.bold, null));
    controller.replaceText(curOffset, 0, 'normalword', TextSelection.collapsed(offset: curOffset + 10));

    // Delete "normalword" back to space
    curOffset = controller.document.length - 1;
    controller.replaceText(curOffset - 10, 10, '', TextSelection.collapsed(offset: curOffset - 10));
    expect(controller.getSelectionStyle().containsKey(Attribute.bold.key), isFalse,
        reason: 'Should retain unbolded style after space even when deleting back to space');

    // Retype "retypednormal" after space -> verify it remains unbolded
    curOffset = controller.document.length - 1;
    controller.replaceText(curOffset, 0, 'retypednormal', TextSelection.collapsed(offset: curOffset + 13));
    final retypedOp = controller.document.toDelta().toList().firstWhere(
        (op) => op.data is String && (op.data as String).contains('retypednormal'));
    expect(retypedOp.attributes == null || retypedOp.attributes!['bold'] != true, isTrue);

    // 8. Test character-by-character deletion back to newline boundary
    curOffset = controller.document.length - 1;
    controller.updateSelection(TextSelection.collapsed(offset: curOffset), ChangeSource.local);
    controller.replaceText(curOffset, 0, '\n', TextSelection.collapsed(offset: curOffset + 1));
    
    // Line 3: Bold text
    curOffset = controller.document.length - 1;
    controller.formatSelection(Attribute.bold);
    controller.replaceText(curOffset, 0, 'Line 3 Bold', TextSelection.collapsed(offset: curOffset + 11));
    curOffset = controller.document.length - 1;
    controller.replaceText(curOffset, 0, '\n', TextSelection.collapsed(offset: curOffset + 1));

    // Line 4: Turn bold off
    curOffset = controller.document.length - 1;
    controller.formatSelection(Attribute.clone(Attribute.bold, null));
    controller.replaceText(curOffset, 0, 'abc', TextSelection.collapsed(offset: curOffset + 3));

    // Backspace character by character
    curOffset = controller.document.length - 1;
    controller.replaceText(curOffset - 1, 1, '', TextSelection.collapsed(offset: curOffset - 1));
    curOffset = controller.document.length - 1;
    controller.replaceText(curOffset - 1, 1, '', TextSelection.collapsed(offset: curOffset - 1));
    curOffset = controller.document.length - 1;
    controller.replaceText(curOffset - 1, 1, '', TextSelection.collapsed(offset: curOffset - 1));

    expect(controller.getSelectionStyle().containsKey(Attribute.bold.key), isFalse,
        reason: 'Line 4 should still be unbolded after character-by-character deletion back to newline');
    
    // Retype "xyz" on line 4
    curOffset = controller.document.length - 1;
    controller.replaceText(curOffset, 0, 'xyz', TextSelection.collapsed(offset: curOffset + 3));
    final xyzOp = controller.document.toDelta().toList().firstWhere(
        (op) => op.data is String && (op.data as String).contains('xyz'));
    expect(xyzOp.attributes == null || xyzOp.attributes!['bold'] != true, isTrue);
  });

  test('Test SmartQuillController preserves color and italic changes across line and space deletions', () {
    final doc = Document();
    final controller = SmartQuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Line 1: Italic text
    controller.formatSelection(Attribute.italic);
    controller.replaceText(0, 0, 'Italic Line', const TextSelection.collapsed(offset: 11));
    controller.replaceText(11, 0, '\n', const TextSelection.collapsed(offset: 12));

    // Line 2: Turn off italic, set Color Blue
    controller.formatSelection(Attribute.clone(Attribute.italic, null));
    controller.formatSelection(const ColorAttribute('#0000FF'));
    controller.replaceText(12, 0, 'Blue Text', const TextSelection.collapsed(offset: 21));

    // Delete "Blue Text" on Line 2
    controller.replaceText(12, 9, '', const TextSelection.collapsed(offset: 12));

    // Selection style should not have italic, but should have blue color
    expect(controller.getSelectionStyle().containsKey(Attribute.italic.key), isFalse);
    expect(controller.getSelectionStyle().containsKey(Attribute.color.key), isTrue);

    // Retype text on Line 2
    controller.replaceText(12, 0, 'Retyped Blue', const TextSelection.collapsed(offset: 24));
    final blueOp = controller.document.toDelta().toList().firstWhere(
        (op) => op.data is String && (op.data as String).contains('Retyped Blue'));
    expect(blueOp.attributes?['italic'], isNull);
    expect(blueOp.attributes?['color'], '#0000FF');
  });

  testWidgets('Test NoteEditorScreen inserts and renders customizable horizontal divider line', (WidgetTester tester) async {
    NoteModel? savedNote;
    final note = NoteModel(
      id: 'test-divider-note',
      title: 'Catatan Garis',
      contentJson: json.encode([
        {'insert': 'Paragraf Pertama\n'}
      ]),
      plainText: 'Paragraf Pertama',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lineSpacing: 1.6,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Poppins'),
        home: NoteEditorScreen(
          note: note,
          folders: const [],
          onSave: (updated) {
            savedNote = updated;
          },
          onDelete: (_) {},
          onFolderCreated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Editor screen loaded
    expect(find.text('Catatan Garis'), findsOneWidget);

    // Find the divider button in CustomToolbar
    final dividerIconFinder = find.byIcon(Icons.horizontal_rule_rounded);
    expect(dividerIconFinder, findsOneWidget);

    // Tap divider toolbar button
    await tester.tap(dividerIconFinder);
    await tester.pumpAndSettle();

    // Verify DividerSheet is displayed
    expect(find.text('Sisipkan Garis Pembatas'), findsWidgets);
    expect(find.text('Pilihan Warna'), findsOneWidget);
    expect(find.text('Ketebalan Garis'), findsOneWidget);
    expect(find.text('Gaya Garis'), findsOneWidget);

    // Select color 'Merah' or 'Teal'
    final tealFinder = find.byTooltip('Teal');
    if (tealFinder.evaluate().isNotEmpty) {
      await tester.tap(tealFinder);
      await tester.pumpAndSettle();
    }

    // Tap insert button
    final insertBtn = find.widgetWithText(ElevatedButton, 'Sisipkan Garis Pembatas');
    await tester.scrollUntilVisible(
      insertBtn,
      50,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(insertBtn);
    await tester.pumpAndSettle();

    // Pop editor screen to trigger immediate save
    final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Verify saved note contains the divider embed
    expect(savedNote, isNotNull);
    expect(savedNote!.contentJson, contains('divider'));
  });

  testWidgets('Test combined Undo/Redo button in CustomToolbar opens history floating options', (WidgetTester tester) async {
    final doc = Document()..insert(0, 'Initial Text\n');
    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomToolbar(
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify combined History button exists
    final historyBtn = find.byIcon(Icons.history_rounded);
    expect(historyBtn, findsOneWidget);

    // Tap History button
    await tester.tap(historyBtn);
    await tester.pumpAndSettle();

    // Verify floating bar with Undo and Redo options appeared
    expect(find.text('Batal (Undo)'), findsOneWidget);
    expect(find.text('Ulangi (Redo)'), findsOneWidget);

    // Tap close button in floating bar
    final closeBtn = find.byIcon(Icons.close_rounded);
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    // Floating bar is closed
    expect(find.text('Batal (Undo)'), findsNothing);
  });
}






















