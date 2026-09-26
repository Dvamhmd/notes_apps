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

  testWidgets('Test CustomTouchTextSelectionControls returns correct size and anchor for collapsed handle', (WidgetTester tester) async {
    final controls = CustomTouchTextSelectionControls.instance;
    final size = controls.getHandleSize(20.0);
    expect(size.width, 28.0);
    expect(size.height, 30.0);

    final anchor = controls.getHandleAnchor(TextSelectionHandleType.collapsed, 20.0);
    expect(anchor.dx, 14.0);
    expect(anchor.dy, 0.0);
  });

  testWidgets('Test NoteEditorScreen initializes with teardrop cursor handle overlay', (WidgetTester tester) async {
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
    await tester.pumpAndSettle();

    expect(find.byType(QuillCursorHandleOverlay), findsOneWidget);
    expect(find.byType(QuillEditor), findsOneWidget);
  });
}
