import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/widgets/divider_embed_builder.dart';
import 'package:notes_app/widgets/divider_sheet.dart';

void insertDividerHelper(QuillController controller, String embedData) {
  final index = controller.selection.baseOffset < 0 ? 0 : controller.selection.baseOffset;
  final length = (controller.selection.extentOffset - index).clamp(0, controller.document.length);
  final plainText = controller.document.toPlainText();

  int insertPos = index;
  if (insertPos > 0 && insertPos <= plainText.length && plainText[insertPos - 1] != '\n') {
    controller.replaceText(insertPos, 0, '\n', TextSelection.collapsed(offset: insertPos + 1));
    insertPos += 1;
  }

  controller.replaceText(
    insertPos,
    length,
    BlockEmbed('divider', embedData),
    TextSelection.collapsed(offset: insertPos + 1),
  );

  final updatedPlain = controller.document.toPlainText();
  if (insertPos + 1 >= updatedPlain.length || updatedPlain[insertPos + 1] != '\n') {
    controller.replaceText(insertPos + 1, 0, '\n', TextSelection.collapsed(offset: insertPos + 2));
    controller.updateSelection(TextSelection.collapsed(offset: insertPos + 2), ChangeSource.local);
  } else {
    controller.updateSelection(TextSelection.collapsed(offset: insertPos + 2), ChangeSource.local);
  }
}

void main() {
  testWidgets('Test inserting divider at various positions and styles', (WidgetTester tester) async {
    final doc = Document()..insert(0, 'First Line\nSecond Line\n');
    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 10),
    );

    final dividerData = json.encode({
      'color': '#4F46E5',
      'thickness': 2.5,
      'style': 'dashed',
    });

    insertDividerHelper(controller, dividerData);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuillEditor.basic(
            controller: controller,
            config: QuillEditorConfig(
              embedBuilders: [DividerEmbedBuilder()],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final delta = controller.document.toDelta();
    expect(delta.toJson().any((op) => op['insert'] is Map && op['insert']['divider'] != null), isTrue);
  });

  testWidgets('Test DividerSheet opens and selects colors', (WidgetTester tester) async {
    String? insertedData;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                DividerSheet.show(
                  context: context,
                  onInsert: (data) {
                    insertedData = data;
                  },
                );
              },
              child: const Text('Buka Garis Sheet'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buka Garis Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Sisipkan Garis Pembatas'), findsNWidgets(2));
    expect(find.text('Pratinjau Garis (Live Preview)'), findsOneWidget);
    expect(find.text('Pilihan Warna'), findsOneWidget);
    expect(find.text('Ketebalan Garis'), findsOneWidget);
    expect(find.text('Gaya Garis'), findsOneWidget);

    final insertBtn = find.widgetWithText(ElevatedButton, 'Sisipkan Garis Pembatas');
    await tester.scrollUntilVisible(
      insertBtn,
      50,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(insertBtn);
    await tester.pumpAndSettle();

    expect(insertedData, isNotNull);
    final decoded = json.decode(insertedData!);
    expect(decoded['color'], isNotNull);
    expect(decoded['thickness'], isNotNull);
    expect(decoded['style'], isNotNull);
  });

  testWidgets('Test selective line-height on specific paragraph', (WidgetTester tester) async {
    final doc = Document()
      ..insert(0, 'Paragraph One\nParagraph Two\nParagraph Three\n');

    final controller = QuillController(
      document: doc,
      selection: const TextSelection(baseOffset: 15, extentOffset: 25), // In Paragraph Two
    );

    controller.formatSelection(Attribute.clone(Attribute.lineHeight, 2.4));

    final delta = controller.document.toDelta();
    final ops = delta.toList();

    // Line 1 should not have line-height
    expect(ops.first.attributes?['line-height'], isNull);
    // Line 2 newline should have line-height 2.4
    expect(ops.any((op) => op.attributes != null && op.attributes!['line-height'] == 2.4), isTrue);
  });
}
