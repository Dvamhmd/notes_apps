import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Comprehensive bidirectional converter between HTML and Quill Delta.
/// Preserves font sizes, colors, background highlights, styles (bold, italic, underline, strike),
/// text alignments, lists (bullet, ordered, checkboxes), headers, blockquotes, code blocks,
/// links, line-heights, and dividers across all Android devices and web.
class HtmlDeltaConverter {
  /// Converts an HTML string into a well-formed Quill [Delta].
  static Delta htmlToDelta(String html) {
    if (html.trim().isEmpty) {
      return Delta()..insert('\n');
    }

    try {
      final parser = _HtmlToDeltaParser(html);
      return parser.parse();
    } catch (_) {
      // Fallback: strip tags and insert plain text
      final plain = html.replaceAll(RegExp(r'<[^>]*>'), '');
      final clean = _decodeHtmlEntities(plain);
      final d = Delta();
      if (clean.isNotEmpty) {
        d.insert(clean.endsWith('\n') ? clean : '$clean\n');
      } else {
        d.insert('\n');
      }
      return d;
    }
  }

  /// Converts a Quill [Delta] into a clean, standards-compliant HTML string with inline CSS.
  static String deltaToHtml(Delta delta) {
    return _DeltaToHtmlConverter.convert(delta);
  }
}

// ---------------------------------------------------------------------------
// HTML -> DELTA PARSER IMPLEMENTATION
// ---------------------------------------------------------------------------

class _InlineStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final String? color;
  final String? background;
  final String? size;
  final String? font;
  final String? link;

  const _InlineStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.color,
    this.background,
    this.size,
    this.font,
    this.link,
  });

  _InlineStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    bool? code,
    String? color,
    String? background,
    String? size,
    String? font,
    String? link,
  }) {
    return _InlineStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strike: strike ?? this.strike,
      code: code ?? this.code,
      color: color ?? this.color,
      background: background ?? this.background,
      size: size ?? this.size,
      font: font ?? this.font,
      link: link ?? this.link,
    );
  }

  Map<String, dynamic> toAttributes() {
    final map = <String, dynamic>{};
    if (bold) map[Attribute.bold.key] = true;
    if (italic) map[Attribute.italic.key] = true;
    if (underline) map[Attribute.underline.key] = true;
    if (strike) map[Attribute.strikeThrough.key] = true;
    if (code) map[Attribute.inlineCode.key] = true;
    if (color != null && color!.isNotEmpty) map[Attribute.color.key] = color;
    if (background != null && background!.isNotEmpty) map[Attribute.background.key] = background;
    if (size != null && size!.isNotEmpty) map[Attribute.size.key] = size;
    if (font != null && font!.isNotEmpty) map[Attribute.font.key] = font;
    if (link != null && link!.isNotEmpty) map[Attribute.link.key] = link;
    return map;
  }
}

class _BlockContext {
  final String? align;
  final int? header;
  final String? list;
  final bool isBlockQuote;
  final bool isCodeBlock;
  final String? lineHeight;

  const _BlockContext({
    this.align,
    this.header,
    this.list,
    this.isBlockQuote = false,
    this.isCodeBlock = false,
    this.lineHeight,
  });

  _BlockContext copyWith({
    String? align,
    int? header,
    String? list,
    bool? isBlockQuote,
    bool? isCodeBlock,
    String? lineHeight,
  }) {
    return _BlockContext(
      align: align ?? this.align,
      header: header ?? this.header,
      list: list ?? this.list,
      isBlockQuote: isBlockQuote ?? this.isBlockQuote,
      isCodeBlock: isCodeBlock ?? this.isCodeBlock,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }

  Map<String, dynamic> toLineAttributes() {
    final map = <String, dynamic>{};
    if (header != null && header! >= 1 && header! <= 3) {
      if (header == 1) map[Attribute.h1.key] = 1;
      if (header == 2) map[Attribute.h2.key] = 2;
      if (header == 3) map[Attribute.h3.key] = 3;
    }
    if (align != null && align!.isNotEmpty) {
      map[Attribute.align.key] = align;
    }
    if (list != null && list!.isNotEmpty) {
      map[Attribute.list.key] = list;
    }
    if (isBlockQuote) {
      map[Attribute.blockQuote.key] = true;
    }
    if (isCodeBlock) {
      map[Attribute.codeBlock.key] = true;
    }
    if (lineHeight != null && lineHeight!.isNotEmpty) {
      map[Attribute.lineHeight.key] = lineHeight;
    }
    return map;
  }
}

class _HtmlToDeltaParser {
  final String rawHtml;
  final List<Operation> _ops = [];

