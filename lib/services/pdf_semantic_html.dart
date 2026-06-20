import 'dart:math' as math;

/// Escapes HTML special characters.
String escapeHtml(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

/// Converts plain paragraph text to safe HTML, wrapping transcript-style
/// citations (e.g. Tr.D.1, Pl.D. 2, Ex. 4) in `<sup class="cite-ref">`.
String plainTextToHtmlWithCitations(String plain) {
  if (plain.isEmpty) return '';

  final RegExp cite = RegExp(
    r'\b(?:Tr\.?\s*)?[Dd]\.?\s*\d+[a-z]?\b'
    r'|\b(?:Pl\.?\s*)?[Dd]\.?\s*\d+[a-z]?\b'
    r'|\bEx\.?\s*\d+[a-z]?\b'
    r'|\b(?:App\.?\s*)?(?:Vol\.?\s*)?\d+\s*,\s*p\.?\s*\d+\b',
    caseSensitive: false,
  );

  final StringBuffer buf = StringBuffer();
  int last = 0;
  for (final RegExpMatch m in cite.allMatches(plain)) {
    buf.write(escapeHtml(plain.substring(last, m.start)));
    buf.write('<sup class="cite-ref">${escapeHtml(m[0]!)}</sup>');
    last = m.end;
  }
  buf.write(escapeHtml(plain.substring(last)));
  return buf.toString();
}

/// True if [line] matches legal-style Roman + uppercase remainder.
bool isRomanSectionHeadingLine(String line) {
  final String t = line.trim();
  if (t.length < 10 || t.length > 220) return false;
  final RegExp re = RegExp(
    r'^(?:[IVXLCDM]{1,8}|[ivxlcdm]{1,8})\.\s+(.+)$',
  );
  final Match? m = re.firstMatch(t);
  if (m == null) return false;
  final String rest = m[1]!.trim();
  if (rest.length < 6) return false;
  if (RegExp(r'[a-z]').hasMatch(rest)) return false;
  final int letters = RegExp(r'[A-Za-z]').allMatches(rest).length;
  final int upper = RegExp(r'[A-Z]').allMatches(rest).length;
  return letters >= 8 && upper / math.max(letters, 1) > 0.75;
}
