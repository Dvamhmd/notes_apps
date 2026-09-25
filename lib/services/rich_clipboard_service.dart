import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Service that preserves rich text formatting (bold, italic, underline, color,
/// headings, lists, highlights, etc.) when copying and pasting notes.
class RichClipboardService {
  static Delta? _cachedRichDelta;
  static String? _cachedPlainText;

  /// Returns the current cached rich delta if available
  static Delta? get cachedRichDelta => _cachedRichDelta;

  /// Returns the current cached plain text
  static String? get cachedPlainText => _cachedPlainText;

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

    _cachedRichDelta = deltaSlice;
    _cachedPlainText = plainText;

    // Also update system clipboard with clean plain text
    await Clipboard.setData(ClipboardData(text: plainText));
  }

  /// Cuts the currently selected text and copies its rich text attributes.
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

  /// Pastes clipboard content. If rich formatting is available for the copied text,
  /// it inserts the text preserving all rich formatting. Otherwise, it pastes plain text.
  static Future<bool> paste(QuillController controller) async {
    String? clipText;
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      clipText = clipboardData?.text;
    } catch (_) {}

    final textToPaste = clipText ?? _cachedPlainText;
    if (textToPaste == null || textToPaste.isEmpty) return false;

    final selection = controller.selection;
    final docLength = controller.document.length;
    final start = selection.start.clamp(0, docLength > 0 ? docLength - 1 : 0);
    final end = selection.end.clamp(0, docLength > 0 ? docLength - 1 : 0);
    final length = selection.isCollapsed ? 0 : (end - start);

    // If the system clipboard matches our cached plain text, use the rich formatted Delta!
    if (_cachedRichDelta != null && (clipText == null || _cachedPlainText == clipText)) {
      insertDeltaAt(controller, start, length, _cachedRichDelta!);
      return true;
    }

    // Otherwise, paste plain text
    controller.replaceText(
      start,
      length,
      textToPaste,
      TextSelection.collapsed(offset: start + textToPaste.length),
    );
    return true;
  }

  /// Inserts a rich Delta at the specified offset, replacing [replaceLength] characters.
  static void insertDeltaAt(
    QuillController controller,
    int start,
    int replaceLength,
    Delta richDelta,
  ) {
    int totalInsertedLength = 0;
    for (final op in richDelta.toList()) {
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
    for (final op in richDelta.toList()) {
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
