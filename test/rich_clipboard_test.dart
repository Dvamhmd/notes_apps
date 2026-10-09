import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:notes_app/services/html_delta_converter.dart';
import 'package:notes_app/services/rich_clipboard_service.dart';
import 'package:notes_app/services/smart_quill_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HtmlDeltaConverter Tests', () {
    test('Converts inline styles (bold, italic, underline, strike, code)', () {
      const html = '<p><b>Bold</b> <i>Italic</i> <u>Underline</u> <s>Strike</s> <code>Code</code></p>';
      final delta = HtmlDeltaConverter.htmlToDelta(html);

      final ops = delta.toList();
      expect(ops.any((op) => op.data == 'Bold' && op.attributes?['bold'] == true), isTrue);
      expect(ops.any((op) => op.data == 'Italic' && op.attributes?['italic'] == true), isTrue);
      expect(ops.any((op) => op.data == 'Underline' && op.attributes?['underline'] == true), isTrue);
      expect(ops.any((op) => op.data == 'Strike' && op.attributes?['strike'] == true), isTrue);
      expect(ops.any((op) => op.data == 'Code' && op.attributes?['code'] == true), isTrue);
    });

    test('Converts text colors and background highlights', () {
      const html = '<p><span style="color:#EF4444;background-color:#FEF08A;">Red on Yellow</span></p>';
      final delta = HtmlDeltaConverter.htmlToDelta(html);

      final ops = delta.toList();
      final op = ops.firstWhere((o) => o.data == 'Red on Yellow');
      expect(op.attributes?['color'], equals('#EF4444'));
      expect(op.attributes?['background'], equals('#FEF08A'));
    });

    test('Converts font sizes (keywords and numeric)', () {
      const html = '<p><span style="font-size:24px;">Big 24px</span> <span style="font-size:small;">Small Text</span></p>';
      final delta = HtmlDeltaConverter.htmlToDelta(html);

      final ops = delta.toList();
      final op1 = ops.firstWhere((o) => o.data == 'Big 24px');
      expect(op1.attributes?['size'], equals('24'));

      final op2 = ops.firstWhere((o) => o.data == 'Small Text');
      expect(op2.attributes?['size'], equals('small'));
    });

    test('Converts alignment (center, right, justify)', () {
      const html = '<p style="text-align:center;">Centered Paragraph</p>';
      final delta = HtmlDeltaConverter.htmlToDelta(html);

      final ops = delta.toList();
      expect(ops.any((op) => op.data == 'Centered Paragraph'), isTrue);
      expect(ops.any((op) => op.data == '\n' && op.attributes?['align'] == 'center'), isTrue);
    });

    test('Converts headers (h1, h2, h3)', () {
      const html = '<h1>Main Title</h1><h2>Subtitle</h2>';
      final delta = HtmlDeltaConverter.htmlToDelta(html);

      final ops = delta.toList();
      expect(ops.any((op) => op.data == 'Main Title'), isTrue);
      expect(ops.any((op) => op.data == '\n' && op.attributes?['header'] == 1), isTrue);
      expect(ops.any((op) => op.data == 'Subtitle'), isTrue);
      expect(ops.any((op) => op.data == '\n' && op.attributes?['header'] == 2), isTrue);
    });

    test('Converts lists (bullet and numbered)', () {
      const html = '<ul><li>Item 1</li><li>Item 2</li></ul><ol><li>Step 1</li></ol>';
      final delta = HtmlDeltaConverter.htmlToDelta(html);

      final ops = delta.toList();
      expect(ops.any((op) => op.data == 'Item 1'), isTrue);
      expect(ops.any((op) => op.data == '\n' && op.attributes?['list'] == 'bullet'), isTrue);
      expect(ops.any((op) => op.data == 'Step 1'), isTrue);
      expect(ops.any((op) => op.data == '\n' && op.attributes?['list'] == 'ordered'), isTrue);
    });

    test('Converts links and dividers', () {
      const html = '<p><a href="https://example.com">Example Link</a></p><hr/>';
      final delta = HtmlDeltaConverter.htmlToDelta(html);

      final ops = delta.toList();
      final linkOp = ops.firstWhere((o) => o.data == 'Example Link');
      expect(linkOp.attributes?['link'], equals('https://example.com'));

      expect(ops.any((op) => op.data is Map && (op.data as Map).containsKey('divider')), isTrue);
    });

    test('Converts Delta to HTML bidirectionally', () {
      final initialDelta = Delta()
        ..insert('Hello ', {'bold': true, 'color': '#3B82F6', 'size': '20'})
        ..insert('World', {'italic': true, 'background': '#FEF08A'})
        ..insert('\n', {'align': 'center'});

      final html = HtmlDeltaConverter.deltaToHtml(initialDelta);
      expect(html.contains('style='), isTrue);
      expect(html.contains('text-align:center'), isTrue);
      expect(html.contains('color:#3B82F6'), isTrue);
      expect(html.contains('font-size:20px'), isTrue);
      expect(html.contains('background-color:#FEF08A'), isTrue);
      expect(html.contains('<b>'), isTrue);
      expect(html.contains('<i>'), isTrue);

      final reParsedDelta = HtmlDeltaConverter.htmlToDelta(html);
      final ops = reParsedDelta.toList();
      final helloOp = ops.firstWhere((o) => o.data == 'Hello ');
      expect(helloOp.attributes?['bold'], isTrue);
      expect(helloOp.attributes?['color'], equals('#3B82F6'));
      expect(helloOp.attributes?['size'], equals('20'));

      final worldOp = ops.firstWhere((o) => o.data == 'World');
      expect(worldOp.attributes?['italic'], isTrue);
      expect(worldOp.attributes?['background'], equals('#FEF08A'));
    });
  });

  group('RichClipboardService Tests', () {
    test('copySelection and paste preserves delta formatting', () async {
      final doc = Document()
        ..insert(0, 'Rich Formatted Note')
        ..format(0, 4, Attribute.bold)
        ..format(5, 9, const ColorAttribute('#EF4444'));

      final controller = SmartQuillController(
        document: doc,
        selection: const TextSelection(baseOffset: 0, extentOffset: 14),
      );

      await RichClipboardService.copySelection(controller);
      expect(RichClipboardService.hasData, isTrue);
      expect(RichClipboardService.cachedPlainText, equals('Rich Formatted'));

      // Create target editor
      final targetDoc = Document();
      final targetController = SmartQuillController(
        document: targetDoc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      final pasted = await RichClipboardService.paste(targetController);
      expect(pasted, isTrue);

      final targetDelta = targetController.document.toDelta();
      final ops = targetDelta.toList();

      expect(ops.any((o) => o.data == 'Rich' && o.attributes?['bold'] == true), isTrue);
      expect(ops.any((o) => o.data == 'Formatted' && o.attributes?['color'] == '#EF4444'), isTrue);
    });

    test('paste raw HTML string converts to rich Delta', () async {
      final targetDoc = Document();
      final targetController = SmartQuillController(
        document: targetDoc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      // Clear cache so it falls back to parsing
      RichClipboardService.clearCache();

      const html = '<p><span style="color:#22C55E;font-size:24px;"><b>Green Big Title</b></span></p>';
      final richDelta = HtmlDeltaConverter.htmlToDelta(html);
      RichClipboardService.insertDeltaAt(targetController, 0, 0, richDelta);

      final targetDelta = targetController.document.toDelta();
      final op = targetDelta.toList().firstWhere((o) => o.data == 'Green Big Title');
      expect(op.attributes?['bold'], isTrue);
      expect(op.attributes?['color'], equals('#22C55E'));
      expect(op.attributes?['size'], equals('24'));
    });
  });
}