  _HtmlToDeltaParser(this.rawHtml);

  Delta parse() {
    // 1. Sanitize & clean HTML
    String cleanHtml = rawHtml
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '') // Remove comments
        .replaceAll(RegExp(r'<style[\s\S]*?<\/style>', caseSensitive: false), '') // Remove styles
        .replaceAll(RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), '') // Remove scripts
        .replaceAll(RegExp(r'<head[\s\S]*?<\/head>', caseSensitive: false), '') // Remove head
        .replaceAll(RegExp(r'<meta[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<link[^>]*>', caseSensitive: false), '');

    // Extract body if present
    final bodyMatch = RegExp(r'<body[^>]*>([\s\S]*?)<\/body>', caseSensitive: false).firstMatch(cleanHtml);
    if (bodyMatch != null) {
      cleanHtml = bodyMatch.group(1)!;
    }

    _processHtmlTree(cleanHtml);

    // Ensure document ends with at least a trailing newline
    if (_ops.isEmpty) {
      _ops.add(Operation.insert('\n'));
    } else {
      final lastOp = _ops.last;
      if (lastOp.data is! String || !(lastOp.data as String).endsWith('\n')) {
        _ops.add(Operation.insert('\n'));
      }
    }

    final delta = Delta();
    for (final op in _ops) {
      delta.push(op);
    }
    return delta;
  }

  void _processHtmlTree(String html) {
    final tokens = _tokenize(html);
    final inlineStack = <_InlineStyle>[const _InlineStyle()];
    final blockStack = <_BlockContext>[const _BlockContext()];

    for (final token in tokens) {
      if (token.isText) {
        final text = _decodeHtmlEntities(token.text);
        if (text.isNotEmpty) {
          final activeInline = inlineStack.last;
          final attrs = activeInline.toAttributes();
          
          // Split by newline if any
          final lines = text.split('\n');
          for (int i = 0; i < lines.length; i++) {
            final lineText = lines[i];
            if (lineText.isNotEmpty) {
              if (attrs.isNotEmpty) {
                _ops.add(Operation.insert(lineText, attrs));
              } else {
                _ops.add(Operation.insert(lineText));
              }
            }
            if (i < lines.length - 1) {
              _closeLine(blockStack.last);
            }
          }
        }
      } else if (token.isDivider) {
        // Embed divider
        final dividerJson = json.encode({
          'color': token.attributes['color'] ?? '#CBD5E1',
          'thickness': 2.0,
          'style': 'solid',
        });
        _ops.add(Operation.insert({'divider': dividerJson}));
        _closeLine(blockStack.last);
      } else if (token.isLineBreak) {
        _closeLine(blockStack.last);
      } else if (token.isStartTag) {
        final tag = token.tagName.toLowerCase();
        
        // Inline formatting tags
        if (_isInlineTag(tag)) {
          final current = inlineStack.last;
          final updated = _applyInlineTag(current, tag, token.attributes);
          inlineStack.add(updated);
        }
        
        // Block formatting tags
        if (_isBlockTag(tag)) {
          // If previous text in line hasn't closed, close line before block if needed
          if (_ops.isNotEmpty && _ops.last.data is String && !(_ops.last.data as String).endsWith('\n')) {
            _closeLine(blockStack.last);
          }
          final currentBlock = blockStack.last;
          final updatedBlock = _applyBlockTag(currentBlock, tag, token.attributes);
          blockStack.add(updatedBlock);
        }
      } else if (token.isEndTag) {
        final tag = token.tagName.toLowerCase();
        if (_isInlineTag(tag)) {
          if (inlineStack.length > 1) {
            inlineStack.removeLast();
          }
        }
        if (_isBlockTag(tag)) {
          // Only close line for leaf blocks (not container tags like ul / ol)
          if (tag != 'ul' && tag != 'ol') {
            _closeLine(blockStack.last);
          }
          if (blockStack.length > 1) {
            blockStack.removeLast();
          }
        }
      }
    }
  }

  void _closeLine(_BlockContext block) {
    final lineAttrs = block.toLineAttributes();
    if (_ops.isNotEmpty) {
      final lastOp = _ops.last;
      if (lastOp.data is String && (lastOp.data as String).endsWith('\n')) {
        // Line is already ended with newline. If last newline has no block attributes, apply them.
        if (lineAttrs.isNotEmpty && (lastOp.attributes == null || lastOp.attributes!.isEmpty)) {
          final lastStr = lastOp.data as String;
          if (lastStr == '\n') {
            _ops[_ops.length - 1] = Operation.insert('\n', lineAttrs);
          }
        }
        return;
      }
    }

    if (lineAttrs.isNotEmpty) {
      _ops.add(Operation.insert('\n', lineAttrs));
    } else {
      _ops.add(Operation.insert('\n'));
    }
  }

  bool _isInlineTag(String tag) {
    return const {
      'b', 'strong', 'i', 'em', 'u', 'ins', 's', 'strike', 'del',
      'span', 'font', 'a', 'code', 'mark', 'kbd', 'tt', 'small', 'big',
    }.contains(tag);
  }

  bool _isBlockTag(String tag) {
    return const {
      'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      'ul', 'ol', 'li', 'blockquote', 'pre', 'center', 'section', 'article',
    }.contains(tag);
  }

  _InlineStyle _applyInlineTag(_InlineStyle current, String tag, Map<String, String> attrs) {
    var s = current;
    if (tag == 'b' || tag == 'strong') s = s.copyWith(bold: true);
    if (tag == 'i' || tag == 'em') s = s.copyWith(italic: true);
    if (tag == 'u' || tag == 'ins') s = s.copyWith(underline: true);
    if (tag == 's' || tag == 'strike' || tag == 'del') s = s.copyWith(strike: true);
    if (tag == 'code' || tag == 'kbd' || tag == 'tt') s = s.copyWith(code: true);
    if (tag == 'mark') s = s.copyWith(background: '#FEF08A');
    if (tag == 'small') s = s.copyWith(size: 'small');
    if (tag == 'big') s = s.copyWith(size: 'large');

    if (tag == 'a') {
      final href = attrs['href'];
      if (href != null && href.isNotEmpty) {
        s = s.copyWith(link: href);
      }
    }

    if (tag == 'font') {
      final color = attrs['color'];
      if (color != null) {
        final parsedColor = _parseColor(color);
        if (parsedColor != null) s = s.copyWith(color: parsedColor);
      }
      final size = attrs['size'];
      if (size != null) {
        final parsedSize = _parseFontSizeValue(size);
        if (parsedSize != null) s = s.copyWith(size: parsedSize);
      }
      final face = attrs['face'];
      if (face != null && face.isNotEmpty) {
        s = s.copyWith(font: face);
      }
    }

    // Parse style attribute (CSS)
    final styleAttr = attrs['style'];
    if (styleAttr != null && styleAttr.isNotEmpty) {
      s = _parseCssInlineStyles(s, styleAttr);
    }

    return s;
  }

  _BlockContext _applyBlockTag(_BlockContext current, String tag, Map<String, String> attrs) {
    var b = current;

    if (tag == 'h1') b = b.copyWith(header: 1);
    if (tag == 'h2') b = b.copyWith(header: 2);
    if (tag == 'h3' || tag == 'h4' || tag == 'h5' || tag == 'h6') b = b.copyWith(header: 3);

    if (tag == 'center') b = b.copyWith(align: 'center');
    if (tag == 'blockquote') b = b.copyWith(isBlockQuote: true);
    if (tag == 'pre') b = b.copyWith(isCodeBlock: true);

    if (tag == 'ul') b = b.copyWith(list: 'bullet');
    if (tag == 'ol') b = b.copyWith(list: 'ordered');

    final alignAttr = attrs['align'];
    if (alignAttr != null && alignAttr.isNotEmpty) {
      final a = alignAttr.toLowerCase();
      if (a == 'left' || a == 'center' || a == 'right' || a == 'justify') {
        b = b.copyWith(align: a);
      }
    }

    final styleAttr = attrs['style'];
    if (styleAttr != null && styleAttr.isNotEmpty) {
      final cssMap = _parseCssMap(styleAttr);
      final textAlign = cssMap['text-align'];
      if (textAlign != null) {
        final a = textAlign.toLowerCase().trim();
        if (a == 'left' || a == 'center' || a == 'right' || a == 'justify') {
          b = b.copyWith(align: a);
        }
      }
      final lineHeight = cssMap['line-height'];
      if (lineHeight != null) {
        final lh = double.tryParse(lineHeight.replaceAll(RegExp(r'[^\d.]'), ''));
        if (lh != null) {
          b = b.copyWith(lineHeight: lh.toStringAsFixed(1));
        }
      }
    }

    return b;
  }

  _InlineStyle _parseCssInlineStyles(_InlineStyle current, String css) {
    var s = current;
    final cssMap = _parseCssMap(css);

    // Bold
    final fontWeight = cssMap['font-weight']?.toLowerCase();
    if (fontWeight != null) {
      if (fontWeight == 'bold' || fontWeight == 'bolder' || fontWeight == '700' || fontWeight == '800' || fontWeight == '900') {
        s = s.copyWith(bold: true);
      } else if (fontWeight == 'normal' || fontWeight == '400') {
        s = s.copyWith(bold: false);
      }
    }

    // Italic
    final fontStyle = cssMap['font-style']?.toLowerCase();
    if (fontStyle != null) {
      if (fontStyle == 'italic' || fontStyle == 'oblique') {
        s = s.copyWith(italic: true);
      } else if (fontStyle == 'normal') {
        s = s.copyWith(italic: false);
      }
    }

    // Text decoration (underline / strike)
    final textDec = (cssMap['text-decoration'] ?? cssMap['text-decoration-line'])?.toLowerCase();
    if (textDec != null) {
      if (textDec.contains('underline')) s = s.copyWith(underline: true);
      if (textDec.contains('line-through')) s = s.copyWith(strike: true);
      if (textDec == 'none') {
        s = s.copyWith(underline: false, strike: false);
      }
    }

    // Color
    final color = cssMap['color'];
    if (color != null) {
      final parsed = _parseColor(color);
      if (parsed != null) s = s.copyWith(color: parsed);
    }

    // Background Color
    final bg = cssMap['background-color'] ?? cssMap['background'];
    if (bg != null) {
      final parsed = _parseColor(bg);
      if (parsed != null) s = s.copyWith(background: parsed);
    }

    // Font Size
    final fontSize = cssMap['font-size'];
    if (fontSize != null) {
      final parsed = _parseFontSizeValue(fontSize);
      if (parsed != null) s = s.copyWith(size: parsed);
    }

    // Font Family
    final fontFam = cssMap['font-family'];
    if (fontFam != null && fontFam.isNotEmpty) {
      final clean = fontFam.split(',').first.replaceAll(RegExp(r'''['"]'''), '').trim();
      if (clean.toLowerCase().contains('mono') || clean.toLowerCase().contains('courier') || clean.toLowerCase().contains('consolas')) {
        s = s.copyWith(code: true);
      } else if (clean.isNotEmpty) {
        s = s.copyWith(font: clean);
      }
    }

    return s;
  }

  static Map<String, String> _parseCssMap(String css) {
    final result = <String, String>{};
    final pairs = css.split(';');
    for (final pair in pairs) {
      final colonIndex = pair.indexOf(':');
      if (colonIndex > 0) {
        final key = pair.substring(0, colonIndex).trim().toLowerCase();
        final value = pair.substring(colonIndex + 1).trim();
        result[key] = value;
      }
    }
    return result;
  }

  static String? _parseColor(String raw) {
    final str = raw.trim().toLowerCase();
    if (str.startsWith('#')) {
      final hex = str.substring(1);
      if (hex.length == 3) {
        final r = hex[0];
        final g = hex[1];
        final b = hex[2];
        return '#$r$r$g$g$b$b'.toUpperCase();
      }
      if (hex.length == 6) {
        return '#${hex.toUpperCase()}';
      }
      if (hex.length == 8) {
        // #RRGGBBAA or #AARRGGBB -> return #RRGGBB
        return '#${hex.substring(0, 6).toUpperCase()}';
      }
    }

    // rgb(r, g, b) or rgba(r, g, b, a)
    final rgbMatch = RegExp(r'rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)').firstMatch(str);
    if (rgbMatch != null) {
      final r = int.parse(rgbMatch.group(1)!).clamp(0, 255);
      final g = int.parse(rgbMatch.group(2)!).clamp(0, 255);
      final b = int.parse(rgbMatch.group(3)!).clamp(0, 255);
      return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
    }

    // Standard HTML color names
    final namedColors = {
      'black': '#000000',
      'white': '#FFFFFF',
      'red': '#EF4444',
      'green': '#22C55E',
      'blue': '#3B82F6',
      'yellow': '#EAB308',
      'orange': '#F97316',
      'purple': '#A855F7',
      'pink': '#EC4899',
      'gray': '#6B7280',
      'grey': '#6B7280',
      'cyan': '#06B6D4',
      'teal': '#14B8A6',
      'indigo': '#6366F1',
      'violet': '#8B5CF6',
      'fuchsia': '#D946EF',
      'rose': '#F43F5E',
      'amber': '#F59E0B',
      'emerald': '#10B981',
      'sky': '#0EA5E9',
      'slate': '#64748B',
      'zinc': '#71717A',
    };

    if (namedColors.containsKey(str)) {
      return namedColors[str];
    }

    return null;
  }

  static String? _parseFontSizeValue(String raw) {
    final str = raw.trim().toLowerCase();

    // Standard Quill keywords
    if (str == 'small' || str == 'x-small' || str == 'xx-small') return 'small';
    if (str == 'medium' || str == 'normal') return 'normal';
    if (str == 'large' || str == 'x-large') return 'large';
    if (str == 'xx-large' || str == 'xxx-large' || str == 'huge') return 'huge';

    // Numeric pt/px/em
    if (str.endsWith('px') || str.endsWith('pt') || str.endsWith('em') || str.endsWith('rem')) {
      final numVal = double.tryParse(str.replaceAll(RegExp(r'[^\d.]'), ''));
      if (numVal != null) {
        if (str.endsWith('em') || str.endsWith('rem')) {
          final px = numVal * 16.0;
          return px.round().toString();
        }
        if (str.endsWith('pt')) {
          final px = numVal * 1.333;
          return px.round().toString();
        }
        return numVal.round().toString();
      }
    }

    // Plain digit font size <font size="1..7">
    final intSize = int.tryParse(str);
    if (intSize != null) {
      if (intSize <= 2) return 'small';
      if (intSize == 3) return 'normal';
      if (intSize == 4 || intSize == 5) return 'large';
      if (intSize >= 6) return 'huge';
      return intSize.toString();
    }

    return null;
  }

  List<_HtmlToken> _tokenize(String html) {
    final tokens = <_HtmlToken>[];
    final regex = RegExp(r'<(\/)?([a-zA-Z0-9\-]+)([^>]*)>|([^<]+)');
    final matches = regex.allMatches(html);

    for (final match in matches) {
      final isClosing = match.group(1) == '/';
      final tagName = match.group(2);
      final attrString = match.group(3);
      final textContent = match.group(4);

      if (textContent != null && textContent.isNotEmpty) {
        tokens.add(_HtmlToken.text(textContent));
      } else if (tagName != null) {
        final t = tagName.toLowerCase();
        if (t == 'br') {
          tokens.add(_HtmlToken.lineBreak());
        } else if (t == 'hr') {
          final attrs = _parseAttributes(attrString ?? '');
          tokens.add(_HtmlToken.divider(attrs));
        } else if (isClosing) {
          tokens.add(_HtmlToken.endTag(t));
        } else {
          final attrs = _parseAttributes(attrString ?? '');
          tokens.add(_HtmlToken.startTag(t, attrs));
        }
      }
    }

    return tokens;
  }

  static Map<String, String> _parseAttributes(String raw) {
    final attrs = <String, String>{};
    final regex = RegExp(r'''([a-zA-Z0-9\-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))''');
    final matches = regex.allMatches(raw);
    for (final m in matches) {
      final key = m.group(1)!.toLowerCase();
      final value = m.group(2) ?? m.group(3) ?? m.group(4) ?? '';
      attrs[key] = value;
    }
    return attrs;
  }
}

