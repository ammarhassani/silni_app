# Golden Tests

Golden tests compare rendered widgets to saved "golden" image files to detect unintended visual changes.

## How to Add Golden Tests

1. Create test file in this directory (e.g., `home_screen_golden_test.dart`)
2. Use `golden_toolkit` package:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('HomeScreen renders correctly', (tester) async {
    await loadAppFonts();
    await tester.pumpWidgetBuilder(HomeScreen());
    await screenMatchesGolden(tester, 'home_screen');
  });
}
```

3. First run generates golden files: `flutter test test/golden/ --update-goldens`
4. Future runs compare against golden files

## Updating Goldens

When UI intentionally changes:
```bash
make update-goldens
```

## CI Considerations

Golden tests may produce different results on different machines due to font rendering.
Consider running golden tests only on CI with consistent environment.
