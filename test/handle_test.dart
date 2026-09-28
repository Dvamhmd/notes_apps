import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/note_model.dart';
import 'package:notes_app/screens/note_editor_screen.dart';
import 'package:notes_app/widgets/custom_selection_controls.dart';
import 'package:notes_app/widgets/quill_cursor_handle_overlay.dart';

void main() {
  testWidgets('Test QuillCursorHandleOverlay renders teardrop handle and supports drag cursor repositioning', (WidgetTester tester) async {
    final doc = Document()..insert(0, 'Halo selamat datang di catatan kita\n');
    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 5),
    );
    final focusNode = FocusNode();
    final editorKey = GlobalKey<QuillEditorState>();
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: Color(0xFF4F46E5),
          ),
        ),
        home: Scaffold(
          body: QuillCursorHandleOverlay(
            controller: controller,
            focusNode: focusNode,
            editorKey: editorKey,
            scrollController: scrollController,
            child: QuillEditor.basic(
              key: editorKey,
              controller: controller,
              focusNode: focusNode,
              scrollController: scrollController,
              config: const QuillEditorConfig(
                enableInteractiveSelection: true,
                showCursor: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Verify TeardropHandlePainter is present in the widget tree
    expect(
      find.byWidgetPredicate((w) => w is CustomPaint && w.painter is TeardropHandlePainter),
      findsOneWidget,
    );

    // Initial cursor offset is 5
    expect(controller.selection.baseOffset, 5);

    // Find the handle gesture detector and drag it to the right
    final handleFinder = find.byKey(const Key('quill_cursor_teardrop_handle'));
    expect(handleFinder, findsOneWidget);

    // Drag the handle to the right by 80px
    await tester.drag(handleFinder, const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 100));

    // Cursor position should have moved forward
    expect(controller.selection.baseOffset > 5, true);
  });

  testWidgets('Test QuillCursorHandleOverlay dragging on multi-line text', (WidgetTester tester) async {
    final doc = Document()..insert(0, 'Baris pertama yang panjang sekali disini\nBaris kedua ada di bawah baris satu\nBaris ketiga teks paling bawah\n');
    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 45), // In line 2
    );
    final focusNode = FocusNode();
    final editorKey = GlobalKey<QuillEditorState>();
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: Color(0xFF4F46E5),
          ),
        ),
        home: Scaffold(
          body: QuillCursorHandleOverlay(
            controller: controller,
            focusNode: focusNode,
            editorKey: editorKey,
            scrollController: scrollController,
            child: QuillEditor.basic(
              key: editorKey,
              controller: controller,
              focusNode: focusNode,
              scrollController: scrollController,
              config: const QuillEditorConfig(
                enableInteractiveSelection: true,
                showCursor: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final handleFinder = find.byKey(const Key('quill_cursor_teardrop_handle'));
    expect(handleFinder, findsOneWidget);

    // Drag slightly horizontally on line 2
    await tester.drag(handleFinder, const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.selection.baseOffset, 46);
  });

  testWidgets('Test QuillCursorHandleOverlay dragging on deep multi-line text stays on active line without jumping to top', (WidgetTester tester) async {
    final doc = Document()..insert(0, 'Baris ke-0 teks awal yang panjang\nBaris ke-1 teks kedua yang panjang\nBaris ke-2 teks ketiga yang panjang\nBaris ke-3 teks keempat yang panjang\nBaris ke-4 teks kelima yang panjang\n');
    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 110), // On Line 3 (starts around 105)
    );
    final focusNode = FocusNode();
    final editorKey = GlobalKey<QuillEditorState>();
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: Color(0xFF4F46E5),
          ),
        ),
        home: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 80), // AppBar/Toolbar simulation
              Expanded(
                child: QuillCursorHandleOverlay(
                  controller: controller,
                  focusNode: focusNode,
                  editorKey: editorKey,
                  scrollController: scrollController,
                  child: QuillEditor.basic(
                    key: editorKey,
                    controller: controller,
                    focusNode: focusNode,
                    scrollController: scrollController,
                    config: const QuillEditorConfig(
                      enableInteractiveSelection: true,
                      showCursor: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final handleFinder = find.byKey(const Key('quill_cursor_teardrop_handle'));
    expect(handleFinder, findsOneWidget);

    // Initial offset is 110 (Line 3)
    expect(controller.selection.baseOffset, 110);

    // Drag handle right by 40px
    await tester.drag(handleFinder, const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 100));

    // Must advance on Line 3 (offset > 110), NOT jump to Line 0 (< 35)
    expect(controller.selection.baseOffset > 110, true);
    expect(controller.selection.baseOffset < 145, true);
  });

  testWidgets('Test QuillCursorHandleOverlay fades out after 1.5 seconds of idle time', (WidgetTester tester) async {
    final doc = Document()..insert(0, 'Catatan uji timeout teardrop 1.5 detik\n');
    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 8),
    );
    final focusNode = FocusNode();
    final editorKey = GlobalKey<QuillEditorState>();
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: Color(0xFF4F46E5),
          ),
        ),
        home: Scaffold(
          body: QuillCursorHandleOverlay(
            controller: controller,
            focusNode: focusNode,
            editorKey: editorKey,
            scrollController: scrollController,
            child: QuillEditor.basic(
              key: editorKey,
              controller: controller,
              focusNode: focusNode,
              scrollController: scrollController,
              config: const QuillEditorConfig(
                enableInteractiveSelection: true,
                showCursor: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final handleKey = const Key('quill_cursor_teardrop_handle');

    // Handle is visible initially
    expect(find.byKey(handleKey), findsOneWidget);

    // After 1000ms (1s), timer has not fired yet (1.5s timeout)
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.byKey(handleKey), findsOneWidget);

    // After 500ms more (total 1500ms), timer fires and reverse animation completes (180ms)
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 200));

    // Teardrop handle should now be hidden/removed from overlay
    expect(find.byKey(handleKey), findsNothing);
  });

  testWidgets('Test CustomTouchTextSelectionControls returns correct size and anchor for all handle types', (WidgetTester tester) async {
    final controls = CustomTouchTextSelectionControls.instance;
    final size = controls.getHandleSize(20.0);
    expect(size.width, 28.0);
    expect(size.height, 30.0);

    for (final type in [
      TextSelectionHandleType.left,
      TextSelectionHandleType.right,
      TextSelectionHandleType.collapsed,
    ]) {
      final anchor = controls.getHandleAnchor(type, 20.0);
      expect(anchor.dx, 14.0);
      expect(anchor.dy, 0.0);
    }
  });

  testWidgets('Test NoteEditorScreen initializes with custom teardrop text selection controls', (WidgetTester tester) async {
    final note = NoteModel(
      id: 'note-1',
      title: 'Judul Catatan Android',
      contentJson: '[{"insert":"Catatan dengan teardrop kursor.\\n"}]',
      plainText: 'Catatan dengan teardrop kursor.',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          fontFamily: 'Poppins',
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: Color(0xFF4F46E5),
          ),
        ),
        home: NoteEditorScreen(
          note: note,
          folders: const [],
          onSave: (_) {},
          onDelete: (_) {},
          onFolderCreated: (_) {},
        ),
      ),
    );
    expect(find.byType(QuillEditor), findsOneWidget);
  });

  testWidgets('Test bullet list cursor offset and drag positioning', (WidgetTester tester) async {
    final doc = Document.fromJson([
      {"insert": "Fitur Navigasi Hirarki:\n"},
      {"insert": "Buat folder di dalam folder (subfolder)."},
      {"insert": "\n", "attributes": {"list": "bullet"}},
      {"insert": "Navigasi mudah dengan jejak breadcrumb."},
      {"insert": "\n", "attributes": {"list": "bullet"}},
      {"insert": "Pindahkan catatan antar level folder."},
      {"insert": "\n", "attributes": {"list": "bullet"}},
      {"insert": "Kelola folder lewat menu titik 3 di pojok kanan atas."},
      {"insert": "\n", "attributes": {"list": "bullet"}}
    ]);
    final totalLength = doc.length;
    final controller = QuillController(
      document: doc,
      selection: TextSelection.collapsed(offset: totalLength - 1),
    );
    final focusNode = FocusNode();
    final editorKey = GlobalKey<QuillEditorState>();
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: Color(0xFF4F46E5),
          ),
        ),
        home: Scaffold(
          body: QuillCursorHandleOverlay(
            controller: controller,
            focusNode: focusNode,
            editorKey: editorKey,
            scrollController: scrollController,
            child: QuillEditor.basic(
              key: editorKey,
              controller: controller,
              focusNode: focusNode,
              scrollController: scrollController,
              config: const QuillEditorConfig(
                enableInteractiveSelection: true,
                showCursor: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final rawEditorState = editorKey.currentState!.editableTextKey.currentState!;
    final renderEditor = rawEditorState.renderEditor;
    // Drag the handle from the end to line 3
    final handleFinder = find.byKey(const Key('quill_cursor_teardrop_handle'));
    expect(handleFinder, findsOneWidget);

    // Initial selection is at the end (offset 196)
    expect(controller.selection.baseOffset, totalLength - 1);

    // Drag handle up and left to reach line 3
    await tester.drag(handleFinder, const Offset(-40, -40));
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.selection.baseOffset < totalLength - 1, true);
    expect(controller.selection.baseOffset >= 105, true);
  });
}


