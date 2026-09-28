import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notes_app/services/link_service.dart';
import 'package:notes_app/services/smart_quill_controller.dart';

void main() {
  group('LinkService & URL Detection Tests', () {
    test('isValidUrl detects URLs correctly', () {
      expect(LinkService.isValidUrl('https://flutter.dev'), isTrue);
      expect(LinkService.isValidUrl('http://example.com/test'), isTrue);
      expect(LinkService.isValidUrl('www.google.com'), isTrue);
      expect(LinkService.isValidUrl('github.com/Dvamhmd/notes_apps'), isTrue);
      expect(LinkService.isValidUrl('Bukan sebuah url'), isFalse);
    });

    test('normalizeUrl handles protocol and trailing punctuation', () {
      expect(LinkService.normalizeUrl('google.com'), 'https://google.com');
      expect(LinkService.normalizeUrl('www.youtube.com'), 'https://www.youtube.com');
      expect(LinkService.normalizeUrl('https://flutter.dev.'), 'https://flutter.dev');
      expect(LinkService.normalizeUrl('http://test.com/path,'), 'http://test.com/path');
    });

    test('extractDomain extracts domain name cleanly', () {
      expect(LinkService.extractDomain('https://www.google.com/search'), 'google.com');
      expect(LinkService.extractDomain('https://github.com/user/repo'), 'github.com');
    });

    test('autoFormatLinks formats Quill document correctly', () {
      final text = 'Kunjungi tautan ini: https://flutter.dev dan www.google.com ya.';
      final doc = Document();
      doc.insert(0, text);
      LinkService.autoFormatLinks(doc);

      final flutterIdx = text.indexOf('https://flutter.dev');
      final styleFlutter = doc.collectStyle(flutterIdx, 'https://flutter.dev'.length);
      expect(
        styleFlutter.attributes[Attribute.link.key]?.value,
        'https://flutter.dev',
      );

      final googleIdx = text.indexOf('www.google.com');
      final styleGoogle = doc.collectStyle(googleIdx, 'www.google.com'.length);
      expect(
        styleGoogle.attributes[Attribute.link.key]?.value,
        'https://www.google.com',
      );
    });

    test('SmartQuillController formats links automatically on text replacement', () {
      final controller = SmartQuillController.basic();
      controller.replaceText(0, 0, 'Link: https://flutter.dev selesai', null);

      final style = controller.document.collectStyle(6, 19);
      expect(
        style.attributes[Attribute.link.key]?.value,
        'https://flutter.dev',
      );
    });
  });
}
