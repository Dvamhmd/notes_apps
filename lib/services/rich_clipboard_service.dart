import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'html_delta_converter.dart';

/// Service that preserves rich text formatting (bold, italic, underline, strike, color,
/// background highlight, font size, headings, lists, alignment, links, line height, dividers)
/// when copying and pasting notes across all Android versions, keyboards, and other apps.
class RichClipboardService {
  static const MethodChannel _channel = MethodChannel('com.example.notes_app/clipboard');

  static Delta? _cachedRichDelta;
  static String? _cachedPlainText;
  static QuillController? activeController;

  /// Returns the current cached rich delta if available
  static Delta? get cachedRichDelta => _cachedRichDelta;

  /// Returns the current cached plain text
  static String? get cachedPlainText => _cachedPlainText;

  /// Returns true if rich clipboard data is currently held in cache
  static bool get hasData => _cachedRichDelta != null && _cachedPlainText != null;

  /// Set rich clipboard data directly
  static void setRichData(Delta delta, String plainText) {
    _cachedRichDelta = delta;
    _cachedPlainText = plainText;
  }

  /// Clears the internal rich clipboard cache
  static void clearCache() {
    _cachedRichDelta = null;
    _cachedPlainText = null;
  }

  /// Copies the currently selected text along with all its rich text attributes.
  /// Writes both rich HTML and plain text to the Android System Clipboard.
  static Future<void> copySelection(QuillController controller) async {
    final selection = controller.selection;
    if (selection.isCollapsed) return;

    final docLength = controller.document.length;
    final start = selection.start.clamp(0, docLength > 0 ? docLength - 1 : 0);
    final end = selection.end.clamp(0, docLength > 0 ? docLength - 1 : 0);
    final length = end - start;
    if (length <= 0) return;

    final deltaSlice = controller.document.toDelta().slice(start, end);
    final plainText = controller.document.getPlainText(start, length);
    final htmlText = HtmlDeltaConverter.deltaToHtml(deltaSlice);

    _cachedRichDelta = deltaSlice;
    _cachedPlainText = plainText;

    // 1. Write rich HTML and plain text to Android Native Clipboard
    bool nativeSuccess = false;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod('setClipboardData', {
          'plainText': plainText,
          'htmlText': htmlText,
        });
        nativeSuccess = true;
      } catch (_) {}
    }

    // 2. Fallback / supplementary write to standard Flutter Clipboard
    if (!nativeSuccess) {
      try {
        await Clipboard.setData(ClipboardData(text: plainText));
      } catch (_) {}
    }
  }

  /// Cuts the currently selected text and copies its rich text attributes to clipboard.
  static Future<void> cutSelection(QuillController controller) async {
    await copySelection(controller);
    final selection = controller.selection;
    if (selection.isCollapsed) return;

    final docLength = controller.document.length;
    final start = selection.start.clamp(0, docLength > 0 ? docLength - 1 : 0);
    final end = selection.end.clamp(0, docLength > 0 ? docLength - 1 : 0);
    final length = end - start;
    if (length <= 0) return;

    controller.replaceText(
      start,
      length,
      '',
      TextSelection.collapsed(offset: start),
    );
  }

  /// Pastes clipboard content. If rich formatting is available (either from native Android
  /// HTML clipboard, Gboard, external apps, or internal cache), it converts and inserts
  /// preserving all rich formatting (size, color, align, bold, list, header, etc.).
  static Future<bool> paste(QuillController controller) async {
    String? nativePlainText;
    String? nativeHtmlText;
    bool hasNativeHtml = false;

    // 1. Check Native Android rich clipboard
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final res = await _channel.invokeMethod<Map>('getClipboardData');
        if (res != null) {
          nativePlainText = res['plainText']?.toString();
          nativeHtmlText = res['htmlText']?.toString();
          hasNativeHtml = res['hasHtml'] == true && nativeHtmlText != null && nativeHtmlText.trim().isNotEmpty;
        }
      } catch (_) {}
    }

    // 2. Fallback to standard Flutter Clipboard if native plain text is absent
    if (nativePlainText == null || nativePlainText.isEmpty) {
      try {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        nativePlainText = clipboardData?.text;
      } catch (_) {}
    }

    final selection = controller.selection;
    final docLength = controller.document.length;
    final start = selection.start.clamp(0, docLength > 0 ? docLength - 1 : 0);
    final end = selection.end.clamp(0, docLength > 0 ? docLength - 1 : 0);
    final length = selection.isCollapsed ? 0 : (end - start);

    // Normalize strings for matching
    final normClip = nativePlainText?.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    final normCached = _cachedPlainText?.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

    final isMatchingCachedDelta = _cachedRichDelta != null &&
        (nativePlainText == null ||
         _cachedPlainText == nativePlainText ||
         (normClip != null && normCached != null && normClip == normCached));

    // A. Priority 1: Use cached rich Delta if copied within this app session
    if (isMatchingCachedDelta && _cachedRichDelta != null) {
      insertDeltaAt(controller, start, length, _cachedRichDelta!);
      return true;
    }

    // B. Priority 2: Use Native HTML clipboard data if available (from Chrome, Docs, Word, Gboard, etc.)
    if (hasNativeHtml && nativeHtmlText != null && nativeHtmlText.trim().isNotEmpty) {
      final richDelta = HtmlDeltaConverter.htmlToDelta(nativeHtmlText);
      if (richDelta.isNotEmpty) {
        insertDeltaAt(controller, start, length, richDelta);
        return true;
      }
    }

    // C. Priority 3: Check if plain text is raw JSON Delta or contains HTML tags
    if (nativePlainText != null && nativePlainText.isNotEmpty) {
      final trimmedText = nativePlainText.trim();

      // Check if it's JSON Delta array: e.g. [{"insert":"..."}]
      if (trimmedText.startsWith('[') && trimmedText.endsWith(']')) {
        try {
          final decoded = json.decode(trimmedText);
          if (decoded is List) {
            final deltaFromJson = Delta.fromJson(decoded);
            insertDeltaAt(controller, start, length, deltaFromJson);
            return true;
          }
        } catch (_) {}
      }

      // Check if text is raw HTML string: e.g. <p><b>...</b></p>
      if (trimmedText.startsWith('<') && trimmedText.contains('>') &&
          (trimmedText.contains('<p') ||
           trimmedText.contains('<span') ||
           trimmedText.contains('<h') ||
           trimmedText.contains('<b') ||
           trimmedText.contains('<i') ||
           trimmedText.contains('<u') ||
           trimmedText.contains('<div') ||
           trimmedText.contains('<ul') ||
           trimmedText.contains('<ol'))) {
        final richDelta = HtmlDeltaConverter.htmlToDelta(trimmedText);
        if (richDelta.isNotEmpty) {
          insertDeltaAt(controller, start, length, richDelta);
          return true;
        }
      }

      // Standard plain text paste
      controller.replaceText(
        start,
        length,
        nativePlainText,
        TextSelection.collapsed(offset: start + nativePlainText.length),
      );
      return true;
    }

    return false;
  }

  /// Inserts a rich Delta at the specified offset, replacing [replaceLength] characters,
  /// perfectly preserving all inline (size, color, styles) and block (align, headers, lists) attributes.
  static void insertDeltaAt(
    QuillController controller,
    int start,
    int replaceLength,
    Delta richDelta,
  ) {
    if (richDelta.isEmpty) return;

    // Clean trailing single newline from delta if inserting inline without replacing a whole line
    final ops = richDelta.toList();
    final cleanOps = <Operation>[];

    for (int i = 0; i < ops.length; i++) {
      final op = ops[i];
      if (i == ops.length - 1 && op.data is String) {
        final str = op.data as String;
        // If it's a single trailing newline with no block attributes, strip it to prevent unwanted empty paragraph
        if (str == '\n' && (op.attributes == null || op.attributes!.isEmpty)) {
          continue;
        } else if (str.endsWith('\n') && (op.attributes == null || op.attributes!.isEmpty) && ops.length == 1) {
          cleanOps.add(Operation.insert(str.substring(0, str.length - 1), op.attributes));
          continue;
        }
      }
      cleanOps.add(op);
    }

    int totalInsertedLength = 0;
    for (final op in cleanOps) {
      if (op.data is String) {
        totalInsertedLength += (op.data as String).length;
      } else {
        totalInsertedLength += 1;
      }
    }

    final changeDelta = Delta();
    if (start > 0) {
      changeDelta.retain(start);
    }
    if (replaceLength > 0) {
      changeDelta.delete(replaceLength);
    }
    for (final op in cleanOps) {
      changeDelta.push(op);
    }

    final newSelection = TextSelection.collapsed(offset: start + totalInsertedLength);
    controller.compose(
      changeDelta,
      newSelection,
      ChangeSource.local,
    );
  }
}
