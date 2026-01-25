.PHONY: test test-unit test-widget test-integration test-e2e test-golden coverage clean

# Run all tests (one command to rule them all)
test:
	@./scripts/test_all.sh

# Individual test suites
test-unit:
	flutter test test/unit/ --coverage

test-widget:
	flutter test test/widget/ --coverage

test-integration:
	flutter test integration_test/

test-golden:
	flutter test test/golden/

test-e2e:
	patrol test

# Update golden files when UI changes intentionally
update-goldens:
	flutter test test/golden/ --update-goldens

# Coverage report
coverage:
	flutter test --coverage
	@echo "Coverage report: coverage/lcov.info"
	@lcov --summary coverage/lcov.info 2>/dev/null || echo "Install lcov: brew install lcov"

# Clean generated files
clean:
	flutter clean
	rm -rf coverage/
	rm -rf .dart_tool/

# Quick smoke test (fastest feedback)
smoke:
	flutter analyze --no-fatal-infos
	flutter test test/unit/

# Watch mode for TDD
watch:
	@echo "Running tests in watch mode (requires entr)"
	@find lib test -name "*.dart" | entr -c flutter test
