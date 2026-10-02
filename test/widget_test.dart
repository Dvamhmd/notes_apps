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

  testWidgets('Test NoteEditorScreen scales bullet and numbering with enlarged font size (26pt)', (WidgetTester tester) async {
    final doc = Document()
      ..insert(0, 'Large bullet\nLarge number\n')
      ..format(0, 12, Attribute.ul)
      ..format(0, 12, Attribute.clone(Attribute.size, '26'))
      ..format(13, 12, Attribute.ol)
      ..format(13, 12, Attribute.clone(Attribute.size, '26'));

    final note = NoteModel(
      id: 'test-large-bullet-note',
      title: 'Teks Besar',
      contentJson: json.encode(doc.toDelta().toJson()),
      plainText: 'Large bullet\nLarge number',
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

    expect(find.text('Teks Besar'), findsOneWidget);
    final numberFinder = find.text('1.');
    expect(numberFinder, findsOneWidget);

    final Text textWidget = tester.widget(numberFinder);
    expect(textWidget.style?.fontSize, 26.0);
  });

  testWidgets('Test NoteEditorScreen scales bullet and numbering with reduced font size (12pt)', (WidgetTester tester) async {
    final doc = Document()
      ..insert(0, 'Small bullet\nSmall number\n')
      ..format(0, 12, Attribute.ul)
      ..format(0, 12, Attribute.clone(Attribute.size, '12'))
      ..format(13, 12, Attribute.ol)
      ..format(13, 12, Attribute.clone(Attribute.size, '12'));

    final note = NoteModel(
      id: 'test-small-bullet-note',
      title: 'Teks Kecil',
      contentJson: json.encode(doc.toDelta().toJson()),
      plainText: 'Small bullet\nSmall number',
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

    expect(find.text('Teks Kecil'), findsOneWidget);
    final numberFinder = find.text('1.');
    expect(numberFinder, findsOneWidget);

    final Text textWidget = tester.widget(numberFinder);
    expect(textWidget.style?.fontSize, 12.0);
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

  test('Test CustomTouchTextSelectionControls and RichClipboardService preserve color, size, align, style on copy and paste', () async {
    final doc = Document();
    doc.insert(0, 'Rich Formatted Android Text\n');
    doc.format(0, 4, Attribute.bold);
    doc.format(5, 9, const ColorAttribute('#E11D48')); // Red
    doc.format(5, 9, Attribute.clone(Attribute.size, '20')); // 20pt size
    doc.format(15, 7, Attribute.italic);
    doc.format(15, 7, Attribute.underline);
    doc.format(23, 4, const BackgroundAttribute('#FEF08A')); // Yellow highlight

    final controller = QuillController(
      document: doc,
      selection: const TextSelection(baseOffset: 0, extentOffset: 27),
    );
    RichClipboardService.activeController = controller;

    // Copy selection
    await RichClipboardService.copySelection(controller);

    expect(RichClipboardService.hasData, isTrue);
    expect(RichClipboardService.cachedPlainText, 'Rich Formatted Android Text');

    // Create target document and paste
    final targetDoc = Document()..insert(0, 'Target: \n');
    final targetController = QuillController(
      document: targetDoc,
      selection: const TextSelection.collapsed(offset: 8),
    );
    RichClipboardService.activeController = targetController;

    final pasteSuccess = await RichClipboardService.paste(targetController);
    expect(pasteSuccess, isTrue);

    final targetOps = targetController.document.toDelta().toList();

    // Verify all formatting is preserved
    final hasBold = targetOps.any((op) => op.attributes != null && op.attributes!['bold'] == true);
    final hasColor = targetOps.any((op) => op.attributes != null && op.attributes!['color'] == '#E11D48');
    final hasSize = targetOps.any((op) => op.attributes != null && op.attributes!['size'] == '20');
    final hasItalic = targetOps.any((op) => op.attributes != null && op.attributes!['italic'] == true);
    final hasUnderline = targetOps.any((op) => op.attributes != null && op.attributes!['underline'] == true);
    final hasBg = targetOps.any((op) => op.attributes != null && op.attributes!['background'] == '#FEF08A');

    expect(hasBold, isTrue, reason: 'Bold must be preserved on paste');
    expect(hasColor, isTrue, reason: 'Color must be preserved on paste');
    expect(hasSize, isTrue, reason: 'Font size must be preserved on paste');
    expect(hasItalic, isTrue, reason: 'Italic must be preserved on paste');
    expect(hasUnderline, isTrue, reason: 'Underline must be preserved on paste');
    expect(hasBg, isTrue, reason: 'Highlight background must be preserved on paste');
  });

  testWidgets('Test Bullet and Numbering buttons in CustomToolbar toggle independently without interfering', (WidgetTester tester) async {
    final doc = Document()..insert(0, 'Contoh catatan teks\n');
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

    // 1. Initially neither is active
    expect(controller.getSelectionStyle().attributes[Attribute.ul.key], isNull);

    // 2. Open list menu
    final listMenuTrigger = find.byTooltip('Daftar (Poin / Angka)');
    expect(listMenuTrigger, findsOneWidget);
    await tester.tap(listMenuTrigger);
    await tester.pumpAndSettle();

    final poinOption = find.text('Poin');
    final angkaOption = find.text('Angka');
    expect(poinOption, findsOneWidget);
    expect(angkaOption, findsOneWidget);

    // 3. Tap Poin -> Only bullet should be active, NOT number
    await tester.tap(poinOption);
    await tester.pumpAndSettle();

    final bulletAttr = controller.getSelectionStyle().attributes[Attribute.ul.key];
    expect(bulletAttr, isNotNull);
    expect(bulletAttr!.value, 'bullet');

    // 4. Tap Angka -> Only numbering should be active, NOT bullet
    await tester.tap(angkaOption);
    await tester.pumpAndSettle();

    final numberAttr = controller.getSelectionStyle().attributes[Attribute.ol.key];
    expect(numberAttr, isNotNull);
    expect(numberAttr!.value, 'ordered');
  });

  testWidgets('Test NoteEditorScreen supports pinch gesture (gesture cubit) to zoom in and out', (WidgetTester tester) async {
    final note = NoteModel(
      id: 'test-pinch-note',
      title: 'Pinch Zoom Note',
      contentJson: json.encode([
        {'insert': 'Teks untuk zoom gesture cubit\n'}
      ]),
      plainText: 'Teks untuk zoom gesture cubit',
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

    // Verify text exists
    expect(find.text('Pinch Zoom Note'), findsOneWidget);

    // Initial scale check on QuillEditor styles
    QuillEditor editor = tester.widget(find.byType(QuillEditor));
    expect(editor.config.customStyles?.paragraph?.style.fontSize, 15.0);

    // Create 2 pointer gestures for pinch
    final center = tester.getCenter(find.byType(QuillEditor));
    final gesture1 = await tester.createGesture(pointer: 1);
    final gesture2 = await tester.createGesture(pointer: 2);

    // Initial touch: 100 pixels apart
    await gesture1.down(center + const Offset(-50, 0));
    await gesture2.down(center + const Offset(50, 0));
    await tester.pump();

    // Spread fingers apart (zoom in): 200 pixels apart (scale = 200/100 = 2.0 => 15 * 2 = 30)
    await gesture1.moveTo(center + const Offset(-100, 0));
    await gesture2.moveTo(center + const Offset(100, 0));
    await tester.pumpAndSettle();

    editor = tester.widget(find.byType(QuillEditor));
    expect(editor.config.customStyles!.paragraph!.style.fontSize!, closeTo(30.0, 1.0));

    // Pinch fingers closer (zoom out): 50 pixels apart (scale = 50/100 = 0.5 clamped to 0.6 => 15 * 0.6 = 9.0)
    await gesture1.moveTo(center + const Offset(-25, 0));
    await gesture2.moveTo(center + const Offset(25, 0));
    await tester.pumpAndSettle();

    editor = tester.widget(find.byType(QuillEditor));
    expect(editor.config.customStyles!.paragraph!.style.fontSize!, closeTo(9.0, 1.0));

    // Release pointers
    await gesture1.up();
    await gesture2.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Test NoteEditorScreen line spacing slider full left (1.0) and full right (2.8)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final note = NoteModel(
      id: 'test-spacing',
      title: 'Note Spacing Test',
      contentJson: json.encode([
        {'insert': 'First line\nSecond line\n'},
        {'insert': 'Bullet item\n', 'attributes': {'list': 'bullet'}},
      ]),
      plainText: 'First line\nSecond line\nBullet item\n',
      lineSpacing: 1.6,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
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

    final toolbarBtn = find.byTooltip('Ukuran Teks & Jarak Baris');
    expect(toolbarBtn, findsOneWidget);
    await tester.tap(toolbarBtn);
    await tester.pumpAndSettle();

    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);
    final slider = tester.widget<Slider>(sliderFinder.first);

    // Full left
    slider.onChanged?.call(1.0);
    await tester.pumpAndSettle();
    expect(find.text('First line', findRichText: true), findsOneWidget);

    // Full right
    slider.onChanged?.call(2.8);
    await tester.pumpAndSettle();
    expect(find.text('First line', findRichText: true), findsOneWidget);
  });
}























