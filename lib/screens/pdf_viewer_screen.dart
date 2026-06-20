import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../services/pdf_semantic_html.dart';

class PDFViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String fileName;

  const PDFViewerScreen({
    super.key,
    required this.pdfPath,
    required this.fileName,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late final WebViewController _controller;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  String? _htmlContent;
  bool _isLoading = true;
  String _loadingMessage = "Preparing to convert...";
  bool _showHtmlView = true; // true = HTML reflow, false = native Syncfusion PDF
  /// After switching PDF → HTML, scroll this 1-based page into view once the page loads.
  int? _pendingHtmlScrollToPdfPage;
  /// Rebuilt when opening native PDF view so [initialPageNumber] is respected.
  int _pdfViewerGeneration = 0;
  int _pdfViewerInitialPage = 1;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _onWebViewPageFinished(),
        ),
      );
    _convertPdfToReflowableHtml();
  }

  void _onWebViewPageFinished() {
    final int? target = _pendingHtmlScrollToPdfPage;
    if (target == null || !_showHtmlView) return;
    _pendingHtmlScrollToPdfPage = null;
    _controller.runJavaScript(
      'document.getElementById("html-pdf-page-$target")?.scrollIntoView({block:"start",behavior:"auto"});',
    );
  }

  int _readNativePdfViewerPage() {
    try {
      final int n = _pdfViewerController.pageNumber;
      return n < 1 ? 1 : n;
    } catch (_) {
      return 1;
    }
  }

  /// Switch between reflow HTML and native Syncfusion PDF (zoom, selection, search in toolbar).
  Future<void> _toggleView() async {
    if (_isLoading) return;

    final int page = _showHtmlView
        ? await _readVisiblePdfPageFromHtml()
        : _readNativePdfViewerPage();

    final bool goingToHtml = !_showHtmlView;

    if (goingToHtml) {
      setState(() {
        _showHtmlView = true;
        _pendingHtmlScrollToPdfPage = page;
        _isLoading = _htmlContent == null;
      });
      if (_htmlContent != null) {
        _controller.loadHtmlString(_htmlContent!);
        setState(() {
          _isLoading = false;
        });
      } else {
        await _convertPdfToReflowableHtml();
      }
    } else {
      setState(() {
        _showHtmlView = false;
        _pendingHtmlScrollToPdfPage = null;
        _pdfViewerGeneration++;
        _pdfViewerInitialPage = page < 1 ? 1 : page;
        _isLoading = false;
      });
    }
  }

  int _coerceJsPageNumber(Object? raw) {
    if (raw is int) return raw < 1 ? 1 : raw;
    if (raw is double) {
      final int r = raw.round();
      return r < 1 ? 1 : r;
    }
    return 1;
  }

  /// Which PDF page (1-based) is at the top of the HTML scroll position.
  Future<int> _readVisiblePdfPageFromHtml() async {
    if (_htmlContent == null) return 1;
    try {
      final Object? raw = await _controller.runJavaScriptReturningResult(r'''
(function(){
  var sections = document.querySelectorAll('section[data-pdf-page]');
  if (!sections.length) return 1;
  var scrollTop = window.pageYOffset || document.documentElement.scrollTop || 0;
  var best = 1;
  for (var i = 0; i < sections.length; i++) {
    var sec = sections[i];
    var docTop = sec.getBoundingClientRect().top + window.scrollY;
    if (docTop <= scrollTop + 2)
      best = parseInt(sec.getAttribute('data-pdf-page'), 10) || best;
  }
  return best;
})()
''');
      return _coerceJsPageNumber(raw);
    } catch (_) {
      return 1;
    }
  }

  /// This is the core logic that extracts text and generates reflowable HTML.
  /// This version includes smarter text cleanup for better results.
  Future<void> _convertPdfToReflowableHtml() async {
    try {
      setState(() {
        _loadingMessage = "Reading PDF file...";
      });

      // 1. Load the PDF document from the file path.
      final List<int> bytes = await File(widget.pdfPath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      setState(() {
        _loadingMessage = "Extracting text from ${document.pages.count} pages...";
      });

      // 2. Extract text per page so scroll position maps to PDF page numbers on toggle.
      final int pageCount = document.pages.count;
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final StringBuffer pageSections = StringBuffer();

      setState(() {
        _loadingMessage = "Cleaning and structuring text...";
      });

      for (int i = 0; i < pageCount; i++) {
        if (mounted) {
          setState(() {
            _loadingMessage = "Processing page ${i + 1} of $pageCount...";
          });
        }
        final List<TextLine> layoutLines =
            extractor.extractTextLines(startPageIndex: i, endPageIndex: i);
        final String processedText = layoutLines.isNotEmpty
            ? _layoutTextLinesToHtml(layoutLines, document.pages[i])
            : _structuredTextFromPlainExtraction(
                extractor,
                pageIndex: i,
              );
        final int pageNum = i + 1;
        pageSections.writeln(
          '<section class="pdf-source-page" data-pdf-page="$pageNum" id="html-pdf-page-$pageNum">$processedText</section>',
        );
      }

      // 3. IMPORTANT: Dispose the document to free up memory.
      document.dispose();

      setState(() {
        _loadingMessage = "Generating reflowable HTML...";
      });

      // 6. Assemble the final HTML with mobile-friendly styling and dark mode support.
      final String finalHtml = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
              font-size: 1.1rem;
              line-height: 1.6;
              max-width: 100%;
              padding: 16px;
              margin: 0;
              background-color: #FFFFFF;
              color: #1a1a1a;
            }
            h1 {
              font-size: 1.75rem;
              line-height: 1.2;
              margin-bottom: 0.5em;
            }
            h2 {
              font-size: 1.4rem;
              color: #1a1a1a;
              line-height: 1.3;
              margin-top: 24px;
              margin-bottom: 0.75em;
              border-bottom: 2px solid #e0e0e0;
              padding-bottom: 0.3em;
            }
            p {
              margin-top: 0;
              margin-bottom: 16px;
            }
            p.pdf-flow-p {
              margin-top: 0;
              margin-bottom: 16px;
            }
            p.pdf-flow-p.pdf-para-gap {
              margin-top: 1.1em;
            }
            sup.cite-ref {
              font-size: 0.75em;
              vertical-align: super;
              color: #0d47a1;
            }
            .footnote {
              font-size: 0.9rem;
              color: #666;
            }
            ul {
              margin: 1em 0;
              padding-left: 2em;
            }
            li {
              margin-bottom: 0.5em;
              line-height: 1.6;
            }
            @media (max-width: 600px) {
              body { font-size: 1rem; padding: 12px; }
              h2 { font-size: 1.25rem; margin-top: 20px; }
            }
            @media (prefers-color-scheme: dark) {
              h2 { border-bottom-color: #444; color: #f2f2f7; }
              body {
                background-color: #1c1c1e;
                color: #f2f2f7;
              }
              sup.cite-ref { color: #90caf9; }
              .footnote { color: #aaa; }
            }
            .pdf-source-page:not(:first-of-type) {
              margin-top: 2em;
              padding-top: 1em;
              border-top: 1px solid #e0e0e0;
            }
            @media (prefers-color-scheme: dark) {
              .pdf-source-page:not(:first-of-type) {
                border-top-color: #444;
              }
            }
          </style>
        </head>
        <body>
          <h1>${widget.fileName}</h1>
          <hr>
          $pageSections
        </body>
        </html>
      ''';

      // 7. Update the state and load the generated HTML into the WebView.
      setState(() {
        _htmlContent = finalHtml;
        _isLoading = false;
      });
      _controller.loadHtmlString(_htmlContent!);

    } catch (e) {
      // If anything goes wrong, display a helpful error in the WebView.
      setState(() {
        _htmlContent =
            '<html><body><h2>Failed to Convert PDF</h2><p>An error occurred during the text extraction process.</p><p>Error: ${escapeHtml(e.toString())}</p></body></html>';
        _isLoading = false;
      });
      _controller.loadHtmlString(_htmlContent!);
    }
  }

  /// Fallback when [PdfTextExtractor.extractTextLines] is empty: tries layout-aware text, then plain.
  String _structuredTextFromPlainExtraction(
    PdfTextExtractor extractor, {
    required int pageIndex,
  }) {
    String laidOut = extractor.extractText(
      startPageIndex: pageIndex,
      endPageIndex: pageIndex,
      layoutText: true,
    );
    laidOut = laidOut.replaceAll('\r\n', '\n').replaceAll(RegExp(r'-\n\s*'), '');
    if (laidOut.trim().isNotEmpty) {
      return _processTextIntelligently(laidOut);
    }
    final String raw = extractor
        .extractText(startPageIndex: pageIndex, endPageIndex: pageIndex)
        .replaceAll(RegExp(r'-\n\s*'), '');
    return _processTextIntelligently(raw);
  }

  /// Builds HTML from [TextLine] geometry so indents and paragraph spacing follow the PDF layout.
  String _layoutTextLinesToHtml(List<TextLine> lines, PdfPage page) {
    final List<TextLine> nonEmpty = lines
        .where((TextLine l) => l.text.trim().isNotEmpty)
        .toList(growable: false);
    if (nonEmpty.isEmpty) return '';

    final List<TextLine> sorted = List<TextLine>.from(nonEmpty);
    sorted.sort((TextLine a, TextLine b) {
      const double yTol = 5.0;
      final double dy = a.bounds.top - b.bounds.top;
      if (dy.abs() > yTol) {
        return dy.compareTo(0.0);
      }
      return a.bounds.left.compareTo(b.bounds.left);
    });

    final double pageW = page.size.width;
    final double bodyLeft = _inferBodyLeftEdge(sorted, pageW);

    final List<double> heights = sorted
        .map((TextLine l) => math.max(1.0, l.bounds.height))
        .toList()
      ..sort();
    final double medianH = heights[heights.length ~/ 2];
    final List<double> fontSizes = sorted
        .where((TextLine l) => l.fontSize > 0)
        .map((TextLine l) => l.fontSize)
        .toList()
      ..sort();
    final double medianFs =
        fontSizes.isEmpty ? medianH : fontSizes[fontSizes.length ~/ 2];
    final double paragraphGapTh = math.max(medianH * 0.72, 7.0);

    final List<_TextLineGroup> groups = <_TextLineGroup>[];
    List<TextLine>? current;
    for (int i = 0; i < sorted.length; i++) {
      final TextLine line = sorted[i];
      if (current == null) {
        current = <TextLine>[line];
        continue;
      }
      final TextLine prev = current.last;
      double gap = _verticalGapAfterLine(prev, line, medianH);
      if (gap > paragraphGapTh) {
        groups.add(_TextLineGroup(current, 0));
        current = <TextLine>[line];
      } else {
        current.add(line);
      }
    }
    if (current != null) {
      groups.add(_TextLineGroup(current, 0));
    }

    for (int g = 1; g < groups.length; g++) {
      final TextLine prevLast = groups[g - 1].lines.last;
      final TextLine nextFirst = groups[g].lines.first;
      groups[g] = _TextLineGroup(
        groups[g].lines,
        _verticalGapAfterLine(prevLast, nextFirst, medianH),
      );
    }

    final StringBuffer buf = StringBuffer();
    for (int g = 0; g < groups.length; g++) {
      final _TextLineGroup group = groups[g];
      if (group.lines.isEmpty) continue;

      String merged = group.lines.first.text.trim();
      for (int j = 1; j < group.lines.length; j++) {
        merged = _joinHyphenatedLineBreak(merged, group.lines[j].text.trim());
      }
      merged = _preprocessText(merged);
      if (merged.trim().isEmpty) continue;

      final List<String> rawLines =
          group.lines.map((TextLine l) => l.text.trim()).toList();
      final String firstLine = rawLines.first;

      if (_isLikelyListItem(firstLine)) {
        buf.writeln('<li>${plainTextToHtmlWithCitations(merged)}</li>');
        continue;
      }
      if (isRomanSectionHeadingLine(firstLine)) {
        buf.writeln('<h2>${plainTextToHtmlWithCitations(merged)}</h2>');
        continue;
      }
      if (_qualifiesFontSizeHeading(group.lines, medianFs, merged)) {
        buf.writeln('<h2>${plainTextToHtmlWithCitations(merged)}</h2>');
        continue;
      }
      if (_isLikelyHeading(firstLine, 0, rawLines)) {
        buf.writeln('<h2>${plainTextToHtmlWithCitations(merged)}</h2>');
        continue;
      }

      double fontSize = medianH;
      for (final TextLine l in group.lines) {
        if (l.fontSize > 0) {
          fontSize = l.fontSize;
          break;
        }
      }
      fontSize = math.max(8.0, fontSize);

      final double blockLeft =
          group.lines.map((TextLine l) => l.bounds.left).reduce(math.min);
      final double firstLeft = group.lines.first.bounds.left;
      double restLeft = firstLeft;
      if (group.lines.length > 1) {
        restLeft = group.lines
            .skip(1)
            .map((TextLine l) => l.bounds.left)
            .reduce(math.min);
      }

      final double marginLeftPt = blockLeft - bodyLeft;
      final double marginLeftEm =
          marginLeftPt > 6.0 ? marginLeftPt / fontSize : 0.0;

      double textIndentEm = 0.0;
      if (group.lines.length > 1 && firstLeft > restLeft + 5.0) {
        textIndentEm = (firstLeft - restLeft) / fontSize;
      }

      final List<String> styles = <String>[];
      if (marginLeftEm > 0.08) {
        styles.add('margin-left:${marginLeftEm.toStringAsFixed(2)}em');
      }
      if (textIndentEm > 0.08) {
        styles.add('text-indent:${textIndentEm.toStringAsFixed(2)}em');
      }

      double marginTopEm = 0.0;
      if (g > 0 && group.gapBefore > paragraphGapTh * 1.15) {
        marginTopEm =
            math.min(2.8, (group.gapBefore / fontSize) * 0.42);
      }
      if (marginTopEm > 0.08) {
        styles.add('margin-top:${marginTopEm.toStringAsFixed(2)}em');
      }

      final String gapClass =
          g > 0 && group.gapBefore > paragraphGapTh * 1.35 ? ' pdf-para-gap' : '';
      final String styleAttr =
          styles.isEmpty ? '' : ' style="${styles.join(';')}"';
      buf.writeln(
        '<p class="pdf-flow-p$gapClass"$styleAttr>${plainTextToHtmlWithCitations(merged)}</p>',
      );
    }

    return _wrapListItems(buf.toString());
  }

  bool _qualifiesFontSizeHeading(
    List<TextLine> lines,
    double medianFs,
    String merged,
  ) {
    if (lines.isEmpty || medianFs <= 0) return false;
    double maxFs = 0;
    for (final TextLine l in lines) {
      if (l.fontSize > maxFs) {
        maxFs = l.fontSize;
      }
    }
    if (maxFs <= 0) return false;
    if (maxFs < medianFs * 1.13) return false;
    if (merged.length > 165) return false;
    if (lines.length > 6) return false;
    return true;
  }

  double _inferBodyLeftEdge(List<TextLine> sorted, double pageWidth) {
    final List<TextLine> wide = sorted
        .where((TextLine l) => l.bounds.width > pageWidth * 0.32)
        .toList();
    final Iterable<TextLine> src = wide.isNotEmpty ? wide : sorted;
    return src.map((TextLine l) => l.bounds.left).reduce(math.min);
  }

  double _verticalGapAfterLine(
    TextLine prev,
    TextLine next,
    double medianH,
  ) {
    double gap = next.bounds.top - prev.bounds.bottom;
    if (gap >= -medianH * 0.5 && gap <= medianH * 8) {
      return gap;
    }
    final double prevBase = prev.bounds.top + prev.bounds.height * 0.88;
    final double nextBase = next.bounds.top + next.bounds.height * 0.88;
    return nextBase - prevBase;
  }

  String _joinHyphenatedLineBreak(String a, String b) {
    final String left = a.trimRight();
    final String right = b.trimLeft();
    if (left.isEmpty) return right;
    if (right.isEmpty) return left;
    if (left.endsWith('-') && left.length >= 2) {
      final String c = left[left.length - 2];
      if (RegExp(r'[a-zA-Z\u00C0-\u024F]').hasMatch(c)) {
        return '${left.substring(0, left.length - 1)}$right';
      }
    }
    return '$left $right';
  }

  /// Intelligent text processing that separates text into paragraphs, headings, and lists
  String _processTextIntelligently(String text) {
    if (text.isEmpty) return '';
    
    // Pre-process text to handle common PDF extraction issues
    text = _preprocessText(text);
    
    // Split text into lines
    List<String> lines = text.split('\n');
    List<String> processedLines = [];
    List<String> currentParagraph = [];
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      // Skip empty lines
      if (line.isEmpty) {
        // If we have accumulated text, create a paragraph
        if (currentParagraph.isNotEmpty) {
          processedLines.add(
            '<p class="pdf-flow-p">${plainTextToHtmlWithCitations(currentParagraph.join(' '))}</p>',
          );
          currentParagraph.clear();
        }
        continue;
      }
      
      // Check if this line might be a heading
      if (_isLikelyHeading(line, i, lines)) {
        // If we have accumulated text, create a paragraph first
        if (currentParagraph.isNotEmpty) {
          processedLines.add(
            '<p class="pdf-flow-p">${plainTextToHtmlWithCitations(currentParagraph.join(' '))}</p>',
          );
          currentParagraph.clear();
        }
        // Add heading
        processedLines.add('<h2>${plainTextToHtmlWithCitations(line)}</h2>');
        continue;
      }
      
      // Check if this line might be a list item
      if (_isLikelyListItem(line)) {
        // If we have accumulated text, create a paragraph first
        if (currentParagraph.isNotEmpty) {
          processedLines.add(
            '<p class="pdf-flow-p">${plainTextToHtmlWithCitations(currentParagraph.join(' '))}</p>',
          );
          currentParagraph.clear();
        }
        // Add list item
        processedLines.add('<li>${plainTextToHtmlWithCitations(line)}</li>');
        continue;
      }
      
      // Check if this line should start a new paragraph
      if (_shouldStartNewParagraph(line, i, lines)) {
        // If we have accumulated text, create a paragraph
        if (currentParagraph.isNotEmpty) {
          processedLines.add(
            '<p class="pdf-flow-p">${plainTextToHtmlWithCitations(currentParagraph.join(' '))}</p>',
          );
          currentParagraph.clear();
        }
      }
      
      // Add line to current paragraph
      currentParagraph.add(line);
    }
    
    // Don't forget the last paragraph
    if (currentParagraph.isNotEmpty) {
      processedLines.add(
        '<p class="pdf-flow-p">${plainTextToHtmlWithCitations(currentParagraph.join(' '))}</p>',
      );
    }
    
    // Wrap list items in ul tags
    return _wrapListItems(processedLines.join('\n'));
  }
  
  /// Pre-process text to handle common PDF extraction issues that cause unwanted breaks
  /// This is conservative - it only fixes obvious word breaks, not structural line breaks
  String _preprocessText(String text) {
    // Handle common PDF extraction issues that cause unwanted breaks
    // BUT preserve lines that should remain separate (like author/company lines)
    
    // 1. Fix § symbol spacing issues (don't break around section symbols)
    text = text.replaceAll(RegExp(r'\s*\n\s*§'), ' §'); // Remove line breaks before §
    text = text.replaceAll(RegExp(r'§\s*\n\s*'), '§ '); // Remove line breaks after §
    text = text.replaceAll(RegExp(r'\s*§\s*'), ' §'); // Normalize § spacing
    text = text.replaceAll(RegExp(r'§\s+'), '§ '); // Remove extra spaces after §
    
    // 2. Fix punctuation that got separated from words (but preserve sentence endings)
    // Only fix punctuation that's clearly wrong (not at end of sentence)
    text = text.replaceAll(RegExp(r'([a-zA-Z])\s*\n\s*([,;:])', multiLine: false), r'$1$2'); // Connect commas, semicolons, colons
    text = text.replaceAll(RegExp(r'([,;:])\s*\n\s*([a-zA-Z])', multiLine: false), r'$1 $2'); // Space after punctuation
    
    // 3. Fix punctuation that should be attached (quotes, parentheses)
    text = text.replaceAll('"\n', '"'); // Remove breaks after opening quotes
    text = text.replaceAll('\n"', '"'); // Remove breaks before closing quotes
    text = text.replaceAll("'\n", "'"); // Remove breaks after opening quotes
    text = text.replaceAll("\n'", "'"); // Remove breaks before closing quotes
    text = text.replaceAll('(\n', '('); // Remove breaks after opening parentheses
    text = text.replaceAll('\n)', ')'); // Remove breaks before closing parentheses
    
    // 4. Fix common abbreviations that got split (only very specific cases)
    text = text.replaceAll(RegExp(r'([A-Z]\.)\s*\n\s*([A-Z]\.)', caseSensitive: false), r'$1 $2'); // Fix "U.S."
    text = text.replaceAll(RegExp(r'([a-z]\.)\s*\n\s*([a-z]\.)', caseSensitive: false), r'$1 $2'); // Fix "etc."
    
    // 5. Fix decimal numbers and units that got split
    text = text.replaceAll(RegExp(r'(\d+\.\d+)\s*\n\s*'), r'$1 '); // Fix decimal number breaks like "1.5\nmeters"
    text = text.replaceAll(RegExp(r'(\d+)\s*\n\s*([a-zA-Z%])'), r'$1 $2'); // Connect numbers with units "5\nmeters"
    
    // 6. Fix single letter abbreviations that got split (like "L.L.C." but preserve structure)
    // Only join if it's clearly part of the same abbreviation
    text = text.replaceAll(RegExp(r'([A-Z]\.)\s*\n\s*([A-Z]\.)\s*\n\s*([A-Z]\.)'), r'$1 $2 $3'); // "L.\nL.\nC." -> "L. L. C."
    
    // 7. Fix very short word fragments (likely font change artifacts)
    // Only connect if previous line doesn't end with punctuation (sentence ending)
    // This is handled more carefully in _processTextIntelligently
    
    // IMPORTANT: Do NOT join lines that:
    // - End with periods followed by lines starting with capital letters (likely separate items)
    // - Are short and followed by longer lines (likely headers/labels)
    // - End with punctuation and are followed by proper nouns (likely separate entries)
    
    return text;
  }
  
  /// Check if a line is likely a heading based on various patterns
  bool _isLikelyHeading(String line, int index, List<String> lines) {
    if (isRomanSectionHeadingLine(line)) {
      return true;
    }
    if (RegExp(r'^(?:STATEMENT OF THE ISSUE|SUMMARY|STATEMENT OF FACTS|CONCLUSION|ARGUMENT)',
            caseSensitive: false)
        .hasMatch(line.trim())) {
      return true;
    }
    // Check for common heading patterns
    if (line.length < 100 && // Short line
        (line.endsWith('.') == false) && // Doesn't end with period
        !line.contains('§') && // Exclude lines with section symbol (common in legal docs)
        (line.contains(RegExp(r'^[A-Z][A-Z\s]+$')) || // ALL CAPS
         line.contains(RegExp(r'^[0-9]+\.\s')) || // Numbered heading
         line.contains(RegExp(r'^[A-Z][a-z]+:')) || // Title: format
         line.contains(RegExp(r'^Chapter|Section|Part|Appendix|Introduction|Conclusion|Summary|Abstract|References|Bibliography|Index', caseSensitive: false)) || // Common heading words
         line.contains(RegExp(r'^[IVX]+\.\s')) || // Roman numerals
         line.contains(RegExp(r'^[A-Z][A-Z\s]{2,}$')) || // ALL CAPS with spaces
         (line.length < 50 && line.contains(RegExp(r'^[A-Z]')) && !line.contains(RegExp(r'[a-z]'))))) { // Short ALL CAPS
      return true;
    }
    return false;
  }
  
  /// Check if a line is likely a list item
  bool _isLikelyListItem(String line) {
    // Check for bullet points, numbered lists, etc.
    return line.contains(RegExp(r'^[\•\-\*]\s')) || // Bullet points
           line.contains(RegExp(r'^[0-9]+[\.\)]\s')) || // Numbered lists
           line.contains(RegExp(r'^[a-z][\.\)]\s')) || // Lettered lists
           line.contains(RegExp(r'^[A-Z][\.\)]\s')) || // Capital lettered lists
           line.contains(RegExp(r'^[ivx]+[\.\)]\s', caseSensitive: false)) || // Roman numeral lists
           line.contains(RegExp(r'^[IVX]+[\.\)]\s')) || // Capital Roman numeral lists
           line.contains(RegExp(r'^\d+\.\d+\s')) || // Decimal numbered lists (1.1, 2.3, etc.)
           line.contains(RegExp(r'^[•◦‣⁃]\s')) || // Various bullet characters
           line.contains(RegExp(r'^[→⇒➤]\s')) || // Arrow-style bullets
           line.contains(RegExp(r'^[✓✔☑]\s')) || // Checkmark-style bullets
           line.contains(RegExp(r'^[▪▫]\s')); // Square bullets
  }
  
  /// Determine if a line should start a new paragraph based on context
  bool _shouldStartNewParagraph(String line, int index, List<String> lines) {
    // Check if this line should start a new paragraph based on context
    
    // If it's the first line, start a paragraph
    if (index == 0) return true;
    
    // If previous line was empty, start new paragraph
    if (index > 0 && lines[index - 1].trim().isEmpty) return true;
    
    String previousLine = index > 0 ? lines[index - 1].trim() : '';
    
    // Legal document considerations - don't break on common legal references
    if (line.contains('§') || // Section symbol
        line.contains(RegExp(r'^\d+\.\d+')) || // Decimal numbers (like 1.1, 2.3)
        line.contains(RegExp(r'^[A-Z]\.\s')) || // Single letter followed by period
        line.contains(RegExp(r'^[ivx]+\.', caseSensitive: false))) { // Roman numerals
      return false; // Don't start new paragraph for these
    }
    
    // Check for drop caps and font change artifacts
    if (_isLikelyDropCapOrFontChange(line, index, lines)) {
      return false; // Don't break paragraph for these
    }
    
    // IMPORTANT: Detect when lines should be separate (like author/company, name/title)
    // If previous line ends with a title/designation and current line looks like a company/org
    if (previousLine.isNotEmpty && 
        previousLine.endsWith('.') &&
        _endsWithTitleOrDesignation(previousLine)) {
      // Check if current line looks like a company/organization name
      if (_looksLikeCompanyOrOrganization(line)) {
        return true; // Separate these into different paragraphs
      }
    }
    
    // If previous line ends with title/designation and current line starts with capital
    // and is fairly short, likely separate entries (like "Name, Title" followed by "Company Name")
    if (previousLine.isNotEmpty && 
        previousLine.endsWith('.') &&
        previousLine.length < 80 && // Short line (like a name/title)
        line.isNotEmpty &&
        line[0] == line[0].toUpperCase() &&
        line.length > 10) { // Current line has content
      // Check if previous line has title indicators
      if (_endsWithTitleOrDesignation(previousLine) || 
          previousLine.contains(RegExp(r',\s*(Esq|Ph\.D|M\.D|Jr|Sr|LLC|L\.L\.C|Inc|Corp|Ltd)', caseSensitive: false))) {
        return true; // Separate these
      }
    }
    
    // If line starts with capital letter and previous line ends with period
    // This is a common sentence boundary
    if (previousLine.isNotEmpty && 
        line.isNotEmpty && 
        line[0] == line[0].toUpperCase() &&
        previousLine.endsWith('.')) {
      // But check if it's likely a continuation vs new sentence
      // If previous line is very short, it's more likely a label/title, so keep separate
      if (previousLine.length < 60) {
        return true; // Short lines ending with period + new capitalized line = likely separate
      }
      return true; // Default: new sentence = new paragraph
    }
    
    // If line is significantly shorter than average (might be a new sentence or label)
    if (index > 0 && line.length < 50 && previousLine.length > 100) {
      return true;
    }
    
    // If line starts with common paragraph starters
    if (line.isNotEmpty && 
        (line.startsWith('However,') ||
         line.startsWith('Therefore,') ||
         line.startsWith('Furthermore,') ||
         line.startsWith('Moreover,') ||
         line.startsWith('In addition,') ||
         line.startsWith('On the other hand,') ||
         line.startsWith('For example,') ||
         line.startsWith('In conclusion,') ||
         line.startsWith('First,') ||
         line.startsWith('Second,') ||
         line.startsWith('Third,') ||
         line.startsWith('Finally,'))) {
      return true;
    }
    
    // If there's a significant gap in line length (indicates different content type)
    if (previousLine.isNotEmpty && 
        previousLine.length > 80 && 
        line.length < 30) {
      return true;
    }
    
    return false;
  }
  
  /// Check if a line ends with a title or professional designation
  bool _endsWithTitleOrDesignation(String line) {
    return line.contains(RegExp(r',\s*(Esq|Ph\.D|M\.D|Jr|Sr|LLC|L\.L\.C|Inc|Corp|Ltd|Attorney|Counsel|Partner)', caseSensitive: false)) ||
           line.endsWith(', Esq.') ||
           line.endsWith(' Esq.') ||
           line.contains(RegExp(r'\b(Ph\.D|M\.D|LLC|L\.L\.C)\b', caseSensitive: false));
  }
  
  /// Check if a line looks like a company or organization name
  bool _looksLikeCompanyOrOrganization(String line) {
    // Company/organization indicators
    return line.contains(RegExp(r'\b(LLC|L\.L\.C|Inc|Corp|Corporation|Ltd|Limited|Company|Consulting|Law|Legal|Associates|Group|Partners)\b', caseSensitive: false)) ||
           (line.length > 15 && line.length < 80 && // Reasonable length for company name
            line[0] == line[0].toUpperCase() && // Starts with capital
            !line.endsWith('.') && // Doesn't end with period (unlike sentences)
            !line.contains(RegExp(r'^[A-Z][a-z]+\s+[A-Z]'))); // Not a simple name pattern
  }
  
  /// Check if a line is likely a drop cap or font change artifact
  bool _isLikelyDropCapOrFontChange(String line, int index, List<String> lines) {
    if (index == 0) return false;
    
    String previousLine = lines[index - 1].trim();
    
    // Check for drop cap patterns (single capital letter followed by rest of word)
    if (line.length > 1 && 
        line[0] == line[0].toUpperCase() && 
        line[1] == line[1].toLowerCase() &&
        previousLine.isNotEmpty &&
        previousLine.endsWith('.')) {
      return true; // Likely a drop cap continuation
    }
    
    // Check for font change artifacts (very short lines that are part of a word)
    if (line.length <= 3 && 
        previousLine.isNotEmpty &&
        !previousLine.endsWith('.') &&
        !previousLine.endsWith('!') &&
        !previousLine.endsWith('?')) {
      return true; // Likely a font change artifact
    }
    
    // Check for mixed case patterns that suggest font changes
    if (line.length > 0 && 
        line[0] == line[0].toLowerCase() &&
        previousLine.isNotEmpty &&
        previousLine[previousLine.length - 1] == previousLine[previousLine.length - 1].toLowerCase()) {
      return true; // Likely continuation after font change
    }
    
    // Check for § symbol patterns
    if (line.contains('§') || previousLine.contains('§')) {
      return true; // Don't break around § symbols
    }
    
    return false;
  }
  
  /// Wrap consecutive list items in ul tags
  String _wrapListItems(String html) {
    // Find consecutive list items and wrap them in ul tags
    List<String> htmlLines = html.split('\n');
    List<String> result = [];
    List<String> currentList = [];
    
    for (String line in htmlLines) {
      if (line.trim().startsWith('<li>')) {
        currentList.add(line);
      } else {
        // If we have accumulated list items, wrap them
        if (currentList.isNotEmpty) {
          result.add('<ul>');
          result.addAll(currentList);
          result.add('</ul>');
          currentList.clear();
        }
        result.add(line);
      }
    }
    
    // Don't forget the last list
    if (currentList.isNotEmpty) {
      result.add('<ul>');
      result.addAll(currentList);
      result.add('</ul>');
    }
    
    return result.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          // Toggle switch for HTML/PDF view
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PDF',
                style: TextStyle(
                  fontSize: 12,
                  color: _showHtmlView ? Colors.white70 : Colors.white,
                ),
              ),
              Switch(
                value: _showHtmlView,
                onChanged: (_) => _toggleView(),
              ),
              Text(
                'HTML',
                style: TextStyle(
                  fontSize: 12,
                  color: _showHtmlView ? Colors.white : Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Refresh button (only show in HTML view)
          if (_showHtmlView)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Re-convert PDF',
              onPressed: () {
                // Allow the user to re-run the conversion if they want.
                if (!_isLoading) {
                  setState(() {
                    _isLoading = true;
                  });
                  _convertPdfToReflowableHtml();
                }
              },
            ),
        ],
      ),
      // Show a loading indicator with progress messages while converting...
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    _loadingMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : _showHtmlView
              ? WebViewWidget(controller: _controller)
              : SfPdfViewer.file(
                  File(widget.pdfPath),
                  key: ValueKey<int>(_pdfViewerGeneration),
                  controller: _pdfViewerController,
                  initialPageNumber: _pdfViewerInitialPage,
                  canShowPaginationDialog: true,
                  canShowScrollHead: true,
                  enableTextSelection: true,
                  interactionMode: PdfInteractionMode.selection,
                  pageLayoutMode: PdfPageLayoutMode.continuous,
                ),
    );
  }
}

class _TextLineGroup {
  _TextLineGroup(this.lines, this.gapBefore);
  final List<TextLine> lines;
  final double gapBefore;
}
