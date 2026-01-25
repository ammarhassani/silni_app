# Silni App Testing Guidelines

## Quick Reference

```bash
# Run all tests (the "one button" solution)
make test

# Quick smoke test during development
make smoke

# Watch mode for TDD
make watch
```

## Testing Pyramid

```
        /\
       /E2E\         ← Few, slow, high-value (Patrol)
      /------\
     / Golden \      ← UI regression detection
    /----------\
   / Integration \   ← Critical user flows
  /--------------\
 /   Widget Tests  \ ← Screen-level behavior
/------------------\
     Unit Tests      ← Services, models, utils
```

## Test Organization

```
test/
├── unit/           # Pure logic tests (fast, isolated)
│   ├── services/   # Service layer tests
│   ├── models/     # Model serialization tests
│   └── utils/      # Utility function tests
├── widget/         # Widget behavior tests
│   └── [feature]/  # Organized by feature
├── golden/         # UI screenshot tests
│   ├── widgets/    # Component goldens
│   └── screens/    # Full screen goldens
├── integration/    # Multi-component tests
└── helpers/        # Shared test utilities
```

## Writing Tests

### Unit Tests
- Test one thing per test
- Use descriptive names: `should_doX_when_Y`
- Mock all dependencies
- Focus on behavior, not implementation

### Widget Tests
- Test user interactions
- Verify UI state changes
- Use `pumpAndSettle()` for animations
- Don't test framework behavior

### Golden Tests
- Capture baseline: `make update-goldens`
- Review diffs carefully before updating
- Test different device sizes

### Integration Tests
- Test complete user flows
- Use real services where possible
- Clean up test data after

## Coverage Requirements - TORTURE MODE

| Category | Minimum | Target | Nuclear |
|----------|---------|--------|---------|
| Unit Tests | 80% | 95% | 100% |
| Widget Tests | All screens | All interactions | Every gesture |
| Integration | All flows | All failures | All edge cases |
| Adversarial | All inputs | All boundaries | Total chaos |
| Mutation | 70% killed | 90% killed | 100% killed |
| Memory Leaks | 0 | 0 | 0 |

## Before Committing

1. Run `make smoke` - quick validation
2. All tests should pass
3. No new lint warnings

## When Tests Fail in CI

1. Check the failed test output
2. Run locally to reproduce
3. Fix the issue (don't skip the test)
4. For golden failures: review the diff
