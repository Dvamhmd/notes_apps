// ignore_for_file: experimental_member_use
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Smart QuillController that preserves formatting across lines and spaces.
///
/// Prevents text format (e.g. bold, italic, underline, color, size) from
/// unintentionally reverting to the previous line's or previous word's format
/// when characters are deleted back to a newline or space boundary and retyped.
class SmartQuillController extends QuillController {
  SmartQuillController({
    required super.document,
    required super.selection,
    super.readOnly = false,
  });

  factory SmartQuillController.basic() {
    return SmartQuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  final Map<String, Attribute> _lastActiveInlineMap = <String, Attribute>{};

  @override
  void formatSelection(Attribute? attribute, {bool shouldNotifyListeners = true}) {
    super.formatSelection(attribute, shouldNotifyListeners: shouldNotifyListeners);
    if (attribute != null && attribute.scope == AttributeScope.inline) {
      if (attribute.value == null) {
        _lastActiveInlineMap.remove(attribute.key);
      } else {
        _lastActiveInlineMap[attribute.key] = attribute;
      }
    }
  }

  @override
  void replaceText(
    int index,
    int len,
    Object? data,
    TextSelection? textSelection, {
    bool ignoreFocus = false,
    bool shouldNotifyListeners = true,
  }) {
    Map<String, Attribute>? deletedInlineMap;
    bool isDeletionAtBoundary = false;

    if (len > 0) {
      // Capture the inline style of the text being deleted
      try {
        final collected = document.collectStyle(index, len);
        final inlineMap = <String, Attribute>{};
        for (final entry in collected.attributes.entries) {
          if (entry.value.scope == AttributeScope.inline) {
            inlineMap[entry.key] = entry.value;
          }
        }
        deletedInlineMap = inlineMap;
      } catch (_) {}

      final plain = document.toPlainText();
      if (index > 0 && index - 1 < plain.length) {
        final prevChar = plain[index - 1];
        if (prevChar == '\n' || prevChar == ' ' || prevChar == '\t' || prevChar == '\r') {
          isDeletionAtBoundary = true;
        }
      }
    }

    super.replaceText(
      index,
      len,
      data,
      textSelection,
      ignoreFocus: ignoreFocus,
      shouldNotifyListeners: shouldNotifyListeners,
    );

    // If text was inserted, update _lastActiveInlineMap from current selection style
    if (data is String && data.isNotEmpty) {
      final currentStyle = getSelectionStyle();
      final inlineMap = <String, Attribute>{};
      for (final entry in currentStyle.attributes.entries) {
        if (entry.value.scope == AttributeScope.inline) {
          inlineMap[entry.key] = entry.value;
        }
      }
      _lastActiveInlineMap
        ..clear()
        ..addAll(inlineMap);
    }

    // If a deletion occurred at a newline or space boundary, restore the style of the deleted text
    if (len > 0 && (data is! String || data.isEmpty) && isDeletionAtBoundary && deletedInlineMap != null) {
      final targetMap = deletedInlineMap;
      final baseStyle = document.collectStyle(index, 0);

      // Compute attributes that need to be toggled to match targetMap
      // 1. Attributes in baseStyle that are NOT in targetMap -> set to null
      for (final entry in baseStyle.attributes.entries) {
        if (entry.value.scope == AttributeScope.inline) {
          if (!targetMap.containsKey(entry.key)) {
            toggledStyle = toggledStyle.put(Attribute.clone(entry.value, null));
          } else if (targetMap[entry.key]!.value != entry.value.value) {
            toggledStyle = toggledStyle.put(targetMap[entry.key]!);
          }
        }
      }
      // 2. Attributes in targetMap that are NOT in baseStyle -> set to targetMap value
      for (final entry in targetMap.entries) {
        if (entry.value.scope == AttributeScope.inline) {
          if (!baseStyle.attributes.containsKey(entry.key)) {
            toggledStyle = toggledStyle.put(entry.value);
          }
        }
      }

      if (shouldNotifyListeners) {
        notifyListeners();
      }
    }
  }
}
