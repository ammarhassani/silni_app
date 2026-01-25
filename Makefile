.PHONY: test test-unit test-widget test-integration test-e2e test-golden coverage clean bug-scout test-adversarial adversarial-quick mutation-test torture-quick torture torture-ultimate nuclear

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
	@command -v entr >/dev/null 2>&1 || { echo "Install entr for watch mode: brew install entr"; exit 1; }
	@find lib test -name "*.dart" | entr -c flutter test

# Adversarial Testing - Bug Scout (The Prosecutor)
bug-scout:
	@./scripts/bug_scout.sh

# Run all adversarial tests
test-adversarial:
	flutter test test/adversarial/

# Quick adversarial tests (fuzz + security only)
adversarial-quick:
	@./scripts/bug_scout.sh --quick

# Mutation Testing - Kill Every Mutant!
mutation-test:
	@./scripts/mutation_test.sh

# ============================================================================
# TORTURE TESTING - Leave No Bug Alive!
# ============================================================================

# Quick torture - fast feedback (analyze + unit + widget)
torture-quick:
	@echo ""
	@echo "⚡ QUICK TORTURE - Fast feedback loop"
	@echo "======================================="
	@flutter analyze --no-fatal-infos && \
	flutter test test/unit/ --coverage && \
	flutter test test/widget/ --coverage
	@echo ""
	@echo "✓ Quick torture complete!"

# Standard torture - comprehensive testing
torture:
	@echo ""
	@echo "🔥 STANDARD TORTURE - Comprehensive testing"
	@echo "============================================"
	@./scripts/test_all.sh && ./scripts/bug_scout.sh
	@echo ""
	@echo "✓ Standard torture complete!"

# Ultimate torture - the full battery with mutation testing
torture-ultimate:
	@./scripts/ultimate_torture.sh --full

# Nuclear option - when you want to be ABSOLUTELY sure
nuclear:
	@echo ""
	@echo "☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️"
	@echo ""
	@echo "        N U C L E A R   O P T I O N   A C T I V A T E D"
	@echo ""
	@echo "    This will run EVERYTHING. Tests. Fuzzing. Chaos. Mutations."
	@echo "    No stone will be left unturned. No bug will survive."
	@echo ""
	@echo "    Estimated time: 15-30 minutes"
	@echo ""
	@echo "☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️  ☢️"
	@echo ""
	@sleep 2
	@./scripts/ultimate_torture.sh --full
