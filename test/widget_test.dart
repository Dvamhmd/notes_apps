import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notes_app/main.dart';
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
          textTheme: GoogleFonts.plusJakartaSansTextTheme(),
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
}