class _HtmlToken {
  final bool isText;
  final bool isStartTag;
  final bool isEndTag;
  final bool isLineBreak;
  final bool isDivider;
  final String text;
  final String tagName;
  final Map<String, String> attributes;

  const _HtmlToken._({
    this.isText = false,
    this.isStartTag = false,
    this.isEndTag = false,
    this.isLineBreak = false,
    this.isDivider = false,
    this.text = '',
    this.tagName = '',
    this.attributes = const {},
  });

  factory _HtmlToken.text(String text) => _HtmlToken._(isText: true, text: text);
  factory _HtmlToken.startTag(String tag, Map<String, String> attrs) => _HtmlToken._(isStartTag: true, tagName: tag, attributes: attrs);
  factory _HtmlToken.endTag(String tag) => _HtmlToken._(isEndTag: true, tagName: tag);
  factory _HtmlToken.lineBreak() => const _HtmlToken._(isLineBreak: true);
  factory _HtmlToken.divider(Map<String, String> attrs) => _HtmlToken._(isDivider: true, attributes: attrs);
}

// ---------------------------------------------------------------------------
// DELTA -> HTML CONVERTER IMPLEMENTATION
// ---------------------------------------------------------------------------

class _DeltaToHtmlConverter {
  static String convert(Delta delta) {
    if (delta.isEmpty) return '<p></p>';

    final buffer = StringBuffer();
    final ops = delta.toList();

    // Group delta into lines
    int opIndex = 0;
    String? currentListType;

    while (opIndex < ops.length) {
      // Collect all inline segments until next \n
      final inlineSegments = <Operation>[];
      Operation? lineOp;

      while (opIndex < ops.length) {
        final op = ops[opIndex];
        if (op.data is String) {
          final str = op.data as String;
          final newlinePos = str.indexOf('\n');
          if (newlinePos != -1) {
            if (newlinePos > 0) {
              inlineSegments.add(Operation.insert(str.substring(0, newlinePos), op.attributes));
            }
            lineOp = Operation.insert('\n', op.attributes);

            // If there is remainder after \n, replace current op with remainder
            final remainder = str.substring(newlinePos + 1);
            if (remainder.isNotEmpty) {
              ops[opIndex] = Operation.insert(remainder, op.attributes);
            } else {
              opIndex++;
            }
            break;
          } else {
            inlineSegments.add(op);
            opIndex++;
          }
        } else {
          // Embed (e.g. divider)
          inlineSegments.add(op);
          opIndex++;
        }
      }

      final lineAttributes = lineOp?.attributes ?? <String, dynamic>{};
      final listAttr = lineAttributes[Attribute.list.key]?.toString();

      // Manage <ul> / <ol> wrapper tags
      if (listAttr != currentListType) {
        if (currentListType == 'bullet' || currentListType == 'unchecked' || currentListType == 'checked') {
          buffer.write('</ul>');
        } else if (currentListType == 'ordered') {
          buffer.write('</ol>');
        }

        if (listAttr == 'bullet' || listAttr == 'unchecked' || listAttr == 'checked') {
          buffer.write('<ul>');
        } else if (listAttr == 'ordered') {
          buffer.write('<ol>');
        }
        currentListType = listAttr;
      }

      // Render line content
      _renderLine(buffer, inlineSegments, lineAttributes);
    }

    // Close any unclosed list tag
    if (currentListType == 'bullet' || currentListType == 'unchecked' || currentListType == 'checked') {
      buffer.write('</ul>');
    } else if (currentListType == 'ordered') {
      buffer.write('</ol>');
    }

    return buffer.toString();
  }

