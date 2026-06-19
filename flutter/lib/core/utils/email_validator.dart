/// Compiled once at first use. Mirrors the de-facto RFC 5322 simplified
/// pattern: a local part composed of one or more dot-separated atoms,
/// then `@`, then a hostname whose labels are alphanumeric (with optional
/// internal hyphens) joined by single dots, and at least one TLD segment.
///
/// Rejects:
///  - consecutive dots in the local part (`foo..bar@…`)
///  - consecutive dots in the domain (`…@combinate..me`)
///  - leading or trailing dots (`.foo@…`, `foo.@…`, `…@.bar.com`,
///    `…@bar.com.`)
///  - hyphens at the start or end of a label (`-bar.com`, `bar-.com`)
///  - missing TLD (`foo@bar`)
///
/// Accepts everything `<input type="email">` accepts in a browser, plus
/// the same plus-tagging / dot-segment local parts (`a.b+tag@host.tld`)
/// real auth providers use.
final RegExp _emailRegExp = RegExp(
  r"^[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+"
  r"(?:\.[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)*"
  r"@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
  r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
);

/// Returns true when [value] is a syntactically valid email per the
/// simplified RFC 5322 pattern. Trims surrounding whitespace first.
bool isValidEmail(String value) => _emailRegExp.hasMatch(value.trim());