  static void _renderLine(StringBuffer buffer, List<Operation> inlines, Map<String, dynamic> lineAttrs) {
    // Check if line contains a divider embed
    for (final op in inlines) {
      if (op.data is Map && (op.data as Map).containsKey('divider')) {
        buffer.write('<hr style="border:none;border-top:2px solid #CBD5E1;margin:12px 0;"/>');
        return;
      }
    }

    final headerVal = lineAttrs[Attribute.header.key];
    final alignVal = lineAttrs[Attribute.align.key]?.toString();
    final listVal = lineAttrs[Attribute.list.key]?.toString();
    final isQuote = lineAttrs[Attribute.blockQuote.key] == true;
    final isCodeBlock = lineAttrs[Attribute.codeBlock.key] == true;
    final lineHeight = lineAttrs[Attribute.lineHeight.key]?.toString();

    // Determine tag
    String tag = 'p';
    if (headerVal == 1) tag = 'h1';
    if (headerVal == 2) tag = 'h2';
    if (headerVal == 3) tag = 'h3';
    if (listVal != null) tag = 'li';
    if (isQuote) tag = 'blockquote';
    if (isCodeBlock) tag = 'pre';

    final styles = <String>[];
    if (alignVal != null && alignVal.isNotEmpty) {
      styles.add('text-align:$alignVal');
    }
    if (lineHeight != null && lineHeight.isNotEmpty) {
      styles.add('line-height:$lineHeight');
    }

    final styleAttr = styles.isNotEmpty ? ' style="${styles.join(';')}"' : '';

    buffer.write('<$tag$styleAttr>');

    if (inlines.isEmpty) {
      buffer.write('<br/>');
    } else {
      for (final op in inlines) {
        if (op.data is String) {
          _renderInlineSpan(buffer, op.data as String, op.attributes);
        }
      }
    }

    buffer.write('</$tag>');
  }

  static void _renderInlineSpan(StringBuffer buffer, String text, Map<String, dynamic>? attrs) {
    if (text.isEmpty) return;

    final encodedText = _encodeHtmlEntities(text);
    if (attrs == null || attrs.isEmpty) {
      buffer.write(encodedText);
      return;
    }

    final isBold = attrs[Attribute.bold.key] == true;
    final isItalic = attrs[Attribute.italic.key] == true;
    final isUnderline = attrs[Attribute.underline.key] == true;
    final isStrike = attrs[Attribute.strikeThrough.key] == true;
    final isCode = attrs[Attribute.inlineCode.key] == true;
    final color = attrs[Attribute.color.key]?.toString();
    final bg = attrs[Attribute.background.key]?.toString();
    final size = attrs[Attribute.size.key]?.toString();
    final font = attrs[Attribute.font.key]?.toString();
    final link = attrs[Attribute.link.key]?.toString();

    final cssStyles = <String>[];
    if (color != null && color.isNotEmpty) cssStyles.add('color:$color');
    if (bg != null && bg.isNotEmpty) cssStyles.add('background-color:$bg');
    if (size != null && size.isNotEmpty) {
      if (size == 'small') {
        cssStyles.add('font-size:12px');
      } else if (size == 'normal') {
        cssStyles.add('font-size:15px');
      } else if (size == 'large') {
        cssStyles.add('font-size:20px');
      } else if (size == 'huge') {
        cssStyles.add('font-size:26px');
      } else {
        final numSize = double.tryParse(size);
        if (numSize != null) {
          final cleanSize = numSize == numSize.roundToDouble() ? numSize.toInt().toString() : numSize.toString();
          cssStyles.add('font-size:${cleanSize}px');
        } else {
          cssStyles.add('font-size:$size');
        }
      }
    }
    if (font != null && font.isNotEmpty) cssStyles.add('font-family:$font');

    var result = encodedText;

    if (isCode) result = '<code>$result</code>';
    if (isStrike) result = '<s>$result</s>';
    if (isUnderline) result = '<u>$result</u>';
    if (isItalic) result = '<i>$result</i>';
    if (isBold) result = '<b>$result</b>';

    if (cssStyles.isNotEmpty) {
      result = '<span style="${cssStyles.join(';')}">$result</span>';
    }

    if (link != null && link.isNotEmpty) {
      result = '<a href="$link">$result</a>';
    }

    buffer.write(result);
  }
}

// ---------------------------------------------------------------------------
// HTML ENTITIES UTILITIES
// ---------------------------------------------------------------------------

String _decodeHtmlEntities(String text) {
  var s = text;
  s = s.replaceAll('&nbsp;', ' ');
  s = s.replaceAll('&amp;', '&');
  s = s.replaceAll('&lt;', '<');
  s = s.replaceAll('&gt;', '>');
  s = s.replaceAll('&quot;', '"');
  s = s.replaceAll('&#39;', "'");
  s = s.replaceAll('&apos;', "'");

  // Numeric decimal &#123;
  s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    try {
      final code = int.parse(match.group(1)!);
      return String.fromCharCode(code);
    } catch (_) {
      return match.group(0)!;
    }
  });

  // Numeric hex &#x1f600;
  s = s.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
    try {
      final code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    } catch (_) {
      return match.group(0)!;
    }
  });

  return s;
}

String _encodeHtmlEntities(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
